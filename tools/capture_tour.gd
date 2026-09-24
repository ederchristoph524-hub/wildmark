class_name CaptureTour
extends SceneTree
## Rundgang durch das Gebiet mit freier Kamera (Übersicht, Dorf, Orte) für Grafik-Prüfungen, Bilder nach build/tour/.
## Aufruf: xvfb-run godot --path . --rendering-driver opengl3 --fixed-fps 60 --resolution 1280x720 --script res://tools/capture_tour.gd

const STEPS_PATH: String = "res://tools/capture_tour_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
