class_name AreaValidator
extends RefCounted
## Prüft die Gebiete aus gebiete.json: Region, Biom, Siedlungs-Fraktionen, Orte, Gegner-Zonen, Funde und Belohnungen.

const PLACE_TYPES: Array[StringName] = [&"geisterquelle", &"see", &"aschefeld", &"frostquelle", &"friedhof", &"erbe"]
const OBSTACLE_KINDS: Array[StringName] = [&"hecke", &"wasser", &"fels", &"schalter", &"lichtsiegel", &"blutsiegel", &"vorsprung"]
const SETTLEMENT_TYPES: Array[StringName] = [&"klan_dorf"]

var _report: ImportReport
var _ids: Dictionary = {}


func _init(report: ImportReport, ids: Dictionary) -> void:
	_report = report
	_ids = ids


func check(areas: Array, regions: Array) -> void:
	var region_ids: Array[int] = []
	for region: RegionData in regions:
		region_ids.append(region.id)
	var any_open: bool = false
	for area: AreaData in areas:
		var context: String = "Gebiet '%s'" % area.id
		if area.region not in region_ids:
			_report.error("%s: unbekannte Region %d" % [context, area.region])
		if area.rank_min < 1 or area.rank_max < area.rank_min:
			_report.error("%s: ungültige Rangspanne %d–%d" % [context, area.rank_min, area.rank_max])
		any_open = any_open or area.open
		if area.open:
			_check_open(area, context)
	if not any_open:
		_report.error("gebiete.json: kein Gebiet ist bereisbar")


func _check_open(area: AreaData, context: String) -> void:
	_require(area.biome, "biomes", context + " Biom")
	var half: float = area.size * 0.5
	for settlement: Dictionary in area.settlements:
		_require(settlement["faction"], "sects", context + " Siedlung '%s' Fraktion" % settlement["id"])
		if settlement["type"] not in SETTLEMENT_TYPES:
			_report.error("%s: Siedlungstyp '%s' unbekannt" % [context, settlement["type"]])
		_inside(settlement["position"], half, context + " Siedlung '%s'" % settlement["id"])
	for place: Dictionary in area.places:
		if place["type"] not in PLACE_TYPES:
			_report.error("%s: Ortstyp '%s' unbekannt" % [context, place["type"]])
		_inside(place["position"], half, context + " Ort '%s'" % place["name"])
		if place["item"] != &"":
			_require(place["item"], "items", context + " Ort '%s' Gegenstand" % place["name"])
		_check_place_reward(place, context)
	for obstacle: Dictionary in area.obstacles:
		if obstacle["kind"] not in OBSTACLE_KINDS:
			_report.error("%s: Hindernisart '%s' unbekannt" % [context, obstacle["kind"]])
		_require(obstacle["reward"], "gu", context + " Hindernis '%s'" % obstacle["id"])
	for item: StringName in area.resources:
		_require(item, "items", context + " Ressource")
	for zone: Variant in area.enemy_zones:
		if (zone as Array).is_empty():
			_report.error("%s: leere Gegnerzone" % context)
		for entry: Variant in zone:
			if entry is StringName:
				_require(entry, "enemies", context + " Gegnerzone")
	if area.enemy_zones.size() != area.enemy_radii.size() + 1:
		_report.error("%s: %d Zonen brauchen %d Radien" % [context, area.enemy_zones.size(), area.enemy_zones.size() - 1])
	for entry: Variant in area.wild_passives:
		_require(entry[0], "body" if entry[1] == &"body" else "support", context + " wilder passiver Gu")


func _check_place_reward(place: Dictionary, context: String) -> void:
	var where: String = context + " Ort '%s'" % place["name"]
	for item: StringName in place["offering"]:
		_require(item, "items", where + " Opfergabe")
	for enemy: StringName in place["guards"]:
		_require(enemy, "enemies", where + " Wächter")
	var reward: Dictionary = place["reward"]
	for id: StringName in reward["support"]:
		_require(id, "support", where + " Hilfs-Gu")
	for id: StringName in reward["body"]:
		_require(id, "body", where + " Körper-Gu")
	for id: StringName in reward["gu"]:
		_require(id, "gu", where + " Gu")
	for item: StringName in reward["items"]:
		_require(item, "items", where + " Belohnung")


func _require(id: StringName, type: String, context: String) -> void:
	if not (_ids.get(type, {}) as Dictionary).has(String(id)):
		_report.error("%s: '%s' unbekannt" % [context, id])


func _inside(position: Vector2, half: float, context: String) -> void:
	if absf(position.x) > half or absf(position.y) > half:
		_report.error("%s liegt außerhalb des Gebiets" % context)
