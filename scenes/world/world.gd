class_name World
extends Node3D
## Das aktuelle Gebiet (GameState.area, Daten aus gebiete.json): Gelände mit Plätzen, Seen und Wegen, Vegetation des Bioms,
## Siedlungen mit Bewohnern, besondere Orte, Hindernis-Orte, Sammelstellen, wilde Gu, Bestien und Tageszeit.

const GROUP_WORLD: StringName = &"world"
const SEED: int = 99
const BOUND_HEIGHT: float = 160.0
## Übergang, mit dem Plätze ins Gelände eingeebnet werden.
const SETTLEMENT_FALLOFF: float = 26.0
const PLACE_FALLOFF: float = 10.0
const SITE_RADIUS: float = 10.0
const RESOURCE_MIN_DISTANCE: float = 20.0
## Kartenname je Siedlungsart (%s = Fraktion).
const SETTLEMENT_TITLES: Dictionary[StringName, String] = {
	&"klan_dorf": "Dorf des %s", &"stadt": "Stadt des %s", &"zeltlager": "Lager: %s", &"oasenstadt": "Oase: %s",
	&"inseldorf": "Insel: %s", &"festung": "Festung des %s", &"sekte": "Sitz: %s", &"versteck": "Versteck: %s",
}
const SQUARE_SETTLEMENTS: Array[StringName] = [&"stadt", &"festung"]
const SQUARE_REACH: float = 1.3
## Übergang ins Gelände für Inseldörfer (sonst würde das Plateau ins Meer wachsen).
const ISLAND_FALLOFF: float = 6.0

var area: AreaData = null
var biome: BiomeData = null
var terrain: Terrain = null
var entities: Node3D = null
var spawner: EnemySpawner = null
## Bestienflut des Gebiets (null ohne gebiete.json → flut).
var tide: BeastTide = null
var wanderers: Wanderers = null
var day_night: DayNight = null
var camp: Campfire = null
## Freiflächen ohne Bäume und Sammelstellen (Siedlungen, Orte, Hindernis-Orte): (x, _, z, Radius).
var clearings: Array[Vector4] = []
## Siedlungen als Kreise (x, _, z, Radius) – dort keine Bestien.
var settlement_areas: Array[Vector4] = []
## Feste Kartenpunkte des Gebiets: {position: Vector3, kind: StringName (MapData.KIND_*), label: String}.
var pois: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "World"
	add_to_group(GROUP_WORLD)
	area = DataRegistry.area(GameState.area)
	if area == null or not area.open:
		area = DataRegistry.area(&"qing_mao")
		GameState.area = area.id
	biome = DataRegistry.biome(area.biome)
	_rng.seed = SEED + area.terrain_seed
	_build_terrain()
	if terrain.has_sea():
		WaterSurface.sea(self, biome.sea_level, biome.water)
	add_child(Vegetation.new(terrain, clearings, biome))
	_build_bounds()
	entities = Node3D.new()
	entities.name = "Entities"
	entities.add_to_group(Combat.GROUP_FX_ROOT)
	add_child(entities)
	day_night = DayNight.new()
	day_night.biome = biome
	add_child(day_night)
	_build_settlements()
	for place: Dictionary in area.places:
		WorldAreas.build(self, place)
	ObstacleSites.build(self, area)
	_place_resources()
	_place_wild_gu()
	spawner = EnemySpawner.new(terrain, entities)
	add_child(spawner)
	if not area.tide.is_empty():
		tide = BeastTide.new(self)
		add_child(tide)
	if area.wanderer_count > 0:
		wanderers = Wanderers.new(self)
		add_child(wanderers)
	BuildSystem.restore(self)
	if not GameState.loot_sack.is_empty() and GameState.loot_sack.get("area", area.id) == area.id:
		Pickup.spawn(get_tree(), GameState.loot_sack["position"], GameState.loot_sack["items"], true)


## Gelände: Plätze für Siedlungen, Orte und Hindernisse einebnen, Seen ausheben, Wege färben.
func _build_terrain() -> void:
	terrain = Terrain.new(area, biome)
	var roads: Array = area.paths.duplicate()
	for settlement: Dictionary in area.settlements:
		var at: Vector2 = settlement["position"]
		var radius: float = settlement["radius"]
		# Quadratische Mauern (Stadt, Festung) reichen mit den Ecken bis 1,27 × Radius – auch dort muss es eben sein.
		var reach: float = radius * SQUARE_REACH if settlement["type"] in SQUARE_SETTLEMENTS else radius
		terrain.flats.append(Vector4(at.x, at.y, reach + 4.0, ISLAND_FALLOFF if settlement["type"] == &"inseldorf" else SETTLEMENT_FALLOFF))
		terrain.plazas.append(Vector4(at.x, at.y, radius * 0.95, 0.0))
		clearings.append(Vector4(at.x, 0.0, at.y, reach + 8.0))
		settlement_areas.append(Vector4(at.x, 0.0, at.y, radius + 10.0))
		roads.append_array(Settlement.roads(settlement))
		if settlement.get("pond", 0.0) > 0.0:
			terrain.lakes.append(Vector4(at.x, at.y, float(settlement["pond"]), 0.0))
	for place: Dictionary in area.places:
		var at: Vector2 = place["position"]
		var radius: float = place["radius"]
		if place["type"] == &"see":
			terrain.lakes.append(Vector4(at.x, at.y, radius, 0.0))
		else:
			terrain.flats.append(Vector4(at.x, at.y, radius + 2.0, PLACE_FALLOFF))
		if WorldAreas.GROUND_COLORS.has(place["type"]):
			terrain.stains.append({"at": at, "radius": radius + 1.5, "color": WorldAreas.GROUND_COLORS[place["type"]]})
		clearings.append(Vector4(at.x, 0.0, at.y, radius + 3.0))
	for point: Vector2 in ObstacleSites.centers(area):
		terrain.flats.append(Vector4(point.x, point.y, SITE_RADIUS, PLACE_FALLOFF))
		clearings.append(Vector4(point.x, 0.0, point.y, SITE_RADIUS))
	terrain.paths = roads
	terrain.generate()
	add_child(terrain)


func _build_settlements() -> void:
	for settlement: Dictionary in area.settlements:
		var at: Vector2 = settlement["position"]
		var center: Vector3 = ground_point(at.x, at.y)
		if float(settlement.get("pond", 0.0)) > 0.0:
			# Die Mitte liegt im Teich – Bauhöhe vom Ufer nehmen.
			center.y = terrain.height_at(at.x, at.y + float(settlement["pond"]) + 4.0)
		var anchors: Dictionary = Settlement.build(self, settlement, center)
		SettlementPeople.place(self, settlement, anchors)
		if float(settlement.get("pond", 0.0)) > 0.0:
			WaterSurface.lake(self, terrain.lake_at(at), biome.water, 0.0)
		var sect: SectData = DataRegistry.sect(settlement["faction"])
		add_poi(center, MapData.KIND_VILLAGE, Loc.t(String(SETTLEMENT_TITLES.get(settlement["type"], "Dorf des %s"))) % Loc.t(sect.display_name))
		if camp == null:
			camp = Campfire.new()
			add_child(camp)
			var fire: Vector3 = anchors.get("fire", Vector3(at.x, 0.0, at.y + settlement["radius"] * 0.12))
			camp.position = ground_point(fire.x, fire.z)


func _build_bounds() -> void:
	var bounds := StaticBody3D.new()
	bounds.name = "Bounds"
	add_child(bounds)
	var limit: float = area.size * 0.5 - 6.0
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, BOUND_HEIGHT, limit * 2.0) if side.x != 0.0 else Vector3(limit * 2.0, BOUND_HEIGHT, 2.0)
		shape.shape = box
		shape.position = side * limit
		bounds.add_child(shape)


func add_poi(at: Vector3, kind: StringName, label: String) -> void:
	pois.append({"position": at, "kind": kind, "label": label})


func ground_point(x: float, z: float) -> Vector3:
	return Vector3(x, terrain.height_at(x, z), z)


## Ankunftspunkt des Gebiets (neues Spiel, Reisen, Wiederbeleben ohne Ruheort).
func spawn_point() -> Vector3:
	return ground_point(area.arrival.x, area.arrival.y) + Vector3.UP * 0.5


## Liegt der Punkt in einer Siedlung (dort erscheinen keine Bestien)?
func in_settlement(x: float, z: float) -> bool:
	for zone: Vector4 in settlement_areas:
		if Vector2(x - zone.x, z - zone.z).length() < zone.w:
			return true
	return false


func _random_point(min_distance: float, max_distance: float) -> Vector3:
	for attempt: int in 30:
		var angle: float = _rng.randf() * TAU
		var distance: float = _rng.randf_range(min_distance, max_distance)
		var x: float = cos(angle) * distance
		var z: float = sin(angle) * distance
		if terrain.is_inside(x, z, 3.0) and terrain.slope_at(x, z) < 0.45 and not in_clearing(x, z) and not terrain.in_water(x, z):
			return ground_point(x, z)
	return ground_point(min_distance, 0.0)


## Sammelstelle an einem Punkt (auch für besondere Orte).
func add_resource(item: StringName, yield_amount: int, at: Vector3) -> ResourceNode:
	var node := ResourceNode.new(item, yield_amount)
	add_child(node)
	node.position = at
	node.rotation.y = _rng.randf() * TAU
	return node


func random_point_near(center: Vector2, radius: float) -> Vector3:
	var angle: float = _rng.randf() * TAU
	var distance: float = sqrt(_rng.randf()) * radius
	return ground_point(center.x + cos(angle) * distance, center.y + sin(angle) * distance)


func in_clearing(x: float, z: float) -> bool:
	for clearing: Vector4 in clearings:
		if Vector2(x - clearing.x, z - clearing.z).length() < clearing.w:
			return true
	return false


func _place_resources() -> void:
	var limit: float = area.size * 0.5 - area.relief.get(&"rand", 40.0)
	for item: StringName in area.resources:
		var layout: Vector2i = area.resources[item]
		for i: int in layout.x:
			add_resource(item, layout.y, _random_point(RESOURCE_MIN_DISTANCE, limit))


## Je ein wilder Gu jeder Familie (Rang des Gebiets) außer der gewählten; gefundene erscheinen nicht erneut.
func _place_wild_gu() -> void:
	for resource: Resource in DataRegistry.all(&"families"):
		var family: GuFamilyData = resource as GuFamilyData
		var point: Vector3 = _random_point(area.wild_gu_range.x, area.wild_gu_range.y)
		var spot: StringName = StringName("wild_" + String(family.id)) if area.wild_gu_rank == 1 else StringName("wild_%s_r%d" % [family.id, area.wild_gu_rank])
		if (family.id == GameState.first_family and area.wild_gu_rank == 1) or spot in GameState.collected_wild_gu:
			continue
		var member: GuData = family.member_for_rank(area.wild_gu_rank)
		if member != null:
			_add_wild(spot, member, point, false)
	for entry: Array in area.wild_passives:
		var passive_spot: StringName = StringName("wild_" + String(entry[0]))
		if passive_spot in GameState.collected_wild_gu:
			continue
		var data: Resource = null
		if entry[1] == &"body":
			data = DataRegistry.body_gu(entry[0])
		else:
			data = DataRegistry.support_gu(entry[0])
		_add_wild(passive_spot, data, _random_point(float(entry[2]), float(entry[3])), bool(entry[4]))


func _add_wild(spot: StringName, data: Resource, point: Vector3, is_hidden: bool) -> void:
	var wild := WildGu.new()
	wild.setup(spot, data, is_hidden)
	add_child(wild)
	wild.position = point
