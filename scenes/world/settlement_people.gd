class_name SettlementPeople
extends RefCounted
## Bewohner der Siedlungen: wer wo steht (Ankerpunkt aus Settlement), welche Aufgabe und welcher Tausch.
## Dazu Klan-Gu-Meister und Beerenbüsche (Kindheit) im Gu-Yue-Dorf.

## Je Bewohner-Gruppe: NPC-Art, Titel (leer = Name aus den Daten), Aufgabe, Tausch, Anker, Versatz (x, z).
const RESIDENTS: Dictionary[StringName, Array] = {
	&"gu_yue": [
		[&"klan", "Dorfältester", &"bau", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Klanwächter", &"j10", false, &"gate", Vector2(0.0, 0.0)],
		[&"klan", "Holzfäller", &"holz", false, &"back_gate", Vector2(0.0, 0.0)],
		[&"klan", "Späherin", &"ero", false, &"tower", Vector2(0.0, 0.0)],
		[&"klan", "Akademie-Lehrerin", &"", false, &"academy", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"daemon", "", &"", true, &"gate_outside", Vector2(0.0, 0.0)],
	],
	&"bai": [
		[&"klan", "Bai-Ältester", &"", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Bai-Wächter", &"", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"xiong": [
		[&"klan", "Xiong-Ältester", &"", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Xiong-Jäger", &"", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
}
## Klan-Gu-Meister: Daten-ID, Titel, Anker.
const MASTERS: Dictionary[StringName, Array] = {
	&"gu_yue": [&"gu_yue", "Klanlehrer", &"training"],
}
## Beerenbüsche im Garten (Versatz zum Anker garden) – für die Kindheit.
const BUSHES: Dictionary[StringName, Array] = {
	&"gu_yue": [Vector2(-2.5, -1.5), Vector2(1.5, -2.5), Vector2(0.5, 2.5)],
}
const BUSH_YIELD: int = 3


## Setzt Bewohner, Gu-Meister und Büsche an die Ankerpunkte der Siedlung.
static func place(world: World, data: Dictionary, anchors: Dictionary) -> void:
	var group: StringName = data["residents"]
	var robe: Color = (data["colors"] as Dictionary).get(&"banner", Color.WHITE)
	for entry: Array in RESIDENTS.get(group, []):
		var npc := Npc.new()
		npc.setup(DataRegistry.npc_type(entry[0]), String(entry[1]), entry[2], bool(entry[3]))
		if entry[0] == &"klan":
			npc.robe_color = robe
		world.add_child(npc)
		npc.position = _at(world, anchors, entry[4], entry[5])
	if MASTERS.has(group):
		var master_entry: Array = MASTERS[group]
		var master := GuMaster.new()
		master.setup(DataRegistry.gu_master(master_entry[0]), String(master_entry[1]), _at(world, anchors, master_entry[2], Vector2.ZERO))
		world.add_child(master)
	for offset: Vector2 in BUSHES.get(group, []):
		var bush := ResourceNode.new(&"beeren", BUSH_YIELD)
		world.add_child(bush)
		bush.position = _at(world, anchors, &"garden", offset)


static func _at(world: World, anchors: Dictionary, anchor: StringName, offset: Vector2) -> Vector3:
	var base: Vector3 = anchors.get(anchor, anchors.get(&"hall", Vector3.ZERO))
	return world.ground_point(base.x + offset.x, base.z + offset.y)
