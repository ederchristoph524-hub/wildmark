class_name ExpectedCounts
extends RefCounted
## Erwartete Anzahlen der importierten Daten, direkt aus den Quelldateien in docs/daten/ gezählt
## (so bleiben die Tests gültig, wenn Inhalte dazukommen). Schlüssel wie DataRegistry-Kategorien.

const SOURCE_DIR: String = "res://docs/daten/"


static func compute() -> Dictionary[StringName, int]:
	var gu: Dictionary = _read("gu_system")
	var mats: Dictionary = _read("materialien")
	var result: Dictionary[StringName, int] = {
		&"families": (gu["familien"] as Array).size(),
		&"body": (gu["koerper_gu"] as Array).size(),
		&"support": (gu["hilfs_gu"] as Array).size(),
		&"traits": (gu["merkmale"] as Array).size() if gu["merkmale"] is Array else (gu["merkmale"] as Dictionary).size(),
		&"statuses": (gu["zustaende"] as Dictionary).size(),
		&"reactions": (gu["reaktionen"] as Array).size(),
		&"killer_moves": (gu["killer_moves"] as Array).size(),
		&"enemies": (_read("gegner")["MON"] as Dictionary).size(),
		&"items": (mats["MATS"] as Dictionary).size() + (mats["BASIS_RES"] as Dictionary).size(),
		&"regions": (_read("welt")["REGIONS"] as Array).size(),
		&"sects": (_read("fraktionen")["SECTS"] as Array).size(),
		&"quests": (_read("quests")["QUESTS"] as Array).size(),
		&"standings": (_read("fraktionen")["STANDING"] as Dictionary).size(),
	}
	return result


## Alle Gu-Mitglieder der Familien.
static func members() -> int:
	var total: int = 0
	for family: Variant in _read("gu_system")["familien"]:
		total += ((family as Dictionary)["mitglieder"] as Array).size()
	return total


static func _read(file: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(SOURCE_DIR + file + ".json")
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
