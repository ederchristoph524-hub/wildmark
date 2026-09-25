class_name SettlementPeople
extends RefCounted
## Bewohner der Siedlungen: wer wo steht (Ankerpunkt aus Settlement), welche Aufgabe und welcher Tausch – die Listen
## stehen in SettlementRoster. Dazu Klan-Gu-Meister und Beerenbüsche (Kindheit) im Gu-Yue-Dorf.

## Beerenbüsche im Garten (Versatz zum Anker garden) – für die Kindheit.
const BUSHES: Dictionary[StringName, Array] = {
	&"gu_yue": [Vector2(-2.5, -1.5), Vector2(1.5, -2.5), Vector2(0.5, 2.5)],
}
const BUSH_YIELD: int = 3
## Spaziergänger je Siedlung: ein Bewohner je VILLAGER_SPACING m Radius, begrenzt.
const VILLAGER_TYPE: StringName = &"bewohner"
const VILLAGER_SPACING: float = 9.0
const VILLAGERS_MIN: int = 2
const VILLAGERS_MAX: int = 7
const VILLAGER_ANCHORS: Array[StringName] = [&"market", &"well", &"hall", &"gate", &"garden", &"fire", &"training"]
const VILLAGER_TITLES: Array[String] = ["Bauer", "Bäuerin", "Wäscherin", "Holzträger", "Alter Mann", "Alte Frau", "Junger Schüler", "Jägerin", "Wasserträger", "Händlerlehrling"]


## Setzt Bewohner, Gu-Meister und Büsche an die Ankerpunkte der Siedlung.
static func place(world: World, data: Dictionary, anchors: Dictionary) -> void:
	var group: StringName = data["residents"]
	var robe: Color = (data["colors"] as Dictionary).get(&"banner", Color.WHITE)
	for entry: Array in SettlementRoster.RESIDENTS.get(group, []):
		var npc := Npc.new()
		npc.setup(DataRegistry.npc_type(entry[0]), String(entry[1]), entry[2], bool(entry[3]))
		# Wer in der Halle steht, vertritt die Sekte (Beitritt, Rang, Spenden).
		npc.sect_id = data.get("faction", &"")
		npc.leader = entry[4] == &"hall"
		if entry[0] == &"klan":
			npc.robe_color = robe
		world.add_child(npc)
		npc.position = _at(world, anchors, entry[4], entry[5])
	_place_villagers(world, data, anchors, robe)
	for master_entry: Array in SettlementRoster.MASTERS.get(group, []):
		var master := GuMaster.new()
		master.setup(DataRegistry.gu_master(master_entry[0]), String(master_entry[1]), _at(world, anchors, master_entry[2], Vector2(2.0, 0.0)))
		world.add_child(master)
	for offset: Vector2 in BUSHES.get(group, []):
		var bush := ResourceNode.new(&"beeren", BUSH_YIELD)
		world.add_child(bush)
		bush.position = _at(world, anchors, &"garden", offset)


## Spaziergänger zwischen Markt, Brunnen, Halle, Tor und Garten; ihre Zahl wächst mit der Siedlung.
static func _place_villagers(world: World, data: Dictionary, anchors: Dictionary, robe: Color) -> void:
	var points: Array[Vector3] = []
	for key: StringName in VILLAGER_ANCHORS:
		if anchors.has(key):
			points.append(world.ground_point((anchors[key] as Vector3).x, (anchors[key] as Vector3).z))
	if points.size() < 2:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = String(data["id"]).hash()
	var count: int = clampi(roundi(float(data["radius"]) / VILLAGER_SPACING), VILLAGERS_MIN, VILLAGERS_MAX)
	var type: NpcTypeData = DataRegistry.npc_type(VILLAGER_TYPE)
	for i: int in count:
		var npc := Npc.new()
		npc.setup(type, VILLAGER_TITLES[rng.randi() % VILLAGER_TITLES.size()], &"", false)
		npc.robe_color = robe.lerp(Color(0.6, 0.55, 0.45), rng.randf_range(0.3, 0.8))
		npc.wander_points = points
		world.add_child(npc)
		npc.position = points[rng.randi() % points.size()] + Vector3(rng.randf_range(-2.0, 2.0), 0.0, rng.randf_range(-2.0, 2.0))


static func _at(world: World, anchors: Dictionary, anchor: StringName, offset: Vector2) -> Vector3:
	var base: Vector3 = anchors.get(anchor, anchors.get(&"hall", Vector3.ZERO))
	return world.ground_point(base.x + offset.x, base.z + offset.y)
