class_name StepValidator
extends RefCounted
## Prüft Wirkungsschritte (Killer Moves, Ranggaben, Bestien-Fähigkeiten) und Wirkformen der Familien.

const STEP_TYPES: Array[String] = ["circle", "line", "cone", "projectiles", "chain", "zone", "orbit", "trap", "delay",
	"armor", "heal", "summon", "buff", "stealth", "teleport", "dash", "cleanse", "unstoppable", "reflect"]
## Wirkformen aus GuCaster und GuForms (hier als Text, weil das Importskript ohne Autoloads läuft).
const FORMS: Array[StringName] = [&"geschoss", &"geschoss_explodierend", &"geschoss_schnell", &"strahl", &"stich", &"kreis",
	&"selbstschild", &"selbst_heilung", &"bewegung", &"zaehmen", &"zone", &"kegel", &"sturmlauf", &"aura", &"schwarm",
	&"umkreisen", &"falle", &"tarnung", &"staerkung", &"beschwoerung"]
const FORM_SUMMON: StringName = &"beschwoerung"
## Ranggaben, die Schritte (Liste) oder einen Schritt (Objekt) enthalten.
const STEP_LIST_GIFTS: Array[String] = ["extra", "impact", "then"]
const STEP_GIFTS: Array[String] = ["as_zone", "heal_zone"]

var _report: ImportReport
var _ids: Dictionary


func _init(report: ImportReport, ids: Dictionary) -> void:
	_report = report
	_ids = ids


func check_form(family: GuFamilyData, context: String) -> void:
	if family.form not in FORMS:
		_report.error("%s: unbekannte Wirkform '%s'" % [context, family.form])
	if family.form == FORM_SUMMON:
		_expect("enemies", family.base_r1.get(&"wesen", ""), context + " (Wesen)")
	for member: GuData in family.members:
		check_gifts(member.gifts, "%s, Gu '%s'" % [context, member.id])


func check_gifts(gifts: Dictionary, context: String) -> void:
	for key: String in STEP_LIST_GIFTS:
		if gifts.has(key):
			check_steps(gifts[key], "%s (%s)" % [context, key])
	for key: String in STEP_GIFTS:
		if gifts.has(key):
			check_steps([gifts[key]], "%s (%s)" % [context, key])


func check_steps(steps: Variant, context: String) -> void:
	if not steps is Array:
		_report.error("%s: Schritte müssen eine Liste sein" % context)
		return
	for raw: Variant in steps:
		if not raw is Dictionary:
			_report.error("%s: Schritt ist kein Objekt" % context)
			continue
		var step: Dictionary = raw
		var kind: String = str(step.get("t", ""))
		if kind not in STEP_TYPES:
			_report.error("%s: unbekannte Schrittart '%s'" % [context, kind])
		if step.has("status"):
			_expect("statuses", step["status"], context)
		for tag: Variant in step.get("tags", []):
			_expect("tags", tag, context)
		if kind == "summon":
			_expect("enemies", step.get("enemy", ""), context + " (Beschwörung)")
		if step.get("set_stacks") is Dictionary:
			for id: Variant in step["set_stacks"]:
				_expect("statuses", id, context)
		if step.has("then"):
			check_steps(step["then"], context + " → then")


func _expect(type: String, id: Variant, context: String) -> void:
	var key: String = str(id)
	var known: Dictionary = _ids.get(type, {})
	if key.is_empty() or not (known.has(key) or known.has(StringName(key))):
		_report.error("%s: unbekannte %s-ID '%s'" % [context, type, key])
