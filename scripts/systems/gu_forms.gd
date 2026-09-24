class_name GuForms
extends RefCounted
## Weitere Wirkformen (GU_SYSTEM.md, Abschnitt 2): Jede baut aus den Basiswerten der Familie einen Wirkungsschritt
## für EffectSteps. Die Ranggabe "step" überschreibt beliebige Schritt-Parameter (z. B. {"radius": 4.5, "pull": 1}),
## "then" hängt Folgeschritte an den Schritt (z. B. an eine Falle).

const FORM_ZONE: StringName = &"zone"
const FORM_CONE: StringName = &"kegel"
const FORM_CHARGE: StringName = &"sturmlauf"
const FORM_AURA: StringName = &"aura"
const FORM_SWARM: StringName = &"schwarm"
const FORM_ORBIT: StringName = &"umkreisen"
const FORM_TRAP: StringName = &"falle"
const FORM_STEALTH: StringName = &"tarnung"
const FORM_BUFF: StringName = &"staerkung"
const FORM_SUMMON: StringName = &"beschwoerung"
## Summe des Schadens aller Sterne eines Schwarms bzw. aller Fallen auf ein Ziel (× Grundschaden).
const SWARM_TOTAL: float = 3.0
const TRAP_TOTAL: float = 2.5
const FORMS: Array[StringName] = [FORM_ZONE, FORM_CONE, FORM_CHARGE, FORM_AURA, FORM_SWARM, FORM_ORBIT, FORM_TRAP, FORM_STEALTH, FORM_BUFF, FORM_SUMMON]


static func cast(caster: GuCaster) -> bool:
	var step: Dictionary = build_step(caster.family, caster.gu)
	if step.is_empty():
		return false
	EffectSteps.run_step(step, caster.context())
	return true


## Schritt aus Wirkform, Basiswerten und Ranggaben (auch für Anzeige und Tests nutzbar).
static func build_step(family: GuFamilyData, gu: GuData) -> Dictionary:
	var gifts: Dictionary = GuGifts.flags(gu)
	var step: Dictionary = _base_step(family, gifts)
	if step.is_empty():
		return step
	if gifts.get("step") is Dictionary:
		step.merge(gifts["step"], true)
	if gifts.get("then") is Array:
		step["then"] = gifts["then"]
	# Viele Sterne oder Fallen teilen sich den Schaden (sonst wächst er mit der Anzahl unbegrenzt).
	var count: int = int(step.get("count", 1))
	if family.form == FORM_SWARM:
		step["mult"] = float(step.get("mult", 1.0)) * minf(1.0, SWARM_TOTAL / count)
	elif family.form == FORM_TRAP:
		var share: float = minf(1.0, TRAP_TOTAL / count)
		step["mult"] = float(step.get("mult", 1.0)) * share
		# Folgeschritte (Feuerfeld, Kettenblitz) teilen sich den Schaden ebenso, sonst stapeln sich sechs Felder.
		if step.get("then") is Array:
			step["then"] = _scaled(step["then"], share)
	return step


static func _scaled(steps: Array, factor: float) -> Array:
	var result: Array = []
	for raw: Variant in steps:
		var scaled: Dictionary = (raw as Dictionary).duplicate(true)
		scaled["mult"] = float(scaled.get("mult", 1.0)) * factor
		result.append(scaled)
	return result


static func _base_step(family: GuFamilyData, gifts: Dictionary) -> Dictionary:
	var hit: Dictionary = {"mult": 1.0, "tags": Array(family.tags).map(func(tag: StringName) -> String: return String(tag))}
	if family.status != &"":
		hit["status"] = String(family.status)
		hit["stacks"] = int(_value(family, &"stapel", 1.0)) + int(gifts.get("stacks_add", 0))
	for key: String in ["stun", "lifesteal", "execute", "pierce_armor"]:
		if gifts.has(key):
			hit[key] = gifts[key]
	var radius: float = _value(family, &"radius", 3.0) + float(gifts.get("radius_add", 0.0))
	var reach: float = _value(family, &"reichweite", 8.0)
	var duration: float = _value(family, &"dauer", 5.0) + float(gifts.get("time_add", 0.0))
	var count: int = int(_value(family, &"anzahl", 3.0)) + int(gifts.get("count_add", 0))
	var step: Dictionary = {}
	match family.form:
		FORM_ZONE:
			step = {"t": "zone", "radius": radius, "time": duration, "tick": _value(family, &"takt", 0.5), "at": "target", "distance": reach * 0.7,
				"slow": _value(family, &"verlangsamung", 0.0), "pull": float(gifts.get("pull", 0.0))}
		FORM_CONE:
			step = {"t": "cone", "reach": reach, "angle": _value(family, &"winkel", 80.0), "knockback": _value(family, &"rueckstoss", 0.0)}
		FORM_CHARGE:
			step = {"t": "line", "length": reach, "width": _value(family, &"breite", 2.2), "knockback": _value(family, &"rueckstoss", 1.2), "dash": true}
		FORM_AURA:
			step = {"t": "zone", "follow": true, "radius": radius, "time": duration, "tick": _value(family, &"takt", 0.5)}
		FORM_SWARM:
			step = {"t": "projectiles", "count": count, "spread": _value(family, &"winkel", 70.0), "homing": true, "range": reach, "speed": _value(family, &"tempo", 14.0)}
		FORM_ORBIT:
			step = {"t": "orbit", "count": count, "radius": radius, "time": duration, "speed": _value(family, &"tempo", 0.7), "tick": _value(family, &"takt", 0.5)}
		FORM_TRAP:
			step = {"t": "trap", "count": count, "radius": radius, "time": duration, "trigger": _value(family, &"ausloeser", 1.6), "at": "aim", "distance": reach * 0.5}
		FORM_STEALTH:
			return {"t": "stealth", "time": duration}
		FORM_BUFF:
			return {"t": "buff", "key": String(family.id), "damage": _value(family, &"staerke", 1.3), "speed": _value(family, &"tempo", 1.0),
				"reduction": _value(family, &"reduktion", 0.0), "time": duration}
		FORM_SUMMON:
			return {"t": "summon", "enemy": String(family.base_r1.get(&"wesen", "wolf")), "time": duration, "count": count}
	step.merge(hit)
	return step


static func _value(family: GuFamilyData, key: StringName, fallback: float) -> float:
	return float(family.base_r1.get(key, fallback))
