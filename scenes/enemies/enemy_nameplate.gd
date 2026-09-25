class_name EnemyNameplate
extends Label3D
## Namensschild über einer Bestie: Name, Lebensbalken und aktive Zustände.

const BAR_SEGMENTS: int = 8
const ENEMY_TINT: Color = Color(1.0, 0.95, 0.9)
const COMPANION_TINT: Color = Color(0.75, 0.65, 1.0)
const PIXEL_SIZE: float = 0.006
## Ab dieser Nähe wächst das Schild nicht weiter (sonst füllt es bei nahen Bestien den halben Bildschirm).
const FULL_SIZE_DISTANCE: float = 8.0


func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = 40
	pixel_size = PIXEL_SIZE
	outline_size = 10


func _process(_delta: float) -> void:
	visibility_range_end = PassiveGu.detection_range()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null:
		var distance: float = camera.global_position.distance_to(global_position)
		pixel_size = PIXEL_SIZE * clampf(distance / FULL_SIZE_DISTANCE, 0.25, 1.0)


func refresh(title: String, health: HealthComponent, status: StatusComponent, companion: bool) -> void:
	var filled: int = ceili(health.ratio() * BAR_SEGMENTS)
	var lines: String = title + "\n" + "■".repeat(filled) + "□".repeat(BAR_SEGMENTS - filled)
	var states: PackedStringArray = []
	for id: StringName in status.active_statuses():
		var stacks: int = status.stacks_of(id)
		states.append(tr(DataRegistry.status(id).display_name) + ("×%d" % stacks if stacks > 1 else ""))
	if status.is_frozen():
		states.append(tr("Eingefroren"))
	if not states.is_empty():
		lines += "\n" + " · ".join(states)
	text = lines
	modulate = COMPANION_TINT if companion else ENEMY_TINT
