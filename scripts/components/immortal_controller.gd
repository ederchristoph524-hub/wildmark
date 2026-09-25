class_name ImmortalController
extends Node
## Unsterbliche Gu und Unsterblichen-Killer-Moves des Spielers (docs/UNSTERBLICH.md, 7–8): Abklingzeiten, Einsatz
## gegen Perlen, Kanalisierung der Killer Moves (Kern-Gu + sterbliche Familien) und Eingebung neuer Killer Moves.

signal channel_started(move: ImmortalKillerData, duration: float)
signal channel_ended(completed: bool)

const ANNOUNCE_COLOR: Color = Color(1.0, 0.85, 0.45)
## Geschätzter Anteil der Treffer an einem Ziel (wie KillerMoveEffects.steps_total).
const DAO_PER_IMMORTAL_USE: float = 3.0

var host: Combatant = null
var channel_move: ImmortalKillerData = null
var channel_left: float = 0.0
var channel_total: float = 0.0
var _aim: Vector3 = Vector3.FORWARD
static var _scale_cache: Dictionary = {}


func _init(owner_combatant: Combatant) -> void:
	host = owner_combatant
	name = "Immortal"


func _physics_process(delta: float) -> void:
	var cooldowns: Dictionary[StringName, float] = GameState.immortal.cooldowns
	for id: StringName in cooldowns.keys():
		cooldowns[id] -= delta
		if cooldowns[id] <= 0.0:
			cooldowns.erase(id)
	if channel_move == null:
		return
	if host.status.is_stunned():
		interrupt()
		return
	channel_left -= delta
	if channel_left <= 0.0:
		_complete()


func is_channeling() -> bool:
	return channel_move != null


func channel_progress() -> float:
	return 1.0 - channel_left / channel_total if channel_total > 0.0 else 0.0


func cooldown_left(id: StringName) -> float:
	return float(GameState.immortal.cooldowns.get(id, 0.0))


# --- Unsterbliche Gu ---

## Leer = einsatzbereit, sonst Grund für die Anzeige.
func blocked_reason(id: StringName) -> String:
	if id == &"" or not DataRegistry.has_immortal_gu(id):
		return tr("Leerer Unsterblichen-Slot")
	var data: ImmortalGuData = DataRegistry.immortal_gu(id)
	if not data.is_usable():
		return tr("%s wirkt dauerhaft") % tr(data.display_name)
	if GameState.rank < data.rank:
		return tr("%s braucht Rang %d") % [tr(data.display_name), data.rank]
	if DimensionRules.blocks_gu():
		return tr("Hier schweigt jeder Gu")
	if cooldown_left(id) > 0.0:
		return tr("Noch nicht bereit")
	if GameState.immortal.beads_for(data.rank) + 0.0001 < Immortal.bead_cost(data.beads):
		return tr("Zu wenig %s") % tr(Immortal.essence_name(data.rank))
	return ""


func use_slot(slot: int, aim: Vector3, target: Combatant) -> bool:
	if slot < 0 or slot >= GameState.immortal.slots.size():
		return false
	return cast(GameState.immortal.slots[slot], aim, target)


func cast(id: StringName, aim: Vector3, target: Combatant) -> bool:
	var reason: String = blocked_reason(id)
	if reason != "":
		EventBus.message.emit(reason, Color(1.0, 0.6, 0.4))
		return false
	var data: ImmortalGuData = DataRegistry.immortal_gu(id)
	var color: Color = DataRegistry.gu_system().path_color(data.path)
	var ctx := EffectContext.create(host, data.base_damage * Immortal.power(data.rank) * Dao.power_mult(data.path), aim, color)
	ctx.target = target if is_instance_valid(target) else null
	ctx.power = Immortal.power(data.rank)
	ctx.path = data.path
	EffectSteps.run(data.steps, ctx)
	GameState.immortal.spend_beads(data.rank, Immortal.bead_cost(data.beads))
	GameState.immortal.cooldowns[id] = data.cooldown * Dao.cooldown_mult(data.path)
	Dao.add(data.path, Balance.values.dao_per_use * DAO_PER_IMMORTAL_USE)
	GuVfx.burst(host.get_tree(), host.aim_point(), GuVfx.style_of(data.path, []), 1.6, 1.4)
	EventBus.floating_text.emit(tr(data.display_name) + "!", host.aim_point() + Vector3.UP * 1.2, color)
	return true


# --- Unsterblichen-Killer-Moves ---

## Bekannte Killer Moves, deren Kern du besitzt und deren sterbliche Familien in deiner Apertur liegen.
func available() -> Array[ImmortalKillerData]:
	var result: Array[ImmortalKillerData] = []
	for id: StringName in GameState.immortal.known_killers:
		var move: ImmortalKillerData = DataRegistry.immortal_killer(id)
		if move != null and ImmortalGu.has_parts(move):
			result.append(move)
	return result


func current() -> ImmortalKillerData:
	var moves: Array[ImmortalKillerData] = available()
	if moves.is_empty():
		return null
	return moves[posmod(GameState.immortal.active_killer, moves.size())]


func cycle(step: int) -> void:
	GameState.immortal.active_killer += step
	var move: ImmortalKillerData = current()
	if move != null:
		EventBus.message.emit(tr("Unsterblichen-Killer-Move: %s") % tr(move.display_name), ANNOUNCE_COLOR)


func killer_blocked_reason(move: ImmortalKillerData) -> String:
	if move == null:
		return tr("Kein Unsterblichen-Killer-Move bereit")
	var core: ImmortalGuData = DataRegistry.immortal_gu(move.core)
	if GameState.rank < core.rank:
		return tr("%s braucht Rang %d") % [tr(move.display_name), core.rank]
	if DimensionRules.blocks_gu():
		return tr("Hier schweigt jeder Gu")
	if cooldown_left(move.id) > 0.0:
		return tr("%s ist noch nicht bereit") % tr(move.display_name)
	if GameState.immortal.beads_for(core.rank) + 0.0001 < Immortal.bead_cost(move.beads):
		return tr("Zu wenig %s für %s") % [tr(Immortal.essence_name(core.rank)), tr(move.display_name)]
	return ""


func start_killer(aim: Vector3) -> bool:
	var move: ImmortalKillerData = current()
	var reason: String = killer_blocked_reason(move)
	if reason != "" or is_channeling():
		if reason != "":
			EventBus.message.emit(reason, Color(1.0, 0.6, 0.4))
		return false
	var core: ImmortalGuData = DataRegistry.immortal_gu(move.core)
	GameState.immortal.spend_beads(core.rank, Immortal.bead_cost(move.beads))
	channel_move = move
	channel_total = maxf(move.channel, 0.05)
	channel_left = channel_total
	_aim = aim
	EventBus.floating_text.emit(tr(move.display_name) + " …", host.aim_point() + Vector3.UP * 1.4, ANNOUNCE_COLOR)
	channel_started.emit(move, channel_total)
	return true


func interrupt() -> void:
	if channel_move == null:
		return
	EventBus.message.emit(tr("%s abgebrochen!") % tr(channel_move.display_name), Color(1.0, 0.36, 0.45))
	GameState.immortal.cooldowns[channel_move.id] = channel_move.cooldown * 0.5
	channel_move = null
	channel_ended.emit(false)


func _complete() -> void:
	var move: ImmortalKillerData = channel_move
	channel_move = null
	var core: ImmortalGuData = DataRegistry.immortal_gu(move.core)
	var bonus: float = 1.0 + Balance.immortal.killer_component_bonus * move.mortal_families.size()
	var damage: float = move.base_damage * Immortal.power(core.rank) * bonus * Dao.power_mult(move.path) * cap_scale(move)
	var color: Color = DataRegistry.gu_system().path_color(move.path)
	var ctx := EffectContext.create(host, damage, _aim, color)
	var targeting: Variant = host.get(&"targeting")
	ctx.target = (targeting as TargetingComponent).soft_target if targeting is TargetingComponent else null
	if not is_instance_valid(ctx.target):
		ctx.target = null
	ctx.power = Immortal.power(core.rank)
	ctx.path = move.path
	EffectSteps.run(move.steps, ctx)
	for family_id: StringName in move.mortal_families:
		var family: GuFamilyData = DataRegistry.family(family_id)
		if family != null:
			GuVfx.burst(host.get_tree(), host.aim_point(), GuVfx.style_of(family.path, family.tags), 1.2, 1.0)
	GameState.immortal.cooldowns[move.id] = move.cooldown
	Dao.add(move.path, Balance.values.dao_per_killer * DAO_PER_IMMORTAL_USE)
	EventBus.floating_text.emit(tr(move.display_name) + "!", host.aim_point() + Vector3.UP * 1.6, ANNOUNCE_COLOR)
	EventBus.killer_move_used.emit(move.id)
	channel_ended.emit(true)


## Dämpfung (≤ 1), damit die Schritte zusammen die Obergrenze der Unsterblichen-Killer-Moves nicht übersteigen.
static func cap_scale(move: ImmortalKillerData) -> float:
	if _scale_cache.has(move.id):
		return _scale_cache[move.id]
	var total: float = KillerMoveEffects.steps_total(move.steps)
	var scale: float = minf(1.0, Balance.immortal.killer_total_cap / total) if total > 0.0 else 1.0
	_scale_cache[move.id] = scale
	return scale
