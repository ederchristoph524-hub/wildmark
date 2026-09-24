class_name GuCaster
extends RefCounted
## Setzt einen Gu nach seiner Wirkform um (GU_SYSTEM.md, Abschnitt 2). Neue Gu brauchen hier keinen Code, nur neue Wirkformen.

const FORM_PROJECTILE: StringName = &"geschoss"
const FORM_EXPLODING: StringName = &"geschoss_explodierend"
const FORM_FAST: StringName = &"geschoss_schnell"
const FORM_BEAM: StringName = &"strahl"
const FORM_STAB: StringName = &"stich"
const FORM_CIRCLE: StringName = &"kreis"
const FORM_SHIELD: StringName = &"selbstschild"
const FORM_HEAL: StringName = &"selbst_heilung"
const FORM_MOVE: StringName = &"bewegung"
const FORM_TAME: StringName = &"zaehmen"
const TAG_FORCE: StringName = &"wucht"
const DEFAULT_RANGE: float = 10.0
const SHIELD_KEY: StringName = &"haut"
const HEAL_COLOR: Color = Color(0.5, 1.0, 0.5)

## Wer wirkt, mit welchem Gu, welcher Stärke und in welche Richtung.
var caster: Combatant
var family: GuFamilyData
var gu: GuData
var power: float = 1.0
var extra_stacks: int = 0
var aim_direction: Vector3 = Vector3.FORWARD
var target: Combatant = null


func _init(who: Combatant, family_data: GuFamilyData, gu_data: GuData) -> void:
	caster = who
	family = family_data
	gu = gu_data


func base(key: StringName, fallback: float = 0.0) -> float:
	return float(family.base_r1.get(key, fallback))


func color() -> Color:
	return DataRegistry.gu_system().path_color(family.path)


## Führt den Gu aus. Liefert false, wenn nichts passieren konnte (z. B. kein zähmbares Ziel).
func cast() -> bool:
	match family.form:
		FORM_PROJECTILE, FORM_FAST, FORM_EXPLODING:
			return _cast_projectile()
		FORM_BEAM:
			return _cast_beam()
		FORM_STAB:
			return _cast_stab()
		FORM_CIRCLE:
			return _cast_circle()
		FORM_SHIELD:
			return _cast_shield()
		FORM_HEAL:
			return _cast_heal()
		FORM_MOVE:
			return caster.has_method("gu_leap") and bool(caster.call("gu_leap"))
		FORM_TAME:
			return _cast_tame()
	push_warning("GuCaster: unbekannte Wirkform '%s'" % family.form)
	return false


## Treffer mit Schaden, Tags und Zustand der Familie.
func make_hit(damage_mult: float = 1.0) -> HitInfo:
	var hit := HitInfo.create(base(&"schaden") * power * damage_mult, caster, caster.team).with_tags(family.tags)
	if family.status != &"":
		hit.with_status(family.status, int(base(&"stapel", 1.0)) + extra_stacks)
	hit.rank_factor = power
	if TAG_FORCE in family.tags:
		hit.knockback = aim_direction * Balance.values.knockback_force
	return hit


func _cast_projectile() -> bool:
	var b: BalanceData = Balance.values
	var config: Dictionary = {"range": base(&"reichweite", DEFAULT_RANGE), "color": color()}
	if family.form == FORM_FAST:
		config["speed"] = b.fast_projectile_speed
	if family.form == FORM_EXPLODING:
		config["explode_radius"] = base(&"radius", 1.5)
	var start: Vector3 = caster.aim_point() + Vector3(aim_direction.x, 0.0, aim_direction.z).normalized() * 0.6
	Projectile.launch(caster.get_tree(), start, make_hit(), _aim_from(start), config)
	return true


## Richtung vom Startpunkt zum Ziel (inklusive Höhe) oder die Blickrichtung.
func _aim_from(start: Vector3) -> Vector3:
	if target != null and is_instance_valid(target) and not target.is_dead():
		return (target.aim_point() - start).normalized()
	return Vector3(aim_direction.x, 0.0, aim_direction.z).normalized()


func _cast_beam() -> bool:
	var start: Vector3 = caster.aim_point()
	var end: Vector3 = start + _aim_from(start) * base(&"reichweite", DEFAULT_RANGE)
	var targets: Array[Combatant] = Combat.on_line(Combat.hostiles(caster.get_tree(), caster.team), start, end, Balance.values.beam_width)
	if not targets.is_empty():
		var first: Combatant = targets[0]
		first.receive_hit(make_hit())
		var slow_amount: float = base(&"verlangsamung")
		if slow_amount > 0.0:
			first.status.slow(slow_amount, Balance.values.status_durations.get(family.status, 3.0))
		end = first.aim_point()
	Fx.beam(caster.get_tree(), start, end, color(), 0.3, 0.35)
	return true


func _cast_stab() -> bool:
	var reach: float = base(&"reichweite", 3.0)
	var forward: Vector3 = _aim_from(caster.aim_point())
	var targets: Array[Combatant] = Combat.in_cone(Combat.hostiles(caster.get_tree(), caster.team), caster.global_position, forward, reach, Balance.values.stab_angle)
	var hit_target: Combatant = Combat.nearest(targets, caster.global_position)
	if hit_target != null:
		hit_target.receive_hit(make_hit())
	Fx.sphere(caster.get_tree(), caster.aim_point() + Vector3(forward.x, 0.0, forward.z) * reach * 0.6, reach * 0.35, Color(color(), 0.6), 0.2)
	return true


func _cast_circle() -> bool:
	var radius: float = base(&"radius", 2.5)
	var center: Vector3 = caster.global_position
	for other: Combatant in Combat.in_radius(Combat.hostiles(caster.get_tree(), caster.team), center, radius):
		var hit: HitInfo = make_hit()
		if hit.knockback != Vector3.ZERO:
			var away: Vector3 = other.global_position - center
			away.y = 0.0
			hit.knockback = away.normalized() * Balance.values.knockback_force
		other.receive_hit(hit)
	Fx.ring(caster.get_tree(), center, radius, color(), 0.35)
	return true


func _cast_shield() -> bool:
	var duration: float = base(&"dauer", 4.0)
	caster.add_timed_reduction(SHIELD_KEY, clampf(base(&"reduktion", 0.5) * minf(power, 1.5), 0.0, 0.9), duration)
	if family.base_r1.get(&"rueckstoss", false):
		for other: Combatant in Combat.in_radius(Combat.hostiles(caster.get_tree(), caster.team), caster.global_position, 2.5):
			var push := HitInfo.create(0.0, caster, caster.team)
			var away: Vector3 = other.global_position - caster.global_position
			away.y = 0.0
			push.knockback = away.normalized() * Balance.values.knockback_force
			push.can_react = false
			other.receive_hit(push)
	Fx.sphere(caster.get_tree(), caster.aim_point(), 1.3, Color(color(), 0.35), duration)
	return true


func _cast_heal() -> bool:
	var total: float = base(&"heilung_anteil", 0.25) * caster.health.max_hp * power
	caster.start_regeneration(total, base(&"dauer", 5.0))
	Fx.ring(caster.get_tree(), caster.global_position, 1.6, HEAL_COLOR, 0.6)
	return true


func _cast_tame() -> bool:
	var threshold: float = base(&"hp_schwelle", 0.3)
	var candidates: Array[Combatant] = []
	for other: Combatant in Combat.in_radius(Combat.hostiles(caster.get_tree(), caster.team), caster.global_position, 8.0):
		if other.has_method("can_be_tamed") and bool(other.call("can_be_tamed", gu.rank)) and other.health.ratio() <= threshold:
			candidates.append(other)
	var chosen: Combatant = target if target in candidates else Combat.nearest(candidates, caster.global_position)
	if chosen == null:
		EventBus.message.emit(tr("Keine geschwächte Bestie in der Nähe (unter %d %% Leben)") % roundi(threshold * 100.0), Color(1.0, 0.6, 0.4))
		return false
	chosen.call("tame", caster, base(&"dauer", 25.0), int(base(&"max_gefaehrten", 1.0)))
	Fx.beam(caster.get_tree(), caster.aim_point(), chosen.aim_point(), color(), 0.5)
	return true
