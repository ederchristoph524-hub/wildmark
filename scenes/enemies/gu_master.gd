class_name GuMaster
extends Combatant
## NPC-Gu-Meister nach denselben Regeln wie der Spieler: eigene Apertur, Gu mit Essenzkosten und Cooldowns; im Dorf zum Duell forderbar.

signal duel_finished(player_won: bool)

enum DuelState { IDLE, COUNTDOWN, FIGHT }

const TURN_SPEED: float = 8.0
const FIST_KNOCKBACK: float = 4.0
const ESSENCE_SEGMENTS: int = 8

var data: GuMasterData = null
var title: String = ""
var rank: int = 1
var stage: int = 0
var essence: float = 0.0
var gu_list: Array[GuInstance] = []
var duel_state: DuelState = DuelState.IDLE
var home: Vector3 = Vector3.ZERO
var brain: GuMasterBrain = null
## Killer Moves aus je zwei seiner Gu (GuMasterKillers.options), stärkste Stufe zuerst.
var killer_options: Array[Dictionary] = []
## Summe der selbst gezahlten Lebenskosten (Blutpfad), z. B. für die Balancing-Messung.
var paid_hp: float = 0.0
## Gegner im Duell; beim Lesen verworfen, wenn er nicht mehr gültig ist.
var opponent: Combatant = null:
	get:
		if opponent != null and not is_instance_valid(opponent):
			opponent = null
		return opponent

var _state_time: float = 0.0
var _model: PlayerModel = null
var _label: EnemyNameplate = null
var _facing: Vector3 = Vector3.FORWARD
var _bonus_damage: float = 0.0


func setup(master_data: GuMasterData, master_title: String, at: Vector3) -> void:
	data = master_data
	title = master_title
	home = at
	position = at


func _ready() -> void:
	var b: BalanceData = Balance.values
	rank = data.rank if data.rank > 0 else b.master_rank
	stage = data.stage if data.stage >= 0 else b.master_stage
	display_name = display_title()
	_init_combatant(TEAM_PLAYER, Formulas.master_hp(b, rank, stage))
	# Gu-Meister sterben im Duell nicht; bei 1 Leben ist spätestens Schluss.
	health.floor_hp = 1.0
	_set_fighting(false)
	_bonus_damage = Formulas.cultivated_damage(b, rank, stage)
	for id: StringName in data.gu:
		var chosen: GuData = _member_for_rank(id)
		if chosen != null:
			gu_list.append(GuInstance.create(chosen.id))
	essence = essence_capacity()
	killer_options = GuMasterKillers.options(self)
	brain = GuMasterBrain.new(self)
	_build_body()
	health.damaged.connect(func(_amount: float) -> void: _update_label())
	health.floored.connect(_on_floored)
	status.changed.connect(_update_label)
	_update_label()


## Gu-Meister nutzen den höchsten Familien-Gu bis zu ihrem Rang (wie ein Spieler nach der Aufstiegsverfeinerung);
## ein höherrangiger Eintrag in den Daten wird auf ihren Rang zurückgestuft.
func _member_for_rank(id: StringName) -> GuData:
	if not DataRegistry.has_gu(id):
		return null
	var base_gu: GuData = DataRegistry.gu(id)
	var best: GuData = null
	for member: GuData in DataRegistry.family(base_gu.family).members:
		if member.rank <= rank and (best == null or member.rank > best.rank):
			best = member
	return best if best != null else base_gu


func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = body_radius
	capsule.height = body_height
	shape.shape = capsule
	shape.position.y = body_height * 0.5
	add_child(shape)
	_model = PlayerModel.new()
	_model.cloth_color = data.color.darkened(0.35)
	_model.body_color = data.color
	_model.hat = data.hat
	add_child(_model)
	_model.set_rank_color(DataRegistry.progression().rank_color(rank))
	_label = EnemyNameplate.new()
	_label.position.y = body_height + 0.55
	add_child(_label)


func display_title() -> String:
	return tr(title) if title != "" else tr(data.display_name)


# --- Apertur und Gu (gleiche Formeln wie beim Spieler) ---

func essence_capacity() -> float:
	return Formulas.essence_cap(Balance.values, rank, stage, Balance.values.master_apt)


func gu_data(index: int) -> GuData:
	return DataRegistry.gu(gu_list[index].gu_id)


func family_of(index: int) -> GuFamilyData:
	return DataRegistry.family(gu_data(index).family)


func essence_cost(index: int) -> float:
	var base_cost: float = float(family_of(index).base_r1.get(GuHolderComponent.COST_KEY, 0.0))
	return Formulas.gu_essence_cost(Balance.values, base_cost, gu_data(index).rank, rank)


func range_of(index: int) -> float:
	return float(family_of(index).base_r1.get(&"reichweite", GuCaster.DEFAULT_RANGE))


func is_ready(index: int) -> bool:
	return gu_list[index].cooldown_left <= 0.0 and essence + 0.001 >= essence_cost(index) and health.hp > hp_cost(index) * 2.0


## Lebenskosten wie beim Spieler (Blutpfad).
func hp_cost(index: int) -> float:
	return Formulas.gu_hp_cost(float(family_of(index).base_r1.get(GuHolderComponent.HP_COST_KEY, 0.0)), health.max_hp)


## Erster einsatzbereiter Gu mit einer dieser Wirkformen, sonst -1.
func ready_index(forms: Array[StringName]) -> int:
	for index: int in gu_list.size():
		if family_of(index).form in forms and is_ready(index):
			return index
	return -1


## Hat er noch Essenz für irgendeinen Gu? Sonst bleibt nur die Faust.
func can_afford_any() -> bool:
	for index: int in gu_list.size():
		if essence + 0.001 >= essence_cost(index):
			return true
	return false


func use_gu(index: int, aim: Vector3, foe: Combatant) -> bool:
	if not is_ready(index):
		return false
	var caster := GuCaster.new(self, family_of(index), gu_data(index))
	caster.power = Formulas.gu_power(Balance.values, gu_data(index).rank, rank)
	caster.aim_direction = aim
	caster.target = foe
	if not caster.cast():
		return false
	essence = maxf(0.0, essence - essence_cost(index))
	pay_hp(hp_cost(index))
	put_on_cooldown(index)
	return true


func pay_hp(amount: float) -> void:
	if amount > 0.0:
		paid_hp += health.apply_damage(amount)


func put_on_cooldown(index: int) -> void:
	var gift_mult: float = GuGifts.number(gu_data(index), "cd_mult")
	gu_list[index].cooldown_left = float(family_of(index).base_r1.get(GuHolderComponent.COOLDOWN_KEY, 1.0)) * (gift_mult if gift_mult > 0.0 else 1.0)
	_update_label()


func fist(foe: Combatant) -> void:
	var b: BalanceData = Balance.values
	var hit := HitInfo.create(b.player_base_damage + _bonus_damage, self, team)
	var away: Vector3 = foe.global_position - global_position
	away.y = 0.0
	hit.knockback = away.normalized() * FIST_KNOCKBACK
	foe.receive_hit(hit)
	Fx.ring(get_tree(), foe.global_position, 0.7, Color(1.0, 0.9, 0.7), 0.2)


func face(direction: Vector3) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length() > 0.05:
		_facing = flat.normalized()


# --- Ablauf ---

func _physics_process(delta: float) -> void:
	tick_combatant(delta)
	for instance: GuInstance in gu_list:
		instance.cooldown_left = maxf(0.0, instance.cooldown_left - delta)
	essence = minf(essence_capacity(), essence + Formulas.essence_regen(Balance.values, essence_capacity(), Balance.values.master_apt) * delta)
	_state_time += delta
	var wish: Vector3 = Vector3.ZERO
	match duel_state:
		DuelState.IDLE:
			wish = _idle()
		DuelState.COUNTDOWN:
			wish = _countdown()
		DuelState.FIGHT:
			wish = _fight(delta)
	_move(delta, wish)
	_label.visible = duel_state != DuelState.IDLE or health.ratio() < 1.0 or _near_player(8.0)


func _idle() -> Vector3:
	var offset: Vector3 = home - global_position
	offset.y = 0.0
	if offset.length() > 1.0:
		return offset.normalized() * 0.6
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
	if player != null and _near_player(6.0):
		face(player.global_position - global_position)
	return Vector3.ZERO


func _countdown() -> Vector3:
	if opponent == null or _opponent_left():
		_abort()
		return Vector3.ZERO
	face(opponent.global_position - global_position)
	if _state_time >= Balance.values.duel_countdown:
		_enter(DuelState.FIGHT)
		_set_fighting(true)
		EventBus.message.emit(tr("Kämpft!"), Color(1.0, 0.8, 0.3))
	return Vector3.ZERO


func _fight(delta: float) -> Vector3:
	if opponent == null or _opponent_left():
		_abort()
		return Vector3.ZERO
	if status.is_stunned() or status.is_frozen():
		return Vector3.ZERO
	return brain.tick(delta, opponent)


func _move(delta: float, wish: Vector3) -> void:
	var b: BalanceData = Balance.values
	var target_velocity: Vector3 = wish * b.master_speed * status.speed_multiplier()
	velocity.x = move_toward(velocity.x, target_velocity.x, b.acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, b.acceleration * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - b.gravity * delta
	apply_knockback(delta)
	move_and_slide()
	if duel_state == DuelState.IDLE and wish.length() > 0.1:
		face(wish)
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-_facing.x, -_facing.z), clampf(delta * TURN_SPEED, 0.0, 1.0))
	_model.animate(delta, Vector2(velocity.x, velocity.z).length())
	if global_position.y < -40.0:
		global_position = home


func _near_player(distance: float) -> bool:
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
	return player != null and player.global_position.distance_to(global_position) < distance


## Entfernt sich der Gegner zu weit von ihm (Rückstoß zählt nicht als Flucht, solange er in Reichweite bleibt).
func _opponent_left() -> bool:
	return opponent.is_dead() or opponent.global_position.distance_to(global_position) > Balance.values.duel_leash


func _enter(new_state: DuelState) -> void:
	duel_state = new_state
	_state_time = 0.0


## Im Kampf ist er Gegner (Team, Zielbarkeit); sonst unantastbar und ansprechbar.
func _set_fighting(active: bool) -> void:
	set_team(TEAM_ENEMY if active else TEAM_PLAYER)
	if active:
		add_to_group(Combat.GROUP_COMBATANTS)
		remove_from_group(Player.GROUP_INTERACTABLES)
	else:
		remove_from_group(Combat.GROUP_COMBATANTS)
		if duel_state == DuelState.IDLE:
			add_to_group(Player.GROUP_INTERACTABLES)


func _update_label() -> void:
	if _label == null:
		return
	_label.refresh(display_title(), health, status, false)
	var filled: int = ceili(essence / maxf(essence_capacity(), 0.01) * ESSENCE_SEGMENTS)
	_label.text += "\n" + "◆".repeat(filled) + "◇".repeat(ESSENCE_SEGMENTS - filled)


# --- Duell ---

func interact_label() -> String:
	if Childhood.is_child():
		return tr("Sprechen mit %s") % display_title()
	return tr("Duell fordern: %s") % display_title()


## Als Kind: Erwachen (sobald das Tutorial so weit ist); danach Duell.
func interact(player: Player) -> void:
	if not Childhood.is_child() and data.faction == Renown.RIGHTEOUS and Renown.is_demon() and not Renown.disguised():
		EventBus.message.emit(tr("%s: „Ein Dämon fordert mich heraus? Verschwinde, bevor ich die Wache rufe!“") % display_title(), Renown.INFAMY_COLOR)
	elif not Childhood.is_child():
		start_duel(player)
	elif Childhood.is_awakening_step():
		EventBus.awakening_requested.emit()
	else:
		EventBus.message.emit(tr("%s: „Noch nicht, Kind. Hilf erst im Dorf.“") % display_title(), UiTheme.MUTED)


func start_duel(foe: Combatant) -> void:
	if duel_state != DuelState.IDLE:
		return
	opponent = foe
	remove_from_group(Player.GROUP_INTERACTABLES)
	foe.health.floor_hp = foe.health.max_hp * Balance.values.duel_player_floor
	if not foe.health.floored.is_connected(_on_opponent_floored):
		foe.health.floored.connect(_on_opponent_floored)
	_enter(DuelState.COUNTDOWN)
	EventBus.message.emit(tr("%s nimmt die Herausforderung an. Das Duell beginnt …") % display_title(), Color(1.0, 0.8, 0.3))
	if foe is Player and GameState.rank < rank:
		EventBus.message.emit(tr("Er steht auf %s – über dir. Weiche seitlich aus, wenn er ausholt.") % tr(DataRegistry.progression().rank_name(rank)), UiTheme.MUTED)
	EventBus.duel_started.emit(self)


## Gibt bei niedrigem Leben auf (Untergrenze verhindert den Tod im Duell).
func _after_hit(_hit: HitInfo, _dealt: float) -> void:
	if duel_state == DuelState.FIGHT and health.ratio() <= Balance.values.duel_surrender_ratio:
		_finish(true)


func _on_floored() -> void:
	if duel_state == DuelState.FIGHT:
		_finish(true)


func _on_opponent_floored() -> void:
	if duel_state == DuelState.FIGHT:
		_finish(false)


func _abort() -> void:
	EventBus.message.emit(tr("Duell abgebrochen."), Color(1.0, 0.6, 0.4))
	_reset_after_duel()
	duel_finished.emit(false)


func _finish(player_won: bool) -> void:
	var foe: Combatant = opponent
	if player_won:
		EventBus.message.emit(tr("%s gibt auf: „Genug! Du hast gewonnen.“") % display_title(), Color(0.6, 1.0, 0.6))
		DuelRewards.grant(self)
	else:
		EventBus.message.emit(tr("Du unterliegst. %s reicht dir die Hand.") % display_title(), Color(1.0, 0.6, 0.4))
	if foe != null and not foe.is_dead():
		foe.status.clear_negative()
		foe.heal(foe.health.max_hp)
	_reset_after_duel()
	duel_finished.emit(player_won)
	EventBus.duel_ended.emit(self, player_won)


func _reset_after_duel() -> void:
	if opponent != null:
		opponent.health.floor_hp = 0.0
		if opponent.health.floored.is_connected(_on_opponent_floored):
			opponent.health.floored.disconnect(_on_opponent_floored)
	opponent = null
	_enter(DuelState.IDLE)
	_set_fighting(false)
	status.clear_negative()
	reductions.clear()
	health.hp = health.max_hp
	essence = essence_capacity()
	for instance: GuInstance in gu_list:
		instance.cooldown_left = 0.0
	_update_label()
