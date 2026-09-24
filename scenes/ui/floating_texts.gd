class_name FloatingTexts
extends Control
## Schwebende Texte (Schaden, Reaktionen, Beute) an Weltpositionen, die aufsteigen und verblassen.

const LIFETIME: float = 1.1
const RISE: float = 1.2
const MAX_TEXTS: int = 40

var _entries: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.floating_text.connect(_on_text)


func _on_text(text: String, world_position: Vector3, color: Color) -> void:
	if _entries.size() >= MAX_TEXTS:
		(_entries.pop_front()["label"] as Label).queue_free()
	var label := UiTheme.label(text, 22, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_constant_override(&"outline_size", 6)
	label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	add_child(label)
	_entries.append({"label": label, "position": world_position + Vector3(randf_range(-0.3, 0.3), 0.0, 0.0), "age": 0.0})


func _process(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	for i: int in range(_entries.size() - 1, -1, -1):
		var entry: Dictionary = _entries[i]
		var label: Label = entry["label"]
		entry["age"] = float(entry["age"]) + delta
		var age: float = entry["age"]
		if age >= LIFETIME or camera == null:
			label.queue_free()
			_entries.remove_at(i)
			continue
		var point: Vector3 = (entry["position"] as Vector3) + Vector3.UP * RISE * age / LIFETIME
		label.visible = not camera.is_position_behind(point)
		label.position = camera.unproject_position(point) - label.size * 0.5
		label.modulate.a = 1.0 - clampf((age - LIFETIME * 0.6) / (LIFETIME * 0.4), 0.0, 1.0)
