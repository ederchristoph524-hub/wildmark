class_name CaptureGuGallery
extends SceneTree
## Wirkt jeden Gu (eine Familie pro Feld, Rang über --rank=N, Standard 3) auf Übungsziele und legt je zwei Momente
## nebeneinander auf Übersichtsbögen nach build/gallery/ (braucht eine Anzeige, z. B. xvfb-run). Zum Prüfen, ob sich
## die Wirkungen sichtbar unterscheiden.
## Aufruf: xvfb-run godot --path . --rendering-driver opengl3 --fixed-fps 60 --resolution 1280x720
##   --script res://tools/capture_gu_gallery.gd -- --rank=3 [--only=flamme,frost]

const STEPS_PATH: String = "res://tools/capture_gu_gallery_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
