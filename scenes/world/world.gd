class_name World
extends Node3D
## Das Startgebiet (Südliche Grenze): Gelände, Vegetation, Sammelstellen, Lager, wilde Gu, Bestien und Tageszeit.

const GROUP_WORLD: StringName = &"world"
const SEED: int = 99
const CAMP_CENTER: Vector3 = Vector3.ZERO
const SPAWN_OFFSET: Vector3 = Vector3(3.0, 0.0, 4.0)
## Sammelstellen: Gegenstand → [Anzahl, Ertrag, minimale und maximale Entfernung vom Lager].
const RESOURCE_LAYOUT: Dictionary[StringName, Array] = {
	&"beeren": [46, 3, 20.0, 100.0],
	&"stein": [30, 2, 22.0, 105.0],
	&"kristall": [18, 1, 26.0, 108.0],
	&"holz": [26, 2, 20.0, 100.0],
	&"gruenkraut": [34, 2, 18.0, 100.0],
	&"eisenerz": [18, 1, 60.0, 108.0],
	&"mondtau": [40, 1, 15.0, 95.0],
}
## Unsichtbare Grenze hinter dem Randgebirge.
const BOUND_DISTANCE: float = 112.0
const BOUND_HEIGHT: float = 120.0
const WILD_GU_MIN_DISTANCE: float = 30.0
const WILD_GU_MAX_DISTANCE: float = 92.0

var terrain: Terrain = null
var entities: Node3D = null
var spawner: EnemySpawner = null
var day_night: DayNight = null
var camp: Campfire = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "World"
	add_to_group(GROUP_WORLD)
	_rng.seed = SEED
	terrain = Terrain.new()
	add_child(terrain)
	add_child(Vegetation.new(terrain))
	_build_bounds()
	entities = Node3D.new()
	entities.name = "Entities"
	entities.add_to_group(Combat.GROUP_FX_ROOT)
	add_child(entities)
	day_night = DayNight.new()
	add_child(day_night)
	camp = Campfire.new()
	add_child(camp)
	camp.position = ground_point(CAMP_CENTER.x, CAMP_CENTER.z)
	_place_resources()
	WorldAreas.build(self)
	_place_wild_gu()
	spawner = EnemySpawner.new(terrain, entities)
	add_child(spawner)
	if not GameState.loot_sack.is_empty():
		Pickup.spawn(get_tree(), GameState.loot_sack["position"], GameState.loot_sack["items"], true)


func _build_bounds() -> void:
	var bounds := StaticBody3D.new()
	bounds.name = "Bounds"
	add_child(bounds)
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, BOUND_HEIGHT, BOUND_DISTANCE * 2.0) if side.x != 0.0 else Vector3(BOUND_DISTANCE * 2.0, BOUND_HEIGHT, 2.0)
		shape.shape = box
		shape.position = side * BOUND_DISTANCE
		bounds.add_child(shape)


func ground_point(x: float, z: float) -> Vector3:
	return Vector3(x, terrain.height_at(x, z), z)


## Startpunkt neben dem Lagerfeuer.
func spawn_point() -> Vector3:
	return ground_point(CAMP_CENTER.x + SPAWN_OFFSET.x, CAMP_CENTER.z + SPAWN_OFFSET.z) + Vector3.UP * 0.5


func _random_point(min_distance: float, max_distance: float) -> Vector3:
	for attempt: int in 20:
		var angle: float = _rng.randf() * TAU
		var distance: float = _rng.randf_range(min_distance, max_distance)
		var x: float = cos(angle) * distance
		var z: float = sin(angle) * distance
		if terrain.is_inside(x, z, 3.0) and terrain.slope_at(x, z) < 0.45:
			return ground_point(x, z)
	return ground_point(min_distance, 0.0)


## Sammelstelle an einem Punkt (auch für besondere Gebiete).
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


func _place_resources() -> void:
	for item: StringName in RESOURCE_LAYOUT:
		var layout: Array = RESOURCE_LAYOUT[item]
		for i: int in int(layout[0]):
			add_resource(item, int(layout[1]), _random_point(float(layout[2]), float(layout[3])))


## Je ein wilder Rang-1-Gu jeder Familie außer der gewählten; gefundene erscheinen nicht erneut.
func _place_wild_gu() -> void:
	var families: Array[Resource] = DataRegistry.all(&"families")
	for i: int in families.size():
		var family: GuFamilyData = families[i] as GuFamilyData
		var point: Vector3 = _random_point(WILD_GU_MIN_DISTANCE, WILD_GU_MAX_DISTANCE)
		var spot: StringName = StringName("wild_" + String(family.id))
		if family.id == GameState.first_family or spot in GameState.collected_wild_gu:
			continue
		var member: GuData = family.member_for_rank(1)
		if member == null:
			continue
		var wild := WildGu.new()
		wild.setup(spot, member)
		add_child(wild)
		wild.position = point
