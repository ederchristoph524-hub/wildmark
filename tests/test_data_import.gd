class_name TestDataImport
extends SceneTree
## Prüft headless, dass die importierten Resources in data/ vollständig und ladbar sind und ihre Verweise auflösen.
## Aufruf: godot --headless --path . --script res://tests/test_data_import.gd

const EXPECTED_COUNTS: Dictionary[String, int] = {
	"res://data/gu/families/": 12,
	"res://data/gu/body/": 4,
	"res://data/gu/support/": 7,
	"res://data/gu/traits/": 10,
	"res://data/combat/statuses/": 6,
	"res://data/combat/reactions/": 8,
	"res://data/killer_moves/": 8,
	"res://data/enemies/": 25,
	"res://data/items/": 41,
	"res://data/regions/": 8,
	"res://data/sects/": 15,
	"res://data/quests/": 18,
}
const EXPECTED_GU_MEMBERS: int = 36

var _failures: PackedStringArray = []


func _init() -> void:
	var loaded: Dictionary = {}
	for dir: String in EXPECTED_COUNTS:
		loaded[dir] = _load_dir(dir)
		_check(loaded[dir].size() == EXPECTED_COUNTS[dir], "%s: %d statt %d" % [dir, loaded[dir].size(), EXPECTED_COUNTS[dir]])
	_check_members(loaded["res://data/gu/families/"])
	_check_killer_moves(loaded["res://data/killer_moves/"], loaded["res://data/gu/families/"])
	_check_drops(loaded["res://data/enemies/"], loaded["res://data/items/"])
	var system: GuSystemData = load("res://data/gu/gu_system.tres")
	_check(system != null and system.start_families.size() == 4, "gu_system.tres fehlt oder unvollständig")
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_data_import: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	quit(0 if _failures.is_empty() else 1)


func _load_dir(dir: String) -> Dictionary:
	var result: Dictionary = {}
	for file_name: String in DirAccess.get_files_at(dir):
		if not file_name.ends_with(".tres"):
			continue
		var resource: Resource = load(dir + file_name)
		_check(resource != null, "%s%s lässt sich nicht laden" % [dir, file_name])
		if resource != null:
			result[str(resource.get("id"))] = resource
	return result


func _check_members(families: Dictionary) -> void:
	var count: int = 0
	for family: GuFamilyData in families.values():
		count += family.members.size()
		for member: GuData in family.members:
			_check(member.family == family.id, "Gu %s zeigt auf falsche Familie" % member.id)
	_check(count == EXPECTED_GU_MEMBERS, "%d Gu statt %d" % [count, EXPECTED_GU_MEMBERS])


func _check_killer_moves(moves: Dictionary, families: Dictionary) -> void:
	for move: KillerMoveData in moves.values():
		_check(families.has(String(move.family_a)) and families.has(String(move.family_b)), "Killer Move %s: Familie fehlt" % move.id)


func _check_drops(enemies: Dictionary, items: Dictionary) -> void:
	for enemy: EnemyData in enemies.values():
		for drop: DropEntry in enemy.drops:
			_check(items.has(String(drop.item)), "Gegner %s: Drop %s fehlt" % [enemy.id, drop.item])


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
