class_name Enemy
extends Combatant
## Eine Bestie aus gegner.json: Umherstreifen, Verfolgen, Angriffe mit Telegraph, Verhalten nach Feld beh, Beute und Zähmung.

enum State { WANDER, CHASE, WINDUP, CHARGE, RECOVER, FLEE }

const GROUP_ENEMIES: StringName = &"enemies"
const GROUP_COMPANIONS: StringName = &"companions"
const BEH_CHARGE: StringName = &"charge"
const BEH_RANGED: StringName = &"ranged"
const BEH_SPAWN: StringName = &"spawn"
const BEH_EXPLODE: StringName = &"explode"
const BEH_HEAL: StringName = &"heal"
const BEH_ARMOR: StringName = &"armor"
const BEH_TELEPORT: StringName = &"teleport"
const BEH_BOSS: StringName = &"boss"
const WANDER_RADIUS: float = 8.0
const TURN_SPEED: float = 8.0

var data: EnemyData = null
var home: Vector3 = Vector3.ZERO
var target: Combatant = null
var state: State = State.WANDER
## Gezähmt: Besitzer und verbleibende Zeit als Gefährte.
var companion_owner: Combatant = null
var companion_time: float = 0.0
var is_minion: bool = false
## Wächter (z. B. eines Erbes) werden nicht wegen Entfernung entfernt.
var persistent: bool = false

var _state_time: float = 0.0
var _attack_cooldown: float = 0.0
var _special_cooldown: float = 0.0
var _wander_point: Vector3 = Vector3.ZERO
var _charge_direction: Vector3 = Vector3.ZERO
var _telegraph: Telegraph = null
var _model: EnemyModel = null
var _label: EnemyNameplate = null
var _facing: Vector3 = Vector3.FORWARD
## Beschworene Diener (für die Obergrenze).
var minions: Array[Enemy] = []


func setup(enemy_data: EnemyData, at: Vector3) -> void:
	data = enemy_data
	home = at
	position = at
	_wander_point = at


func _ready() -> void:
	var b: BalanceData = Balance.values
	display_name = tr(data.display_name)
	body_radius = data.radius * b.enemy_size_scale
	body_height = body_radius * 2.4
	_init_combatant(TEAM_ENEMY, data.max_hp)
	add_to_group(GROUP_ENEMIES)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = body_radius * 0.8
	capsule.height = maxf(body_height, capsule.radius * 2.0)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)
	_model = EnemyModel.new()
	_model.build(data.shape, data.color, body_radius, data.flying)
	add_child(_model)
	_label = EnemyNameplate.new()
	_label.position.y = body_height + 0.55 + (1.2 if data.flying else 0.0)
	add_child(_label)
	health.damaged.connect(func(_amount: float) -> void: _update_label())
	status.changed.connect(_update_label)
	_attack_cooldown = randf_range(0.3, 1.0)
	_special_cooldown = b.spawn_minion_interval
	_update_label()


func fears_light() -> bool:
	return data.night_only or data.shape == &"ghost"


func is_companion() -> bool:
	return companion_owner != null


func can_be_tamed(gu_rank: int) -> bool:
	return not data.boss and not is_companion() and data.radius <= Balance.values.tame_max_radius_r1 * (1.0 + (gu_rank - 1) * 0.5)


## Sklaverei-Familie: wird für duration zum Gefährten; bei zu vielen Gefährten verlässt dich der älteste.
func tame(owner_combatant: Combatant, duration: float, max_companions: int) -> void:
	var existing: Array[Node] = get_tree().get_nodes_in_group(GROUP_COMPANIONS)
	if existing.size() >= max_companions and not existing.is_empty():
		(existing[0] as Enemy).release()
	companion_owner = owner_combatant
	companion_time = duration
	set_team(TEAM_PLAYER)
	remove_from_group(GROUP_ENEMIES)
	add_to_group(GROUP_COMPANIONS)
	target = null
	health.hp = health.max_hp * 0.6
	status.clear_negative()
	_enter(State.CHASE)
	EventBus.message.emit(tr("%s folgt dir jetzt") % display_name, Color(0.7, 0.6, 1.0))
	_update_label()


## Beschworene Gefährten wachsen mit dem Rang des Gu, der sie ruft.
func scale_power(power: float) -> void:
	health.max_hp *= power
	health.hp = health.max_hp
	add_buff(&"power", power, 1.0, INF)
	_update_label()


func release() -> void:
	companion_owner = null
	remove_from_group(GROUP_COMPANIONS)
	_enter(State.FLEE)


func _physics_process(delta: float) -> void:
	tick_combatant(delta)
	if is_dead():
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_special_cooldown = maxf(0.0, _special_cooldown - delta)
	_state_time += delta
	if is_companion():
		companion_time -= delta
		if companion_time <= 0.0:
			release()
	var wish: Vector3 = Vector3.ZERO
	if status.is_feared() and target != null and is_instance_valid(target):
		wish = (global_position - target.global_position).normalized()
	elif not status.is_stunned():
		wish = _think(delta)
	_move(delta, wish)


func _think(delta: float) -> Vector3:
	match state:
		State.WANDER:
			return _wander()
		State.CHASE:
			return _chase()
		State.WINDUP:
			if _state_time >= _windup_time():
				_attack()
			return Vector3.ZERO
		State.CHARGE:
			return _charge(delta)
		State.RECOVER:
			if _state_time >= 0.35:
				_enter(State.CHASE)
			return Vector3.ZERO
		State.FLEE:
			if _state_time > 4.0:
				queue_free()
			return (global_position - (companion_owner.global_position if companion_owner != null else home)).normalized()
	return Vector3.ZERO


func _wander() -> Vector3:
	target = _find_target()
	if target != null:
		_enter(State.CHASE)
		return Vector3.ZERO
	if is_companion():
		return _follow_owner()
	var offset: Vector3 = _wander_point - global_position
	offset.y = 0.0
	if offset.length() < 1.0 or _state_time > 6.0:
		_wander_point = home + Vector3(randf_range(-WANDER_RADIUS, WANDER_RADIUS), 0.0, randf_range(-WANDER_RADIUS, WANDER_RADIUS))
		_state_time = 0.0
	return offset.normalized() * 0.4


func _follow_owner() -> Vector3:
	var offset: Vector3 = companion_owner.global_position - global_position
	offset.y = 0.0
	return offset.normalized() if offset.length() > Balance.values.companion_follow_distance else Vector3.ZERO


func _find_target() -> Combatant:
	if status.is_blinded():
		return null
	var b: BalanceData = Balance.values
	var center: Vector3 = companion_owner.global_position if is_companion() else global_position
	var candidates: Array[Combatant] = []
	for candidate: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), team), center, b.aggro_radius):
		if candidate.team == TEAM_WORLD:
			continue
		if candidate.global_position.distance_to(center) <= b.aggro_radius * candidate.aggro_factor() + candidate.body_radius:
			candidates.append(candidate)
	return Combat.nearest(candidates, global_position)


func _target_lost() -> bool:
	if target == null or not is_instance_valid(target) or target.is_dead() or status.is_blinded():
		return true
	var anchor: Vector3 = companion_owner.global_position if is_companion() else home
	return target.global_position.distance_to(anchor) > Balance.values.leash_radius


func _chase() -> Vector3:
	if _target_lost():
		target = null
		_enter(State.WANDER)
		return Vector3.ZERO
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	var distance: float = offset.length()
	_special(distance)
	if state != State.CHASE:
		return Vector3.ZERO
	var reach: float = _reach()
	if distance <= reach and _attack_cooldown <= 0.0:
		_start_windup()
		return Vector3.ZERO
	if data.behavior == BEH_RANGED or data.behavior == BEH_HEAL:
		if distance < reach * 0.6:
			return -offset.normalized()
		return offset.normalized() if distance > reach * 0.9 else Vector3.ZERO
	return offset.normalized() if distance > reach * 0.8 else Vector3.ZERO


func _reach() -> float:
	var b: BalanceData = Balance.values
	if data.attack_range > 0.0:
		return data.attack_range * b.enemy_size_scale * 0.8
	if data.behavior == BEH_CHARGE:
		return 9.0
	if data.behavior == BEH_EXPLODE:
		return b.explode_radius * 0.6
	return b.attack_range + body_radius


## Sonderfähigkeiten während der Verfolgung (Beschwören, Heilen, Teleport).
func _special(distance: float) -> void:
	if _special_cooldown <= 0.0:
		_special_cooldown = EnemyAbilities.use(self, distance)


# --- Angriffe ---

func _windup_time() -> float:
	var b: BalanceData = Balance.values
	match data.behavior:
		BEH_CHARGE:
			return b.attack_telegraph * 1.5
		BEH_EXPLODE:
			return b.attack_telegraph * 1.6
	return b.attack_telegraph


func _start_windup() -> void:
	_enter(State.WINDUP)
	var b: BalanceData = Balance.values
	_face_towards(target.global_position)
	match data.behavior:
		BEH_CHARGE:
			_charge_direction = Vector3(_facing.x, 0.0, _facing.z).normalized()
			_telegraph = Telegraph.show_line(get_tree(), global_position, global_position + _charge_direction * 9.0, body_radius * 2.0, _windup_time())
		BEH_EXPLODE:
			_telegraph = Telegraph.show_disc(get_tree(), global_position, b.explode_radius, _windup_time())
		BEH_RANGED, BEH_HEAL:
			pass
		_:
			_telegraph = Telegraph.show_disc(get_tree(), global_position + _facing * (body_radius + 0.6), body_radius + 0.9, _windup_time())


func _attack() -> void:
	var b: BalanceData = Balance.values
	_attack_cooldown = b.attack_cooldown
	match data.behavior:
		BEH_CHARGE:
			_enter(State.CHARGE)
			return
		BEH_EXPLODE:
			for victim: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), team), global_position, b.explode_radius):
				victim.receive_hit(_make_hit(1.0))
			Fx.sphere(get_tree(), aim_point(), b.explode_radius, Color(1.0, 0.4, 0.2, 0.6), 0.35)
			health.apply_damage(health.hp)
			return
		BEH_RANGED, BEH_HEAL:
			if target != null and is_instance_valid(target):
				var hit: HitInfo = _make_hit(1.0)
				var config: Dictionary = {"speed": b.enemy_projectile_speed, "range": _reach() * 1.6, "color": Color(1.0, 0.3, 0.2)}
				Projectile.launch(get_tree(), aim_point(), hit, (target.aim_point() - aim_point()).normalized(), config)
		_:
			var reach: float = body_radius + 1.5
			for victim: Combatant in Combat.in_cone(Combat.hostiles(get_tree(), team), global_position, _facing, reach, 120.0):
				victim.receive_hit(_make_hit(1.0))
	_enter(State.RECOVER)


func _charge(_delta: float) -> Vector3:
	if _state_time > 0.8:
		_enter(State.RECOVER)
		return Vector3.ZERO
	for victim: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), team), global_position, body_radius + 0.6):
		victim.receive_hit(_make_hit(1.3))
		_enter(State.RECOVER)
		return Vector3.ZERO
	return _charge_direction * Balance.values.charge_speed_mult


## Treffer der Bestie: Schaden aus den Daten, nachts stärker, Gift/Brand bei Giftschleim und Feuerwesen.
func _make_hit(mult: float) -> HitInfo:
	var b: BalanceData = Balance.values
	var night: float = b.night_damage_mult if Formulas.is_night(b, GameState.time_of_day) and not is_companion() else 1.0
	var hit := HitInfo.create(data.damage * mult * night, self, team)
	if data.poison:
		hit.with_status(&"gift", 1)
	elif data.burn:
		hit.with_status(&"brand", 1)
	hit.knockback = _facing * 2.0
	return hit


# --- Bewegung und Zustände ---

func _enter(new_state: State) -> void:
	if _telegraph != null and is_instance_valid(_telegraph) and new_state != State.WINDUP:
		_telegraph.queue_free()
	_telegraph = null if new_state != State.WINDUP else _telegraph
	state = new_state
	_state_time = 0.0


func _move(delta: float, wish: Vector3) -> void:
	var b: BalanceData = Balance.values
	var speed: float = data.speed * b.enemy_speed_scale * status.speed_multiplier()
	var target_velocity: Vector3 = wish * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, 30.0 * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - b.gravity * delta
	apply_knockback(delta)
	move_and_slide()
	if wish.length() > 0.1 and state != State.CHARGE:
		_facing = Vector3(wish.x, 0.0, wish.z).normalized()
	if _facing.length() > 0.1:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-_facing.x, -_facing.z), clampf(delta * TURN_SPEED, 0.0, 1.0))
	_model.animate(delta, Vector2(velocity.x, velocity.z).length(), state == State.WINDUP)
	if global_position.y < -40.0:
		queue_free()


func _face_towards(point: Vector3) -> void:
	var offset: Vector3 = point - global_position
	offset.y = 0.0
	if offset.length() > 0.05:
		_facing = offset.normalized()


## Panzerkäfer und Co.: von vorn getroffen weniger Schaden, außer der Treffer durchbohrt.
func _armor_multiplier(hit: HitInfo) -> float:
	if hit.pierce_armor or not (data.armored or data.behavior == BEH_ARMOR) or hit.source == null or not is_instance_valid(hit.source):
		return 1.0
	var from: Vector3 = hit.source.global_position - global_position
	from.y = 0.0
	if from.length() > 0.01 and _facing.angle_to(from.normalized()) < deg_to_rad(70.0):
		return 1.0 - Balance.values.armor_front_reduction
	return 1.0


func _after_hit(hit: HitInfo, _dealt: float) -> void:
	if hit.source == null or not is_instance_valid(hit.source):
		return
	var attacker: Combatant = hit.source as Combatant
	if attacker != null and is_instance_valid(attacker) and attacker.team != team and not status.is_blinded():
		if state == State.WANDER or target == null:
			target = attacker
			_enter(State.CHASE)


func _die() -> void:
	if _telegraph != null and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	if not is_companion() and team == TEAM_ENEMY:
		Pickup.drop_loot(get_tree(), data, global_position)
		EventBus.enemy_killed.emit(data.id, global_position)
	queue_free()


func _update_label() -> void:
	if _label != null:
		_label.refresh(display_name, health, status, is_companion())
