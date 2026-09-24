class_name GuMasterBrain
extends RefCounted
## Kampf-KI eines Gu-Meisters: Schild oder Heilung bei Bedrängnis, Wirbel aus der Nähe, sonst Fernangriff auf Abstand; ohne Essenz nur die Faust.

const RANGED_FORMS: Array[StringName] = [GuCaster.FORM_PROJECTILE, GuCaster.FORM_FAST, GuCaster.FORM_EXPLODING, GuCaster.FORM_BEAM,
	GuForms.FORM_SWARM, GuForms.FORM_ZONE, GuForms.FORM_TRAP]
const CLOSE_FORMS: Array[StringName] = [GuCaster.FORM_CIRCLE, GuCaster.FORM_STAB, GuForms.FORM_CONE, GuForms.FORM_AURA, GuForms.FORM_ORBIT, GuForms.FORM_CHARGE]
const DEFEND_FORMS: Array[StringName] = [GuCaster.FORM_SHIELD, GuCaster.FORM_HEAL, GuForms.FORM_BUFF, GuForms.FORM_SUMMON, GuForms.FORM_STEALTH]
const CLOSE_RANGE: float = 2.6
const DEFEND_RANGE: float = 6.0
const STRAFE_FLIP_CHANCE: float = 0.2

var master: GuMaster = null
var _think_left: float = 0.0
var _fist_cooldown: float = 0.0
var _strafe_sign: float = 1.0
var _wish: Vector3 = Vector3.ZERO
## Angriff in Vorbereitung (Index, feste Richtung, Restzeit).
var _pending: int = -1
var _pending_aim: Vector3 = Vector3.FORWARD
var _pending_left: float = 0.0


func _init(owner_master: GuMaster) -> void:
	master = owner_master


## Liefert die Laufrichtung; entscheidet in festen Abständen neu (Reaktionszeit).
func tick(delta: float, foe: Combatant) -> Vector3:
	_fist_cooldown = maxf(0.0, _fist_cooldown - delta)
	if _pending >= 0:
		_pending_left -= delta
		if _pending_left <= 0.0:
			master.use_gu(_pending, _pending_aim, foe)
			_pending = -1
			_think_left = 0.0
		return Vector3.ZERO
	_think_left -= delta
	if _think_left > 0.0:
		return _wish
	_think_left = Balance.values.master_think_interval
	_wish = _decide(foe)
	return _wish


func _decide(foe: Combatant) -> Vector3:
	var offset: Vector3 = foe.global_position - master.global_position
	offset.y = 0.0
	var distance: float = offset.length()
	var toward: Vector3 = offset.normalized() if distance > 0.05 else Vector3.FORWARD
	master.face(toward)
	if master.status.is_blinded():
		return -toward * 0.5
	if master.health.ratio() < Balance.values.master_defend_ratio and distance < DEFEND_RANGE:
		var defend: int = master.ready_index(DEFEND_FORMS)
		if defend >= 0 and master.use_gu(defend, toward, foe):
			return Vector3.ZERO
	if distance <= CLOSE_RANGE:
		var close: int = master.ready_index(CLOSE_FORMS)
		if close >= 0:
			_wind_up(close, toward)
			Telegraph.show_disc(master.get_tree(), master.global_position, float(master.family_of(close).base_r1.get(&"radius", CLOSE_RANGE)), Balance.values.master_cast_windup)
			return Vector3.ZERO
	var ranged: int = master.ready_index(RANGED_FORMS)
	if ranged >= 0 and distance <= master.range_of(ranged) * 0.9:
		_wind_up(ranged, (foe.aim_point() - master.aim_point()).normalized())
		return Vector3.ZERO
	if not master.can_afford_any():
		return _brawl(foe, toward, distance)
	return _keep_range(toward, distance)


## Ausholen: Richtung wird jetzt festgelegt, der Gu wirkt erst nach der Vorwarnzeit.
func _wind_up(index: int, aim: Vector3) -> void:
	_pending = index
	_pending_aim = aim
	_pending_left = Balance.values.master_cast_windup
	var color: Color = DataRegistry.gu_system().path_color(master.family_of(index).path)
	Fx.sphere(master.get_tree(), master.aim_point() + Vector3(aim.x, 0.0, aim.z).normalized() * 0.5, 0.3, color, _pending_left)


## Essenz leer: ran und zuschlagen – das ist der Moment des Spielers.
func _brawl(foe: Combatant, toward: Vector3, distance: float) -> Vector3:
	if distance <= Balance.values.fist_range:
		if _fist_cooldown <= 0.0:
			_fist_cooldown = Balance.values.master_fist_cooldown
			master.fist(foe)
		return Vector3.ZERO
	return toward


func _keep_range(toward: Vector3, distance: float) -> Vector3:
	var preferred: float = Balance.values.master_preferred_range
	if distance > preferred:
		return toward
	if distance < preferred * 0.5:
		return -toward
	return _strafe(toward)


func _strafe(toward: Vector3) -> Vector3:
	if randf() < STRAFE_FLIP_CHANCE:
		_strafe_sign = -_strafe_sign
	return toward.cross(Vector3.UP).normalized() * _strafe_sign * 0.7
