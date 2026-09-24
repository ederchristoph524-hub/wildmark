class_name StatusComponent
extends Node
## Zustände einer Figur (Stapel, Dauer, Schaden über Zeit) und Auslöser der Reaktionen – alles aus Daten und Balance.

signal changed

const FREEZE: StringName = &"freeze"
const DISCHARGE: StringName = &"discharge"
const DERIVED_FROZEN: StringName = &"eingefroren"
const TAG_CUT: StringName = &"schnitt"
const TAG_LIGHT: StringName = &"licht"
const WOUND: StringName = &"wunde"

var host: Combatant = null
var frozen_time: float = 0.0
var stun_time: float = 0.0
## Geblendet: Gegner verlieren ihr Ziel (Dampf, Licht).
var blind_time: float = 0.0
var slow_time: float = 0.0
var slow_amount: float = 0.0

var _stacks: Dictionary[StringName, int] = {}
var _time_left: Dictionary[StringName, float] = {}
var _rank_factor: Dictionary[StringName, float] = {}
var _tick: float = 0.0


func _init(owner_combatant: Combatant) -> void:
	host = owner_combatant
	name = "Status"


func _physics_process(delta: float) -> void:
	frozen_time = maxf(0.0, frozen_time - delta)
	stun_time = maxf(0.0, stun_time - delta)
	blind_time = maxf(0.0, blind_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	for id: StringName in _time_left.keys():
		_time_left[id] -= delta
		if _time_left[id] <= 0.0:
			remove_status(id)
	_tick += delta
	var b: BalanceData = Balance.values
	if _tick >= b.status_tick:
		_tick -= b.status_tick
		_apply_damage_over_time(b.status_tick)


func has_status(id: StringName) -> bool:
	return _stacks.has(id)


func stacks_of(id: StringName) -> int:
	return _stacks.get(id, 0)


func active_statuses() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_stacks.keys())
	return result


## Prüft Bedingungen aus Reaktionen: Zustand mit Mindeststapeln oder abgeleitete Bedingung.
func condition_met(condition: StringName, min_stacks: int) -> bool:
	if condition == DERIVED_FROZEN:
		return is_frozen()
	return stacks_of(condition) >= maxi(1, min_stacks)


func is_frozen() -> bool:
	return frozen_time > 0.0


func is_stunned() -> bool:
	return stun_time > 0.0 or frozen_time > 0.0


func is_blinded() -> bool:
	return blind_time > 0.0


func speed_multiplier() -> float:
	if is_stunned():
		return 0.0
	var mult: float = 1.0
	for id: StringName in _stacks:
		mult += Balance.values.status_speed_per_stack.get(id, 0.0) * _stacks[id]
	if slow_time > 0.0:
		mult -= slow_amount
	return clampf(mult, 0.15, 1.0)


func heal_multiplier() -> float:
	var mult: float = 1.0
	for id: StringName in _stacks:
		mult *= Balance.values.status_heal_mult.get(id, 1.0)
	return mult


func freeze(duration: float) -> void:
	frozen_time = maxf(frozen_time, duration)
	changed.emit()


func slow(amount: float, duration: float) -> void:
	slow_amount = maxf(slow_amount if slow_time > 0.0 else 0.0, amount)
	slow_time = maxf(slow_time, duration)


## Fügt Stapel hinzu. Beendet dabei Zustände, die laut Daten durch diesen enden (Nass ↔ Brand).
func apply_status(id: StringName, stacks: int, rank_factor: float = 1.0, allow_over_max: bool = false) -> void:
	var data: StatusData = DataRegistry.status(id)
	if data == null or stacks <= 0 or host.is_dead():
		return
	for active: StringName in _stacks.keys():
		var active_data: StatusData = DataRegistry.status(active)
		if active_data != null and id in active_data.removed_by:
			remove_status(active)
	var cap: int = data.max_stacks * (2 if allow_over_max else 1)
	_stacks[id] = mini(stacks_of(id) + stacks, maxi(cap, stacks_of(id)))
	_time_left[id] = Balance.values.status_durations.get(id, 4.0)
	_rank_factor[id] = maxf(_rank_factor.get(id, 1.0), rank_factor)
	if _stacks[id] >= data.max_stacks and not allow_over_max:
		_on_max_stacks(id)
	changed.emit()


func set_stacks(id: StringName, stacks: int) -> void:
	if stacks <= 0:
		remove_status(id)
		return
	_stacks[id] = stacks
	_time_left[id] = Balance.values.status_durations.get(id, 4.0)
	changed.emit()


func remove_status(id: StringName) -> void:
	if _stacks.erase(id):
		_time_left.erase(id)
		_rank_factor.erase(id)
		changed.emit()


func clear_negative() -> void:
	for id: StringName in _stacks.keys():
		remove_status(id)
	frozen_time = 0.0
	slow_time = 0.0


## Verarbeitet einen eintreffenden Treffer: Reaktionen, Wunde, neue Zustände. Liefert den Schadensfaktor.
func process_hit(hit: HitInfo) -> float:
	var mult: float = 1.0
	if hit.is_dot:
		return mult
	if hit.can_react:
		mult *= ReactionEffects.resolve(self, hit)
	if has_status(WOUND):
		mult *= 1.0 + Balance.values.wound_bonus
		remove_status(WOUND)
	if hit.status != &"":
		apply_status(hit.status, hit.status_stacks, hit.rank_factor)
	if TAG_CUT in hit.tags and randf() < Balance.values.cut_wound_chance:
		apply_status(WOUND, 1)
	if TAG_LIGHT in hit.tags and host.fears_light():
		blind_time = maxf(blind_time, Balance.values.light_blind_time)
	return mult


func _on_max_stacks(id: StringName) -> void:
	var b: BalanceData = Balance.values
	match b.status_on_max.get(id, &""):
		FREEZE:
			remove_status(id)
			freeze(b.freeze_time)
			EventBus.floating_text.emit(tr("Eingefroren!"), host.aim_point(), Color(0.7, 0.9, 1.0))
		DISCHARGE:
			remove_status(id)
			stun_time = maxf(stun_time, b.discharge_stun)
			ReactionEffects.discharge(host, b.discharge_damage, b.discharge_radius)


func _apply_damage_over_time(step: float) -> void:
	for id: StringName in _stacks.keys():
		var dps: float = Balance.values.status_dps.get(id, 0.0)
		if dps <= 0.0 or not _stacks.has(id):
			continue
		var hit := HitInfo.create(dps * step * _stacks[id] * _rank_factor.get(id, 1.0), null, -1)
		hit.is_dot = true
		hit.can_react = false
		host.receive_hit(hit)
		if host.is_dead():
			return
