class_name TestGameSmoke
extends SceneTree
## Durchspiel-Test headless: neues Spiel, Bewegung, Gu, Reaktionen, Killer Moves, Verfeinern, Urstein, Kultivierung, Hunger, Tod, Speichern.
## Aufruf: godot --headless --fixed-fps 60 --path . --script res://tests/test_game_smoke.gd

const STEPS_PATH: String = "res://tests/game_smoke_steps.gd"

## Muss gehalten werden, sonst endet die Coroutine mit dem Objekt.
var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
