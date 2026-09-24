class_name TouchControls
extends Control
## Touch-Steuerung mit echtem Multitouch: Joystick links, Kamera-Wischen rechts, Aktions-Buttons im Bogen um den Faust-Button.
## Buttons lösen dieselben Input-Map-Aktionen aus wie Tastatur und Maus.

const JOYSTICK_RADIUS: float = 90.0
const JOYSTICK_AREA: float = 0.45
const READY_COLOR: Color = Color(0.1, 0.14, 0.12)
const BORDER: Color = Color(0.86, 0.72, 0.36, 0.7)
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]
const KILLER_ACTION: StringName = &"killer_move"
const SWIPE_DISTANCE: float = 40.0
## Kurzes Tippen im Kamerabereich (kaum bewegt) fixiert den Gegner unter dem Finger.
const TAP_DISTANCE: float = 18.0
const TAP_TIME_MS: int = 300

## Button: Aktion, Mittelpunkt relativ zu einer Bildschirmecke, Radius, Beschriftung.
var buttons: Array[Dictionary] = []
var player: Player = null

var _joystick_index: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_knob: Vector2 = Vector2.ZERO
var _camera_index: int = -1
var _camera_last: Vector2 = Vector2.ZERO
## Freie Berührungen (Joystick oder Kamera): Startpunkt, letzter Punkt, Startzeit – für Tippen.
var _free_start: Dictionary[int, Vector2] = {}
var _free_last: Dictionary[int, Vector2] = {}
var _free_ms: Dictionary[int, int] = {}
var _pressed: Dictionary[int, StringName] = {}
## Killer-Move-Button: Tippen startet, seitliches Wischen wechselt (KAMPFSYSTEM, Steuerung).
var _killer_index: int = -1
var _killer_start: Vector2 = Vector2.ZERO
var _killer_swiped: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_define_buttons()


func _define_buttons() -> void:
	var fist := Vector2(-110.0, -110.0)
	_add(&"attack_fist", fist, 60.0, tr("Faust"), true)
	var slot_offsets: Array[Vector2] = [Vector2(-140, 5), Vector2(-120, -95), Vector2(-45, -150), Vector2(55, -160)]
	for i: int in 4:
		_add(StringName("gu_slot_%d" % (i + 1)), fist + slot_offsets[i], 40.0, str(i + 1), true)
	_add(&"killer_move", fist + Vector2(-215, -175), 40.0, tr("Killer"), true)
	_add(&"jump", fist + Vector2(-255, 5), 42.0, tr("Sprung"), true)
	_add(&"dash", fist + Vector2(-245, -88), 36.0, tr("Dash"), true)
	var small: Array[Array] = [[&"pause_menu", "≡"], [&"gu_menu", tr("Gu")], [&"meditate", tr("Medit.")], [&"eat_primeval_stone", tr("Urstein")]]
	for i: int in small.size():
		_add(small[i][0], Vector2(-50.0 - i * 68.0, 50.0), 28.0, small[i][1], false)
	_add(&"interact", Vector2(0.0, -150.0), 34.0, tr("Aktion"), true, true)


## from_bottom: Position relativ zur unteren rechten Ecke (sonst obere rechte); centered: relativ zur unteren Mitte.
func _add(action: StringName, offset: Vector2, radius: float, text: String, from_bottom: bool, centered: bool = false) -> void:
	buttons.append({"action": action, "offset": offset, "radius": radius, "text": text, "bottom": from_bottom, "centered": centered})


func button_center(button: Dictionary) -> Vector2:
	var view: Vector2 = size
	var offset: Vector2 = button["offset"]
	if button["centered"]:
		return Vector2(view.x * 0.5 + offset.x, view.y + offset.y)
	return Vector2(view.x + offset.x, (view.y if button["bottom"] else 0.0) + offset.y)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_touch_down(touch.index, touch.position)
		else:
			_touch_up(touch.index)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _free_last.has(drag.index):
			_free_last[drag.index] = drag.position
		if drag.index == _killer_index:
			_killer_drag(drag.position)
		elif drag.index == _joystick_index:
			_update_joystick(drag.position)
		elif drag.index == _camera_index:
			EventBus.camera_look.emit(drag.position - _camera_last)
			_camera_last = drag.position


func _touch_down(index: int, at: Vector2) -> void:
	for button: Dictionary in buttons:
		if not _button_visible(button):
			continue
		if at.distance_to(button_center(button)) <= float(button["radius"]) * 1.25:
			if button["action"] == KILLER_ACTION:
				_killer_index = index
				_killer_start = at
				_killer_swiped = false
				return
			_pressed[index] = button["action"]
			_send(button["action"], true)
			return
	_free_start[index] = at
	_free_last[index] = at
	_free_ms[index] = Time.get_ticks_msec()
	if at.x < size.x * JOYSTICK_AREA and _joystick_index < 0:
		_joystick_index = index
		_joystick_center = at
		_update_joystick(at)
	elif _camera_index < 0:
		_camera_index = index
		_camera_last = at


func _touch_up(index: int) -> void:
	if index == _killer_index:
		_killer_index = -1
		if not _killer_swiped:
			_send(KILLER_ACTION, true)
			_send(KILLER_ACTION, false)
	if _pressed.has(index):
		_send(_pressed[index], false)
		_pressed.erase(index)
	if index == _joystick_index:
		_joystick_index = -1
		_joystick_knob = Vector2.ZERO
		for action: StringName in MOVE_ACTIONS:
			Input.action_release(action)
	if index == _camera_index:
		_camera_index = -1
	if _free_start.has(index):
		if _free_last[index].distance_to(_free_start[index]) < TAP_DISTANCE and Time.get_ticks_msec() - _free_ms[index] < TAP_TIME_MS:
			_tap(_free_start[index])
		_free_start.erase(index)
		_free_last.erase(index)
		_free_ms.erase(index)


## Gegner antippen: fixieren, anderen antippen wechselt, denselben erneut antippen löst (KAMPFSYSTEM, Steuerung).
func _tap(at: Vector2) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if player != null and is_instance_valid(player) and camera != null:
		player.targeting.tap_select(camera, at)


func _killer_drag(at: Vector2) -> void:
	var dx: float = at.x - _killer_start.x
	if absf(dx) < SWIPE_DISTANCE:
		return
	_killer_swiped = true
	_killer_start = at
	var action: StringName = &"killer_move_next" if dx > 0.0 else &"killer_move_prev"
	_send(action, true)
	_send(action, false)


func _update_joystick(at: Vector2) -> void:
	var offset: Vector2 = (at - _joystick_center).limit_length(JOYSTICK_RADIUS)
	_joystick_knob = offset
	var value: Vector2 = offset / JOYSTICK_RADIUS
	_set_axis(&"move_left", &"move_right", value.x)
	_set_axis(&"move_forward", &"move_back", value.y)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < -0.1:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.1:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


## Alle Berührungen loslassen (z. B. wenn ein Menü aufgeht).
func release_all() -> void:
	_free_start.clear()
	_free_last.clear()
	_free_ms.clear()
	for index: int in _pressed.keys():
		_touch_up(index)
	_touch_up(_joystick_index)
	_camera_index = -1


func _button_visible(button: Dictionary) -> bool:
	if button["action"] == &"interact":
		return player != null and player.nearest_interactable() != null
	return true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if _joystick_index >= 0:
		draw_circle(_joystick_center, JOYSTICK_RADIUS, Color(READY_COLOR, 0.3))
		draw_arc(_joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 40, BORDER, 2.0)
		draw_circle(_joystick_center + _joystick_knob, 34.0, Color(BORDER, 0.6))
	for button: Dictionary in buttons:
		if _button_visible(button):
			TouchButtonPainter.paint(self, font, button, button_center(button), player, _pressed.values().has(button["action"]))
