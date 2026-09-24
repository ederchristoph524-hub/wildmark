class_name TestFormulas
extends SceneTree
## Prüft headless die Formeln aus docs/FORMELN.md mit den Standardwerten aus BalanceData.
## Aufruf: godot --headless --path . --script res://tests/test_formulas.gd

var _failures: PackedStringArray = []
var _b: BalanceData = BalanceData.new()


func _init() -> void:
	_test_essence()
	_test_gu_strength()
	_test_holding()
	_test_talent()
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_formulas: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	quit(0 if _failures.is_empty() else 1)


func _test_essence() -> void:
	_near(Formulas.essence_cap(_b, 1, 0, 100.0), 25.0, "Kapazität R1 apt100")
	_near(Formulas.essence_cap(_b, 2, 0, 100.0), 80.0, "Kapazität R2 apt100")
	_near(Formulas.essence_cap(_b, 1, 3, 50.0), 12.5 * 2.65, "Kapazität R1 Höchststufe apt50")
	# FORMELN: leere Apertur füllt sich bei durchschnittlichem Talent in rund 150 s … bei apt 50: 60,5 s
	_near(Formulas.essence_cap(_b, 1, 0, 50.0) / Formulas.essence_regen(_b, 12.5, 50.0), 60.5, "Füllzeit apt50")
	_near(Formulas.wall_need(_b, 10.0, 2), 26.0, "Wand Stufe 2")


func _test_gu_strength() -> void:
	_near(Formulas.gu_rank_pow(_b, 3), 2.1904, "Rangstärke R3")
	_near(Formulas.gu_fit(_b, 1, 1), 1.0, "Passung gleich")
	_near(Formulas.gu_fit(_b, 1, 3), 0.56, "Passung zwei darunter")
	_near(Formulas.gu_fit(_b, 1, 9), 0.25, "Passung Minimum")
	_near(Formulas.gu_fit(_b, 3, 1), 1.24, "Passung zwei darüber")
	_near(Formulas.gu_fit_cost(_b, 3, 1), 4.4, "Kosten zwei darüber")
	_near(Formulas.gu_fit_cost(_b, 1, 3), 1.0, "Kosten darunter")


func _test_holding() -> void:
	# Ein Rang-1-Gu verliert pro Spieltag hunger_per_day Sättigung.
	_near(Formulas.hunger_per_second(_b, 1) * _b.day_length, _b.hunger_per_day, "Hunger pro Tag R1")
	_check(Formulas.hunger_per_second(_b, 3) < Formulas.hunger_per_second(_b, 1), "höhere Ränge hungern langsamer")
	_check(Formulas.feed_amount(_b, 2, 1) == 1, "Futter R1 Menge 2 → 1")
	_check(Formulas.feed_amount(_b, 3, 3) == 3, "Futter R3 Menge 3 → 3")
	_check(Formulas.gu_capacity(_b, 1, 100.0) == 9, "Kapazität R1 apt100")
	_near(Formulas.refine_chance(_b, 1, 1, 50.0), 0.76, "Verfeinerung gleicher Rang apt50")
	_near(Formulas.refine_chance(_b, 3, 1, 50.0), 0.24, "Verfeinerung zwei darüber")
	_check(Formulas.refine_cost(_b, 1) == 12, "Verfeinerungskosten R1")
	_check(Formulas.is_night(_b, 0.9) and not Formulas.is_night(_b, 0.5), "Nacht am Tagesende")


func _test_talent() -> void:
	var d: Dictionary = Formulas.roll_talent(_b, 80.0, 0.0)
	_check(d["grade"] == &"D" and d["apt"] == 20.0, "Wurf 80 → D 20")
	var broken: Dictionary = Formulas.roll_talent(_b, 0.1, 0.5)
	_check(broken["grade"] == &"Durchbrochen" and broken["apt"] == 100.0, "Wurf 0,1 → Durchbrochen")
	var b_grade: Dictionary = Formulas.talent_for_grade(_b, &"B", 0.999)
	_check(b_grade["apt"] == 79.0, "B höchstens 79")


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.01, "%s: %f statt %f" % [label, actual, expected])


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
