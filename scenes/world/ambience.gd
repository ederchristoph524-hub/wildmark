class_name Ambience
extends Node3D
## Leben in der Luft rund um die Kamera: nachts Glühwürmchen, tagsüber schwebende Pollen (im Sand Staub). Je ein
## CPUParticles3D (ein Draw Call), der der Kamera folgt; in Siedlungen weniger, auf Wasser keine.

const FOLLOW_HEIGHT: float = 1.5
const BOX: Vector3 = Vector3(16.0, 3.0, 16.0)
## Innen frei um die Kamera (m).
const NEAR_CLEAR: float = 3.5
const FIREFLY_COLOR: Color = Color(0.8, 1.0, 0.3)
const POLLEN_COLOR: Color = Color(1.0, 0.97, 0.85, 0.8)
const DUST_COLOR: Color = Color(0.95, 0.85, 0.65, 0.6)

var world: World = null
var _fireflies: CPUParticles3D = null
var _pollen: CPUParticles3D = null


func _init(owner_world: World) -> void:
	world = owner_world
	name = "Ambience"


func _ready() -> void:
	var desert: bool = world.area.biome == &"wueste"
	_fireflies = _particles(FIREFLY_COLOR, 0.22, 60, 7.0, 0.35, true)
	_pollen = _particles(DUST_COLOR if desert else POLLEN_COLOR, 0.08, 36, 9.0, 0.25, false)
	var night: bool = Formulas.is_night(Balance.values, GameState.time_of_day)
	_fireflies.emitting = night
	_pollen.emitting = not night
	EventBus.night_changed.connect(_on_night)


func _on_night(night: bool) -> void:
	_fireflies.emitting = night
	_pollen.emitting = not night
	# Sofort gefüllt (preprocess) statt erst nach einer Lebensdauer.
	(_fireflies if night else _pollen).restart()


func _particles(color: Color, size: float, amount: int, lifetime: float, speed: float, glow: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = color
	material.albedo_texture = _soft_dot()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 3.0
	mesh.material = material
	particles.mesh = mesh
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.local_coords = false
	# Ring um die Kamera: dicht vor dem Auge würden die Lichter zu großen, unscharfen Flecken.
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_axis = Vector3.UP
	particles.emission_ring_radius = BOX.x * 0.5
	particles.emission_ring_inner_radius = NEAR_CLEAR
	particles.emission_ring_height = BOX.y
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = speed * 0.3
	particles.initial_velocity_max = speed
	# Aufleuchten und Verlöschen (Glühwürmchen blinken, Pollen tauchen sanft auf).
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color(1, 1, 1, 1))
	fade.add_point(0.7, Color(1, 1, 1, 1))
	particles.color_ramp = fade
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Ohne eigene Hülle rechnet Godot mit einem Punkt am Knoten – der liegt an der Kamera und wird weggeschnitten.
	particles.custom_aabb = AABB(-BOX, BOX * 2.0)
	add_child(particles)
	return particles


## Runder, weich auslaufender Lichtpunkt statt eines harten Quadrats.
static func _soft_dot() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.35, Color(1, 1, 1, 0.8))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var at: Vector3 = camera.global_position
	global_position = Vector3(at.x, world.terrain.height_at(at.x, at.z) + FOLLOW_HEIGHT, at.z)
	visible = not world.terrain.in_water(at.x, at.z)
