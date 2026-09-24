class_name WorldImportBuilder
extends RefCounted
## Baut Gegner, Items, Regionen, Sekten und Quests aus den übrigen JSON-Dateien in docs/daten/.

const CATEGORY_BASIS := &"basis"
const CATEGORY_MATERIAL := &"material"

var _report: ImportReport
var _sources: Dictionary = {}


func _init(report: ImportReport) -> void:
	_report = report


## Erwartet die geparsten Dateien nach Namen ohne Endung; liefert {enemies, items, regions, sects, quests}.
func build(sources: Dictionary) -> Dictionary:
	_sources = sources
	var items: Array[Resource] = _build_keyed(sources, "materialien", "BASIS_RES", _build_basis_item)
	items.append_array(_build_keyed(sources, "materialien", "MATS", _build_material))
	return {
		"enemies": _build_keyed(sources, "gegner", "MON", _build_enemy),
		"items": items,
		"regions": _build_listed(sources, "welt", "REGIONS", _build_region),
		"sects": _build_listed(sources, "fraktionen", "SECTS", _build_sect),
		"quests": _build_listed(sources, "quests", "QUESTS", _build_quest),
		"npcs": _build_keyed(sources, "gegner", "NPCTYPE", _build_npc),
		"builds": _build_keyed(sources, "materialien", "BUILD", _build_part),
		"gu_masters": _build_keyed(sources, "gegner", "GUMASTER", _build_master),
		"areas": _build_keyed(sources, "gebiete", "GEBIETE", AreaImportBuilder.new(_report).build_area),
		"biomes": _build_keyed(sources, "gebiete", "BIOME", AreaImportBuilder.new(_report).build_biome),
	}


func _section(sources: Dictionary, file: String, key: String) -> Variant:
	var data: Dictionary = sources.get(file, {})
	if not data.has(key):
		_report.error("%s.json: Abschnitt '%s' fehlt" % [file, key])
		return null
	return data[key]


## Abschnitte, die nach ID geschlüsselt sind: builder(id, eintrag).
func _build_keyed(sources: Dictionary, file: String, key: String, builder: Callable) -> Array[Resource]:
	var result: Array[Resource] = []
	var raw: Variant = _section(sources, file, key)
	if not raw is Dictionary:
		if raw != null:
			_report.error("%s.json: '%s' ist kein Objekt" % [file, key])
		return result
	for id: Variant in raw:
		if not raw[id] is Dictionary:
			_report.error("%s.json: '%s.%s' ist kein Objekt" % [file, key, id])
			continue
		var resource: Resource = builder.call(StringName(str(id)), raw[id])
		if resource != null:
			result.append(resource)
	return result


## Abschnitte, die Listen mit Feld "id" sind: builder(eintrag).
func _build_listed(sources: Dictionary, file: String, key: String, builder: Callable) -> Array[Resource]:
	var result: Array[Resource] = []
	var raw: Variant = _section(sources, file, key)
	if not raw is Array:
		if raw != null:
			_report.error("%s.json: '%s' ist keine Liste" % [file, key])
		return result
	for entry: Variant in raw:
		if not entry is Dictionary or not (entry as Dictionary).has("id"):
			_report.error("%s.json: Eintrag in '%s' ohne 'id'" % [file, key])
			continue
		var resource: Resource = builder.call(entry)
		if resource != null:
			result.append(resource)
	return result


func _build_enemy(id: StringName, d: Dictionary) -> Resource:
	var context: String = "Gegner '%s'" % id
	if not ImportUtil.require(d, ["n", "hp", "dmg", "spd"], context, _report):
		return null
	var enemy := EnemyData.new()
	enemy.id = id
	enemy.display_name = ImportUtil.text(d["n"])
	enemy.max_hp = ImportUtil.to_int(d["hp"], 1)
	enemy.damage = ImportUtil.to_int(d["dmg"])
	enemy.speed = ImportUtil.to_float(d["spd"], 1.0)
	enemy.xp = ImportUtil.to_int(d.get("xp"))
	enemy.radius = ImportUtil.to_float(d.get("r"), enemy.radius)
	enemy.color = ImportUtil.color(d.get("c"), context, _report)
	enemy.zone = ImportUtil.to_int(d.get("z"))
	enemy.rank = ImportUtil.to_int(d.get("rang"), clampi(enemy.zone, 1, 5))
	enemy.ability = ImportUtil.plain_list(d.get("faehigkeit"))
	enemy.ability_range = ImportUtil.to_float(d.get("f_reichweite"), enemy.ability_range)
	enemy.ability_cooldown = ImportUtil.to_float(d.get("f_cd"), enemy.ability_cooldown)
	_fill_drops(enemy, d.get("drop", []), context)
	enemy.shape = ImportUtil.sn(d.get("shape"))
	enemy.behavior = ImportUtil.sn(d.get("beh"))
	enemy.attack_range = ImportUtil.to_float(d.get("rng"))
	enemy.minion = ImportUtil.sn(d.get("minion"))
	enemy.poison = ImportUtil.flag(d, "poison")
	enemy.burn = ImportUtil.flag(d, "burn")
	enemy.flying = ImportUtil.flag(d, "fly")
	enemy.night_only = ImportUtil.flag(d, "night")
	enemy.armored = ImportUtil.flag(d, "armor")
	enemy.boss = ImportUtil.flag(d, "boss")
	enemy.no_spawn = ImportUtil.flag(d, "nospawn")
	return enemy


## Drops kommen als Liste [Material-ID, Chance]; gleiche IDs mehrfach = mehrere Würfe.
func _fill_drops(enemy: EnemyData, raw: Variant, context: String) -> void:
	if not raw is Array:
		_report.error("%s: 'drop' ist keine Liste" % context)
		return
	for pair: Variant in raw:
		if not pair is Array or (pair as Array).size() != 2:
			_report.error("%s: Drop-Eintrag muss [Material, Chance] sein" % context)
			continue
		var entry := DropEntry.new()
		entry.item = ImportUtil.sn(pair[0])
		entry.chance = ImportUtil.to_float(pair[1])
		entry.resource_scene_unique_id = "drop_%d" % enemy.drops.size()
		enemy.drops.append(entry)


func _build_basis_item(id: StringName, d: Dictionary) -> Resource:
	var item: ItemData = _build_item(id, d)
	item.category = CATEGORY_BASIS
	return item


func _build_material(id: StringName, d: Dictionary) -> Resource:
	var item: ItemData = _build_item(id, d)
	item.category = CATEGORY_MATERIAL
	item.rank = ImportUtil.to_int(d.get("rank"))
	item.path = ImportUtil.sn(d.get("path"))
	item.immortal = ImportUtil.flag(d, "imm")
	item.source = ImportUtil.text(d.get("src"))
	return item


func _build_item(id: StringName, d: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = ImportUtil.text(d.get("n"))
	if item.display_name.is_empty():
		_report.error("Item '%s': Pflichtfeld 'n' fehlt" % id)
	item.icon = ImportUtil.text(d.get("ic"))
	item.description = ImportUtil.text(d.get("d"))
	return item


func _build_region(d: Dictionary) -> Resource:
	var context: String = "Region '%s'" % d.get("id")
	if not ImportUtil.require(d, ["id", "n"], context, _report):
		return null
	var region := RegionData.new()
	region.id = ImportUtil.to_int(d["id"])
	region.display_name = ImportUtil.text(d["n"])
	region.color = ImportUtil.color(d.get("c"), context, _report)
	region.description = ImportUtil.text(d.get("d"))
	var map: Dictionary = (_sources.get("welt", {}) as Dictionary).get("KARTE", {}).get(str(region.id), {})
	for point: Variant in map.get("poly", []):
		region.map_polygon.append(Vector2(ImportUtil.to_float(point[0]), ImportUtil.to_float(point[1])))
	region.wall_name = ImportUtil.text(map.get("mauer"))
	region.wall_color = ImportUtil.color(map.get("mauer_c", "#ffffff"), context, _report)
	return region



func _build_sect(d: Dictionary) -> Resource:
	var context: String = "Sekte '%s'" % d.get("id")
	if not ImportUtil.require(d, ["id", "n", "f", "type", "reg"], context, _report):
		return null
	var sect := SectData.new()
	sect.id = ImportUtil.sn(d["id"])
	sect.display_name = ImportUtil.text(d["n"])
	sect.icon = ImportUtil.text(d.get("ic"))
	sect.faction = ImportUtil.sn(d["f"])
	sect.org_type = ImportUtil.sn(d["type"])
	sect.region = ImportUtil.to_int(d["reg"])
	sect.immortals = ImportUtil.to_int(d.get("imm"))
	sect.power = ImportUtil.to_int(d.get("power"))
	sect.rivals = ImportUtil.names(d.get("rivals"))
	sect.min_rank = ImportUtil.to_int(d.get("req"))
	var gift: Variant = d.get("gift", {})
	if gift is Dictionary:
		for item: Variant in gift:
			sect.join_gift[StringName(str(item))] = ImportUtil.to_int(gift[item])
	sect.signature_gu = ImportUtil.sn(d.get("gu"))
	sect.politics = ImportUtil.text(d.get("pol"))
	sect.description = ImportUtil.text(d.get("d"))
	return sect


func _build_npc(id: StringName, d: Dictionary) -> Resource:
	var context: String = "NPC '%s'" % id
	if not ImportUtil.require(d, ["n"], context, _report):
		return null
	var npc := NpcTypeData.new()
	npc.id = id
	npc.display_name = ImportUtil.text(d["n"])
	npc.color = ImportUtil.color(d.get("c"), context, _report)
	npc.region = ImportUtil.to_int(d.get("region"))
	npc.side = ImportUtil.sn(d.get("side"))
	for line: Variant in d.get("lines", []):
		npc.lines.append(ImportUtil.text(line))
	var trade: Dictionary = d.get("trade", {})
	for item: Variant in trade.get("give", {}):
		npc.trade_give[StringName(str(item))] = ImportUtil.to_int(trade["give"][item])
	for item: Variant in trade.get("get", {}):
		npc.trade_get[StringName(str(item))] = ImportUtil.to_int(trade["get"][item])
	npc.trade_gu = ImportUtil.to_int(trade.get("gu"))
	npc.trade_gu_rank = ImportUtil.to_int(trade.get("gu_rang"), 1)
	npc.trade_text = ImportUtil.text(trade.get("d"))
	return npc


func _build_master(id: StringName, d: Dictionary) -> Resource:
	var context: String = "Gu-Meister '%s'" % id
	if not ImportUtil.require(d, ["n", "gu"], context, _report):
		return null
	var master := GuMasterData.new()
	master.id = id
	master.display_name = ImportUtil.text(d["n"])
	master.color = ImportUtil.color(d.get("c"), context, _report)
	master.faction = ImportUtil.sn(d.get("f"))
	master.gu = ImportUtil.names(d["gu"])
	master.rank = ImportUtil.to_int(d.get("rang"), 0)
	master.stage = ImportUtil.to_int(d.get("stufe"), -1)
	return master


func _build_part(id: StringName, d: Dictionary) -> Resource:
	if not ImportUtil.require(d, ["n"], "Bauteil '%s'" % id, _report):
		return null
	var part := BuildData.new()
	part.id = id
	part.display_name = ImportUtil.text(d["n"])
	for item: Variant in d.get("cost", {}):
		part.cost[StringName(str(item))] = ImportUtil.to_int(d["cost"][item])
	part.description = ImportUtil.text(d.get("d"))
	part.light = ImportUtil.to_float(d.get("light"))
	part.min_rank = ImportUtil.to_int(d.get("rank"))
	return part


func _build_quest(d: Dictionary) -> Resource:
	if not ImportUtil.require(d, ["id", "n"], "Quest '%s'" % d.get("id"), _report):
		return null
	var quest := QuestData.new()
	quest.id = ImportUtil.sn(d["id"])
	quest.display_name = ImportUtil.text(d["n"])
	quest.description = ImportUtil.text(d.get("d"))
	quest.reward_points = ImportUtil.to_int(d.get("sp"))
	var rule: Dictionary = d.get("regel", {})
	if not rule.is_empty():
		var reward: Dictionary = {}
		for item: Variant in rule.get("reward", {}):
			reward[StringName(str(item))] = ImportUtil.to_int(rule["reward"][item])
		quest.rule = {"type": ImportUtil.sn(rule.get("type")), "item": ImportUtil.sn(rule.get("item")), "count": ImportUtil.to_int(rule.get("count"), 1),
			"area": ImportUtil.text(rule.get("area")), "reward": reward}
	return quest
