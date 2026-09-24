class_name ApertureComponent
extends Node
## Apertur des Spielers: Uressenz, Regeneration, Meditation an der Aperturwand, Stufen und Durchbruch (FORMELN.md).

signal meditation_changed(active: bool)

var host: Combatant = null
var meditating: bool = false


func _init(owner_combatant: Combatant) -> void:
	host = owner_combatant
	name = "Aperture"


func capacity() -> float:
	return Formulas.essence_cap(Balance.values, GameState.rank, GameState.stage, GameState.apt)


func regeneration() -> float:
	return Formulas.essence_regen(Balance.values, capacity(), GameState.apt)


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
	return Balance.values.player_base_hp + GameState.bonus_hp


func _physics_process(delta: float) -> void:
	if host.is_dead():
		return
	if meditating:
		_meditate(delta)
	else:
		gain(regeneration() * delta)


func set_meditating(active: bool) -> void:
	if meditating == active:
		return
	meditating = active
	meditation_changed.emit(active)


func can_break_through() -> bool:
	var b: BalanceData = Balance.values
	return GameState.stage >= b.max_stage and ratio() >= b.breakthrough_min_essence and GameState.rank < rank_cap()


func rank_cap() -> int:
	return DataRegistry.progression().rank_cap.get(GameState.talent_grade, 5)


## Leitet Essenz gegen die Aperturwand; ist sie verfeinert, steigt die Stufe.
func _meditate(delta: float) -> void:
	var b: BalanceData = Balance.values
	if GameState.stage >= b.max_stage:
		gain(regeneration() * delta)
		return
	var burn: float = minf(GameState.essence, capacity() * b.meditation_burn * delta)
	GameState.essence -= burn
	GameState.wall += burn / Formulas.wall_need(b, capacity(), GameState.stage)
	if GameState.wall >= 1.0:
		GameState.wall = 0.0
		_stage_up()


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
