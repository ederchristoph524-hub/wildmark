class_name ImmortalValidator
extends RefCounted
## Prüft die Daten des Unsterblichen-Reichs: Schritte der unsterblichen Gu und Killer Moves, Kerne und sterbliche
## Familien, unsterbliche Gu der Meister (Rang ≤ Meisterrang), Kalamitätswesen, Platzierungen, Regeln der
## Unsterblichen-Gebiete und unsterbliche Erbschafts-Belohnungen.

const RULES: Array[StringName] = [&"keine_gu", &"stroemung", &"seelenlast", &"seelensturm", &"traum", &"zeitfluss",
	&"leichte_schwere", &"sterbliche_sterben"]
const KINDS: Array[StringName] = [&"gesegnetes_land", &"grotto_himmel", &"dimension", &"himmel"]
const ROLES: Array[StringName] = [&"sanctum", &"wanderer", &"waechter"]

var _report: ImportReport
var _ids: Dictionary
var _steps: StepValidator


func _init(report: ImportReport, ids: Dictionary, steps: StepValidator) -> void:
	_report = report
	_ids = ids
	_steps = steps


func check(built: Dictionary) -> void:
	var immortal_ids: Dictionary = {}
	for data: ImmortalGuData in built["immortal_gu"]:
		immortal_ids[data.id] = data
		var context: String = "Unsterblicher Gu '%s'" % data.id
		if not data.steps.is_empty():
			_steps.check_steps(data.steps, context)
	for killer: ImmortalKillerData in built["immortal_killers"]:
		var context: String = "Unsterblichen-Killer-Move '%s'" % killer.id
		_steps.check_steps(killer.steps, context)
		var core: ImmortalGuData = immortal_ids.get(killer.core)
		if core == null or core.kind == ImmortalGuData.KIND_CONCEPT:
			_report.error("%s: Kern '%s' fehlt oder ist ein Konzept-Gu" % [context, killer.core])
		if killer.mortal_families.size() < 3:
			_report.error("%s: mindestens drei sterbliche Familien nötig" % context)
		for family: StringName in killer.mortal_families:
			_expect("families", family, context)
	for master: GuMasterData in built["gu_masters"]:
		for id: StringName in master.immortal_gu:
			var data: ImmortalGuData = immortal_ids.get(id)
			if data == null:
				_report.error("Gu-Meister '%s': unbekannter unsterblicher Gu '%s'" % [master.id, id])
			elif data.rank > master.rank:
				_report.error("Gu-Meister '%s': unsterblicher Gu '%s' (Rang %d) über seinem Rang %d" % [master.id, id, data.rank, master.rank])
	_check_system(built["immortal_system"], built)
	for area: AreaData in built["areas"]:
		_check_area(area, immortal_ids)


func _check_system(system: ImmortalSystemData, built: Dictionary) -> void:
	for rank: int in system.calamity_beasts:
		for id: StringName in system.calamity_beasts[rank]:
			_expect("enemies", id, "unsterblich.json kalamitaet_wesen[%d]" % rank)
	for entry: Dictionary in system.ranks:
		for calamity: StringName in entry["cycle"]:
			if not system.calamities.has(calamity):
				_report.error("unsterblich.json raenge[%d]: unbekannte Kalamität '%s'" % [entry["rank"], calamity])
	var master_ids: Dictionary = {}
	for master: GuMasterData in built["gu_masters"]:
		master_ids[master.id] = master
	var area_ids: Dictionary = {}
	for area: AreaData in built["areas"]:
		area_ids[area.id] = area
	for placement: Dictionary in system.placements:
		var context: String = "unsterblich.json platzierung '%s'" % placement["master"]
		if not master_ids.has(placement["master"]):
			_report.error("%s: unbekannter Meister" % context)
		var area: AreaData = area_ids.get(placement["area"])
		if area == null:
			_report.error("%s: unbekanntes Gebiet '%s'" % [context, placement["area"]])
		elif placement["settlement"] != &"" and area.settlement(placement["settlement"]).is_empty():
			_report.error("%s: Siedlung '%s' gibt es in '%s' nicht" % [context, placement["settlement"], area.id])
		if placement["role"] not in ROLES:
			_report.error("%s: unbekannte Rolle '%s'" % [context, placement["role"]])
	for biome: Variant in system.path_biomes.values():
		_expect("biomes", biome, "unsterblich.json pfad_biome")
	for item: Variant in (system.treasure.get("materialien", {}) as Dictionary):
		_expect("items", item, "unsterblich.json schatzhimmel.materialien")
	for item: Variant in (system.treasure.get("verkauf", {}) as Dictionary):
		_expect("items", item, "unsterblich.json schatzhimmel.verkauf")


func _check_area(area: AreaData, immortal_ids: Dictionary) -> void:
	var context: String = "Gebiet '%s'" % area.id
	if not area.immortal.is_empty():
		if area.immortal.get("kind", &"") not in KINDS:
			_report.error("%s: unbekannte Art der Unsterblichen-Ebene '%s'" % [context, area.immortal.get("kind")])
		for rule: StringName in area.immortal.get("rules", []):
			if rule not in RULES:
				_report.error("%s: unbekannte Weltregel '%s'" % [context, rule])
		var annex: Dictionary = area.immortal.get("annex", {})
		for item: StringName in annex.get("gift", {}):
			_expect("items", item, context + " (Annexion)")
	for place: Dictionary in area.places:
		var reward: Dictionary = place.get("reward", {})
		for id: StringName in reward.get("immortal", []):
			if not immortal_ids.has(id):
				_report.error("%s: Erbe '%s' vergibt unbekannten unsterblichen Gu '%s'" % [context, place.get("name", ""), id])


func _expect(type: String, id: Variant, context: String) -> void:
	var known: Dictionary = _ids.get(type, {})
	var key: String = str(id)
	if key.is_empty() or not (known.has(key) or known.has(StringName(key))):
		_report.error("%s: unbekannte %s-ID '%s'" % [context, type, key])
