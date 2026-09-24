class_name PlayerCamera
extends Node3D
## Third-Person-Kamera: Maus bzw. Wischen dreht, Federarm verhindert das Durchdringen von Gelände, optional folgt sie dem fixierten Ziel.

const MOUSE_SENSITIVITY: float = 0.0035
const TOUCH_SENSITIVITY: float = 0.006
const PITCH_MIN: float = -1.1
const PITCH_MAX: float = 0.45
const ARM_LENGTH: float = 5.5
const HEIGHT: float = 1.6
const LOCK_TURN_SPEED: float = 6.0

var yaw: float = 0.0
var pitch: float = -0.35
var camera: Camera3D = null
var _arm: SpringArm3D = null


func _ready() -> void:
	top_level = true
	_arm = SpringArm3D.new()
	_arm.spring_length = ARM_LENGTH
	_arm.collision_mask = 1
	_arm.margin = 0.3
	add_child(_arm)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.far = 220.0
	_arm.add_child(camera)
	camera.current = true
	EventBus.camera_look.connect(func(delta: Vector2) -> void: rotate_by(delta * TOUCH_SENSITIVITY))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_by((event as InputEventMouseMotion).relative * MOUSE_SENSITIVITY)


func rotate_by(amount: Vector2) -> void:
	yaw -= amount.x
	pitch = clampf(pitch - amount.y, PITCH_MIN, PITCH_MAX)


## Folgt dem Spieler; bei fixiertem Ziel dreht sie sich zu ihm.
func follow(target_position: Vector3, locked_target: Node3D, delta: float) -> void:
	global_position = target_position + Vector3.UP * HEIGHT
	if locked_target != null:
		var to_target: Vector3 = locked_target.global_position - target_position
		var wanted: float = atan2(-to_target.x, -to_target.z)
		yaw = lerp_angle(yaw, wanted, clampf(delta * LOCK_TURN_SPEED, 0.0, 1.0))
	rotation = Vector3(pitch, yaw, 0.0)


## Blickrichtung am Boden (für Bewegung und Zielen).
func flat_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func flat_right() -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))
