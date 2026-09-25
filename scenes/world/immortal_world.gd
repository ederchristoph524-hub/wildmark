class_name ImmortalWorld
extends RefCounted
## Unsterblichen-Ebene in der Welt (docs/UNSTERBLICH.md, 5 und 10): Weltregeln der Dimensionen, Landgeister (eigene
## Apertur und Gesegnete Länder der Geschichte) und die NPC-Unsterblichen – im Allerheiligsten ihrer Siedlung, als
## Wächter an einem Ort oder für sich im Gebiet.

const SANCTUM_OFFSET: Vector3 = Vector3(-5.0, 0.0, -4.0)
const GUARD_DISTANCE: float = 7.0
const LONER_MIN: float = 40.0
const LONER_MAX: float = 140.0


static func world() -> World:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(World.GROUP_WORLD) as World if tree != null else null


static func player() -> Player:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(Player.GROUP_PLAYER) as Player if tree != null else null


## Nach Rangwechsel oder freiem Start: Leben und Rangfarbe des Spielers anpassen.
static func refresh_player() -> void:
	var who: Player = player()
	if who == null:
		return
	who.immortal.refresh()
	who.health.hp = who.health.max_hp
	who.model.set_rank_color(DataRegistry.progression().rank_color(GameState.rank))


## Wird am Ende von World._ready aufgerufen.
static func setup(owner_world: World) -> void:
	ImmortalProgress.connect_signals()
	var area: AreaData = owner_world.area
	if not area.immortal.is_empty():
		owner_world.add_child(DimensionRules.create(owner_world))
	if area.id == ImmortalAperture.AREA_ID:
		_add_spirit(owner_world, area, true, ImmortalAperture.SPIRIT_AT)
	elif area.immortal.has("spirit"):
		_add_spirit(owner_world, area, false, area.arrival * 0.5)
	_place_loners(owner_world, area)


static func _add_spirit(owner_world: World, area: AreaData, own: bool, at: Vector2) -> void:
	var spirit: LandSpirit = LandSpirit.create(area, own)
	owner_world.add_child(spirit)
	spirit.position = owner_world.ground_point(at.x, at.y)
	owner_world.add_poi(spirit.position, MapData.KIND_PLACE, Loc.t(spirit.spirit_name))


## Unsterbliche im Allerheiligsten einer Siedlung (aus SettlementPeople.place, mit den Ankerpunkten der Siedlung).
static func place_sanctum(owner_world: World, settlement: Dictionary, anchors: Dictionary) -> void:
	for placement: Dictionary in DataRegistry.immortal().placements:
		if placement["area"] != owner_world.area.id or placement["settlement"] != settlement.get("id", &""):
			continue
		var hall: Vector3 = anchors.get("hall", owner_world.ground_point(0.0, 0.0))
		_spawn(owner_world, placement["master"], hall + SANCTUM_OFFSET)


## Wächter und Einzelgänger ohne Siedlung.
static func _place_loners(owner_world: World, area: AreaData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(area.id)
	for placement: Dictionary in DataRegistry.immortal().placements:
		if placement["area"] != area.id or placement["settlement"] != &"":
			continue
		var at: Vector2 = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(LONER_MIN, minf(LONER_MAX, area.size * 0.35))
		if placement["role"] == &"waechter":
			for place: Dictionary in area.places:
				if place.get("type") == &"erbe":
					at = (place["position"] as Vector2) + Vector2(GUARD_DISTANCE, GUARD_DISTANCE)
					break
		_spawn(owner_world, placement["master"], owner_world.ground_point(at.x, at.y))


static func _spawn(owner_world: World, id: StringName, at: Vector3) -> void:
	var data: GuMasterData = DataRegistry.gu_master(id)
	if data == null:
		return
	var master := GuMaster.new()
	master.setup(data, "%s, %s" % [Loc.t(data.display_name), Loc.t(data.title)] if data.title != "" else data.display_name, at)
	owner_world.add_child(master)
	owner_world.add_poi(at, MapData.KIND_PLACE, Loc.t(data.display_name))
