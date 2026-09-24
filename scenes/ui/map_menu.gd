class_name MapMenu
extends Control
## Karten-Menü (pausiert das Spiel): Gebietskarte und Weltkarte der Gu-Welt mit Regionen, Regionalmauern und Gebieten.

signal closed

const TAB_AREA: int = 0
const TAB_WORLD: int = 1

var player: Player = null
var world: World = null
var start_tab: int = TAB_AREA
var _info: Label = null


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.03, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var area: AreaData = DataRegistry.area(GameState.area)
	var title: Label = UiTheme.label(tr("Karte – %s") % (tr(area.display_name) if area != null else ""), 26, UiTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiTheme.button(tr("Schließen"), close))
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var area_view := AreaMapView.new()
	area_view.name = tr("Gebiet")
	area_view.world = world
	area_view.player = player
	tabs.add_child(area_view)
	tabs.add_child(_world_page())
	tabs.current_tab = start_tab


func _world_page() -> Control:
	var page := VBoxContainer.new()
	page.name = tr("Gu-Welt")
	var view := WorldMapView.new()
	view.current_area = GameState.area
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.area_selected.connect(_on_area_selected)
	page.add_child(view)
	_info = UiTheme.label(tr("Tippe auf einen Ort. Jede Region ist von ihrer Regionalmauer umgeben."), 16, UiTheme.MUTED)
	page.add_child(_info)
	return page


func _on_area_selected(area: AreaData) -> void:
	var region: RegionData = DataRegistry.region(area.region)
	var status: String = tr("Du bist hier.") if area.id == GameState.area else (tr("Bereisbar.") if area.open else tr("Noch unerforscht."))
	_info.text = "%s (%s, Rang %d–%d) – %s\n%s" % [tr(area.display_name), tr(region.display_name), area.rank_min, area.rank_max, status, tr(area.description)]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"world_map") or event.is_action_pressed(&"pause_menu"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
