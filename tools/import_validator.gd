class_name ImportValidator
extends RefCounted
## Prüft alle Verweise zwischen den gebauten Resources, bevor etwas geschrieben wird.

var _report: ImportReport
var _ids: Dictionary = {}  # Typ → Dictionary der IDs (als Set)
var _paths: Dictionary = {}
var _gudex: Dictionary = {}
var _factions: Dictionary = {}
var _org_types: Dictionary = {}


func _init(report: ImportReport) -> void:
	_report = report


func validate(built: Dictionary, sources: Dictionary) -> void:
	_paths = (sources["gu"] as Dictionary).get("PATHS", {})
	_gudex = (sources["gu"] as Dictionary).get("GUDEX", {})
	_factions = (sources["fraktionen"] as Dictionary).get("FACTIONS", {})
	_org_types = (sources["fraktionen"] as Dictionary).get("ORGTYPE", {})
	for type: String in built:
		if built[type] is Array:
			_ids[type] = _collect_ids(built[type], type)
	_ids["tags"] = (built["gu_system"] as GuSystemData).tags
	_ids["gu"] = _collect_gu_ids(built)
	_check_families(built["families"])
	_check_support(built["support"])
	_check_statuses(built["statuses"])
	_check_reactions(built["reactions"])
	_check_killer_moves(built["killer_moves"])
	_check_gu_system(built["gu_system"], built["traits"])
	_check_enemies(built["enemies"])
	_check_items(built["items"])
	_check_sects(built["sects"])
	_check_trades(built["npcs"], built["builds"])
	_check_masters(built["gu_masters"], built["body"])
	_check_areas(built["areas"], built["regions"])


func _collect_ids(resources: Array, type: String) -> Dictionary:
	var seen: Dictionary = {}
	for resource: Resource in resources:
		var id: String = str(resource.get("id"))
		if id.is_empty():
			_report.error("%s: Eintrag ohne ID" % type)
		elif seen.has(id):
			_report.error("%s: ID '%s' doppelt" % [type, id])
		seen[id] = resource
	return seen


## Mitglieder, Körper- und Hilfs-Gu teilen sich einen ID-Raum (DataRegistry.gu).
func _collect_gu_ids(built: Dictionary) -> Dictionary:
	var seen: Dictionary = {}
	var all: Array[Resource] = []
	for family: GuFamilyData in built["families"]:
		all.append_array(family.members)
	all.append_array(built["body"])
	all.append_array(built["support"])
	for gu: Resource in all:
		var id: String = str(gu.get("id"))
		if seen.has(id):
			_report.error("Gu-ID '%s' kommt mehrfach vor (Mitglieder, Körper- und Hilfs-Gu)" % id)
		seen[id] = gu
	return seen


func _expect(type: String, id: Variant, context: String, allow_empty: bool = false) -> void:
	var key: String = str(id)
	if key.is_empty():
		if not allow_empty:
			_report.error("%s: Verweis auf %s ist leer" % [context, type])
		return
	var known: Dictionary = _ids.get(type, {})
	if not known.has(key) and not known.has(StringName(key)):
		_report.error("%s: unbekannte %s-ID '%s'" % [context, type, key])


func _expect_path(path: StringName, context: String) -> bool:
	if _paths.has(String(path)):
		return true
	_report.error("%s: unbekannter Pfad '%s'" % [context, path])
	return false


func _check_families(families: Array) -> void:
	for family: GuFamilyData in families:
		var context: String = "Familie '%s'" % family.id
		_expect_path(family.path, context)
		if family.form.is_empty():
			_report.error("%s: Wirkform fehlt" % context)
		for tag: StringName in family.tags:
			_expect("tags", tag, context)
		_expect("statuses", family.status, context, true)
		_expect("items", family.feed_item, context + " (Futter)")
		if family.feed_amount <= 0:
			_report.error("%s: Futtermenge muss > 0 sein" % context)
		for rank: int in family.upgrade_materials:
			for item: Variant in family.upgrade_materials[rank]:
				_expect("items", item, "%s (Aufstieg Rang %d)" % [context, rank])
		_check_members(family, context)


func _check_members(family: GuFamilyData, context: String) -> void:
	if family.members.is_empty():
		_report.error("%s: keine Mitglieder" % context)
	var ranks: Dictionary = {}
	for member: GuData in family.members:
		if ranks.has(member.rank):
			_report.error("%s: Rang %d doppelt belegt" % [context, member.rank])
		ranks[member.rank] = true


func _check_support(list: Array) -> void:
	for support: SupportGuData in list:
		var context: String = "Hilfs-Gu '%s'" % support.id
		_expect_path(support.path, context)
		_expect("items", support.feed_item, context + " (Futter)")


func _check_statuses(list: Array) -> void:
	for status: StatusData in list:
		for other: StringName in status.removed_by:
			_expect("statuses", other, "Zustand '%s' (endet durch)" % status.id)


func _check_reactions(list: Array) -> void:
	for reaction: ReactionData in list:
		var context: String = "Reaktion '%s'" % reaction.id
		_expect("tags", reaction.trigger_tag, context + " (Auslöser)")
		if reaction.target_status not in ReactionData.DERIVED_CONDITIONS:
			_expect("statuses", reaction.target_status, context + " (Bedingung)")
			var status: StatusData = (_ids["statuses"] as Dictionary).get(String(reaction.target_status))
			if status != null and reaction.min_stacks > status.max_stacks:
				_report.error("%s: braucht %d Stapel, %s hat nur %d" % [context, reaction.min_stacks, status.id, status.max_stacks])
		for removed: StringName in reaction.removes:
			_expect("statuses", removed, context + " (beendet)")


func _check_killer_moves(list: Array) -> void:
	var pairs: Dictionary = {}
	for move: KillerMoveData in list:
		var context: String = "Killer Move '%s'" % move.id
		_expect("families", move.family_a, context)
		_expect("families", move.family_b, context)
		if move.family_a == move.family_b:
			_report.error("%s: braucht zwei verschiedene Familien" % context)
		var pair: Array[String] = [String(move.family_a), String(move.family_b)]
		pair.sort()
		var key: String = "+".join(pair)
		if pairs.has(key):
			_report.error("%s: Familienpaar %s schon durch '%s' belegt" % [context, key, pairs[key]])
		pairs[key] = move.id


func _check_gu_system(system: GuSystemData, traits: Array) -> void:
	for family: StringName in system.start_families:
		_expect("families", family, "Start-Familien")
	for gu_trait: TraitData in traits:
		if gu_trait.weight <= 0:
			_report.error("Merkmal '%s': Gewicht muss > 0 sein" % gu_trait.id)


func _check_enemies(list: Array) -> void:
	for enemy: EnemyData in list:
		var context: String = "Gegner '%s'" % enemy.id
		for drop: DropEntry in enemy.drops:
			_expect("items", drop.item, context + " (Drop)")
			if drop.chance < 0.0 or drop.chance > 1.0:
				_report.error("%s: Drop-Chance für '%s' außerhalb 0–1" % [context, drop.item])
		_expect("enemies", enemy.minion, context + " (Beschwörung)", true)


## Material-Pfade sind kein Spielverweis, daher nur Warnung.
func _check_items(list: Array) -> void:
	for item: ItemData in list:
		if not item.path.is_empty() and not _paths.has(String(item.path)):
			_report.warn("Item '%s': Pfad '%s' fehlt in gu.json → PATHS" % [item.id, item.path])


func _check_sects(list: Array) -> void:
	for sect: SectData in list:
		var context: String = "Sekte '%s'" % sect.id
		if not _factions.has(String(sect.faction)):
			_report.error("%s: unbekannte Fraktion '%s'" % [context, sect.faction])
		if not _org_types.has(String(sect.org_type)):
			_report.error("%s: unbekannte Organisationsform '%s'" % [context, sect.org_type])
		_expect("regions", sect.region, context + " (Region)")
		for rival: StringName in sect.rivals:
			_expect("sects", rival, context + " (Rivale)")
		for item: StringName in sect.join_gift:
			_expect("items", item, context + " (Beitrittsgeschenk)")
		_check_signature_gu(sect, context)


func _check_trades(npcs: Array, parts: Array) -> void:
	for npc: NpcTypeData in npcs:
		for item: StringName in npc.trade_give.keys() + npc.trade_get.keys():
			_expect("items", item, "NPC '%s' (Tausch)" % npc.id)
	for part: BuildData in parts:
		for item: StringName in part.cost:
			_expect("items", item, "Bauteil '%s' (Kosten)" % part.id)


## Gebiete: Region muss existieren, Rangspanne 1–5, mindestens ein Gebiet bereisbar.
func _check_areas(areas: Array, regions: Array) -> void:
	var region_ids: Array[int] = []
	for region: RegionData in regions:
		region_ids.append(region.id)
	var any_open: bool = false
	for area: AreaData in areas:
		if area.region not in region_ids:
			_report.error("Gebiet '%s': unbekannte Region %d" % [area.id, area.region])
		if area.rank_min < 1 or area.rank_max < area.rank_min:
			_report.error("Gebiet '%s': ungültige Rangspanne %d–%d" % [area.id, area.rank_min, area.rank_max])
		any_open = any_open or area.open
	if not any_open:
		_report.error("gebiete.json: kein Gebiet ist bereisbar")


## Gu der Meister: im Gu-System (Familie oder Körper-Gu) in Ordnung, nur im Ideenpool Warnung, sonst Fehler.
func _check_masters(masters: Array, body: Array) -> void:
	var body_ids: Array[String] = []
	for data: BodyGuData in body:
		body_ids.append(String(data.id))
	for master: GuMasterData in masters:
		for id: StringName in master.gu:
			var key: String = String(id)
			if (_ids["gu"] as Dictionary).has(key) or key in body_ids:
				continue
			if _gudex.has(key):
				_report.warn("Gu-Meister '%s': Gu '%s' gibt es nur im Ideenpool (gu.json)" % [master.id, key])
			else:
				_report.error("Gu-Meister '%s': unbekannter Gu '%s'" % [master.id, key])


## Signatur-Gu außerhalb von gu_system.json kommen erst in späteren Meilensteinen.
func _check_signature_gu(sect: SectData, context: String) -> void:
	var id: String = String(sect.signature_gu)
	if id.is_empty() or (_ids["gu"] as Dictionary).has(id):
		return
	if _gudex.has(id):
		_report.warn("%s: Signatur-Gu '%s' gibt es nur im Ideenpool (gu.json)" % [context, id])
	else:
		_report.error("%s: unbekannter Signatur-Gu '%s'" % [context, id])
