class_name ImmortalImportBuilder
extends RefCounted
## Baut aus unsterbliche_gu.json die unsterblichen Gu und Unsterblichen-Killer-Moves, aus unsterblich.json das
## ImmortalSystemData (nur die kleingeschriebenen Abschnitte; die großgeschriebenen sind der Prototyp-Ideenpool).

var _report: ImportReport


func _init(report: ImportReport) -> void:
	_report = report


func build(sources: Dictionary) -> Dictionary:
	var gu_source: Dictionary = sources.get("unsterbliche_gu", {})
	var immortal_gu: Array = []
	for entry: Variant in gu_source.get("gu", []):
		var built: ImmortalGuData = _gu(entry)
		if built != null:
			immortal_gu.append(built)
	var killers: Array = []
	for entry: Variant in gu_source.get("killer_moves", []):
		var built: ImmortalKillerData = _killer(entry)
		if built != null:
			killers.append(built)
	return {"immortal_gu": immortal_gu, "immortal_killers": killers, "immortal_system": _system(sources.get("unsterblich", {}))}


func _gu(value: Variant) -> ImmortalGuData:
	if not value is Dictionary:
		_report.error("unsterbliche_gu.json: Gu-Eintrag ist kein Objekt")
		return null
	var d: Dictionary = value
	var context: String = "Unsterblicher Gu '%s'" % str(d.get("id", "?"))
	if not ImportUtil.require(d, ["id", "name", "rang", "pfad", "art"], context, _report):
		return null
	var data := ImmortalGuData.new()
	data.id = ImportUtil.sn(d["id"])
	data.display_name = ImportUtil.text(d["name"])
	data.name_en = ImportUtil.text(d.get("name_en"))
	data.rank = clampi(ImportUtil.to_int(d["rang"], 6), 6, 9)
	data.path = ImportUtil.sn(d["pfad"])
	data.category = ImportUtil.sn(d.get("kategorie"))
	data.kind = ImportUtil.sn(d["art"])
	data.description = ImportUtil.text(d.get("beschreibung"))
	data.lore = ImportUtil.text(d.get("lore"))
	data.owner = ImportUtil.text(d.get("besitzer"))
	data.beads = ImportUtil.to_float(d.get("perlen"), 1.0)
	data.cooldown = ImportUtil.to_float(d.get("cd"), 20.0)
	data.base_damage = ImportUtil.to_float(d.get("grundschaden"), 40.0)
	data.steps = ImportUtil.plain_list(d.get("schritte"))
	data.passive = ImportUtil.plain_dict(d.get("passiv"))
	data.world = ImportUtil.sn(d.get("welt"))
	if data.kind not in [ImmortalGuData.KIND_ACTIVE, ImmortalGuData.KIND_PASSIVE, ImmortalGuData.KIND_CONCEPT, ImmortalGuData.KIND_HOUSE]:
		_report.error("%s: unbekannte Art '%s'" % [context, data.kind])
	if data.kind == ImmortalGuData.KIND_ACTIVE and data.steps.is_empty():
		_report.error("%s: aktiver Gu ohne Schritte" % context)
	return data


func _killer(value: Variant) -> ImmortalKillerData:
	if not value is Dictionary:
		_report.error("unsterbliche_gu.json: Killer-Move-Eintrag ist kein Objekt")
		return null
	var d: Dictionary = value
	var context: String = "Unsterblichen-Killer-Move '%s'" % str(d.get("id", "?"))
	if not ImportUtil.require(d, ["id", "name", "kern", "sterbliche", "schritte"], context, _report):
		return null
	var data := ImmortalKillerData.new()
	data.id = ImportUtil.sn(d["id"])
	data.display_name = ImportUtil.text(d["name"])
	data.name_en = ImportUtil.text(d.get("name_en"))
	data.path = ImportUtil.sn(d.get("pfad"))
	data.core = ImportUtil.sn(d["kern"])
	data.mortal_families = ImportUtil.names(d["sterbliche"])
	data.beads = ImportUtil.to_float(d.get("perlen"), 3.0)
	data.cooldown = ImportUtil.to_float(d.get("cd"), 60.0)
	data.channel = ImportUtil.to_float(d.get("kanalisieren"), 1.0)
	data.base_damage = ImportUtil.to_float(d.get("grundschaden"), 50.0)
	data.steps = ImportUtil.plain_list(d["schritte"])
	data.description = ImportUtil.text(d.get("beschreibung"))
	data.lore = ImportUtil.text(d.get("lore"))
	data.owner = ImportUtil.text(d.get("besitzer"))
	return data


func _system(d: Dictionary) -> ImmortalSystemData:
	var system := ImmortalSystemData.new()
	for entry: Variant in d.get("raenge", []):
		var rank: Dictionary = entry
		var cycle: Array[StringName] = ImportUtil.names(rank.get("zyklus", []))
		var breakthrough: Dictionary = ImportUtil.plain_dict(rank.get("durchbruch"))
		system.ranks.append({"rank": ImportUtil.to_int(rank.get("rang"), 6), "essence": ImportUtil.text(rank.get("essenz")),
			"color": ImportUtil.color(rank.get("farbe"), "unsterblich.json raenge", _report), "days": ImportUtil.to_int(rank.get("kalamitaet_tage"), 3),
			"cycle": cycle, "per_stage": maxi(1, ImportUtil.to_int(rank.get("je_stufe"), 3)),
			"breakthrough": {"dao": ImportUtil.to_float(breakthrough.get("dao")), "stones": ImportUtil.to_int(breakthrough.get("steine")),
				"attain": ImportUtil.to_int(breakthrough.get("attain")), "text": ImportUtil.text(breakthrough.get("text"))}})
	var calamities: Dictionary = d.get("kalamitaeten", {})
	for key: Variant in calamities:
		var c: Dictionary = calamities[key]
		system.calamities[StringName(str(key))] = {"name": ImportUtil.text(c.get("n")), "color": ImportUtil.color(c.get("farbe"), "Kalamität " + str(key), _report),
			"warning": ImportUtil.text(c.get("warnung")), "waves": ImportUtil.to_int(c.get("wellen"), 3), "duration": ImportUtil.to_float(c.get("dauer"), 40.0),
			"quakes": bool(c.get("beben", false)), "bolts": ImportUtil.to_int(c.get("blitze")), "dao": ImportUtil.to_float(c.get("dao"))}
	var beasts: Dictionary = d.get("kalamitaet_wesen", {})
	for key: Variant in beasts:
		system.calamity_beasts[ImportUtil.to_int(key)] = ImportUtil.names(beasts[key])
	for entry: Variant in d.get("landgrade", []):
		var g: Dictionary = entry
		system.land_grades.append({"id": ImportUtil.sn(g.get("id")), "name": ImportUtil.text(g.get("n")), "color": ImportUtil.color(g.get("farbe"), "Landgrad", _report),
			"size": ImportUtil.to_float(g.get("groesse"), 300.0), "stones_per_day": ImportUtil.to_float(g.get("steine_pro_tag"), 3.0),
			"time_flow": ImportUtil.to_float(g.get("zeitfluss"), 5.0), "start_beads": ImportUtil.to_float(g.get("perlen_start"), 4.0), "yield": ImportUtil.to_float(g.get("ertrag"), 1.0)})
	system.ascension = ImportUtil.plain_dict(d.get("aufstieg"))
	for entry: Variant in d.get("eingebungen", []):
		var i: Dictionary = entry
		system.inspirations.append({"id": ImportUtil.sn(i.get("id")), "question": ImportUtil.text(i.get("frage")), "text": ImportUtil.text(i.get("wirkung")),
			"effect": ImportUtil.plain_dict(i.get("effekt"))})
	system.treasure = ImportUtil.plain_dict(d.get("schatzhimmel"))
	system.land_spirit = ImportUtil.plain_dict(d.get("landgeist"))
	system.path_biomes = ImportUtil.plain_dict(d.get("pfad_biome"))
	for entry: Variant in d.get("platzierung", []):
		var p: Dictionary = entry
		system.placements.append({"master": ImportUtil.sn(p.get("meister")), "area": ImportUtil.sn(p.get("gebiet")),
			"settlement": ImportUtil.sn(p.get("siedlung")), "role": ImportUtil.sn(p.get("rolle"))})
	if system.ranks.is_empty() or system.land_grades.is_empty():
		_report.error("unsterblich.json: raenge oder landgrade fehlen")
	return system
