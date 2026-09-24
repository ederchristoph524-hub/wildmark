class_name TestDataRegistry
extends SceneTree
## Prüft headless, dass DataRegistry alle Daten lädt und per ID richtig liefert.
## Aufruf: godot --headless --path . --script res://tests/test_data_registry.gd

const REGISTRY_SCRIPT: String = "res://autoload/data_registry.gd"

var _failures: PackedStringArray = []


func _init() -> void:
	var registry: Node = (load(REGISTRY_SCRIPT) as GDScript).new()
	registry.call("load_all")
	_check_counts(registry)
	_check_lookups(registry)
	registry.free()
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_data_registry: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	quit(0 if _failures.is_empty() else 1)


func _check_counts(registry: Node) -> void:
	var expected: Dictionary[StringName, int] = {
		&"families": 12, &"body": 4, &"support": 7, &"traits": 10, &"statuses": 6, &"reactions": 8,
		&"killer_moves": 8, &"enemies": 25, &"items": 41, &"regions": 8, &"sects": 17, &"quests": 18,
	}
	for category: StringName in expected:
		var actual: int = registry.call("count", category)
		_check(actual == expected[category], "%s: %d statt %d" % [category, actual, expected[category]])
	var all_gu: Array[GuData] = registry.call("all_gu")
	_check(all_gu.size() == 36, "all_gu: %d statt 36" % all_gu.size())


func _check_lookups(registry: Node) -> void:
	var moonlight: GuData = registry.call("gu", &"mondlicht")
	_check(moonlight != null and moonlight.rank == 1 and moonlight.family == &"mondlicht", "gu(mondlicht) falsch")
	var flame: GuFamilyData = registry.call("family_of", &"feuerlotus")
	_check(flame != null and flame.id == &"flamme", "family_of(feuerlotus) sollte flamme sein")
	var storm: KillerMoveData = registry.call("killer_move", &"feuersturm")
	_check(storm != null and storm.family_a == &"flamme" and storm.family_b == &"wirbel", "killer_move(feuersturm) falsch")
	var center: RegionData = registry.call("region", 4)
	_check(center != null and center.display_name == "Zentralkontinent", "region(4) falsch")
	var explosion: ReactionData = registry.call("reaction", &"giftexplosion")
	_check(explosion != null and explosion.target_status == &"gift" and explosion.min_stacks == 3, "reaction(giftexplosion) falsch")
	var system: GuSystemData = registry.call("gu_system")
	_check(system != null and system.start_families.has(&"mondlicht"), "gu_system() falsch")
	_check(registry.call("has_gu", &"rosaeber") == false, "Körper-Gu dürfen nicht unter gu() stehen")
	var boar: BodyGuData = registry.call("body_gu", &"rosaeber")
	_check(boar != null and boar.effects.get(&"grundschaden", 0.0) == 4.0, "body_gu(rosaeber) falsch")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
