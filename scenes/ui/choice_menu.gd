class_name ChoiceMenu
extends Control
## Einfache Auswahl mit Titel, Erklärung und Knöpfen (EventBus.choice_requested), z. B. das Urteil über einen
## besiegten Wanderer. Jeder Knopf führt seine Aktion aus und schließt das Fenster.

signal closed

var title: String = ""
var text: String = ""
## [[Beschriftung, Callable], …]
var options: Array = []


static func create(menu_title: String, menu_text: String, menu_options: Array) -> ChoiceMenu:
	var menu := ChoiceMenu.new()
	menu.title = menu_title
	menu.text = menu_text
	menu.options = menu_options
	return menu


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
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	panel.add_child(column)
	column.add_child(UiTheme.label(title, 26, UiTheme.ACCENT))
	var body: Label = UiTheme.label(text, 17)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	for option: Array in options:
		var action: Callable = option[1]
		column.add_child(UiTheme.button(String(option[0]), func() -> void: _choose(action)))


func _choose(action: Callable) -> void:
	close()
	action.call()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
