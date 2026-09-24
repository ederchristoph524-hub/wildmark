class_name CultivationAura
extends Node3D
## Aura beim Kultivieren: Lichtsäule und Bodenring in Rangfarbe, Uressenz-Funken strömen von außen in die Apertur,
## dazu ein pulsierendes Licht. Beim Durchbruch schwillt sie an und entlädt sich.

const AURA_SHADER: Shader = preload("res://assets/shaders/aura.gdshader")
const FADE_SPEED: float = 2.2
const COLUMN_RADIUS: float = 0.95
const COLUMN_HEIGHT: float = 2.8
const RING_RADIUS: float = 1.5
const LIGHT_ENERGY: float = 1.6
const SPARK_COUNT: int = 42

var color: Color = Color(0.5, 0.9, 0.5)
## 0 = aus, 1 = Kultivieren, bis 2 = Durchbruch.
var target_strength: float = 0.0
var _strength: float = 0.0
var _time: float = 0.0
var _column: MeshInstance3D = null
var _ring: MeshInstance3D = null
var _column_material: ShaderMaterial = null
var _sparks: CPUParticles3D = null
var _light: OmniLight3D = null
var _ring_material: StandardMaterial3D = null


func _ready() -> void:
	name = "CultivationAura"
	_column_material = ShaderMaterial.new()
	_column_material.shader = AURA_SHADER
	_column = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = COLUMN_RADIUS * 0.7
	cylinder.bottom_radius = COLUMN_RADIUS
	cylinder.height = COLUMN_HEIGHT
	cylinder.radial_segments = 20
	cylinder.rings = 1
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	_column.mesh = cylinder
	_column.position.y = COLUMN_HEIGHT * 0.5
	_column.material_override = _column_material
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_column)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RING_RADIUS * 0.9
	torus.outer_radius = RING_RADIUS
	torus.rings = 32
	torus.ring_segments = 4
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.15, 1.0)
	_ring.position.y = 0.06
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring.material_override = _ring_material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_build_sparks()
	_light = OmniLight3D.new()
	_light.omni_range = 5.0
	_light.position.y = 1.2
	add_child(_light)
	set_color(color)
	_apply(0.0)


## Funken entstehen auf einem Ring um die Figur und werden zur Apertur (Bauchhöhe) gezogen.
func _build_sparks() -> void:
	_sparks = CPUParticles3D.new()
	_sparks.amount = SPARK_COUNT
	_sparks.lifetime = 1.4
	_sparks.local_coords = true
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_sparks.emission_ring_axis = Vector3.UP
	_sparks.emission_ring_radius = 2.4
	_sparks.emission_ring_inner_radius = 1.6
	_sparks.emission_ring_height = 1.6
	_sparks.direction = Vector3.UP
	_sparks.spread = 30.0
	_sparks.initial_velocity_min = 0.2
	_sparks.initial_velocity_max = 0.6
	_sparks.radial_accel_min = -3.2
	_sparks.radial_accel_max = -2.2
	_sparks.gravity = Vector3(0.0, 0.25, 0.0)
	_sparks.scale_amount_min = 0.5
	_sparks.scale_amount_max = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mesh.radial_segments = 4
	mesh.rings = 2
	_sparks.mesh = mesh
	_sparks.position.y = 0.6
	_sparks.emitting = false
	add_child(_sparks)


func set_color(new_color: Color) -> void:
	color = new_color
	_column_material.set_shader_parameter(&"aura_color", color)
	_light.light_color = color
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = color.lightened(0.35)
	_sparks.material_override = spark_material


func strength() -> float:
	return _strength


## Kurzer Stoß beim Stufenaufstieg oder Durchbruch (Ring breitet sich aus).
func burst(big: bool) -> void:
	Fx.ring(get_tree(), global_position + Vector3.UP * 0.1, 4.5 if big else 2.5, color, 0.8 if big else 0.5)
	Fx.sphere(get_tree(), global_position + Vector3.UP * 1.0, 2.8 if big else 1.4, Color(color, 0.45), 0.6)
	_strength = maxf(_strength, 2.0 if big else 1.5)


func _process(delta: float) -> void:
	_time += delta
	_strength = move_toward(_strength, target_strength, delta * FADE_SPEED)
	_apply(_strength)


func _apply(value: float) -> void:
	var on: bool = value > 0.01
	visible = on
	_sparks.emitting = value > 0.3
	if not on:
		return
	var pulse: float = 0.85 + 0.15 * sin(_time * 3.0)
	_column_material.set_shader_parameter(&"intensity", clampf(value, 0.0, 2.0) * 0.9 * pulse)
	_column.scale = Vector3(1.0 + 0.25 * maxf(value - 1.0, 0.0), 0.6 + 0.4 * minf(value, 1.0) + 0.4 * maxf(value - 1.0, 0.0), 1.0 + 0.25 * maxf(value - 1.0, 0.0))
	_column.position.y = COLUMN_HEIGHT * 0.5 * _column.scale.y
	_ring.rotation.y = _time * 0.8
	_ring.scale = Vector3(1.0, 0.15, 1.0) * (0.9 + 0.1 * sin(_time * 2.0)) * (1.0 + 0.3 * maxf(value - 1.0, 0.0))
	_ring_material.albedo_color = Color(color, 0.55 * minf(value, 1.0))
	_light.light_energy = LIGHT_ENERGY * minf(value, 2.0) * pulse
	_sparks.speed_scale = 1.0 + maxf(value - 1.0, 0.0)
