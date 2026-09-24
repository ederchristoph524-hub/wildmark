class_name DayNight
extends Node
## Tag-Nacht-Zyklus (20 min, davon 7 min Nacht): Sonne, Himmel und Nebel nach den Farben der Südlichen Grenze.

const SKY_DAY: Color = Color(0.62, 0.83, 0.69)
const SKY_TOP_DAY: Color = Color(0.36, 0.6, 0.72)
const SKY_NIGHT: Color = Color(0.07, 0.11, 0.1)
const SKY_TOP_NIGHT: Color = Color(0.02, 0.03, 0.06)
const FOG_DAY: Color = Color(0.62, 0.78, 0.66)
const FOG_NIGHT: Color = Color(0.11, 0.17, 0.14)
const SUN_DAY: Color = Color(1.0, 0.95, 0.85)
const SUN_EVENING: Color = Color(1.0, 0.6, 0.35)
const MOON: Color = Color(0.55, 0.65, 0.9)
const TRANSITION: float = 0.04

var sun: DirectionalLight3D = null
var environment: Environment = null
var _sky_material: ProceduralSkyMaterial = null
var _was_night: bool = false


func _ready() -> void:
	name = "DayNight"
	_sky_material = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky_material
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.9
	environment.fog_enabled = true
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.6
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
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
	sun.light_energy = lerpf(0.25, 0.85, daylight)
	sun.shadow_enabled = daylight > 0.3
	_sky_material.sky_horizon_color = SKY_NIGHT.lerp(SKY_DAY, daylight)
	_sky_material.sky_top_color = SKY_TOP_NIGHT.lerp(SKY_TOP_DAY, daylight)
	_sky_material.ground_horizon_color = _sky_material.sky_horizon_color
	_sky_material.ground_bottom_color = SKY_NIGHT.lerp(Color(0.25, 0.32, 0.25), daylight)
	environment.fog_light_color = FOG_NIGHT.lerp(FOG_DAY, daylight)
	environment.fog_density = lerpf(0.028, 0.0065, daylight)
	environment.ambient_light_energy = lerpf(0.3, 0.4, daylight)


func _daylight(time: float, day_part: float) -> float:
	if time < TRANSITION:
		return time / TRANSITION
	if time < day_part - TRANSITION:
		return 1.0
	if time < day_part:
		return (day_part - time) / TRANSITION
	return 0.0
