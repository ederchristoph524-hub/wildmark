class_name DialogMenu
extends Control
## Gespräch mit einem Dorfbewohner: eine seiner Zeilen, seine Aufgabe (annehmen, Fortschritt, abgeben) und sein Tausch.

signal closed

var npc: Npc = null
var _column: VBoxContainer = null
var _line: String = ""


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", 10)
	panel.add_child(_column)
	if not npc.type.lines.is_empty():
		_line = npc.type.lines[randi() % npc.type.lines.size()]
	refresh()


func refresh() -> void:
	for child: Node in _column.get_children():
		child.queue_free()
	_column.add_child(UiTheme.label(npc.display_title(), 26, npc.type.color.lightened(0.3)))
	_column.add_child(UiTheme.label("„%s“" % tr(_line), 18))
	if npc.quest_id != &"":
		_add_quest()
	if npc.offers_trade:
		_add_trade()
	_column.add_child(UiTheme.button(tr("Auf Wiedersehen"), close))


func _add_quest() -> void:
	var id: StringName = npc.quest_id
	var quest: QuestData = DataRegistry.quest(id)
	var text: String = "%s: %s" % [tr(quest.display_name), tr(quest.description)]
	match Quests.state(id):
		"":
			_column.add_child(UiTheme.label(text, 17, UiTheme.ACCENT))
			var on_accept: Callable = func() -> void:
				Quests.start(id)
				refresh()
			_column.add_child(UiTheme.button(tr("Aufgabe annehmen"), on_accept))
		Quests.ACTIVE:
			_column.add_child(UiTheme.label("%s (%d/%d)" % [text, mini(Quests.current(id), Quests.needed(id)), Quests.needed(id)], 17, UiTheme.ACCENT))
			var can_turn_in: bool = Quests.is_complete(id)
			var on_turn_in: Callable = func() -> void:
				Quests.turn_in(id)
				refresh()
			var button: Button = UiTheme.button(tr("Aufgabe abgeben") if can_turn_in else tr("Noch nicht erfüllt"), on_turn_in)
			button.disabled = not can_turn_in
			_column.add_child(button)
		_:
			_column.add_child(UiTheme.label(tr("Danke für deine Hilfe."), 17, UiTheme.MUTED))


func _add_trade() -> void:
	_column.add_child(UiTheme.label(tr("Tausch: %s") % Trade.offer_text(npc.type), 17))
	var reason: String = Trade.blocked_reason(npc.type)
	var on_trade: Callable = func() -> void:
		Trade.trade(npc.type)
		refresh()
	var button: Button = UiTheme.button(tr("Tauschen") if reason == "" else reason, on_trade)
	button.disabled = reason != ""
	_column.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
