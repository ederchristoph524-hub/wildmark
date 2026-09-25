class_name AreaImportBuilder
extends RefCounted
## Baut aus gebiete.json die Gebiete (AreaData) und Landschaften (BiomeData).

var _report: ImportReport


func _init(report: ImportReport) -> void:
	_report = report


func build_biome(id: StringName, d: Dictionary) -> Resource:
	var context: String = "Biom '%s'" % id
	if not ImportUtil.require(d, ["n", "farben", "vegetation"], context, _report):
		return null
	var biome := BiomeData.new()
	biome.id = id
	biome.display_name = ImportUtil.text(d["n"])
	for key: Variant in d["farben"]:
		biome.colors[StringName(str(key))] = ImportUtil.color(d["farben"][key], context, _report)
	for key: Variant in d["vegetation"]:
		biome.vegetation[StringName(str(key))] = ImportUtil.to_float(d["vegetation"][key])
	biome.trees_per_1000 = ImportUtil.to_float(d.get("baeume_pro_1000m2"), biome.trees_per_1000)
	biome.bushes_per_1000 = ImportUtil.to_float(d.get("buesche_pro_1000m2"), biome.bushes_per_1000)
	biome.grass_per_1000 = ImportUtil.to_float(d.get("gras_pro_1000m2"), biome.grass_per_1000)
	biome.rocks_per_1000 = ImportUtil.to_float(d.get("felsen_pro_1000m2"), biome.rocks_per_1000)
	for field: Array in [["himmel", "sky"], ["himmel_oben", "sky_top"], ["nebel", "fog"], ["wasser", "water"]]:
		if d.has(field[0]):
			biome.set(field[1], ImportUtil.color(d[field[0]], context, _report))
	biome.fog_density = ImportUtil.to_float(d.get("nebel_dichte"), biome.fog_density)
	if d.has("meeresspiegel"):
		biome.sea_level = ImportUtil.to_float(d["meeresspiegel"])
	if d.has("pflanzenfarbe"):
		biome.plant_tint = ImportUtil.color(d["pflanzenfarbe"], context, _report)
	return biome


func build_area(id: StringName, d: Dictionary) -> Resource:
	var context: String = "Gebiet '%s'" % id
	if not ImportUtil.require(d, ["n", "region", "karte", "rang"], context, _report):
		return null
	var area := AreaData.new()
	area.id = id
	area.display_name = ImportUtil.text(d["n"])
	area.region = ImportUtil.to_int(d["region"])
	area.map_position = _vec(d["karte"])
	area.rank_min = ImportUtil.to_int(d["rang"][0], 1)
	area.rank_max = ImportUtil.to_int(d["rang"][1], area.rank_min)
	area.open = bool(d.get("offen", false))
	area.description = ImportUtil.text(d.get("d"))
	if not area.open:
		return area
	if not ImportUtil.require(d, ["groesse", "seed", "biom", "relief", "ankunft"], context, _report):
		return null
	area.size = ImportUtil.to_float(d["groesse"])
	area.terrain_seed = ImportUtil.to_int(d["seed"])
	area.biome = ImportUtil.sn(d["biom"])
	for key: Variant in d["relief"]:
		area.relief[StringName(str(key))] = ImportUtil.to_float(d["relief"][key])
	area.arrival = _vec(d["ankunft"])
	for hill: Variant in d.get("erhebungen", []):
		area.hills.append(Vector4(ImportUtil.to_float(hill[0]), ImportUtil.to_float(hill[1]), ImportUtil.to_float(hill[2]), ImportUtil.to_float(hill[3])))
	for path: Variant in d.get("wege", []):
		var points: Array = []
		for point: Variant in path:
			points.append(_vec(point))
		area.paths.append(points)
	for entry: Variant in d.get("siedlungen", []):
		area.settlements.append(_settlement(entry, context))
	for entry: Variant in d.get("orte", []):
		area.places.append(_place(entry))
	for entry: Variant in d.get("hindernisse", []):
		area.obstacles.append({"id": ImportUtil.sn(entry["id"]), "kind": ImportUtil.sn(entry["art"]), "reward": ImportUtil.sn(entry["belohnung"]), "angle": ImportUtil.to_float(entry["richtung"]), "distance": ImportUtil.to_float(entry["abstand"])})
	_fill_contents(area, d)
	return area


func _fill_contents(area: AreaData, d: Dictionary) -> void:
	var resources: Dictionary = d.get("ressourcen", {})
	for item: Variant in resources:
		area.resources[StringName(str(item))] = Vector2i(ImportUtil.to_int(resources[item][0]), ImportUtil.to_int(resources[item][1]))
	var enemies: Dictionary = d.get("gegner", {})
	for radius: Variant in enemies.get("radien", []):
		area.enemy_radii.append(ImportUtil.to_float(radius))
	# Einträge einer Zone: Gefahrenzone (Zahl, Feld z in gegner.json) oder Bestien-ID (Text).
	for zone: Variant in enemies.get("zonen", []):
		var ids: Array = []
		for value: Variant in zone:
			if value is String:
				ids.append(StringName(value))
			else:
				ids.append(ImportUtil.to_int(value))
		area.enemy_zones.append(ids)
	var wild: Dictionary = d.get("wilde_gu", {})
	area.wild_gu_rank = ImportUtil.to_int(wild.get("rang"), 1)
	if wild.has("abstand"):
		area.wild_gu_range = _vec(wild["abstand"])
	var wanderer: Dictionary = d.get("wanderer", {})
	area.wanderers = ImportUtil.names(wanderer.get("meister", []))
	area.wanderer_count = ImportUtil.to_int(wanderer.get("anzahl"), 0)
	var feud: Dictionary = d.get("fehde", {})
	if not feud.is_empty():
		var spoils: Dictionary = {}
		for item: Variant in feud.get("belohnung", {}):
			spoils[StringName(str(item))] = ImportUtil.to_int(feud["belohnung"][item])
		area.feud = {"name": ImportUtil.text(feud.get("n", "Klanfehde")), "attacker": ImportUtil.sn(feud.get("angreifer")),
			"target": ImportUtil.sn(feud.get("ziel")), "masters": ImportUtil.names(feud.get("meister", [])),
			"count": ImportUtil.to_int(feud.get("anzahl"), 3), "every": ImportUtil.to_int(feud.get("alle_tage"), 5),
			"offset": ImportUtil.to_int(feud.get("versatz"), 2), "reward": spoils}
	var tide: Dictionary = d.get("flut", {})
	if not tide.is_empty():
		var reward: Dictionary = {}
		for item: Variant in tide.get("belohnung", {}):
			reward[StringName(str(item))] = ImportUtil.to_int(tide["belohnung"][item])
		area.tide = {"beasts": ImportUtil.names(tide.get("bestien", [])), "leader": ImportUtil.sn(tide.get("anfuehrer", "")),
			"count": ImportUtil.to_int(tide.get("anzahl"), 10), "every": ImportUtil.to_int(tide.get("alle_tage"), 4),
			"target": ImportUtil.sn(tide.get("ziel", "")), "reward": reward, "name": ImportUtil.text(tide.get("n", "Bestienflut"))}
	for entry: Variant in d.get("wilde_passive", []):
		area.wild_passives.append([ImportUtil.sn(entry[0]), ImportUtil.sn(entry[1]), ImportUtil.to_float(entry[2]), ImportUtil.to_float(entry[3]), bool(entry[4])])


func _settlement(entry: Dictionary, context: String) -> Dictionary:
	var colors: Dictionary = {}
	for key: Variant in entry.get("farben", {}):
		colors[StringName(str(key))] = ImportUtil.color(entry["farben"][key], context, _report)
	return {
		"id": ImportUtil.sn(entry.get("id")), "type": ImportUtil.sn(entry.get("typ")), "faction": ImportUtil.sn(entry.get("fraktion")),
		"position": _vec(entry.get("pos", [0, 0])), "radius": ImportUtil.to_float(entry.get("radius"), 40.0),
		"houses": ImportUtil.to_int(entry.get("haeuser"), 10), "colors": colors, "residents": ImportUtil.sn(entry.get("bewohner")),
		"pond": ImportUtil.to_float(entry.get("teich"), 0.0),
	}


func _place(entry: Dictionary) -> Dictionary:
	var place: Dictionary = {
		"type": ImportUtil.sn(entry.get("typ")), "id": ImportUtil.sn(entry.get("id", entry.get("typ"))), "name": ImportUtil.text(entry.get("n")),
		"position": _vec(entry.get("pos", [0, 0])), "radius": ImportUtil.to_float(entry.get("radius"), 8.0),
		"item": ImportUtil.sn(entry.get("item")), "count": ImportUtil.to_int(entry.get("anzahl")), "text": ImportUtil.text(entry.get("text")),
		"owner": ImportUtil.sn(entry.get("besitzer")), "amount": ImportUtil.to_int(entry.get("ertrag"), 1), "path": ImportUtil.sn(entry.get("pfad")),
	}
	var offering: Dictionary = {}
	for item: Variant in entry.get("opfer", {}):
		offering[StringName(str(item))] = ImportUtil.to_int(entry["opfer"][item])
	place["offering"] = offering
	place["guards"] = ImportUtil.names(entry.get("waechter", []))
	place["style"] = ImportUtil.sn(entry.get("stil", "hoehle"))
	place["accent"] = ImportUtil.color(entry.get("akzent", "#d9b359"), "gebiete.json: Ort " + String(place["id"]), _report)
	var reward: Dictionary = entry.get("belohnung", {})
	var items: Dictionary = {}
	for item: Variant in reward.get("items", {}):
		items[StringName(str(item))] = ImportUtil.to_int(reward["items"][item])
	place["reward"] = {"support": ImportUtil.names(reward.get("hilfs_gu", [])), "gu": ImportUtil.names(reward.get("gu", [])), "body": ImportUtil.names(reward.get("koerper_gu", [])), "items": items}
	return place


func _vec(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(ImportUtil.to_float(value[0]), ImportUtil.to_float(value[1]))
	_report.error("gebiete.json: Koordinate erwartet, gefunden: %s" % str(value))
	return Vector2.ZERO
