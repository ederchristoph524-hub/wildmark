class_name UiTheme
extends RefCounted
## Gemeinsames Aussehen der Oberfläche: dunkle Paneele, gut lesbare Schrift (mindestens 14 px, am Handy mit dem Daumen bedienbar).

const PANEL: Color = Color(0.06, 0.09, 0.08, 0.86)
const PANEL_LIGHT: Color = Color(0.12, 0.17, 0.15, 0.92)
const ACCENT: Color = Color(0.86, 0.72, 0.36)
const TEXT: Color = Color(0.93, 0.92, 0.86)
const MUTED: Color = Color(0.65, 0.68, 0.62)
const DANGER: Color = Color(1.0, 0.36, 0.36)
const ESSENCE: Color = Color(0.45, 0.85, 0.55)
const HEALTH: Color = Color(0.85, 0.3, 0.3)
const FONT_SIZE: int = 20

static var _theme: Theme = null


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = FONT_SIZE
	_theme.set_color(&"font_color", &"Label", TEXT)
	_theme.set_color(&"font_color", &"Button", TEXT)
	_theme.set_color(&"font_hover_color", &"Button", ACCENT)
	_theme.set_color(&"font_pressed_color", &"Button", ACCENT)
	_theme.set_color(&"font_disabled_color", &"Button", MUTED)
	_theme.set_stylebox(&"normal", &"Button", box(PANEL_LIGHT, 10, Color(ACCENT, 0.35)))
	_theme.set_stylebox(&"hover", &"Button", box(PANEL_LIGHT.lightened(0.1), 10, ACCENT))
	_theme.set_stylebox(&"pressed", &"Button", box(Color(ACCENT, 0.35), 10, ACCENT))
	_theme.set_stylebox(&"disabled", &"Button", box(Color(PANEL, 0.6), 10, Color(MUTED, 0.2)))
	_theme.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	_theme.set_stylebox(&"panel", &"PanelContainer", box(PANEL, 12, Color(ACCENT, 0.25)))
	_theme.set_stylebox(&"panel", &"Panel", box(PANEL, 12, Color(ACCENT, 0.25)))
	_theme.set_stylebox(&"background", &"ProgressBar", box(Color(0, 0, 0, 0.55), 6, Color(1, 1, 1, 0.12)))
	_theme.set_stylebox(&"fill", &"ProgressBar", box(ESSENCE, 6, Color(0, 0, 0, 0)))
	_theme.set_color(&"font_color", &"ProgressBar", TEXT)
	_theme.set_stylebox(&"panel", &"TabContainer", box(PANEL, 12, Color(ACCENT, 0.25)))
	_theme.set_color(&"font_selected_color", &"TabContainer", ACCENT)
	_theme.set_color(&"font_unselected_color", &"TabContainer", MUTED)
	return _theme


static func box(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.border_color = border
	style.set_content_margin_all(10.0)
	return style


static func label(text: String, size: int = FONT_SIZE, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override(&"font_size", size)
	node.add_theme_color_override(&"font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


static func button(text: String, callback: Callable, min_height: float = 52.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0.0, min_height)
	node.pressed.connect(callback)
	return node


static func bar(color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(260.0, 22.0)
	node.add_theme_stylebox_override(&"fill", box(color, 6, Color(0, 0, 0, 0)))
	return node
