class_name BeastTide
extends Node
## Bestienflut (wie die Wolfsflut am Qing-Mao-Berg): Alle paar Tage warnen Späher am Morgen, in der Nacht stürmen
## Bestien in Wellen auf eine Siedlung zu. Wer alle erlegt, erhält den Lohn aus gebiete.json → flut und Verdienst
## für seine Sekte. Nicht gespeichert: Wer das Gebiet verlässt, verpasst die Flut.

const WAVES: int = 3
const WAVE_INTERVAL: float = 14.0
const SPAWN_GAP: Vector2 = Vector2(45.0, 60.0)
const WARN_COLOR: Color = Color(1.0, 0.45, 0.35)
const WIN_COLOR: Color = Color(1.0, 0.85, 0.3)
## Verdienst für die eigene Sekte, wenn die Flut abgewehrt ist.
const MERIT: int = 40

## Kurztext für das HUD (leer, wenn keine Flut läuft).
static var status_text: String = ""

var world: World = null
var tide: Dictionary = {}
var active: bool = false
var _pending: bool = false
var _waves_left: int = 0
var _wave_timer: float = 0.0
var _beasts: Array[Enemy] = []
var _center: Vector3 = Vector3.ZERO
var _radius: float = 30.0


func _init(owner_world: World) -> void:
	world = owner_world
	tide = world.area.tide
	name = "BeastTide"


func _ready() -> void:
	status_text = ""
	for settlement: Dictionary in world.area.settlements:
		if settlement["id"] == tide["target"]:
			var at: Vector2 = settlement["position"]
			_center = world.ground_point(at.x, at.y)
			_radius = settlement["radius"]
	EventBus.day_started.connect(_on_day)
	EventBus.night_changed.connect(_on_night)


func _exit_tree() -> void:
	status_text = ""


func _on_day(day: int) -> void:
	if day % int(tide["every"]) == 0 and not active:
		_pending = true
		EventBus.message.emit(tr("Späher warnen: Heute Nacht naht die %s!") % tr(String(tide["name"])), WARN_COLOR)


func _on_night(is_night: bool) -> void:
	if is_night and _pending:
		start()


## Startet die Flut sofort (auch für Tests).
func start() -> void:
	_pending = false
	active = true
	_waves_left = WAVES
	_wave_timer = 0.0
	EventBus.message.emit(tr("Die %s bricht los!") % tr(String(tide["name"])), WARN_COLOR)
	Sound.play(&"drum")


func _process(delta: float) -> void:
	if not active:
		return
	if _waves_left > 0:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_spawn_wave(_waves_left == 1)
			_waves_left -= 1
			_wave_timer = WAVE_INTERVAL
	var alive: Array[Enemy] = []
	for beast: Enemy in _beasts:
		if is_instance_valid(beast) and not beast.is_dead():
			alive.append(beast)
	_beasts = alive
	status_text = tr("%s: %d Bestien") % [tr(String(tide["name"])), _beasts.size()] + (tr(" · weitere Wellen folgen") if _waves_left > 0 else "")
	if _waves_left == 0 and _beasts.is_empty():
		_win()


## Eine Welle aus einer Richtung; die letzte bringt den Anführer mit.
func _spawn_wave(with_leader: bool) -> void:
	var count: int = maxi(1, ceili(float(tide["count"]) / WAVES))
	var beasts: Array = tide["beasts"]
	var angle: float = randf() * TAU
	for i: int in count:
		_spawn(beasts[randi() % beasts.size()], angle + randf_range(-0.4, 0.4))
	if with_leader and tide["leader"] != &"":
		_spawn(tide["leader"], angle)


func _spawn(id: StringName, angle: float) -> void:
	var data: EnemyData = DataRegistry.enemy(id)
	if data == null:
		return
	var distance: float = _radius + randf_range(SPAWN_GAP.x, SPAWN_GAP.y)
	var at := Vector3(_center.x + cos(angle) * distance, 0.0, _center.z + sin(angle) * distance)
	if not world.terrain.is_inside(at.x, at.z, 4.0) or world.terrain.in_water(at.x, at.z):
		at = Vector3(_center.x + cos(angle) * (_radius + 8.0), 0.0, _center.z + sin(angle) * (_radius + 8.0))
	var beast: Enemy = world.spawner.spawn(data, world.ground_point(at.x, at.z) + Vector3.UP * 0.3)
	# Die Flut strömt in die Siedlung und bleibt, bis sie erlegt ist.
	beast.home = _center
	beast.persistent = true
	_beasts.append(beast)


func _win() -> void:
	active = false
	status_text = ""
	var parts: PackedStringArray = []
	var reward: Dictionary = tide["reward"]
	for item: StringName in reward:
		GameState.add_item(item, int(reward[item]))
		parts.append("%d %s" % [int(reward[item]), tr(DataRegistry.item(item).display_name)])
	SectLife.add_merit(MERIT)
	EventBus.message.emit(tr("Die %s ist abgewehrt! Lohn: %s") % [tr(String(tide["name"])), ", ".join(parts)], WIN_COLOR)
	Sound.play(&"gong")
