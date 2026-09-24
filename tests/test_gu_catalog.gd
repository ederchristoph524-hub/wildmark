class_name TestGuCatalog
extends SceneTree
## Katalog-Test headless: Jeder Gu (alle Familien, alle Ränge), jeder Killer Move und jede Bestien-Fähigkeit wird im
## laufenden Spiel ausgelöst und muss sichtbar wirken (Schaden an Übungszielen oder Zustand am Spieler).
## Aufruf: godot --headless --fixed-fps 60 --path . --script res://tests/test_gu_catalog.gd

const STEPS_PATH: String = "res://tests/gu_catalog_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
