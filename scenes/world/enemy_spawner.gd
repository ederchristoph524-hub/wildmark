class_name EnemySpawner
extends Node
## Lässt Bestien je nach Zone (Entfernung vom Lager) und Tageszeit erscheinen, entfernt ferne und beschwört Diener und Gefährten.

const GROUP: StringName = &"enemy_spawner"
const SPAWN_ATTEMPTS: int = 12

var terrain: Terrain = null
var entities: Node3D = null
var _timer: float = 2.0


func _init(world_terrain: Terrain, entity_parent: Node3D) -> void:
	terrain = world_terrain
	entities = entity_parent
	name = "EnemySpawner"


func _ready() -> void:
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Player
	if player == null or player.is_dead():
		return
	var b: BalanceData = Balance.values
	var night: bool = Formulas.is_night(b, GameState.time_of_day)
	_despawn(player, night)
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = b.spawn_interval / (b.night_spawn_mult if night else 1.0)
	var limit: int = roundi(b.max_enemies * (b.night_spawn_mult if night else 1.0))
	if get_tree().get_nodes_in_group(Enemy.GROUP_ENEMIES).size() < limit:
		_spawn_near(player, night)


func zone_at(point: Vector3) -> int:
	var distance: float = Vector2(point.x, point.z).length()
	var radii: Array[float] = Balance.values.zone_radii
	for i: int in radii.size():
		if distance < radii[i]:
			return i
	return radii.size()


## Bestien, die in dieser Zone und Tageszeit vorkommen (gegner.json: z, night, nospawn, boss).
func candidates(zone: int, night: bool) -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for resource: Resource in DataRegistry.all(&"enemies"):
		var data: EnemyData = resource as EnemyData
		if data.zone == zone and not data.no_spawn and not data.boss and (night or not data.night_only):
			result.append(data)
	return result


func _spawn_near(player: Player, night: bool) -> void:
	var b: BalanceData = Balance.values
	for attempt: int in SPAWN_ATTEMPTS:
		var angle: float = randf() * TAU
		var distance: float = randf_range(b.spawn_min_distance, b.spawn_max_distance)
		var x: float = player.global_position.x + cos(angle) * distance
		var z: float = player.global_position.z + sin(angle) * distance
		if not terrain.is_inside(x, z, 4.0) or Vector2(x, z).length() < Balance.values.village_safe_radius:
			continue
		var point := Vector3(x, terrain.height_at(x, z) + 0.3, z)
		var options: Array[EnemyData] = candidates(zone_at(point), night)
		if options.is_empty():
			continue
		spawn(options[randi() % options.size()], point)
		return


func spawn(data: EnemyData, at: Vector3) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(data, at)
	entities.add_child(enemy)
	return enemy


## Für Bestien mit beh=spawn (Riesenspinne → Spinnling).
func spawn_minion(enemy_id: StringName, at: Vector3, team: int) -> Enemy:
	var data: EnemyData = DataRegistry.enemy(enemy_id)
	if data == null:
		return null
	var minion: Enemy = spawn(data, Vector3(at.x, terrain.height_at(at.x, at.z) + 0.3, at.z))
	minion.is_minion = true
	if team != Combatant.TEAM_ENEMY:
		minion.set_team(team)
	return minion


## Für Rudelsegen: ein Gefährte auf Zeit.
func spawn_companion(enemy_id: StringName, at: Vector3, duration: float, owner_combatant: Combatant) -> void:
	var data: EnemyData = DataRegistry.enemy(enemy_id)
	if data == null:
		return
	var companion: Enemy = spawn(data, Vector3(at.x, terrain.height_at(at.x, at.z) + 0.3, at.z))
	companion.tame.call_deferred(owner_combatant, duration, 99)


func _despawn(player: Player, night: bool) -> void:
	var limit: float = Balance.values.despawn_distance
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP_ENEMIES):
		var enemy: Enemy = node as Enemy
		var too_far: bool = enemy.global_position.distance_to(player.global_position) > limit
		if too_far or (enemy.data.night_only and not night and enemy.state == Enemy.State.WANDER):
			enemy.queue_free()
