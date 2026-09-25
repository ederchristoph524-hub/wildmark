class_name PauseMenu
extends Control
## Pause-Menü: Fortsetzen, Speichern, Steuerung, zurück zum Hauptmenü.

signal closed

const CONTROLS_TEXT: String = "PC: WASD laufen · Maus schauen (Klick ins Spiel fängt die Maus) · Linksklick Faust · 1–4 Gu · Q Killer Move · Mausrad Killer Move wechseln · Shift Dash · Leertaste Sprung (in der Luft mit Sprungwurm: Doppelsprung) · Tab Ziel fixieren · Mittelklick Ziel wechseln · E Aktion · M Meditieren · R Urstein essen · G Gu-Menü · Esc Menü\n\nHandy: links ziehen zum Laufen, rechts wischen für die Kamera, Buttons rechts für Faust, Gu, Killer Move, Sprung und Dash; oben Urstein, Meditation, Gu-Menü und Menü."


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
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
	column.add_child(UiTheme.label(tr("Pause"), 30, UiTheme.ACCENT))
	column.add_child(UiTheme.button(tr("Fortsetzen"), close))
	column.add_child(UiTheme.button(tr("Speichern"), _save))
	var quality: Button = UiTheme.button(GraphicsSettings.label(), func() -> void: pass)
	quality.pressed.connect(func() -> void:
		GraphicsSettings.set_quality((GraphicsSettings.quality() + 1) % GraphicsSettings.NAMES.size(), get_viewport())
		quality.text = GraphicsSettings.label()
		EventBus.message.emit(tr("Schatten und Auflösung sofort, Pflanzendichte ab dem nächsten Gebietswechsel."), UiTheme.MUTED))
	column.add_child(quality)
	column.add_child(UiTheme.button(tr("Zum Hauptmenü (speichert)"), _to_menu))
	column.add_child(UiTheme.label(tr(CONTROLS_TEXT), 15, UiTheme.MUTED))


func _save() -> void:
	if SaveSystem.save_game():
		EventBus.message.emit(tr("Spiel gespeichert"), UiTheme.ACCENT)


func _to_menu() -> void:
	SaveSystem.save_game()
	EventBus.return_to_menu_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
