class_name Player
extends Combatant
## Der Spieler: Bewegung, Sprung, Dash, Faust, Gu-Slots, Killer Moves, Urstein essen, Meditation und Interaktion.

const GROUP_PLAYER: StringName = &"player"
const GROUP_INTERACTABLES: StringName = &"interactables"
const GROUP_HARVESTABLE: StringName = &"harvestable"
const INTERACT_RANGE: float = 2.8
const TURN_SPEED: float = 12.0
const FIST_ANGLE: float = 110.0
const STONE_ITEM: StringName = &"kristall"
const SLOT_ACTIONS: Array[StringName] = [&"gu_slot_1", &"gu_slot_2", &"gu_slot_3", &"gu_slot_4"]

var aperture: ApertureComponent = null
var holder: GuHolderComponent = null
var killer: KillerMoveController = null
var loadout: LoadoutComponent = null
var cultivation: PlayerCultivation = null
var camera_rig: PlayerCamera = null
var model: PlayerModel = null
var targeting: TargetingComponent = null
var eat_time_left: float = 0.0
var input_enabled: bool = true

var _dash_time: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _fist_cooldown: float = 0.0
var _air_leaps: int = 0
var _air_dashes: int = 0
var _facing: Vector3 = Vector3.FORWARD
## Reaktive Panzer aus Killer Moves: Art → {time, value}.
var _reactive: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	display_name = tr("Du")
	body_radius = 0.4
	_init_combatant(TEAM_PLAYER, max_hp_now(), GameState.hp if GameState.hp > 0.0 else -1.0)
	add_to_group(GROUP_PLAYER)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	model = PlayerModel.new()
	add_child(model)
	aperture = ApertureComponent.new(self)
	add_child(aperture)
	holder = GuHolderComponent.new(self, aperture)
	add_child(holder)
	killer = KillerMoveController.new(self, holder, aperture)
	add_child(killer)
	loadout = LoadoutComponent.new(self)
	add_child(loadout)
	holder.gu_used.connect(func(_slot: int, _family: StringName) -> void: loadout.mark_combat())
	camera_rig = PlayerCamera.new()
	add_child(camera_rig)
	targeting = TargetingComponent.new(self)
	add_child(targeting)
	cultivation = PlayerCultivation.new(self)
	add_child(cultivation)
	floor_snap_length = 0.4
	model.set_rank_color(DataRegistry.progression().rank_color(GameState.rank))
	EventBus.breakthrough_attempted.connect(func(_ok: bool, rank: int) -> void: model.set_rank_color(DataRegistry.progression().rank_color(rank)))


func max_hp_now() -> float:
	return Balance.values.player_base_hp + GameState.bonus_hp + PassiveGu.body(&"max_hp")


func _physics_process(delta: float) -> void:
	tick_combatant(delta)
	if is_dead():
		return
	_update_timers(delta)
	PlayerActions.apply_passives(self, delta)
	targeting.view_forward = camera_rig.flat_forward()
	var move_input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back") if input_enabled else Vector2.ZERO
	var wish: Vector3 = camera_rig.flat_right() * move_input.x - camera_rig.flat_forward() * move_input.y
	if move_input.length() > 0.2:
		_cancel_idle_actions()
	_move(delta, wish)
	camera_rig.follow(global_position, targeting.locked_target, delta)
	GameState.position = global_position
	GameState.hp = health.hp


func _update_timers(delta: float) -> void:
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_fist_cooldown = maxf(0.0, _fist_cooldown - delta)
	for kind: StringName in _reactive.keys():
		_reactive[kind]["time"] = float(_reactive[kind]["time"]) - delta
		if float(_reactive[kind]["time"]) <= 0.0:
			_reactive.erase(kind)
			reductions.erase(kind)
	if eat_time_left > 0.0:
		eat_time_left -= delta
		if eat_time_left <= 0.0:
			_finish_eating()


func _move(delta: float, wish: Vector3) -> void:
	var b: BalanceData = Balance.values
	var busy: bool = killer.is_channeling() or eat_time_left > 0.0 or aperture.meditating or aperture.ritual_left > 0.0
	var speed: float = b.walk_speed * status.speed_multiplier() * PassiveGu.mult("move_speed_mult") * (0.0 if busy else 1.0)
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity.x = _dash_direction.x * b.dash_speed
		velocity.z = _dash_direction.z * b.dash_speed
	else:
		var target_velocity: Vector3 = wish * speed
		velocity.x = move_toward(velocity.x, target_velocity.x, b.acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, b.acceleration * delta)
	if is_on_floor():
		_air_leaps = 1
		_air_dashes = 1
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= b.gravity * delta
		if velocity.y < -b.glide_fall_speed and Input.is_action_pressed(&"jump") and holder.slotted_gift("glide"):
			velocity.y = -b.glide_fall_speed
	apply_knockback(delta)
	move_and_slide()
	var flat_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if wish.length() > 0.1 and not busy:
		_facing = wish.normalized()
	var target: Combatant = targeting.soft_target
	if target != null and (targeting.locked_target != null or _fist_cooldown > 0.0):
		var to_target: Vector3 = target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.1:
			_facing = to_target.normalized()
	model.rotation.y = lerp_angle(model.rotation.y, atan2(-_facing.x, -_facing.z), clampf(delta * TURN_SPEED, 0.0, 1.0))
	model.animate(delta, flat_velocity.length())


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or is_dead():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event.is_action_pressed(&"jump"):
		_jump()
	elif event.is_action_pressed(&"dash"):
		_dash()
	elif event.is_action_pressed(&"attack_fist"):
		_capture_mouse()
		fist()
	elif event.is_action_pressed(&"killer_move"):
		start_killer_move()
	elif event.is_action_pressed(&"killer_move_next"):
		killer.cycle(1)
	elif event.is_action_pressed(&"killer_move_prev"):
		killer.cycle(-1)
	elif event.is_action_pressed(&"target_lock"):
		targeting.toggle_lock()
	elif event.is_action_pressed(&"target_switch"):
		targeting.switch_target()
	elif event.is_action_pressed(&"eat_primeval_stone"):
		eat_stone()
	elif event.is_action_pressed(&"interact"):
		interact()
	elif event.is_action_pressed(&"meditate"):
		toggle_meditation()
	else:
		for slot: int in SLOT_ACTIONS.size():
			if event.is_action_pressed(SLOT_ACTIONS[slot]):
				use_slot(slot)


func _capture_mouse() -> void:
	if not DisplayServer.is_touchscreen_available() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func aim_direction() -> Vector3:
	if targeting.soft_target != null:
		return (targeting.soft_target.aim_point() - aim_point()).normalized()
	return camera_rig.flat_forward()


func _can_act() -> bool:
	return not is_dead() and not status.is_stunned() and not killer.is_channeling() and eat_time_left <= 0.0 and aperture.ritual_left <= 0.0


func _cancel_idle_actions() -> void:
	if aperture.meditating and aperture.ritual_left <= 0.0:
		aperture.set_meditating(false)


# --- Aktionen ---

func use_slot(slot: int) -> void:
	if not _can_act():
		return
	_cancel_idle_actions()
	loadout.interrupt()
	if holder.use_slot(slot, aim_direction(), targeting.soft_target):
		_face(aim_direction())


func start_killer_move() -> void:
	if _can_act() and killer.start(aim_direction()):
		_cancel_idle_actions()
		loadout.interrupt()


func fist() -> void:
	if not _can_act() or _fist_cooldown > 0.0:
		return
	var b: BalanceData = Balance.values
	_fist_cooldown = b.fist_cooldown
	var forward: Vector3 = aim_direction() if targeting.soft_target != null else _facing
	_face(forward)
	var hit := HitInfo.create(b.player_base_damage + GameState.bonus_damage + flat_damage, self, team)
	PhysiqueEffects.decorate_hit(hit, self)
	hit.is_fist = true
	hit.can_react = false
	var targets: Array[Combatant] = Combat.in_cone(Combat.hostiles(get_tree(), team), global_position, forward, b.fist_range, FIST_ANGLE)
	var target: Combatant = Combat.nearest(targets, global_position)
	if target != null:
		loadout.mark_combat()
		hit.knockback = Vector3(forward.x, 0.0, forward.z).normalized() * b.fist_knockback
		target.receive_hit(hit)
	else:
		WorldInteraction.harvest(self, forward, FIST_ANGLE)
	Fx.sphere(get_tree(), aim_point() + Vector3(forward.x, 0.0, forward.z).normalized() * 0.9, 0.35, Color(1.0, 0.95, 0.8, 0.5), 0.12)


func _jump() -> void:
	if not _can_act():
		return
	_cancel_idle_actions()
	if is_on_floor():
		velocity.y = Balance.values.jump_velocity
		return
	var slot: int = _slot_with_form(GuCaster.FORM_MOVE)
	if slot >= 0:
		use_slot(slot)


func _slot_with_form(form: StringName) -> int:
	for slot: int in GameState.SLOT_COUNT:
		var instance: GuInstance = GameState.slot_instance(slot)
		if instance != null and holder.family_of(instance).form == form:
			return slot
	return -1


## Wirkform „bewegung": in der Luft ein Doppelsprung, am Boden ein Satz nach vorn.
func gu_leap() -> bool:
	var b: BalanceData = Balance.values
	if is_on_floor():
		velocity.y = b.jump_velocity
		var forward: Vector3 = _facing * b.leap_forward_speed
		velocity.x = forward.x
		velocity.z = forward.z
		return true
	if _air_leaps <= 0:
		return false
	_air_leaps -= 1
	velocity.y = b.double_jump_velocity
	Fx.ring(get_tree(), global_position, 1.2, Color(0.7, 0.6, 1.0), 0.3)
	return true


func _dash() -> void:
	if not _can_act() or _dash_cooldown > 0.0:
		return
	if not is_on_floor():
		if _air_dashes <= 0 or not holder.slotted_gift("air_dash"):
			return
		_air_dashes -= 1
	var b: BalanceData = Balance.values
	_cancel_idle_actions()
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var wish: Vector3 = camera_rig.flat_right() * input.x - camera_rig.flat_forward() * input.y
	_dash_direction = wish.normalized() if wish.length() > 0.1 else _facing
	_dash_time = b.dash_time
	_dash_cooldown = b.dash_cooldown
	invulnerable_time = maxf(invulnerable_time, b.dash_invulnerable)


## Für Mondschritt: an einen Punkt gleiten (Gelände bleibt Grenze).
func dash_to(point: Vector3) -> void:
	var offset: Vector3 = point - global_position
	offset.y = 0.0
	_dash_direction = offset.normalized()
	_dash_time = offset.length() / Balance.values.dash_speed
	invulnerable_time = maxf(invulnerable_time, _dash_time + 0.1)


func eat_stone() -> void:
	if _can_act() and PlayerActions.can_eat_stone(self):
		_cancel_idle_actions()
		eat_time_left = Balance.values.stone_eat_time


func _finish_eating() -> void:
	PlayerActions.finish_eating(self)


## Kultivieren-Knopf (M): Meditation an/aus, auf der Höchststufe mit voller Apertur der Durchbruch.
func toggle_meditation() -> void:
	if _can_act() or aperture.meditating:
		cultivation.cultivate()


func interact() -> void:
	var node: Node3D = nearest_interactable()
	if node != null and _can_act():
		node.call("interact", self)


func nearest_interactable() -> Node3D:
	return WorldInteraction.nearest(self, GROUP_INTERACTABLES, INTERACT_RANGE)


func _face(direction: Vector3) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length() > 0.05:
		_facing = flat.normalized()


# --- Treffer, reaktive Panzer, Tod ---

## Knochenfestung (thorns: value = Dornschaden) und Donnerpanzer (thunder: value = Ladungsstapel).
func start_reactive_armor(kind: StringName, duration: float, reduction: float, value: float) -> void:
	_reactive[kind] = {"time": duration, "value": value}
	add_timed_reduction(kind, reduction, duration)


func _after_hit(hit: HitInfo, dealt: float) -> void:
	if dealt <= 0.0:
		return
	loadout.mark_combat()
	if hit.is_dot:
		return
	killer.interrupt()
	loadout.interrupt()
	aperture.cancel_breakthrough()
	_cancel_idle_actions()
	if eat_time_left > 0.0:
		eat_time_left = 0.0
		EventBus.message.emit(tr("Beim Essen gestört!"), Color(1.0, 0.6, 0.4))
	invulnerable_time = maxf(invulnerable_time, Balance.values.hit_invulnerable)
	if hit.source == null or not is_instance_valid(hit.source):
		return
	var attacker: Combatant = hit.source as Combatant
	if attacker == null or attacker.is_dead():
		return
	PhysiqueEffects.thorns(self, attacker)
	if _reactive.has(&"thorns"):
		var thorn := HitInfo.create(float(_reactive[&"thorns"]["value"]), self, team).with_tags([&"durchbohren", &"schnitt"])
		Projectile.launch(get_tree(), aim_point(), thorn, (attacker.aim_point() - aim_point()).normalized(), {"range": 16.0, "color": KillerMoveEffects.COLOR_BONE})
	if _reactive.has(&"thunder"):
		attacker.status.apply_status(&"ladung", int(_reactive[&"thunder"]["value"]))


func _die() -> void:
	killer.interrupt()
	aperture.set_meditating(false)
	eat_time_left = 0.0
	velocity = Vector3.ZERO
	model.rotation.x = -PI * 0.5
	model.position.y = 0.3
	EventBus.player_died.emit()


## Wiederbeleben am Ruheort (Main entscheidet über Verluste je Todesmodus).
func respawn(at: Vector3) -> void:
	_dead = false
	status.clear_negative()
	health.max_hp = max_hp_now()
	health.hp = health.max_hp
	global_position = at
	velocity = Vector3.ZERO
	model.rotation.x = 0.0
	model.position.y = 0.0
	invulnerable_time = 2.0
	EventBus.player_respawned.emit()
