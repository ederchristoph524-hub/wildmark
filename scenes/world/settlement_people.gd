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
		[&"klan", "Xiong-Jäger", &"dk_woelfe", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"shang": [
		[&"klan", "Shang-Verwalter", &"shang_jade", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Stadtwache", &"", false, &"gate", Vector2(0.0, 0.0)],
		[&"shang_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"shang_schmied", "", &"", true, &"market", Vector2(-4.0, 2.0)],
		[&"auktionator", "", &"", true, &"well", Vector2(2.0, 2.0)],
		[&"daemon", "", &"", true, &"gate_outside", Vector2(0.0, 0.0)],
	],
	&"steppe": [
		[&"stamm", "Häuptling", &"steppe_fell", false, &"hall", Vector2(0.0, 0.0)],
		[&"stamm", "", &"", true, &"gate", Vector2(0.0, 0.0)],
		[&"steppen_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"lang_ya": [
		[&"klan", "Lang-Ya-Hüter", &"reise_welt", false, &"hall", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"wueste": [
		[&"klan", "Tempelhüter", &"oase_rose", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Oasenwache", &"", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"wuesten_haendler", "", &"", true, &"market", Vector2(-3.0, 3.0)],
	],
	&"karawane": [
		[&"daemon", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"wuesten_haendler", "", &"", true, &"gate", Vector2(0.0, 0.0)],
	],
	&"wu": [
		[&"klan", "Festungswache", &"wu_schuppe", false, &"gate", Vector2(0.0, 0.0)],
		[&"wu_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"auktionator_hoch", "", &"", true, &"market", Vector2(-4.0, 2.0)],
	],
	&"insel": [
		[&"seemann", "", &"", true, &"gate", Vector2(0.0, 0.0)],
		[&"perlentaucher", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"klan", "Inselältester", &"insel_perle", false, &"hall", Vector2(0.0, 0.0)],
	],
	&"meereszombie": [
		[&"daemon", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"sekte": [
		[&"klan", "Torwächter", &"sekte_herz", false, &"gate", Vector2(0.0, 0.0)],
		[&"klan", "Bibliothekar", &"", false, &"academy", Vector2(0.0, 0.0)],
		[&"sekten_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"sekten_schatzmeister", "", &"", true, &"hall", Vector2(-3.0, 1.0)],
	],
}
## Gu-Meister je Bewohner-Gruppe: [Daten-ID, Titel, Anker] (Rang aus gegner.json → GUMASTER).
const MASTERS: Dictionary[StringName, Array] = {
	&"gu_yue": [[&"gu_yue", "Klanlehrer", &"training"]],
	&"xiong": [[&"xiong_jaeger", "Xiong-Jagdmeister", &"gate"]],
	&"bai": [[&"bai_waechter", "Bai-Klanwächter", &"gate"]],
	&"shang": [[&"shang_arena", "Arenameister", &"arena"], [&"blutfluegel", "Fremder Dämon", &"gate_outside"]],
	&"steppe": [[&"wilde_horde", "Hordenkrieger", &"training"]],
	&"lang_ya": [[&"yi_tian", "Lang-Ya-Gelehrter", &"training"]],
	&"wueste": [[&"wuestentempel", "Tempelwächter", &"training"]],
	&"karawane": [[&"karawane", "Karawanenführer", &"hall"]],
	&"wu": [[&"wu_general", "Wu-General", &"training"], [&"wu_aeltester", "Wu-Ältester", &"hall"]],
	&"insel": [[&"ostmeer", "Inselwächter", &"training"]],
	&"meereszombie": [[&"meereszombie", "Untoter Seefahrer", &"training"]],
	&"sekte": [[&"zehn_extreme", "Sektenmeister", &"training"], [&"himmelshof", "Gast des Himmlischen Hofes", &"tower"]],
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
	for master_entry: Array in MASTERS.get(group, []):
		var master := GuMaster.new()
		master.setup(DataRegistry.gu_master(master_entry[0]), String(master_entry[1]), _at(world, anchors, master_entry[2], Vector2(2.0, 0.0)))
		world.add_child(master)
	for offset: Vector2 in BUSHES.get(group, []):
		var bush := ResourceNode.new(&"beeren", BUSH_YIELD)
		world.add_child(bush)
		bush.position = _at(world, anchors, &"garden", offset)


static func _at(world: World, anchors: Dictionary, anchor: StringName, offset: Vector2) -> Vector3:
	var base: Vector3 = anchors.get(anchor, anchors.get(&"hall", Vector3.ZERO))
	return world.ground_point(base.x + offset.x, base.z + offset.y)
