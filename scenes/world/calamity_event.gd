class_name CalamityEvent
extends Node
## Eine Kalamität oder Trübsal (docs/UNSTERBLICH.md, 2 und 4): Für die Dauer der Prüfung greifen Himmel und Erde an –
## Wellen von Kalamitätswesen des Rangs, angekündigte Blitzeinschläge und Beben rund um den Spieler, der Himmel verdunkelt
## sich. Übersteht der Spieler die Zeit, meldet finished(true); stirbt er, finished(false).

signal finished(survived: bool)

const BOLT_COLOR: Color = Color(0.75, 0.88, 1.0)
const QUAKE_COLOR: Color = Color(0.8, 0.62, 0.38)
const QUAKE_INTERVAL: float = 5.0
const BOLT_TARGET_SPREAD: float = 7.0
const BOLT_ON_PLAYER: float = 0.45
const GLOOM: float = 0.95
const QUAKE_ROOT_STACKS: int = 1

## Anzeige im HUD (wie BeastTide.status_text).
static var status_text: String = ""

var world: World = null
var calamity_id: StringName = &""
var rank: int = 6
var _data: Dictionary = {}
var _elapsed: float = 0.0
var _duration: float = 40.0
var _wave_times: Array[float] = []
var _bolt_times: Array[float] = []
var _quake_timer: float = QUAKE_INTERVAL
var _spawned: Array[Enemy] = []
var _done: bool = false


static func create(owner_world: World, id: StringName, calamity_rank: int) -> CalamityEvent:
	var node := CalamityEvent.new()
	node.name = "Calamity"
	node.world = owner_world
	node.calamity_id = id
	node.rank = calamity_rank
	return node


func _ready() -> void:
	_data = DataRegistry.immortal().calamity(calamity_id)
	_duration = float(_data.get("duration", 40.0))
	var waves: int = int(_data.get("waves", 3))
	for i: int in waves:
		_wave_times.append(_duration * float(i + 1) / (waves + 1))
	var bolts: int = int(_data.get("bolts", 0))
	for i: int in bolts:
		_bolt_times.append(_duration * (0.1 + 0.85 * float(i) / maxf(bolts, 1.0)))
	EventBus.player_died.connect(_on_player_died)
	tree_exiting.connect(_on_exit)
	_set_weather(GLOOM)
	EventBus.message.emit(Loc.t("%s bricht los!") % Loc.t(String(_data.get("name", ""))), _data.get("color", Color.WHITE))
	Sound.play(&"drum")


func _physics_process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Player
	if player == null:
		return
	while not _wave_times.is_empty() and _elapsed >= _wave_times[0]:
		_wave_times.pop_front()
		_spawn_wave(player)
	while not _bolt_times.is_empty() and _elapsed >= _bolt_times[0]:
		_bolt_times.pop_front()
		_bolt(player)
	if bool(_data.get("quakes", false)):
		_quake_timer -= delta
		if _quake_timer <= 0.0:
			_quake_timer = QUAKE_INTERVAL
			_quake(player)
	status_text = "%s · %d s" % [Loc.t(String(_data.get("name", ""))), ceili(maxf(_duration - _elapsed, 0.0))]
	if _elapsed >= _duration:
		_finish(true)


func _spawn_wave(player: Player) -> void:
	var beasts: Array = DataRegistry.immortal().calamity_beasts.get(clampi(rank, 5, 9), [])
	if beasts.is_empty():
		return
	var count: int = Balance.immortal.wave_beasts + floori(float(_data.get("waves", 3)) / 3.0)
	for i: int in count:
		var angle: float = randf() * TAU
		var spot: Vector3 = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * Balance.immortal.wave_spawn_distance
		if not world.terrain.is_inside(spot.x, spot.z, 6.0) or world.terrain.in_water(spot.x, spot.z):
			spot = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 6.0
		var data: EnemyData = DataRegistry.enemy(beasts[randi() % beasts.size()])
		if data == null:
			continue
		var enemy: Enemy = world.spawner.spawn(data, world.ground_point(spot.x, spot.z) + Vector3.UP * 0.4)
		_spawned.append(enemy)
		Fx.sphere(get_tree(), enemy.global_position + Vector3.UP, 1.6, _data.get("color", Color.WHITE), 0.5)


## Blitz: angekündigter Kreis, dann Einschlag (Anteil des Höchstlebens, damit er auf jedem Rang gleich gefährlich ist).
func _bolt(player: Player) -> void:
	var b: ImmortalBalanceData = Balance.immortal
	var at: Vector3 = player.global_position
	if randf() > BOLT_ON_PLAYER:
		at += Vector3(randf_range(-BOLT_TARGET_SPREAD, BOLT_TARGET_SPREAD), 0.0, randf_range(-BOLT_TARGET_SPREAD, BOLT_TARGET_SPREAD))
	at = world.ground_point(at.x, at.z)
	Telegraph.show_disc(get_tree(), at, b.bolt_radius, b.bolt_warning)
	get_tree().create_timer(b.bolt_warning).timeout.connect(_strike.bind(at, b.bolt_radius, b.bolt_hp_fraction, true))


func _quake(player: Player) -> void:
	var b: ImmortalBalanceData = Balance.immortal
	var at: Vector3 = player.global_position + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
	at = world.ground_point(at.x, at.z)
	Telegraph.show_disc(get_tree(), at, b.quake_radius, b.bolt_warning)
	get_tree().create_timer(b.bolt_warning).timeout.connect(_strike.bind(at, b.quake_radius, b.quake_hp_fraction, false))


func _strike(at: Vector3, radius: float, fraction: float, lightning: bool) -> void:
	if _done or not is_inside_tree():
		return
	var tree: SceneTree = get_tree()
	if lightning:
		Fx.beam(tree, at + Vector3.UP * 30.0, at, BOLT_COLOR, 0.3, 0.6)
		GuVfx.burst(tree, at + Vector3.UP * 0.5, GuVfx.style_of(&"blitz", []), 1.8, 1.4)
	else:
		Fx.ring(tree, at, radius, QUAKE_COLOR, 0.5)
		GuVfx.burst(tree, at + Vector3.UP * 0.3, GuVfx.style_of(&"erde", []), 1.8, 1.2)
	var shield: float = 1.0 - clampf(Immortal.passive(&"kalamitaet_schutz"), 0.0, 0.8)
	for victim: Combatant in Combat.in_radius(Combat.members(tree, Combatant.TEAM_PLAYER), at, radius):
		var hit := HitInfo.create(victim.health.max_hp * fraction * shield, null, Combatant.TEAM_ENEMY)
		if lightning:
			hit.with_tags([&"blitz"])
		else:
			hit.with_status(&"verwurzelt", QUAKE_ROOT_STACKS)
		victim.receive_hit(hit)


func _on_player_died() -> void:
	_finish(false)


func _finish(survived: bool) -> void:
	if _done:
		return
	_done = true
	status_text = ""
	for enemy: Enemy in _spawned:
		if is_instance_valid(enemy) and not enemy.is_dead():
			Fx.sphere(get_tree(), enemy.global_position + Vector3.UP, 1.2, _data.get("color", Color.WHITE), 0.4)
			enemy.queue_free()
	_set_weather(0.0)
	finished.emit(survived)
	queue_free()


func _on_exit() -> void:
	status_text = ""


func _set_weather(amount: float) -> void:
	for child: Node in world.get_children():
		if child is Weather and (child as Weather).is_processing():
			(child as Weather).force(amount)
