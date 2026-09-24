class_name LoadoutComponent
extends Node
## Belegung der aktiven Slots: außerhalb des Kampfes frei, im Kampf nur mit Kanalisierung (KAMPFSYSTEM, Abschnitt 2).

signal channel_started(duration: float)
signal channel_ended(completed: bool)

var host: Combatant = null
## Gewünschte Belegung, solange ein Wechsel ansteht oder kanalisiert wird (sonst leer).
var pending_slots: Array[int] = []
var channel_left: float = 0.0
var channel_total: float = 0.0

var _combat_left: float = 0.0
var _pending_gu_count: int = 0


func _init(owner_combatant: Combatant) -> void:
	host = owner_combatant
	name = "Loadout"


func _physics_process(delta: float) -> void:
	_combat_left = maxf(0.0, _combat_left - delta)
	if channel_left <= 0.0:
		return
	channel_left -= delta
	if channel_left <= 0.0:
		_complete()


## Im Kampf: kürzlich getroffen oder Gu eingesetzt, oder ein Gegner ist nah.
func in_combat() -> bool:
	if _combat_left > 0.0:
		return true
	for other: Combatant in Combat.in_radius(Combat.members(host.get_tree(), Combatant.TEAM_ENEMY), host.global_position, Balance.values.combat_radius):
		if other.team != Combatant.TEAM_WORLD:
			return true
	return false


func mark_combat() -> void:
	_combat_left = Balance.values.combat_linger


func is_channeling() -> bool:
	return channel_left > 0.0


func channel_progress() -> float:
	return 1.0 - channel_left / channel_total if channel_total > 0.0 else 0.0


func has_pending() -> bool:
	return not pending_slots.is_empty()


## Belegung, wie sie das Menü anzeigen soll (anstehender Wechsel oder aktuelle).
func shown_slots() -> Array[int]:
	return pending_slots if has_pending() else GameState.slots


## Legt Gu index in slot. Liefert true, wenn es sofort gilt; im Kampf wird der Wechsel vorgemerkt.
func assign(index: int, slot: int) -> bool:
	if not in_combat() and not is_channeling():
		_place(GameState.slots, index, slot)
		return true
	if not has_pending():
		pending_slots = GameState.slots.duplicate()
		_pending_gu_count = GameState.gu.size()
	_place(pending_slots, index, slot)
	channel_left = 0.0
	return false


## Nach dem Schließen des Menüs: anstehenden Wechsel kanalisieren.
func begin_pending() -> void:
	if not has_pending() or is_channeling():
		return
	if pending_slots == GameState.slots:
		pending_slots = []
		return
	channel_total = Balance.values.slot_switch_channel
	channel_left = channel_total
	channel_started.emit(channel_total)
	EventBus.message.emit(tr("Du ordnest deine Gu neu … (%d s, Treffer brechen ab)") % roundi(channel_total), Color(1.0, 0.8, 0.3))


## Treffer oder eigener Gu-Einsatz: Kanalisierung bricht ab, der Wechsel verfällt.
func interrupt() -> void:
	if not has_pending():
		return
	var was_channeling: bool = is_channeling()
	pending_slots = []
	channel_left = 0.0
	if was_channeling:
		EventBus.message.emit(tr("Slot-Wechsel abgebrochen!"), Color(1.0, 0.36, 0.45))
		channel_ended.emit(false)


func _complete() -> void:
	channel_left = 0.0
	if GameState.gu.size() == _pending_gu_count:
		GameState.slots = pending_slots
		EventBus.message.emit(tr("Gu neu geordnet."), Color(0.6, 1.0, 0.6))
	pending_slots = []
	channel_ended.emit(true)


static func _place(slots: Array[int], index: int, slot: int) -> void:
	for other: int in slots.size():
		if slots[other] == index:
			slots[other] = GameState.EMPTY_SLOT
	slots[slot] = index
