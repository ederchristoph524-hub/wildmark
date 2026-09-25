class_name CaptureImmortal
extends SceneTree
## Bildschirmfotos des Unsterblichen-Reichs nach build/immortal/ (Startmenü frei, HUD, Gu-Menü-Seiten, Apertur, Kalamität) (braucht eine Anzeige, z. B. xvfb-run).
## Aufruf: xvfb-run godot --path . --rendering-driver opengl3 --fixed-fps 60 --script res://tools/capture_immortal.gd

const STEPS_PATH: String = "res://tools/capture_immortal_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
