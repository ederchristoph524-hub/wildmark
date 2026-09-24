class_name TestChildhood
extends SceneTree
## Durchspiel-Test der spielbaren Kindheit: Gespräch, Sammeln, Erwachen mit Talenttest und erstem Gu.
## Aufruf: godot --headless --fixed-fps 60 --path . --script res://tests/test_childhood.gd

const STEPS_PATH: String = "res://tests/childhood_steps.gd"

## Muss gehalten werden, sonst endet die Coroutine mit dem Objekt.
var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
