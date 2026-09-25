class_name GuImportBuilder
extends RefCounted
## Baut aus gu_system.json (plus Lore-Texten aus gu.json) alle Gu-bezogenen Resources.

## Kennzeichnet Reaktions-Bedingungen mit Mindeststapeln, z. B. "gift_ab_3".
const STACK_CONDITION_SEPARATOR := "_ab_"
const SOURCE := "gu_system.json"

var _report: ImportReport
var _gudex: Dictionary
var _gu_json: Dictionary


## gu_json ist die geparste gu.json (Ideenpool): liefert Lore-Texte und die Pfad-Tabellen.
func _init(report: ImportReport, gu_json: Dictionary) -> void:
	_report = report
	_gu_json = gu_json
	_gudex = gu_json.get("GUDEX", {})


## Liefert {families, body, support, statuses, reactions, traits, killer_moves, gu_system}.
func build(src: Dictionary) -> Dictionary:
	return {
		"families": _build_list(src, "familien", _build_family),
		"body": _build_list(src, "koerper_gu", _build_body),
		"support": _build_list(src, "hilfs_gu", _build_support),
		"statuses": _build_list(_keyed_to_list(src, "zustaende"), "zustaende", _build_status),
		"reactions": _build_list(src, "reaktionen", _build_reaction),
		"traits": _build_list(src, "merkmale", _build_trait),
		"killer_moves": _build_list(src, "killer_moves", _build_killer_move),
		"gu_system": _build_system(src),
	}


func _build_list(src: Dictionary, key: String, builder: Callable) -> Array[Resource]:
	var result: Array[Resource] = []
	var raw: Variant = src.get(key)
	if not raw is Array:
		_report.error("%s: '%s' fehlt oder ist keine Liste" % [SOURCE, key])
		return result
	for entry: Variant in raw:
		if not entry is Dictionary:
			_report.error("%s: Eintrag in '%s' ist kein Objekt" % [SOURCE, key])
			continue
		var resource: Resource = builder.call(entry)
		if resource != null:
			result.append(resource)
	return result


## Wandelt ein nach ID geschlüsseltes Objekt in eine Liste mit Feld "id" um.
func _keyed_to_list(src: Dictionary, key: String) -> Dictionary:
	var raw: Variant = src.get(key)
	if not raw is Dictionary:
		return {}
	var entries: Array = []
	for id: Variant in raw:
		var entry: Dictionary = (raw[id] as Dictionary).duplicate()
		entry["id"] = id
		entries.append(entry)
	return {key: entries}


func _build_family(d: Dictionary) -> Resource:
	var context: String = "Familie '%s'" % d.get("id", "?")
	if not ImportUtil.require(d, ["id", "name", "pfad", "wirkform", "futter", "mitglieder"], context, _report):
		return null
	var family := GuFamilyData.new()
	family.id = ImportUtil.sn(d["id"])
	family.display_name = ImportUtil.text(d["name"])
	family.path = ImportUtil.sn(d["pfad"])
	family.role = ImportUtil.text(d.get("rolle"))
	family.form = ImportUtil.sn(d["wirkform"])
	family.tags = ImportUtil.names(d.get("tags"))
	family.status = ImportUtil.sn(d.get("status"))
	var feed: Dictionary = d["futter"] if d["futter"] is Dictionary else {}
	family.feed_item = ImportUtil.sn(feed.get("r"))
	family.feed_amount = ImportUtil.to_int(feed.get("n"))
	var base: Variant = d.get("basis_r1", {})
	if base is Dictionary:
		for key: Variant in base:
			family.base_r1[StringName(str(key))] = base[key]
	_fill_upgrades(family, d.get("aufstieg", {}), context)
	for entry: Variant in d["mitglieder"]:
		if entry is Dictionary:
			var member: GuData = _build_member(entry, family.id)
			if member != null:
				family.members.append(member)
	family.world_effect = ImportUtil.text(d.get("welt"))
	return family


## "r2" → Rang 2; Mengen als int.
func _fill_upgrades(family: GuFamilyData, raw: Variant, context: String) -> void:
	if not raw is Dictionary:
		return
	for key: Variant in raw:
		var rank_key: String = str(key)
		if not rank_key.begins_with("r") or not rank_key.substr(1).is_valid_int():
			_report.error("%s: unbekannter Aufstiegs-Schlüssel '%s'" % [context, rank_key])
			continue
		var materials: Dictionary = {}
		for item: Variant in raw[key]:
			materials[StringName(str(item))] = ImportUtil.to_int(raw[key][item])
		family.upgrade_materials[rank_key.substr(1).to_int()] = materials


func _build_member(d: Dictionary, family_id: StringName) -> GuData:
	var context: String = "Gu '%s' (Familie %s)" % [d.get("id", "?"), family_id]
	if not ImportUtil.require(d, ["id", "name", "rang"], context, _report):
		return null
	var gu := GuData.new()
	gu.id = ImportUtil.sn(d["id"])
	gu.resource_scene_unique_id = "gu_%s" % gu.id
	gu.display_name = ImportUtil.text(d["name"])
	gu.family = family_id
	gu.rank = ImportUtil.to_int(d["rang"], 1)
	gu.rank_gift = ImportUtil.text(d.get("ranggabe"))
	gu.description = ImportUtil.text(d.get("beschreibung"))
	gu.gifts = ImportUtil.plain_dict(d.get("gaben"))
	if not bool(d.get("neu", false)):
		gu.lore = _lore_for(gu.id, context)
	return gu


func _lore_for(id: StringName, context: String) -> String:
	if not _gudex.has(String(id)):
		_report.error("%s: neu=false, aber in gu.json (GUDEX) nicht vorhanden" % context)
		return ""
	var lore: String = ImportUtil.text((_gudex[String(id)] as Dictionary).get("lore"))
	if lore.is_empty():
		_report.warn("%s: kein Lore-Text in gu.json" % context)
	return lore


func _build_body(d: Dictionary) -> Resource:
	var context: String = "Körper-Gu '%s'" % d.get("id", "?")
	if not ImportUtil.require(d, ["id", "name", "rang", "wirkung"], context, _report):
		return null
	if not d["wirkung"] is Dictionary:
		_report.error("%s: 'wirkung' muss ein Objekt mit Werten sein" % context)
		return null
	var body := BodyGuData.new()
	body.id = ImportUtil.sn(d["id"])
	body.display_name = ImportUtil.text(d["name"])
	body.rank = ImportUtil.to_int(d["rang"], 1)
	for key: Variant in d["wirkung"]:
		body.effects[StringName(str(key))] = ImportUtil.to_float(d["wirkung"][key])
	return body


func _build_support(d: Dictionary) -> Resource:
	var context: String = "Hilfs-Gu '%s'" % d.get("id", "?")
	if not ImportUtil.require(d, ["id", "name", "rang", "pfad", "futter"], context, _report):
		return null
	var support := SupportGuData.new()
	support.id = ImportUtil.sn(d["id"])
	support.display_name = ImportUtil.text(d["name"])
	support.rank = ImportUtil.to_int(d["rang"], 1)
	support.path = ImportUtil.sn(d["pfad"])
	support.effect_text = ImportUtil.text(d.get("wirkung"))
	var feed: Dictionary = d["futter"] if d["futter"] is Dictionary else {}
	support.feed_item = ImportUtil.sn(feed.get("r"))
	support.feed_amount = ImportUtil.to_int(feed.get("n"))
	support.rules = ImportUtil.plain_dict(d.get("regeln"))
	return support


func _build_status(d: Dictionary) -> Resource:
	if not ImportUtil.require(d, ["id", "name"], "Zustand '%s'" % d.get("id", "?"), _report):
		return null
	var status := StatusData.new()
	status.id = ImportUtil.sn(d["id"])
	status.display_name = ImportUtil.text(d["name"])
	status.effect_text = ImportUtil.text(d.get("wirkung"))
	status.max_stacks = ImportUtil.to_int(d.get("stapel"), 1)
	status.removed_by = ImportUtil.names(d.get("endet_durch"))
	var rule: Dictionary = ImportUtil.plain_dict(d.get("regel"))
	status.duration = ImportUtil.to_float(rule.get("dauer"), status.duration)
	status.dps = ImportUtil.to_float(rule.get("dps"))
	status.speed_per_stack = ImportUtil.to_float(rule.get("tempo"))
	status.heal_mult = ImportUtil.to_float(rule.get("heilung"), 1.0)
	status.damage_taken_per_stack = ImportUtil.to_float(rule.get("schaden_erlitten"))
	status.on_max = ImportUtil.sn(rule.get("bei_max"))
	status.flee = bool(rule.get("flucht", false))
	return status


## "gift_ab_3" → Zustand gift, mindestens 3 Stapel; sonst Bedingung unverändert.
func _build_reaction(d: Dictionary) -> Resource:
	var context: String = "Reaktion '%s'" % d.get("id", "?")
	if not ImportUtil.require(d, ["id", "name", "ausloeser", "auf"], context, _report):
		return null
	var reaction := ReactionData.new()
	reaction.id = ImportUtil.sn(d["id"])
	reaction.display_name = ImportUtil.text(d["name"])
	reaction.trigger_tag = ImportUtil.sn(d["ausloeser"])
	var condition: String = ImportUtil.text(d["auf"])
	var parts: PackedStringArray = condition.split(STACK_CONDITION_SEPARATOR)
	if parts.size() == 2 and parts[1].is_valid_int():
		reaction.target_status = StringName(parts[0])
		reaction.min_stacks = parts[1].to_int()
	else:
		reaction.target_status = StringName(condition)
	reaction.effect_text = ImportUtil.text(d.get("wirkung"))
	reaction.removes = ImportUtil.names(d.get("endet"))
	reaction.rule = ImportUtil.plain_dict(d.get("regel"))
	return reaction


func _build_trait(d: Dictionary) -> Resource:
	if not ImportUtil.require(d, ["id", "name", "gewicht"], "Merkmal '%s'" % d.get("id", "?"), _report):
		return null
	var gu_trait := TraitData.new()
	gu_trait.id = ImportUtil.sn(d["id"])
	gu_trait.display_name = ImportUtil.text(d["name"])
	gu_trait.effect_text = ImportUtil.text(d.get("wirkung"))
	gu_trait.weight = ImportUtil.to_int(d["gewicht"], 1)
	return gu_trait


func _build_killer_move(d: Dictionary) -> Resource:
	var context: String = "Killer Move '%s'" % d.get("id", "?")
	if not ImportUtil.require(d, ["id", "name", "a", "b", "kanal_s", "mult"], context, _report):
		return null
	var move := KillerMoveData.new()
	move.id = ImportUtil.sn(d["id"])
	move.display_name = ImportUtil.text(d["name"])
	move.family_a = ImportUtil.sn(d["a"])
	move.family_b = ImportUtil.sn(d["b"])
	move.channel_time = ImportUtil.to_float(d["kanal_s"])
	move.damage_mult = ImportUtil.to_float(d["mult"], 1.0)
	move.description = ImportUtil.text(d.get("wirkung"))
	move.hint = ImportUtil.text(d.get("hinweis"))
	move.min_rank = ImportUtil.to_int(d.get("rang"), 1)
	move.steps = ImportUtil.plain_list(d.get("schritte"))
	return move


func _build_system(src: Dictionary) -> GuSystemData:
	var system := GuSystemData.new()
	var tags: Variant = src.get("tags", {})
	if tags is Dictionary:
		for key: Variant in tags:
			system.tags[StringName(str(key))] = ImportUtil.text(tags[key])
	else:
		_report.error("%s: 'tags' fehlt oder ist kein Objekt" % SOURCE)
	var chances: Variant = src.get("merkmal_chance", {})
	if chances is Dictionary:
		for key: Variant in chances:
			system.trait_chances[StringName(str(key))] = ImportUtil.to_float(chances[key])
	system.start_families = ImportUtil.names(src.get("start_familien"))
	_fill_paths(system)
	for entry: Variant in src.get("rezepte", []):
		var d: Dictionary = entry
		var materials: Dictionary = {}
		for item: Variant in d.get("material", {}):
			materials[StringName(str(item))] = ImportUtil.to_int(d["material"][item])
		system.recipes.append({"result": ImportUtil.sn(d.get("ergebnis")), "inputs": ImportUtil.names(d.get("aus", [])), "materials": materials,
			"chance": ImportUtil.to_float(d.get("chance"), 0.5), "hint": ImportUtil.text(d.get("hinweis"))})
	return system


func _fill_paths(system: GuSystemData) -> void:
	var names: Variant = _gu_json.get("PATHS", {})
	var colors: Variant = _gu_json.get("PATH_COLOR", {})
	var conflicts: Variant = _gu_json.get("PATH_CONFLICT", {})
	if not names is Dictionary or not colors is Dictionary or not conflicts is Dictionary:
		_report.error("gu.json: PATHS, PATH_COLOR oder PATH_CONFLICT fehlt")
		return
	for key: Variant in names:
		system.path_names[StringName(str(key))] = ImportUtil.text(names[key])
	for key: Variant in colors:
		system.path_colors[StringName(str(key))] = ImportUtil.color(colors[key], "Pfadfarbe " + str(key), _report)
	for key: Variant in conflicts:
		system.path_conflicts[StringName(str(key))] = ImportUtil.names(conflicts[key])
	var last: float = -1.0
	for entry: Variant in _gu_json.get("ATTAIN", []):
		var need: float = ImportUtil.to_float((entry as Dictionary).get("need"))
		if need <= last:
			_report.error("gu.json: ATTAIN-Schwellen müssen steigen ('%s')" % entry.get("n"))
		last = need
		system.attain_names.append(ImportUtil.text(entry.get("n")))
		system.attain_needs.append(need)
		system.attain_colors.append(ImportUtil.color(entry.get("c", "#ffffff"), "Beherrschung " + str(entry.get("n")), _report))
	if system.attain_names.is_empty():
		_report.error("gu.json: ATTAIN (Beherrschungsstufen) fehlt")
