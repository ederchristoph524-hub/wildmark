class_name TestDataImport
extends SceneTree
## Prüft headless, dass die importierten Resources in data/ vollständig und ladbar sind und ihre Verweise auflösen.
## Aufruf: godot --headless --path . --script res://tests/test_data_import.gd

## Datenordner je DataRegistry-Kategorie; die Anzahlen kommen aus ExpectedCounts (Quelldateien).
const DIRS: Dictionary[String, StringName] = {
	"res://data/gu/families/": &"families",
	"res://data/gu/body/": &"body",
	"res://data/gu/support/": &"support",
	"res://data/gu/traits/": &"traits",
	"res://data/combat/statuses/": &"statuses",
	"res://data/combat/reactions/": &"reactions",
	"res://data/killer_moves/": &"killer_moves",
	"res://data/enemies/": &"enemies",
	"res://data/items/": &"items",
	"res://data/regions/": &"regions",
	"res://data/sects/": &"sects",
	"res://data/quests/": &"quests",
}

var _failures: PackedStringArray = []


func _init() -> void:
	var loaded: Dictionary = {}
	var expected: Dictionary[StringName, int] = ExpectedCounts.compute()
	for dir: String in DIRS:
		loaded[dir] = _load_dir(dir)
		var want: int = expected[DIRS[dir]]
		_check(loaded[dir].size() == want, "%s: %d statt %d" % [dir, loaded[dir].size(), want])
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
	_check(count == ExpectedCounts.members(), "%d Gu statt %d" % [count, ExpectedCounts.members()])


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
