class_name ChimneySmoke
extends CPUParticles3D
## Herdrauch einer Siedlung: ein Partikelsystem, das aus allen Schornsteinköpfen zugleich steigt (Austrittspunkte
## = emission_points). Der Rauch ist beleuchtet (tags hell, nachts dunkel) und wird nachts zusätzlich blasser.

const SMOKE: Color = Color(0.75, 0.75, 0.77)
const PER_CHIMNEY: int = 14
const LIFE: float = 8.0
const NIGHT_ALPHA: float = 0.4
const VIEW_DISTANCE: float = 210.0

static var _puff_texture: GradientTexture2D = null


static func create(points: Array[Vector3]) -> ChimneySmoke:
	var particles := ChimneySmoke.new()
	particles.name = "ChimneySmoke"
	particles.amount = points.size() * PER_CHIMNEY
	particles.lifetime = LIFE
	particles.preprocess = LIFE
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	particles.emission_points = PackedVector3Array(points)
	particles.direction = Vector3.UP
	particles.spread = 10.0
	# Leichter Wind: der Rauch zieht schräg ab und wird dabei langsamer.
	particles.gravity = Vector3(0.3, 0.3, 0.12)
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.5
	particles.damping_min = 0.08
	particles.damping_max = 0.14
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.0
	var grow := Curve.new()
	grow.max_value = 3.0
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 2.6))
	particles.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(SMOKE, 0.0))
	fade.set_color(1, Color(SMOKE, 0.0))
	fade.add_point(0.1, Color(SMOKE, 0.6))
	fade.add_point(0.5, Color(SMOKE, 0.35))
	particles.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 1.4
	particles.mesh = quad
	var material := StandardMaterial3D.new()
	# Beleuchtet, damit der Rauch nachts dunkel bleibt und am Tag von der Sonne aufgehellt wird.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_texture = _puff()
	particles.material_override = material
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_range_end = VIEW_DISTANCE
	return particles


func _ready() -> void:
	_on_night(Formulas.is_night(Balance.values, GameState.time_of_day))
	EventBus.night_changed.connect(_on_night)


func _on_night(night: bool) -> void:
	color = Color(1.0, 1.0, 1.0, NIGHT_ALPHA if night else 1.0)


static func _puff() -> GradientTexture2D:
	if _puff_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.45, Color(1.0, 1.0, 1.0, 0.55))
		_puff_texture = GradientTexture2D.new()
		_puff_texture.gradient = gradient
		_puff_texture.fill = GradientTexture2D.FILL_RADIAL
		_puff_texture.fill_from = Vector2(0.5, 0.5)
		_puff_texture.fill_to = Vector2(1.0, 0.5)
		_puff_texture.width = 64
		_puff_texture.height = 64
	return _puff_texture
