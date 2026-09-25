class_name PacingProbe
extends SceneTree
## Tempo-Messung headless, rein rechnerisch mit den Formeln und Balance-Werten des Spiels: Wie viele Minuten reines
## Meditieren braucht jeder Talentgrad je Rang (Stufen, Auffüllen für den Durchbruch, erwartete Fehlversuche)?
## Aufruf: godot --headless --path . --script res://tools/pacing_probe.gd

const STEPS_PATH: String = "res://tools/pacing_probe_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
