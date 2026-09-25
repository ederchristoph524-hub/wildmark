class_name DimensionRules
extends Node
## Weltregeln der Unsterblichen-Gebiete und abgeschotteten Dimensionen (AreaData.immortal.rules, docs/UNSTERBLICH.md):
## keine_gu (kein Gu wirkt), stroemung (Strömung treibt dich ab), seelenlast (Dang-Hun-Berg: je höher, desto schwerer
## lastet der Berg auf der Seele – wer bleibt, stärkt sein Seelenfundament), seelensturm (Luo-Po-Tal: Seelenwinde in
## Wellen, Kultivieren sammelt die Seele), traum (Tod weckt dich am Eingang, Dao ×5), zeitfluss (Dao × Zeitfluss),
## leichte_schwere (halbe Schwerkraft) und sterbliche_sterben (Sterbliche verlieren Leben).

const STORM_WARNING: float = 2.5
const SOUL_COLOR: Color = Color(0.72, 0.6, 1.0)
const FOUNDATION_STEP: float = 5.0
## Höhe über dem Ankunftspunkt, ab der der Berg die Seele belastet bzw. das Fundament wächst.
const SOUL_FREE_HEIGHT: float = 6.0
const SOUL_GROWTH_HEIGHT: float = 20.0
## Unsterbliche tragen die Last leichter.
const IMMORTAL_SOUL_SHARE: float = 0.3
const TICK: float = 0.5

static var _rules: Array[StringName] = []
static var _time_flow: float = 1.0
static var _current: Vector3 = Vector3.ZERO

var world: World = null
var _base_height: float = 0.0
var _storm_timer: float = 0.0
var _storm_warned: bool = false
var _tick: float = 0.0
var _warned_mortal: bool = false


static func create(owner_world: World) -> DimensionRules:
	var node := DimensionRules.new()
	node.name = "DimensionRules"
	node.world = owner_world
	return node


func _ready() -> void:
	_rules.assign(world.area.immortal.get("rules", []))
	_time_flow = float(world.area.immortal.get("time_flow", 1.0))
	_current = world.area.immortal.get("current", Vector3.ZERO)
	_base_height = world.terrain.height_at(world.area.arrival.x, world.area.arrival.y)
	_storm_timer = Balance.immortal.soul_storm_interval
	tree_exiting.connect(_clear)
	set_physics_process(not _rules.is_empty())
	if not _rules.is_empty():
		_announce()


static func _clear() -> void:
	_rules.clear()
	_time_flow = 1.0
	_current = Vector3.ZERO


static func has(rule: StringName) -> bool:
	return rule in _rules


static func blocks_gu() -> bool:
	return has(&"keine_gu")


## Faktor auf alle Dao-Markierungen (Traumreich, beschleunigter Zeitfluss).
static func dao_mult() -> float:
	var mult: float = 1.0
	if has(&"traum"):
		mult *= Balance.immortal.dream_dao_mult
	if has(&"zeitfluss"):
		mult *= maxf(_time_flow, 1.0)
	return mult


static func gravity_scale() -> float:
	return Balance.immortal.light_gravity if has(&"leichte_schwere") else 1.0


## Strömung (m/s), die den Spieler abtreibt.
static func drift() -> Vector3:
	if not has(&"stroemung") or _current == Vector3.ZERO:
		return Vector3.ZERO
	return Vector3(_current.x, 0.0, _current.y).normalized() * _current.z


## Im Traum stirbt man nicht wirklich.
static func dream_death() -> bool:
	return has(&"traum")


func _announce() -> void:
	var texts: Dictionary = {
		&"keine_gu": "Hier schweigt jeder Gu – nur Körper und Wille zählen.",
		&"seelenlast": "Der Berg lastet auf deiner Seele. Je höher du steigst, desto schwerer – wer oben ausharrt, dessen Seele wächst.",
		&"seelensturm": "Seelenwinde ziehen durch das Tal. Kultiviere, wenn sie kommen, um deine Seele zu sammeln.",
		&"traum": "Du träumst. Wer hier fällt, erwacht am Eingang – und lernt fünfmal schneller.",
		&"sterbliche_sterben": "Diese Höhe verzehrt Sterbliche.",
		&"leichte_schwere": "Die Schwere lässt nach – jeder Sprung trägt weiter.",
	}
	for rule: StringName in _rules:
		if texts.has(rule):
			EventBus.message.emit(Loc.t(texts[rule]), SOUL_COLOR)


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Player
	if player == null or player.is_dead():
		return
	if has(&"seelensturm"):
		_soul_storm(player, delta)
	_tick += delta
	if _tick < TICK:
		return
	_tick -= TICK
	if has(&"seelenlast"):
		_soul_load(player, TICK)
	if has(&"sterbliche_sterben") and GameState.rank < Immortal.FIRST_RANK:
		if not _warned_mortal:
			_warned_mortal = true
			EventBus.message.emit(Loc.t("Deine sterbliche Hülle zerfällt hier – kehre um, bevor es zu spät ist!"), UiTheme.DANGER)
		player.health.apply_damage(player.health.max_hp * Balance.immortal.mortal_drain * TICK)


## Dang-Hun-Berg: Seelenschaden je Höhe; wer über SOUL_GROWTH_HEIGHT ausharrt, stärkt sein Seelenfundament.
func _soul_load(player: Player, step: float) -> void:
	var b: ImmortalBalanceData = Balance.immortal
	var height: float = player.global_position.y - _base_height
	if height <= SOUL_FREE_HEIGHT:
		return
	var share: float = IMMORTAL_SOUL_SHARE if Immortal.is_immortal() else 1.0
	player.health.apply_damage(player.health.max_hp * b.soul_load_per_10m * (height - SOUL_FREE_HEIGHT) / 10.0 * share * step)
	if height > SOUL_GROWTH_HEIGHT and GameState.immortal.soul_foundation < b.soul_foundation_max:
		var before: float = GameState.immortal.soul_foundation
		GameState.immortal.soul_foundation = minf(before + b.soul_foundation_rate * height / SOUL_GROWTH_HEIGHT * step, b.soul_foundation_max)
		Dao.add(&"seele", b.soul_foundation_rate * step)
		if floorf(GameState.immortal.soul_foundation / FOUNDATION_STEP) > floorf(before / FOUNDATION_STEP):
			EventBus.message.emit(Loc.t("Dein Seelenfundament wächst: %d") % floori(GameState.immortal.soul_foundation), SOUL_COLOR)


## Luo-Po-Tal: alle paar Sekunden ein Seelenwind; wer kultiviert, sammelt die Seele und nimmt kaum Schaden.
func _soul_storm(player: Player, delta: float) -> void:
	var b: ImmortalBalanceData = Balance.immortal
	_storm_timer -= delta
	if _storm_timer <= STORM_WARNING and not _storm_warned:
		_storm_warned = true
		EventBus.message.emit(Loc.t("Ein Seelenwind heult heran – kultiviere (M), um deine Seele zu sammeln!"), SOUL_COLOR)
	if _storm_timer > 0.0:
		return
	_storm_timer = b.soul_storm_interval
	_storm_warned = false
	var gathered: bool = player.aperture.meditating
	var damage: float = player.health.max_hp * b.soul_storm_damage * (0.15 if gathered else 1.0)
	player.health.apply_damage(damage)
	Fx.ring(get_tree(), player.global_position, 8.0, SOUL_COLOR, 0.6)
	if not player.is_dead():
		Dao.add(&"seele", b.soul_storm_dao * (2.0 if gathered else 1.0))
		GameState.immortal.soul_foundation = minf(GameState.immortal.soul_foundation + (1.0 if gathered else 0.3), b.soul_foundation_max)
