class_name DayNight
extends Node
## Tag-Nacht-Zyklus (20 min, davon 7 min Nacht): Sonne, Himmel und Nebel in den Farben des Bioms.

const SKY_DAY: Color = Color(0.62, 0.83, 0.69)
const SKY_TOP_DAY: Color = Color(0.36, 0.6, 0.72)
const SKY_NIGHT: Color = Color(0.08, 0.12, 0.17)
const SKY_TOP_NIGHT: Color = Color(0.03, 0.05, 0.1)
const FOG_DAY: Color = Color(0.62, 0.78, 0.66)
const FOG_NIGHT: Color = Color(0.1, 0.15, 0.2)
const SUN_DAY: Color = Color(1.0, 0.94, 0.82)
const SUN_EVENING: Color = Color(1.0, 0.6, 0.35)
const MOON: Color = Color(0.55, 0.65, 0.9)
const TRANSITION: float = 0.04
const SUN_ENERGY_DAY: float = 1.25
const SUN_ENERGY_NIGHT: float = 0.38
## Umgebungslicht: halb aus dem Himmel, halb warmes Streulicht (sonst färbt der Himmel alles bläulich).
const AMBIENT_WARM: Color = Color(0.78, 0.72, 0.62)
const AMBIENT_SKY_SHARE: float = 0.3
## Wolkendecke (ProceduralTextures „clouds“, wird zum Himmel addiert): tags weiß, abends warm, nachts kaum sichtbar.
const CLOUDS_DAY: Color = Color(0.55, 0.55, 0.55)
const CLOUDS_EVENING: Color = Color(0.6, 0.38, 0.22)
const CLOUDS_NIGHT: Color = Color(0.05, 0.06, 0.09)

## Landschaft des Gebiets (Himmel- und Nebelfarben); ohne Angabe die Südliche Grenze.
var biome: BiomeData = null
var sun: DirectionalLight3D = null
var environment: Environment = null
var _sky_material: ProceduralSkyMaterial = null
var _was_night: bool = false
## Wie stark volles Wetter Himmel und Licht trübt (0–1).
const WEATHER_GLOOM: float = 0.75


func _ready() -> void:
	name = "DayNight"
	_sky_material = ProceduralSkyMaterial.new()
	_sky_material.sky_cover = ProceduralTextures.get_texture(&"clouds")
	_sky_material.sky_cover_modulate = CLOUDS_DAY
	var sky := Sky.new()
	sky.sky_material = _sky_material
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = AMBIENT_WARM
	environment.ambient_light_sky_contribution = AMBIENT_SKY_SHARE
	environment.ambient_light_energy = 0.7
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.15
	environment.tonemap_white = 6.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.0
	environment.adjustment_contrast = 1.06
	# Leuchten: helle Stellen (Laternen, Gu-Effekte, Sonne auf Wasser) strahlen weich über ihre Kanten.
	# Zurückhaltend: nur die hellsten Stellen strahlen, sonst überstrahlt ein Feuerball den ganzen Bildschirm.
	environment.glow_enabled = GraphicsSettings.glow()
	environment.glow_intensity = 0.3
	environment.glow_strength = 0.6
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.3
	environment.glow_hdr_scale = 2.5
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	environment.set_glow_level(1, 0.35)
	environment.set_glow_level(3, 0.3)
	environment.set_glow_level(5, 0.15)
	environment.fog_enabled = true
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.45
	# Ferne Berge nehmen die Himmelsfarbe an (Luftperspektive).
	environment.fog_aerial_perspective = 0.55
	environment.fog_sun_scatter = 0.18
	_sky_material.sun_angle_max = 18.0
	_sky_material.sun_curve = 0.12
	_sky_material.sky_curve = 0.1
	_sky_material.ground_curve = 0.04
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = GraphicsSettings.shadows()
	sun.directional_shadow_max_distance = 45.0
	# Schatten nicht schwarz: etwas Himmelslicht fällt immer hinein.
	sun.shadow_opacity = 0.78
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	_was_night = Formulas.is_night(Balance.values, GameState.time_of_day)
	_apply(GameState.time_of_day)


func _process(delta: float) -> void:
	var b: BalanceData = Balance.values
	GameState.time_of_day += delta / b.day_length
	GameState.play_time += delta
	if GameState.time_of_day >= 1.0:
		GameState.time_of_day -= 1.0
		GameState.day += 1
		EventBus.message.emit(tr("Tag %d bricht an") % GameState.day, SUN_DAY)
		EventBus.day_started.emit(GameState.day)
	var night: bool = Formulas.is_night(b, GameState.time_of_day)
	if night != _was_night:
		_was_night = night
		EventBus.night_changed.emit(night)
		EventBus.message.emit(tr("Die Nacht bricht herein – Bestien werden stärker.") if night else tr("Der Morgen graut."), MOON if night else SUN_DAY)
	_apply(GameState.time_of_day)


## Tagesanteil 0–1: Sonnenbogen am Tag, Mondlicht in der Nacht, weiche Übergänge.
func _apply(time: float) -> void:
	var b: BalanceData = Balance.values
	var day_part: float = 1.0 - b.night_length / b.day_length
	var daylight: float = _daylight(time, day_part)
	var arc: float = clampf(time / day_part, 0.0, 1.0) if time < day_part else clampf((time - day_part) / (1.0 - day_part), 0.0, 1.0)
	var elevation: float = sin(arc * PI) * 1.1 + 0.15
	sun.rotation = Vector3(-elevation, lerpf(-1.3, 1.3, arc), 0.0)
	var evening: float = 1.0 - clampf(sin(arc * PI) * 3.0, 0.0, 1.0)
	sun.light_color = MOON.lerp(SUN_DAY.lerp(SUN_EVENING, evening), daylight)
	sun.light_energy = lerpf(SUN_ENERGY_NIGHT, SUN_ENERGY_DAY, daylight)
	sun.shadow_enabled = daylight > 0.3 and GraphicsSettings.shadows()
	var sky_day: Color = biome.sky if biome != null else SKY_DAY
	var sky_top_day: Color = biome.sky_top if biome != null else SKY_TOP_DAY
	var fog_day: Color = biome.fog if biome != null else FOG_DAY
	var fog_density: float = biome.fog_density if biome != null else 0.0065
	_sky_material.sky_horizon_color = SKY_NIGHT.lerp(sky_day, daylight)
	_sky_material.sky_cover_modulate = CLOUDS_NIGHT.lerp(CLOUDS_DAY.lerp(CLOUDS_EVENING, evening), daylight)
	_sky_material.sky_top_color = SKY_TOP_NIGHT.lerp(sky_top_day, daylight)
	_sky_material.ground_horizon_color = _sky_material.sky_horizon_color
	_sky_material.ground_bottom_color = SKY_NIGHT.lerp(fog_day.darkened(0.45), daylight)
	environment.fog_light_color = FOG_NIGHT.lerp(fog_day, daylight)
	environment.fog_density = lerpf(fog_density * 3.0, fog_density, daylight)
	environment.ambient_light_energy = lerpf(0.6, 0.82, daylight)
	_apply_weather(daylight)
	WaterSurface.set_sky(_sky_material.sky_horizon_color.lerp(_sky_material.sky_top_color, 0.35))
	# Fenster und Laternen der Siedlungen leuchten, sobald es dämmert.
	WorldMaterials.set_night_glow(1.0 - daylight)


## Regen, Schnee oder Sandsturm trüben Himmel, Licht und Nebel (Weather).
func _apply_weather(daylight: float) -> void:
	var gloom: float = Weather.intensity * WEATHER_GLOOM
	if gloom <= 0.0:
		return
	var tint: Color = Weather.tint().lerp(SKY_NIGHT, 1.0 - daylight)
	sun.light_energy *= 1.0 - gloom * 0.6
	sun.shadow_enabled = sun.shadow_enabled and gloom < 0.45
	_sky_material.sky_horizon_color = _sky_material.sky_horizon_color.lerp(tint, gloom)
	_sky_material.sky_top_color = _sky_material.sky_top_color.lerp(tint.darkened(0.25), gloom)
	_sky_material.ground_horizon_color = _sky_material.sky_horizon_color
	environment.fog_light_color = environment.fog_light_color.lerp(tint, gloom)
	environment.fog_density *= 1.0 + gloom * 1.6


func _daylight(time: float, day_part: float) -> float:
	if time < TRANSITION:
		return time / TRANSITION
	if time < day_part - TRANSITION:
		return 1.0
	if time < day_part:
		return (day_part - time) / TRANSITION
	return 0.0
