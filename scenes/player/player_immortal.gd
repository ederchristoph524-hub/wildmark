class_name PlayerImmortal
extends Node
## Unsterblichen-Seite des Spielers (docs/UNSTERBLICH.md): Tasten für unsterbliche Gu und Killer Moves,
## Kultivierungsrang für den Schaden zwischen Unsterblichen und Sterblichen und die Dauerwirkungen der unsterblichen Gu
## (Schutz, Tempo, Heilung, kritische Treffer, Unaufhaltsamkeit, Rückprall, Tarnung) samt Unsterblichen-Schlagkraft.

const SLOT_ACTIONS: Array[StringName] = [&"immortal_gu_1", &"immortal_gu_2"]
const PASSIVE_KEY: StringName = &"immortal"
const REFRESH: float = 0.5

var player: Player = null
var controller: ImmortalController = null


static func create(owner_player: Player) -> PlayerImmortal:
	var node := PlayerImmortal.new()
	node.name = "PlayerImmortal"
	node.player = owner_player
	node.controller = ImmortalController.new(owner_player)
	return node


func _ready() -> void:
	add_child(controller)
	EventBus.breakthrough_attempted.connect(func(_ok: bool, _rank: int) -> void: refresh())
	refresh()


## Nach Rangwechsel: Kultivierungsrang und Leben neu.
func refresh() -> void:
	player.cultivation_rank = GameState.rank
	player.health.max_hp = player.max_hp_now()


func _unhandled_input(event: InputEvent) -> void:
	if not player.input_enabled or player.is_dead():
		return
	for slot: int in SLOT_ACTIONS.size():
		if event.is_action_pressed(SLOT_ACTIONS[slot]):
			use_slot(slot)
			return
	if event.is_action_pressed(&"immortal_killer"):
		start_killer()
	elif event.is_action_pressed(&"immortal_killer_next"):
		controller.cycle(1)


func can_act() -> bool:
	return not player.is_dead() and not player.status.is_stunned() and not player.killer.is_channeling() \
		and not controller.is_channeling() and player.eat_time_left <= 0.0 and player.aperture.ritual_left <= 0.0


func use_slot(slot: int) -> void:
	if not can_act():
		return
	if not Immortal.is_immortal() and not GameState.immortal.gu.is_empty():
		EventBus.message.emit(Loc.t("Unsterbliche Gu gehorchen nur Unsterblichen."), UiTheme.MUTED)
		return
	player.aperture.set_meditating(false)
	if controller.use_slot(slot, player.aim_direction(), player.targeting.soft_target):
		player.loadout.mark_combat()


func start_killer() -> void:
	if not can_act():
		return
	if not Immortal.is_immortal():
		EventBus.message.emit(Loc.t("Unsterblichen-Killer-Moves brauchen Unsterblichen-Essenz."), UiTheme.MUTED)
		return
	player.aperture.set_meditating(false)
	if controller.start_killer(player.aim_direction()):
		player.loadout.mark_combat()


func _physics_process(delta: float) -> void:
	if player.is_dead():
		return
	player.cultivation_rank = GameState.rank
	if not Immortal.is_immortal():
		return
	player.flat_damage += Immortal.flat_damage(GameState.rank)
	var reduction: float = Immortal.passive(&"reduction")
	if reduction > 0.0:
		player.reductions[PASSIVE_KEY] = minf(reduction, Balance.values.max_damage_reduction)
	var speed: float = Immortal.passive(&"speed")
	var damage: float = Immortal.passive(&"schaden")
	if speed > 0.0 or damage > 0.0:
		player.add_buff(PASSIVE_KEY, 1.0 + damage, 1.0 + speed, REFRESH)
	var regen: float = Immortal.passive(&"regen")
	if regen > 0.0 and player.health.hp < player.health.max_hp:
		player.heal(player.health.max_hp * regen * delta)
	var crit: float = Immortal.passive(&"crit")
	if crit > 0.0:
		player.luck_chance = maxf(player.luck_chance, crit)
		player.luck_time = maxf(player.luck_time, REFRESH)
	if Immortal.has_passive_flag(&"unstoppable"):
		player.unstoppable_time = maxf(player.unstoppable_time, REFRESH)
	if Immortal.has_passive_flag(&"reflect"):
		player.reflect_time = maxf(player.reflect_time, REFRESH)
