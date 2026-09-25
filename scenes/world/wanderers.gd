class_name Wanderers
extends Node
## Wandernde Gu-Meister eines Gebiets (gebiete.json → wanderer): hält anzahl Wanderer auf den Straßen unterwegs
## (Nachschub alle wanderer_respawn Sekunden) und schickt Gesuchten jeden Morgen Kopfgeldjäger ihres Rangs hinterher.

const HUNTER_TITLE: String = "Kopfgeldjäger"
const ROUTE_STEP: float = 12.0
const ROUTE_POINTS: int = 6
## Anteil der Wanderer auf Straßen; die übrigen streifen durch die Wildnis (WILD_WALK Meter hin und her).
const ROAD_SHARE: float = 0.7
const WILD_WALK: float = 18.0
const ARRIVAL_GAP: float = 40.0

var world: World = null
var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init(owner_world: World) -> void:
	world = owner_world
	name = "Wanderers"


func _ready() -> void:
	_rng.randomize()
	_timer = Balance.values.wanderer_respawn
	for i: int in world.area.wanderer_count:
		spawn_wanderer()
	EventBus.day_started.connect(_on_day)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = Balance.values.wanderer_respawn
	if count_alive(false) < world.area.wanderer_count:
		spawn_wanderer()


func count_alive(hunters: bool) -> int:
	var total: int = 0
	for node: Node in get_tree().get_nodes_in_group(Wanderer.GROUP):
		var wanderer: Wanderer = node as Wanderer
		if wanderer.bounty_hunter == hunters and not wanderer.fleeing and wanderer.raid_target == &"":
			total += 1
	return total


## Ein Wanderer auf einem Straßenstück außerhalb der Siedlungen.
func spawn_wanderer() -> Wanderer:
	if world.area.wanderers.is_empty():
		return null
	var id: StringName = world.area.wanderers[_rng.randi() % world.area.wanderers.size()]
	var route: Array[Vector3] = _route()
	if route.is_empty():
		return null
	var wanderer := Wanderer.new()
	wanderer.setup(DataRegistry.gu_master(id), "", route[0] + Vector3.UP * 0.3)
	wanderer.route = route
	world.entities.add_child(wanderer)
	return wanderer


## Kopfgeldjäger auf deinem Rang und deiner Stufe, der dich vom Rand deines Blickfelds aus verfolgt.
func spawn_hunter(near: Vector3) -> Wanderer:
	var source: GuMasterData = _hunter_data()
	if source == null:
		return null
	var data: GuMasterData = source.duplicate() as GuMasterData
	data.rank = clampi(GameState.rank, 1, 5)
	data.stage = GameState.stage
	var at: Vector3 = _point_around(near, Balance.values.bounty_distance)
	var hunter := Wanderer.new()
	hunter.setup(data, "%s – %s" % [tr(HUNTER_TITLE), tr(source.display_name)], at + Vector3.UP * 0.3)
	hunter.bounty_hunter = true
	world.entities.add_child(hunter)
	return hunter


func _on_day(_day: int) -> void:
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
	if player == null or not Renown.is_wanted() or Renown.disguised() or count_alive(true) > 0:
		return
	for i: int in (2 if Renown.is_demon() else 1):
		spawn_hunter(player.global_position)
	EventBus.message.emit(tr("Kopfgeldjäger sind dir auf den Fersen!"), Renown.INFAMY_COLOR)


## Rechtschaffene Meister (Wanderer des Gebiets bevorzugt), deren Rang deinem am nächsten liegt.
func _hunter_data() -> GuMasterData:
	var pool: Array[GuMasterData] = []
	for id: StringName in world.area.wanderers:
		var master: GuMasterData = DataRegistry.gu_master(id)
		if master.faction == Renown.RIGHTEOUS:
			pool.append(master)
	if pool.is_empty():
		for resource: Resource in DataRegistry.all(&"gu_masters"):
			if (resource as GuMasterData).faction == Renown.RIGHTEOUS:
				pool.append(resource as GuMasterData)
	if pool.is_empty():
		return null
	pool.sort_custom(func(a: GuMasterData, b: GuMasterData) -> bool: return absi(a.rank - GameState.rank) < absi(b.rank - GameState.rank))
	return pool[0]


## Meist ein Straßenstück (bis vor die nächste Siedlung), sonst ein kurzer Pfad in der Wildnis.
func _route() -> Array[Vector3]:
	var route: Array[Vector3] = []
	var paths: Array = world.area.paths
	for attempt: int in (8 if _rng.randf() < ROAD_SHARE else 0):
		route.clear()
		if paths.is_empty():
			break
		var points: Array = _densify(paths[_rng.randi() % paths.size()])
		if points.size() < 2:
			continue
		var start: int = _rng.randi_range(0, points.size() - 2)
		for i: int in range(start, mini(points.size(), start + ROUTE_POINTS)):
			var point: Vector2 = points[i]
			if world.in_settlement(point.x, point.y) or world.terrain.in_water(point.x, point.y):
				break
			route.append(world.ground_point(point.x, point.y))
		if route.size() >= 2:
			return route
	route.clear()
	var origin: Vector3 = _wild_point()
	route.append(origin)
	var end: Vector3 = _point_around(origin, WILD_WALK)
	if end.distance_to(origin) > 4.0:
		route.append(end)
	return route


## Freier, nicht zu steiler Platz an Land, abseits von Siedlungen und Ankunftspunkt.
func _wild_point() -> Vector3:
	var half: float = world.area.size * 0.4
	for attempt: int in 40:
		var x: float = _rng.randf_range(-half, half)
		var z: float = _rng.randf_range(-half, half)
		if world.terrain.is_inside(x, z, 6.0) and not world.terrain.in_water(x, z) and not world.in_settlement(x, z) \
				and world.terrain.slope_at(x, z) < 0.45 and Vector2(x, z).distance_to(world.area.arrival) > ARRIVAL_GAP:
			return world.ground_point(x, z)
	return world.spawn_point()


## Straßenpunkte im Abstand von etwa ROUTE_STEP.
func _densify(path: Array) -> Array:
	var result: Array = []
	for i: int in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var steps: int = maxi(1, ceili(a.distance_to(b) / ROUTE_STEP))
		for s: int in steps:
			result.append(a.lerp(b, float(s) / steps))
	if not path.is_empty():
		result.append(path[path.size() - 1])
	return result


func _point_around(center: Vector3, distance: float) -> Vector3:
	for attempt: int in 16:
		var angle: float = _rng.randf() * TAU
		var x: float = center.x + cos(angle) * distance
		var z: float = center.z + sin(angle) * distance
		if world.terrain.is_inside(x, z, 4.0) and not world.terrain.in_water(x, z) and not world.in_settlement(x, z):
			return world.ground_point(x, z)
	return world.ground_point(center.x, center.z)
