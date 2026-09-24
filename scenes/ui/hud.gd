class_name Hud
extends CanvasLayer
## HUD: Leben, Uressenz mit Rang und Stufe, Tageszeit, Meldungen, Interaktion, Kanalisierung, Gu-Leiste (PC) und Touch-Steuerung.

const MESSAGE_TIME: float = 4.5
const MAX_MESSAGES: int = 5
const KEY_HINT: String = "WASD laufen · Maus schauen · Linksklick Faust · 1–4 Gu · Q Killer Move · Mausrad wechseln · Shift Dash · Leertaste Sprung · Tab Ziel · E Aktion · M Meditieren · R Urstein · G Gu-Menü · Esc Menü"
const TOUCH_HINT: String = "Links ziehen: laufen · Rechts wischen: Kamera · Buttons rechts: Faust, Gu 1–4, Killer Move, Sprung, Dash · Oben: Urstein, Meditation, Gu-Menü"

var player: Player = null
var touch: TouchControls = null
var _hp_bar: ProgressBar = null
var _hp_text: Label = null
var _essence_bar: ProgressBar = null
var _essence_text: Label = null
var _rank_text: Label = null
var _status_text: Label = null
var _quest_text: Label = null
var _clock: Label = null
var _messages: VBoxContainer = null
var _prompt: Label = null
var _channel: ProgressBar = null
var _channel_text: Label = null
var _center_info: Label = null
var _gu_bar: Label = null
var _help: Label = null
var _breakthrough: Button = null
var _help_time: float = 14.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	root.add_child(FloatingTexts.new())
	_build_status(root)
	_build_center(root)
	touch = TouchControls.new()
	touch.player = player
	touch.visible = DisplayServer.is_touchscreen_available()
	root.add_child(touch)
	_gu_bar.visible = not touch.visible
	_help.text = tr(TOUCH_HINT if touch.visible else KEY_HINT)
	EventBus.message.connect(show_message)


func _build_status(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_rank_text = UiTheme.label("", 18, UiTheme.ACCENT)
	column.add_child(_rank_text)
	_hp_bar = UiTheme.bar(UiTheme.HEALTH)
	column.add_child(_hp_bar)
	_hp_text = UiTheme.label("", 15)
	_hp_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hp_bar.add_child(_hp_text)
	_hp_text.position = Vector2(8, -1)
	_essence_bar = UiTheme.bar(UiTheme.ESSENCE)
	column.add_child(_essence_bar)
	_essence_text = UiTheme.label("", 15)
	_essence_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_essence_bar.add_child(_essence_text)
	_essence_text.position = Vector2(8, -1)
	_status_text = UiTheme.label("", 15, UiTheme.MUTED)
	_status_text.custom_minimum_size = Vector2(260, 0)
	_quest_text = UiTheme.label("", 15, UiTheme.ACCENT)
	_quest_text.custom_minimum_size = Vector2(260, 0)
	column.add_child(_quest_text)
	column.add_child(_status_text)
	_clock = UiTheme.label("", 18)
	_clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock.position = Vector2(-330, 88)
	_clock.custom_minimum_size = Vector2(310, 0)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_clock)


func _build_center(root: Control) -> void:
	_messages = VBoxContainer.new()
	_messages.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_messages.position = Vector2(-330, 14)
	_messages.custom_minimum_size = Vector2(660, 0)
	_messages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_messages)
	_prompt = _centered_label(root, -190.0, 20, UiTheme.ACCENT)
	_center_info = _centered_label(root, -230.0, 18, UiTheme.TEXT)
	_channel = UiTheme.bar(Color(1.0, 0.7, 0.25))
	_channel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_channel.position = Vector2(-160, -270)
	_channel.custom_minimum_size = Vector2(320, 20)
	root.add_child(_channel)
	_channel_text = UiTheme.label("", 16)
	_channel_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_channel.add_child(_channel_text)
	_channel_text.position = Vector2(8, -1)
	_gu_bar = _centered_label(root, -64.0, 17, UiTheme.TEXT)
	_help = _centered_label(root, -130.0, 15, UiTheme.MUTED)
	_breakthrough = UiTheme.button(tr("Durchbruch wagen"), func() -> void: player.aperture.break_through())
	_breakthrough.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_breakthrough.position = Vector2(-140, 200)
	_breakthrough.custom_minimum_size = Vector2(280, 56)
	root.add_child(_breakthrough)


func _centered_label(root: Control, from_bottom: float, font_size: int, color: Color) -> Label:
	var label: Label = UiTheme.label("", font_size, color)
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.position = Vector2(-460, from_bottom)
	label.custom_minimum_size = Vector2(920, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	return label


func show_message(text: String, color: Color) -> void:
	var label: Label = UiTheme.label(text, 19, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_constant_override(&"outline_size", 6)
	label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	_messages.add_child(label)
	if _messages.get_child_count() > MAX_MESSAGES:
		_messages.get_child(0).queue_free()
	var tween: Tween = label.create_tween()
	tween.tween_interval(MESSAGE_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_help_time -= delta
	_help.visible = _help_time > 0.0
	_update_bars()
	_update_center()
	_gu_bar.text = HudText.gu_bar(player)


func _update_bars() -> void:
	var progression: ProgressionData = DataRegistry.progression()
	var aperture: ApertureComponent = player.aperture
	_hp_bar.max_value = player.health.max_hp
	_hp_bar.value = player.health.hp
	_hp_text.text = tr("Leben %d / %d") % [ceili(player.health.hp), roundi(player.health.max_hp)]
	_essence_bar.max_value = aperture.capacity()
	_essence_bar.value = aperture.essence()
	_essence_text.text = tr("Uressenz %.1f / %.1f") % [aperture.essence(), aperture.capacity()]
	var upkeep: float = PassiveGu.upkeep()
	if upkeep > 0.0:
		_essence_text.text += tr("  (Unterhalt −%.2f/s)") % upkeep
	_essence_bar.add_theme_stylebox_override(&"fill", UiTheme.box(progression.rank_color(GameState.rank).lightened(0.15), 6, Color(0, 0, 0, 0)))
	_rank_text.text = "%s · %s · %s %d %%" % [tr(progression.rank_name(GameState.rank)), tr(progression.stage_name(GameState.stage)), tr("Wand"), roundi(GameState.wall * 100.0)]
	_essence_bar.visible = not Childhood.is_child()
	if Childhood.is_child():
		_rank_text.text = tr("Kindheit · Apertur noch verschlossen")
	_status_text.text = HudText.statuses(player)
	_quest_text.text = Childhood.tracker_text() if Childhood.is_child() else Quests.tracker_text()
	_quest_text.visible = _quest_text.text != ""
	_clock.text = HudText.clock()


func _update_center() -> void:
	var node: Node3D = player.nearest_interactable()
	_prompt.text = ("E: " if not touch.visible else "") + String(node.call("interact_label")) if node != null else ""
	_channel.visible = player.killer.is_channeling() or player.loadout.is_channeling()
	if player.killer.is_channeling():
		_channel.value = player.killer.channel_progress() * 100.0
		_channel_text.text = tr("Kanalisiere %s …") % tr(player.killer.channel_move.display_name)
	elif player.loadout.is_channeling():
		_channel.value = player.loadout.channel_progress() * 100.0
		_channel_text.text = tr("Ordne Gu neu …")
	_center_info.text = HudText.center_info(player)
	_breakthrough.visible = player.aperture.can_break_through() and not player.is_dead()
