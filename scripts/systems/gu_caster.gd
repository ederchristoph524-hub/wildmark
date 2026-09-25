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
## Wirkformen, die nur den Wirker betreffen (kräftigeres Aufleuchten).
const SELF_FORMS: Array[StringName] = [&"selbstschild", &"selbst_heilung", &"tarnung", &"staerkung", &"eingebung", &"glueck", &"verwandlung", &"bewegung"]
const SHIELD_KEY: StringName = &"haut"
const HEAL_COLOR: Color = Color(0.5, 1.0, 0.5)
## Summe der Klingen eines Fächers auf ein Ziel (Regenbogenlicht, Phönixfeder, Mondgift).
const FAN_TOTAL: float = 2.2

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
## Ranggaben können die Wirkform ersetzen (as_circle, as_zone) und Schritte anhängen (extra).
func cast() -> bool:
	var done: bool = _cast_form()
	if done:
		Sound.cast(family, gu.rank, caster.global_position)
		_cast_flash()
		if not (caster is Player):
			# Gegen dich eingesetzt: jetzt kennst du ihn (Gu-Lexikon).
			Codex.note(gu.id)
		var extra: Variant = GuGifts.flags(gu).get("extra", [])
		if extra is Array and not (extra as Array).is_empty():
			EffectSteps.run(extra, context())
	return done


## Aufleuchten beim Wirken in der Handschrift des Pfads; Selbst-Wirkungen (Schutz, Heilung, Tarnung …) kräftiger.
func _cast_flash() -> void:
	var style: StringName = GuVfx.style_of(family.path, family.tags)
	if family.form in SELF_FORMS:
		GuVfx.burst(caster.get_tree(), caster.aim_point(), style, 1.1, 1.0)
	else:
		GuVfx.burst(caster.get_tree(), caster.aim_point() + aim_direction.normalized() * 0.6, style, 0.55, 0.4)


## Wirkungs-Kontext für Schritte: Grundschaden der Familie × Stärke, Farbe und Pfad.
func context() -> EffectContext:
	var raw: float = base(&"schaden")
	var ctx := EffectContext.create(caster, (raw + (caster.flat_damage if raw > 0.0 else 0.0)) * power, aim_direction, color())
	ctx.power = power
	ctx.target = target if is_instance_valid(target) else null
	ctx.path = family.path
	return ctx


func _cast_form() -> bool:
	var gifts: Dictionary = GuGifts.flags(gu)
	if gifts.has("as_circle"):
		return _cast_circle(float(gifts["as_circle"]))
	if gifts.get("as_zone") is Dictionary:
		EffectZone.spawn(_with_family_hit(gifts["as_zone"]), context())
		return true
	if family.form in GuForms.FORMS:
		return GuForms.cast(self)
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
			if GuGifts.number(gu, "teleport") > 0.0:
				EffectStepsSelf.blink(caster, GuGifts.number(gu, "teleport"), context().aim)
				return true
			return caster.has_method("gu_leap") and bool(caster.call("gu_leap"))
		FORM_TAME:
			return _cast_tame()
	push_warning("GuCaster: unbekannte Wirkform '%s'" % family.form)
	return false


## Treffer mit Schaden, Tags und Zustand der Familie.
func make_hit(damage_mult: float = 1.0) -> HitInfo:
	var raw: float = base(&"schaden")
	var hit := HitInfo.create((raw + (caster.flat_damage if raw > 0.0 else 0.0)) * power * damage_mult, caster, caster.team).with_tags(family.tags)
	if family.status != &"":
		hit.with_status(family.status, int(base(&"stapel", 1.0)) + extra_stacks)
	hit.rank_factor = power
	hit.path = family.path
	hit.pierce_armor = hit.pierce_armor or GuGifts.has(gu, "pierce_armor")
	hit.status_stacks += int(GuGifts.number(gu, "stacks_add")) if family.status != &"" else 0
	hit.spread_on_death = GuGifts.has(gu, "spread_on_death")
	hit.stun = GuGifts.number(gu, "stun")
	hit.lifesteal = GuGifts.number(gu, "lifesteal")
	hit.execute_bonus = GuGifts.number(gu, "execute")
	PhysiqueEffects.decorate_hit(hit, caster)
	if TAG_FORCE in family.tags:
		hit.knockback = aim_direction * Balance.values.knockback_force
	return hit


## Geschoss; Ranggaben: pierce, fan (+ fan_angle), homing, chain (+ chain_radius), impact (Schritte am Aufschlag).
## Schritt mit Zustand und Tags der Familie, falls der Schritt keine eigenen hat.
func _with_family_hit(step: Dictionary) -> Dictionary:
	var result: Dictionary = step.duplicate(true)
	if not result.has("tags"):
		result["tags"] = Array(family.tags).map(func(tag: StringName) -> String: return String(tag))
	if not result.has("status") and family.status != &"":
		result["status"] = String(family.status)
	return result


func _cast_projectile() -> bool:
	var b: BalanceData = Balance.values
	var gifts: Dictionary = GuGifts.flags(gu)
	var config: Dictionary = {"range": base(&"reichweite", DEFAULT_RANGE), "color": color(), "pierce": int(GuGifts.number(gu, "pierce")),
		"homing": bool(gifts.get("homing", false)), "chain": int(gifts.get("chain", 0)), "chain_radius": float(gifts.get("chain_radius", 6.0))}
	if family.form == FORM_FAST:
		config["speed"] = b.fast_projectile_speed
	if family.form == FORM_EXPLODING:
		config["explode_radius"] = base(&"radius", 1.5) + GuGifts.number(gu, "radius_add")
	var center_config: Dictionary = config.duplicate()
	if gifts.get("impact") is Array:
		# Aufschlag-Wirkungen nur für die mittlere Klinge, sonst vervielfacht der Fächer Zonen und Explosionen.
		center_config["impact"] = gifts["impact"]
		center_config["impact_ctx"] = context()
	var start: Vector3 = caster.aim_point() + Vector3(aim_direction.x, 0.0, aim_direction.z).normalized() * 0.6
	var direction: Vector3 = _aim_from(start)
	var count: int = 1 + int(gifts.get("fan", 0))
	var spread: float = deg_to_rad(float(gifts.get("fan_angle", 40.0)))
	# Fächer: Jede Klinge trifft schwächer, zusammen höchstens FAN_TOTAL-fach auf ein einzelnes Ziel.
	var blade_mult: float = minf(1.0, FAN_TOTAL / count)
	for i: int in count:
		var angle: float = 0.0 if count == 1 else lerpf(-spread * 0.5, spread * 0.5, i / float(count - 1))
		Projectile.launch(caster.get_tree(), start, make_hit(blade_mult), direction.rotated(Vector3.UP, angle), center_config if i == floori(count / 2.0) else config)
	return true


## Richtung vom Startpunkt zum Ziel (inklusive Höhe) oder die Blickrichtung.
func _aim_from(start: Vector3) -> Vector3:
	if target != null and is_instance_valid(target) and not target.is_dead():
		return (target.aim_point() - start).normalized()
	return Vector3(aim_direction.x, 0.0, aim_direction.z).normalized()


## Strahl; Ranggaben: beam_all, width_mult, knockback (Stoß entlang des Strahls), impact (Schritte am Ende).
func _cast_beam() -> bool:
	var start: Vector3 = caster.aim_point()
	var direction: Vector3 = _aim_from(start)
	var end: Vector3 = start + direction * base(&"reichweite", DEFAULT_RANGE)
	var width: float = Balance.values.beam_width * maxf(1.0, GuGifts.number(gu, "width_mult"))
	var targets: Array[Combatant] = Combat.on_line(Combat.hostiles(caster.get_tree(), caster.team), start, end, width)
	var push: float = GuGifts.number(gu, "knockback")
	if not targets.is_empty():
		var hit_all: bool = GuGifts.has(gu, "beam_all")
		var struck: Array[Combatant] = targets if hit_all else targets.slice(0, 1)
		for target_hit: Combatant in struck:
			var hit: HitInfo = make_hit()
			if push > 0.0:
				hit.knockback = Vector3(direction.x, 0.0, direction.z).normalized() * Formulas.knockback_speed(Balance.values, push)
			target_hit.receive_hit(hit)
			var slow_amount: float = base(&"verlangsamung")
			if slow_amount > 0.0:
				target_hit.status.slow(slow_amount, DataRegistry.status(family.status).duration if family.status != &"" else 3.0)
		if not hit_all:
			end = targets[0].aim_point()
	Fx.beam(caster.get_tree(), start, end, color(), 0.3, 0.35 * width / Balance.values.beam_width)
	var impact: Variant = GuGifts.flags(gu).get("impact")
	if impact is Array:
		EffectSteps.run(impact, context().at_point(end - Vector3.UP * (start.y - caster.global_position.y)))
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


## Kreis um den Wirker; mit Ranggabe „Sog" werden Gegner aus größerem Umkreis herangezogen.
## radius_override > 0: Ranggabe as_circle (z. B. Frostnova).
func _cast_circle(radius_override: float = 0.0) -> bool:
	var pull: float = GuGifts.number(gu, "pull")
	var radius: float = radius_override if radius_override > 0.0 else base(&"radius", 2.5) + GuGifts.number(gu, "radius_add")
	var center: Vector3 = caster.global_position
	for other: Combatant in Combat.in_radius(Combat.hostiles(caster.get_tree(), caster.team), center, radius + pull):
		var hit: HitInfo = make_hit()
		var away: Vector3 = other.global_position - center
		away.y = 0.0
		if pull > 0.0:
			hit.knockback = -away.normalized() * Balance.values.knockback_force
		elif hit.knockback != Vector3.ZERO:
			hit.knockback = away.normalized() * Balance.values.knockback_force
		other.receive_hit(hit)
	Fx.ring(caster.get_tree(), center, radius + pull, color(), 0.35)
	return true


func _cast_shield() -> bool:
	var duration: float = base(&"dauer", 4.0)
	caster.add_timed_reduction(SHIELD_KEY, clampf(base(&"reduktion", 0.5) * minf(power, 1.5), 0.0, 0.9), duration)
	if GuGifts.has(gu, "reflect"):
		caster.reflect_time = duration
	if GuGifts.has(gu, "unstoppable"):
		caster.unstoppable_time = maxf(caster.unstoppable_time, duration)
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
	if GuGifts.has(gu, "cleanse"):
		caster.status.clear_negative()
	var zone: Variant = GuGifts.flags(gu).get("heal_zone")
	if zone is Dictionary:
		EffectZone.spawn(zone, context())
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
	var duration: float = INF if GuGifts.has(gu, "permanent") else base(&"dauer", 25.0)
	chosen.call("tame", caster, duration, int(base(&"max_gefaehrten", 1.0)) + int(GuGifts.number(gu, "companions_add")))
	Fx.beam(caster.get_tree(), caster.aim_point(), chosen.aim_point(), color(), 0.5)
	return true
