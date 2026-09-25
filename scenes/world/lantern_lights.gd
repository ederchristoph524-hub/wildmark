class_name LanternLights
extends Node3D
## Echte Lichter an den Laternen einer Siedlung: nachts werfen sie warmes Licht auf Straße und Wände (mit leichtem
## Flackern), tagsüber sind sie aus. Höchstens MAX_LIGHTS je Siedlung (Compatibility-Renderer: wenige Lichter je
## Objekt), gleichmäßig aus allen gemeldeten Laternen gewählt.

const MAX_LIGHTS: int = 6
const COLOR: Color = Color(1.0, 0.62, 0.3)
const ENERGY: float = 4.5
const RANGE: float = 14.0
const HEIGHT: float = 2.4

var _lights: Array[OmniLight3D] = []
var _night: bool = false
var _time: float = 0.0


## points: Weltpositionen der Laternenfüße.
static func create(world: World, points: Array[Vector3]) -> LanternLights:
	var node := LanternLights.new()
	node.name = "LanternLights"
	var step: float = maxf(1.0, float(points.size()) / MAX_LIGHTS)
	var index: float = 0.0
	while index < points.size() and node._lights.size() < MAX_LIGHTS:
		var light := OmniLight3D.new()
		light.light_color = COLOR
		light.omni_range = RANGE
		light.omni_attenuation = 1.4
		light.light_energy = 0.0
		light.position = points[floori(index)] + Vector3.UP * HEIGHT
		node.add_child(light)
		node._lights.append(light)
		index += step
	world.add_child(node)
	return node


func _ready() -> void:
	_night = Formulas.is_night(Balance.values, GameState.time_of_day)
	EventBus.night_changed.connect(func(night: bool) -> void: _night = night)
	set_process(not _lights.is_empty())


func _process(delta: float) -> void:
	_time += delta
	for i: int in _lights.size():
		var flicker: float = 0.9 + 0.1 * sin(_time * 7.0 + i * 1.9) * sin(_time * 3.1 + i)
		_lights[i].light_energy = move_toward(_lights[i].light_energy, ENERGY * flicker if _night else 0.0, delta * 1.5)
		_lights[i].visible = _lights[i].light_energy > 0.02
