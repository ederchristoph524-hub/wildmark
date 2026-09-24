class_name TestAreas
extends SceneTree
## Gebiets-Test headless: reist in jedes offene Gebiet und prüft Aufbau (Ankunft an Land, Siedlungen mit Bewohnern,
## Orte, Hindernisse, wilde Gu, Bestien je Zone) und die Bauzeit.
## Aufruf: godot --headless --fixed-fps 60 --path . --script res://tests/test_areas.gd

const STEPS_PATH: String = "res://tests/area_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
