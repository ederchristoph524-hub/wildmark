class_name DeathScreen
extends Control
## Einblendung beim Tod; im Hardcore-Modus mit Rückkehr zum Hauptmenü.


static func create(text: String, game_over: bool) -> DeathScreen:
	var screen := DeathScreen.new()
	screen.theme = UiTheme.get_theme()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.0, 0.0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var column := VBoxContainer.new()
	center.add_child(column)
	column.add_child(UiTheme.label(Loc.t("Du bist gestorben"), 44, UiTheme.DANGER))
	column.add_child(UiTheme.label(text, 20))
	if game_over:
		column.add_child(UiTheme.button(Loc.t("Zum Hauptmenü"), func() -> void: EventBus.return_to_menu_requested.emit(), 60.0))
	else:
		screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return screen
