class_name Weather
extends Node3D
## Wetter je Biom (gebiete.json → BIOME.wetter): an manchen Tagen Regen (Dschungel, Sümpfe, Inseln), Schnee
## (Froststeppe, Kranichtal) oder ein Sandsturm (Wüste, rote Schlucht). Die Teilchen folgen der Kamera, Himmel und
## Licht werden trüber, der Nebel dichter (DayNight liest Weather.intensity), Regen rauscht (Sound). Nicht
## gespeichert: Jeder Tag wird aus Tag und Gebiet neu ausgewürfelt, Wechsel blenden sanft über.

const KIND_RAIN: StringName = &"regen"
const KIND_SNOW: StringName = &"schnee"
const KIND_SAND: StringName = &"sand"
## Überblenden: volle Stärke nach etwa 1 / FADE_SPEED Sekunden.
const FADE_SPEED: float = 0.06
const BOX: Vector3 = Vector3(26.0, 2.0, 26.0)
## Trübung von Himmel und Nebel je Wetterart.
const TINTS: Dictionary[StringName, Color] = {
	KIND_RAIN: Color(0.42, 0.46, 0.5), KIND_SNOW: Color(0.78, 0.8, 0.84), KIND_SAND: Color(0.78, 0.62, 0.42),
}

## Aktuelle Stärke 0–1 und Art (für DayNight und Sound).
static var intensity: float = 0.0
static var kind: StringName = &""

var world: World = null
var chance: float = 0.0
var _target: float = 0.0
var _wetness: float = 0.0
var _particles: CPUParticles3D = null


func _init(owner_world: World) -> void:
	world = owner_world
	name = "Weather"


func _ready() -> void:
	kind = world.terrain.biome.weather
	chance = world.terrain.biome.weather_chance
	intensity = 0.0
	if kind == &"" or chance <= 0.0:
		kind = &""
		set_process(false)
		return
	_particles = _build(kind)
	add_child(_particles)
	_particles.emitting = false
	EventBus.day_started.connect(_roll)
	_roll(GameState.day)
	# Beim Betreten des Gebiets gilt das Wetter des Tages sofort.
	intensity = _target
	_wetness = _target if kind == KIND_RAIN else 0.0


func _exit_tree() -> void:
	intensity = 0.0
	kind = &""


## Wetter des Tages (aus Tag und Gebiet, damit Laden und Tests dasselbe Wetter sehen).
func _roll(day: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_%d" % [world.area.id, day])
	_target = rng.randf_range(0.55, 1.0) if rng.randf() < chance else 0.0


## Setzt das Wetter sofort (für Tests und Bildschirmfotos).
func force(amount: float) -> void:
	_target = clampf(amount, 0.0, 1.0)
	intensity = _target
	_wetness = _target if kind == KIND_RAIN else 0.0


func _process(delta: float) -> void:
	intensity = move_toward(intensity, _target, FADE_SPEED * delta)
	_particles.emitting = intensity > 0.08
	# Der Boden wird mit dem Regen nass und trocknet danach langsamer.
	var wet_target: float = intensity if kind == KIND_RAIN else 0.0
	_wetness = move_toward(_wetness, wet_target, FADE_SPEED * delta * (1.0 if wet_target > _wetness else 0.4))
	world.terrain.set_wetness(_wetness)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null:
		var at: Vector3 = camera.global_position
		global_position = Vector3(at.x, at.y + (8.0 if kind != KIND_SAND else 0.0), at.z)


static func tint() -> Color:
	return TINTS.get(kind, Color.GRAY)


func _build(weather: StringName) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = BOX * 0.5
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.custom_aabb = AABB(Vector3(-BOX.x, -20.0, -BOX.z), Vector3(BOX.x * 2.0, 30.0, BOX.z * 2.0))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	match weather:
		KIND_SNOW:
			var flake := QuadMesh.new()
			flake.size = Vector2.ONE * 0.16
			particles.mesh = flake
			material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			material.albedo_texture = Ambience._soft_dot()
			particles.amount = 320
			particles.lifetime = 7.0
			particles.direction = Vector3.DOWN
			particles.spread = 25.0
			particles.initial_velocity_min = 0.8
			particles.initial_velocity_max = 1.6
			particles.gravity = Vector3(0.3, -0.6, 0.0)
			particles.color = Color(1.0, 1.0, 1.0, 0.85)
		KIND_SAND:
			var grain := BoxMesh.new()
			grain.size = Vector3(0.03, 0.5, 0.03)
			particles.mesh = grain
			particles.particle_flag_align_y = true
			particles.amount = 180
			particles.lifetime = 2.2
			particles.direction = Vector3(1.0, 0.1, 0.3)
			particles.spread = 12.0
			particles.initial_velocity_min = 9.0
			particles.initial_velocity_max = 14.0
			particles.gravity = Vector3(0.0, -0.4, 0.0)
			particles.emission_box_extents = Vector3(BOX.x * 0.5, 3.0, BOX.z * 0.5)
			particles.color = Color(0.85, 0.7, 0.5, 0.45)
		_:
			var drop := BoxMesh.new()
			drop.size = Vector3(0.02, 0.7, 0.02)
			particles.mesh = drop
			particles.particle_flag_align_y = true
			particles.amount = 340
			particles.lifetime = 0.9
			particles.direction = Vector3(0.08, -1.0, 0.0)
			particles.spread = 3.0
			particles.initial_velocity_min = 18.0
			particles.initial_velocity_max = 22.0
			particles.gravity = Vector3.ZERO
			particles.color = Color(0.75, 0.82, 0.92, 0.5)
	particles.material_override = material
	particles.preprocess = particles.lifetime
	return particles
