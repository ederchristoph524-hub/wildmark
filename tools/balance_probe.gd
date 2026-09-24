class_name BalanceProbe
extends SceneTree
## Balancing-Messung headless: Spieler je Rang (Stufe 2, vier Gu seines Rangs) gegen typische Bestien dieses Rangs.
## Gibt Zeit bis zum Sieg und erlittenen Schaden pro Sekunde aus (Zeit bis zum eigenen Tod = Leben / Schaden pro s).
## Aufruf: godot --headless --fixed-fps 60 --path . --script res://tools/balance_probe.gd

const STEPS_PATH: String = "res://tools/balance_probe_steps.gd"

var _steps: RefCounted = null


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	await physics_frame
	_steps = (load(STEPS_PATH) as GDScript).new()
	_steps.call("run", self)
