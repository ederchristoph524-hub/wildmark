class_name MaterialSourceValidator
extends RefCounted
## Prüft beim Datenimport, dass jedes Aufstiegsmaterial der Gu-Familien im Spiel auch zu finden ist – und zwar
## spätestens in Gebieten des Rangs, auf den der Aufstieg führt (ein Rang-2-Spieler erkundet Rang-3-Gebiete am Rand).
## Quellen: Ressourcen und Orte der Gebiete, Beute der dort erscheinenden Bestien, Angebote der Händler der Siedlungen.
## Fehlt eine Quelle ganz, ist das ein Fehler; kommt sie erst später, eine Warnung.

var _report: ImportReport
## Item → frühester Gebietsrang, in dem es zu finden ist.
var _earliest: Dictionary[StringName, int] = {}


func _init(report: ImportReport) -> void:
	_report = report


func check(families: Array, areas: Array, enemies: Array, npcs: Array) -> void:
	var enemy_by_id: Dictionary[StringName, EnemyData] = {}
	for resource: Resource in enemies:
		var enemy: EnemyData = resource as EnemyData
		enemy_by_id[enemy.id] = enemy
	var npc_by_id: Dictionary[StringName, NpcTypeData] = {}
	for resource: Resource in npcs:
		var npc: NpcTypeData = resource as NpcTypeData
		npc_by_id[npc.id] = npc
	for resource: Resource in areas:
		var area: AreaData = resource as AreaData
		if area.open:
			_collect_area(area, enemy_by_id, npc_by_id)
	for resource: Resource in families:
		var family: GuFamilyData = resource as GuFamilyData
		for rank: int in family.upgrade_materials:
			for item: StringName in family.upgrade_materials[rank]:
				var context: String = "Familie '%s': Aufstiegsmaterial '%s' (Aufstieg auf Rang %d)" % [family.id, item, rank]
				if not _earliest.has(item):
					_report.error(context + " ist nirgends zu finden (Ressource, Ort, Beute oder Händler fehlt)")
				elif _earliest[item] > rank:
					_report.warn(context + " gibt es erst in Gebieten ab Rang %d" % _earliest[item])


func _collect_area(area: AreaData, enemy_by_id: Dictionary[StringName, EnemyData], npc_by_id: Dictionary[StringName, NpcTypeData]) -> void:
	var rank: int = area.rank_min
	for item: StringName in area.resources:
		_note(item, rank)
	for place: Dictionary in area.places:
		if place.get("item", &"") != &"":
			_note(place["item"], rank)
		var reward: Dictionary = place.get("reward", {})
		for item: StringName in reward.get("items", {}):
			_note(item, rank)
	for zone: Variant in area.enemy_zones:
		for enemy: EnemyData in enemy_by_id.values():
			if _in_zone(enemy, zone):
				for drop: DropEntry in enemy.drops:
					_note(drop.item, rank)
	for settlement: Dictionary in area.settlements:
		for entry: Array in SettlementRoster.RESIDENTS.get(settlement.get("residents", &""), []):
			var npc: NpcTypeData = npc_by_id.get(entry[0])
			if npc != null:
				for item: StringName in npc.trade_get:
					_note(item, rank)


## Zonen nennen Bestien-IDs oder Gefahrenstufen (Zahl = EnemyData.zone).
func _in_zone(enemy: EnemyData, zone: Variant) -> bool:
	if zone is Array:
		for entry: Variant in zone:
			if (entry is String or entry is StringName) and StringName(entry) == enemy.id:
				return true
			if (entry is int or entry is float) and int(entry) == enemy.zone:
				return true
		return false
	return (zone is int or zone is float) and int(zone) == enemy.zone


func _note(item: StringName, rank: int) -> void:
	_earliest[item] = mini(_earliest.get(item, 99), rank)
