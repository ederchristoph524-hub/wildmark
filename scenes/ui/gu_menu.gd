class_name GuMenu
extends Control
## Gu-Menü (pausiert das Spiel): Gu mit Slots und Fütterung, Kombinationsbuch, Reaktionen, Inventar, Kultivierung.

signal closed

var player: Player = null
var _tabs: TabContainer = null


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title: Label = UiTheme.label(tr("Gu-Menü"), 28, UiTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiTheme.button(tr("Schließen"), close))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"gu_menu") or event.is_action_pressed(&"pause_menu"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()


func refresh() -> void:
	var current: int = _tabs.current_tab
	for child: Node in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	_add_tab(tr("Gu"), GuMenuPages.gu_page(player, refresh))
	_add_tab(tr("Passive Gu"), PassivePage.build(player, refresh))
	_add_tab(tr("Kombinationsbuch"), GuMenuPages.combo_page())
	_add_tab(tr("Inventar"), GuMenuPages.inventory_page(player, refresh))
	_add_tab(tr("Bauen"), BuildPage.build(player, close))
	_add_tab(tr("Aufgaben"), BuildPage.quests_page())
	_add_tab(tr("Kultivierung"), GuMenuPages.cultivation_page(player, refresh))
	_tabs.current_tab = clampi(current, 0, _tabs.get_tab_count() - 1)


func _add_tab(title: String, content: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_tabs.add_child(scroll)
