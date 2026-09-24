class_name ApertureComponent
extends Node
## Apertur des Spielers: Uressenz, Regeneration, Meditation an der Aperturwand, Stufen und Durchbruch (FORMELN.md).

signal meditation_changed(active: bool)
## Durchbruch-Ritual beginnt (true) oder endet bzw. wird unterbrochen (false).
signal ritual_changed(active: bool)

var host: Combatant = null
var meditating: bool = false
## Restzeit des Durchbruch-Rituals (0 = keins).
var ritual_left: float = 0.0


func _init(owner_combatant: Combatant) -> void:
	host = owner_combatant
	name = "Aperture"


func capacity() -> float:
	return Formulas.essence_cap(Balance.values, GameState.rank, GameState.stage, GameState.apt) * PassiveGu.mult("cap_mult")


## Regeneration (Hilfs-Gu wie der Schnaps-Wurm eingerechnet), ohne Unterhalt.
func regeneration() -> float:
	return Formulas.essence_regen(Balance.values, capacity(), GameState.apt) * PassiveGu.mult("regen_mult")


func essence() -> float:
	return GameState.essence


func ratio() -> float:
	var cap: float = capacity()
	return GameState.essence / cap if cap > 0.0 else 0.0


func has_essence(amount: float) -> bool:
	return GameState.essence + 0.001 >= amount


func spend(amount: float) -> bool:
	if not has_essence(amount):
		return false
	GameState.essence = maxf(0.0, GameState.essence - amount)
	return true


func gain(amount: float) -> void:
	GameState.essence = clampf(GameState.essence + amount, 0.0, capacity())


func max_hp() -> float:
	return Balance.values.player_base_hp + GameState.bonus_hp + PassiveGu.body(&"max_hp")


func _physics_process(delta: float) -> void:
	if host.is_dead():
		return
	if ritual_left > 0.0:
		ritual_left -= delta
		if ritual_left <= 0.0:
			ritual_left = 0.0
			ritual_changed.emit(false)
			break_through()
		return
	if meditating:
		_meditate(delta)
	else:
		gain(regeneration() * delta)
		_auto_refine(delta)
	_pay_upkeep(delta)


## Unterhalt der Hilfs-Gu; läuft die Apertur leer, ruhen sie, bis wieder etwas Essenz da ist.
func _pay_upkeep(delta: float) -> void:
	var upkeep: float = PassiveGu.upkeep()
	if GameState.passives_suspended:
		if ratio() >= Balance.values.passive_restart_fraction:
			GameState.passives_suspended = false
		return
	if upkeep <= 0.0:
		return
	GameState.essence = maxf(0.0, GameState.essence - upkeep * delta)
	if GameState.essence <= 0.0:
		GameState.passives_suspended = true
		EventBus.message.emit(tr("Zu viele Gu – deine Essenz reicht nicht für den Unterhalt. Hilfs-Gu ruhen."), Color(1.0, 0.36, 0.45))


func set_meditating(active: bool) -> void:
	if meditating == active:
		return
	meditating = active
	meditation_changed.emit(active)


## Startet das Durchbruch-Ritual (Kultivieren auf der Höchststufe mit fast voller Apertur).
func start_breakthrough() -> bool:
	if ritual_left > 0.0 or not can_break_through():
		return false
	ritual_left = Balance.values.breakthrough_ritual_time
	ritual_changed.emit(true)
	EventBus.message.emit(tr("Deine Uressenz stürmt gegen die Aperturwand …"), DataRegistry.progression().rank_color(GameState.rank + 1))
	return true


## Ein Treffer reißt dich aus dem Ritual (ohne Verlust).
func cancel_breakthrough() -> void:
	if ritual_left <= 0.0:
		return
	ritual_left = 0.0
	ritual_changed.emit(false)
	EventBus.message.emit(tr("Durchbruch gestört!"), Color(1.0, 0.36, 0.45))


func can_break_through() -> bool:
	var b: BalanceData = Balance.values
	return GameState.stage >= b.max_stage and ratio() >= b.breakthrough_min_essence and GameState.rank < rank_cap()


func rank_cap() -> int:
	return DataRegistry.progression().rank_cap.get(GameState.talent_grade, 5)


## Leitet Essenz gegen die Aperturwand; ist sie verfeinert, steigt die Stufe.
func _meditate(delta: float) -> void:
	var b: BalanceData = Balance.values
	var spring: float = SpiritSpring.bonus_at(host.get_tree(), host.global_position)
	if GameState.stage >= b.max_stage:
		gain(regeneration() * b.meditation_peak_regen_mult * spring * delta)
		return
	var burn: float = minf(GameState.essence, capacity() * b.meditation_burn * spring * delta)
	GameState.essence -= burn
	GameState.wall += burn / Formulas.wall_need(b, capacity(), GameState.stage)
	if GameState.wall >= 1.0:
		GameState.wall = 0.0
		_stage_up()


## Extreme Physiques: Die Wand verfeinert sich von selbst (ohne Essenz), langsamer als beim Meditieren.
func _auto_refine(delta: float) -> void:
	var b: BalanceData = Balance.values
	if GameState.physique == &"" or Childhood.is_child() or GameState.stage >= b.max_stage:
		return
	GameState.wall += capacity() * b.meditation_burn * b.physique_auto_wall * delta / Formulas.wall_need(b, capacity(), GameState.stage)
	if GameState.wall >= 1.0:
		GameState.wall = 0.0
		_stage_up()


## Relikt-Gu: verfeinert die Aperturwand sofort um eine Stufe (nicht über die Höchststufe hinaus).
func instant_stage() -> bool:
	if GameState.stage >= Balance.values.max_stage:
		return false
	GameState.wall = 0.0
	_stage_up()
	return true


func _stage_up() -> void:
	var b: BalanceData = Balance.values
	GameState.stage += 1
	GameState.bonus_hp += b.stage_max_hp
	GameState.bonus_damage += b.stage_damage
	host.health.max_hp = max_hp()
	host.health.hp = host.health.max_hp
	EventBus.stage_reached.emit(GameState.rank, GameState.stage)
	var progression: ProgressionData = DataRegistry.progression()
	EventBus.message.emit(tr("Aperturwand verfeinert · %s") % tr(progression.stage_name(GameState.stage)), progression.rank_color(GameState.rank))
	if GameState.stage >= b.max_stage:
		set_meditating(false)
		EventBus.message.emit(tr("Höchststufe erreicht – mit fast voller Apertur kannst du den Durchbruch wagen."), progression.rank_color(GameState.rank))


## Durchbruch zum nächsten Rang. roll in [0, 1) für Tests; Standard ist Zufall.
func break_through(roll: float = -1.0) -> bool:
	if not can_break_through():
		return false
	var b: BalanceData = Balance.values
	var progression: ProgressionData = DataRegistry.progression()
	var chance: float = progression.breakthrough_chance.get(GameState.talent_grade, 0.5)
	var success: bool = (randf() if roll < 0.0 else roll) < chance
	if success:
		GameState.rank += 1
		GameState.stage = 0
		GameState.essence = 0.0
		GameState.wall = 0.0
		GameState.bonus_hp += b.breakthrough_hp_per_rank * GameState.rank
		GameState.bonus_damage += b.breakthrough_damage
		host.health.max_hp = max_hp()
		host.health.hp = host.health.max_hp
		EventBus.message.emit(tr("Durchbruch! %s") % tr(progression.rank_name(GameState.rank)), progression.rank_color(GameState.rank))
	else:
		GameState.essence *= b.breakthrough_fail_keep
		EventBus.message.emit(tr("Durchbruch gescheitert – die Wand hält stand."), Color(1.0, 0.36, 0.45))
	EventBus.breakthrough_attempted.emit(success, GameState.rank)
	return success
