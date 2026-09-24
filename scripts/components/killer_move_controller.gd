class_name KillerMoveController
extends Node
## Killer Moves des Spielers: Verfügbarkeit, Auswahl, Kanalisierung mit Abbruch, Kosten und Entdeckung durch Eingebung.

signal channel_started(move: KillerMoveData, duration: float)
signal channel_ended(completed: bool)

const DAMAGE_KEY: StringName = &"schaden"
const COST_KEY: StringName = &"ess"
const HP_COST_KEY: StringName = &"hp_kosten"

var host: Combatant = null
var holder: GuHolderComponent = null
var aperture: ApertureComponent = null
var selected: int = 0
var channel_move: KillerMoveData = null
var channel_left: float = 0.0
var channel_total: float = 0.0

var _channel_slots: Array[int] = []
var _channel_aim: Vector3 = Vector3.FORWARD
var _last_family: StringName = &""
var _last_use_time: float = -100.0
var _pair_attempts: Dictionary[String, float] = {}
var _clock: float = 0.0


func _init(owner_combatant: Combatant, owner_holder: GuHolderComponent, owner_aperture: ApertureComponent) -> void:
	host = owner_combatant
	holder = owner_holder
	aperture = owner_aperture
	name = "KillerMoves"
	holder.gu_used.connect(_on_gu_used)


func _physics_process(delta: float) -> void:
	_clock += delta
	if channel_move == null:
		return
	channel_left -= delta
	if channel_left <= 0.0:
		_complete()


func is_channeling() -> bool:
	return channel_move != null


func channel_progress() -> float:
	return 1.0 - channel_left / channel_total if channel_total > 0.0 else 0.0


## Slots, in denen je ein Gu der beiden Familien liegt (bereit, nicht ausgehungert, mindestens Rang des Moves), sonst leer.
func slots_for(move: KillerMoveData) -> Array[int]:
	var a: int = _ready_slot_of(move.family_a, move.min_rank)
	var b: int = _ready_slot_of(move.family_b, move.min_rank)
	if a < 0 or b < 0:
		return []
	return [a, b]


func _ready_slot_of(family_id: StringName, min_rank: int = 1) -> int:
	for slot: int in GameState.SLOT_COUNT:
		var instance: GuInstance = GameState.slot_instance(slot)
		if instance == null or holder.is_starved(instance) or instance.cooldown_left > 0.0 or holder.gu_data(instance).rank < min_rank:
			continue
		if holder.family_of(instance).id == family_id:
			return slot
	return -1


## Bekannte Killer Moves, deren Gu gerade bereitliegen; von mehreren Stufen desselben Paars nur die höchste.
func available() -> Array[KillerMoveData]:
	var best: Dictionary[String, KillerMoveData] = {}
	for id: StringName in GameState.known_killer_moves:
		var move: KillerMoveData = DataRegistry.killer_move(id)
		if move == null or slots_for(move).is_empty():
			continue
		var pair: String = _pair_key(move.family_a, move.family_b)
		if not best.has(pair) or best[pair].min_rank < move.min_rank:
			best[pair] = move
	var result: Array[KillerMoveData] = []
	result.assign(best.values())
	return result


static func _pair_key(a: StringName, b: StringName) -> String:
	return "%s+%s" % ([a, b] if String(a) < String(b) else [b, a])


func current() -> KillerMoveData:
	var moves: Array[KillerMoveData] = available()
	if moves.is_empty():
		return null
	return moves[posmod(selected, moves.size())]


func cycle(step: int) -> void:
	selected += step


## Kosten laut KAMPFSYSTEM: (ess_a + ess_b) × 2; Knochen zahlen ihren Anteil in HP.
func costs(slots: Array[int]) -> Dictionary:
	var essence: float = 0.0
	var hp: float = 0.0
	for slot: int in slots:
		var instance: GuInstance = GameState.slot_instance(slot)
		essence += holder.essence_cost(instance)
		hp += holder.hp_cost(instance)
	var mult: float = Balance.values.killer_cost_mult
	return {"essence": essence * mult, "hp": hp * mult}


func start(aim: Vector3) -> bool:
	var move: KillerMoveData = current()
	if move == null or is_channeling():
		if move == null:
			EventBus.message.emit(tr("Kein Killer Move bereit"), Color(1.0, 0.6, 0.4))
		return false
	var slots: Array[int] = slots_for(move)
	var cost: Dictionary = costs(slots)
	if not aperture.has_essence(cost["essence"]) or host.health.hp <= cost["hp"]:
		EventBus.message.emit(tr("Zu wenig Uressenz für %s") % tr(move.display_name), Color(1.0, 0.6, 0.4))
		return false
	aperture.spend(cost["essence"])
	if cost["hp"] > 0.0:
		host.health.apply_damage(cost["hp"])
	channel_move = move
	channel_total = maxf(move.channel_time, 0.05)
	channel_left = channel_total
	_channel_slots = slots
	_channel_aim = aim
	channel_started.emit(move, channel_total)
	return true


## Treffer während der Kanalisierung: Abbruch, Essenz verloren, Gu gehen trotzdem auf Cooldown.
func interrupt() -> void:
	if not is_channeling():
		return
	EventBus.message.emit(tr("%s abgebrochen!") % tr(channel_move.display_name), Color(1.0, 0.36, 0.45))
	_put_on_cooldown()
	channel_move = null
	channel_ended.emit(false)


func _complete() -> void:
	var move: KillerMoveData = channel_move
	var damage: float = 0.0
	var power: float = INF
	for slot: int in _channel_slots:
		var instance: GuInstance = GameState.slot_instance(slot)
		if instance == null:
			continue
		damage = maxf(damage, float(holder.family_of(instance).base_r1.get(DAMAGE_KEY, 0.0)))
		power = minf(power, holder.power_of(instance))
	if power == INF:
		power = 1.0
	_put_on_cooldown()
	channel_move = null
	var soft_target: Combatant = host.get(&"targeting").soft_target if host.get(&"targeting") != null else null
	KillerMoveEffects.execute(move, host, damage * power * move.damage_mult * PassiveGu.mult("killer_mult"), _channel_aim, soft_target, power)
	channel_ended.emit(true)


func _put_on_cooldown() -> void:
	for slot: int in _channel_slots:
		var instance: GuInstance = GameState.slot_instance(slot)
		if instance != null:
			instance.cooldown_left = holder.cooldown_of(instance)


## Eingebung: zwei Gu kurz nacheinander, die ein unbekanntes Paar bilden.
func _on_gu_used(_slot: int, family_id: StringName) -> void:
	var b: BalanceData = Balance.values
	if _last_family != &"" and _last_family != family_id and _clock - _last_use_time <= b.insight_window:
		_try_insight(_last_family, family_id)
	_last_family = family_id
	_last_use_time = _clock


func _try_insight(first: StringName, second: StringName, roll: float = -1.0) -> bool:
	var b: BalanceData = Balance.values
	var move: KillerMoveData = find_move(first, second, _slotted_rank(first, second))
	if move == null or GameState.knows_killer_move(move.id):
		return false
	var key: String = String(move.id)
	if _pair_attempts.has(key) and _clock - _pair_attempts[key] < b.insight_pair_cooldown:
		return false
	_pair_attempts[key] = _clock
	if (randf() if roll < 0.0 else roll) >= minf(b.insight_base * PassiveGu.mult("insight_mult"), b.insight_max):
		EventBus.message.emit(tr("Die beiden Gu regen sich seltsam … (%s)") % tr(move.hint), Color(0.8, 0.8, 1.0))
		return false
	learn(move.id)
	return true


## Unbekannter Killer Move des Paars mit dem niedrigsten Rang ≤ max_rank (erst die Grundstufe, dann die höheren).
static func find_move(first: StringName, second: StringName, max_rank: int = 99) -> KillerMoveData:
	var found: KillerMoveData = null
	for resource: Resource in DataRegistry.all(&"killer_moves"):
		var move: KillerMoveData = resource as KillerMoveData
		if not ((move.family_a == first and move.family_b == second) or (move.family_a == second and move.family_b == first)):
			continue
		if move.min_rank > max_rank or GameState.knows_killer_move(move.id):
			continue
		if found == null or move.min_rank < found.min_rank:
			found = move
	return found


## Niedrigster Rang der beiden eingesetzten Gu dieser Familien (für höhere Killer-Move-Stufen).
func _slotted_rank(first: StringName, second: StringName) -> int:
	var ranks: Array[int] = []
	for family_id: StringName in [first, second]:
		var best: int = 0
		for slot: int in GameState.SLOT_COUNT:
			var instance: GuInstance = GameState.slot_instance(slot)
			if instance != null and holder.family_of(instance).id == family_id:
				best = maxi(best, holder.gu_data(instance).rank)
		ranks.append(best)
	return mini(ranks[0], ranks[1])


static func learn(id: StringName) -> void:
	if id in GameState.known_killer_moves:
		return
	GameState.known_killer_moves.append(id)
	var move: KillerMoveData = DataRegistry.killer_move(id)
	EventBus.message.emit(Loc.t("Eingebung! Killer Move erlernt: %s") % Loc.t(move.display_name), Color(1.0, 0.85, 0.3))
	EventBus.killer_move_learned.emit(id)
