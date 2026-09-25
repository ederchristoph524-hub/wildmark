class_name DeathScreen
extends Control
## Einblendung beim Tod; im Hardcore-Modus mit Rückkehr zum Hauptmenü.

const COLUMN_WIDTH: float = 620.0


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
	# Ohne Mindestbreite bricht der umbrechende Text Buchstabe für Buchstabe um (senkrechte Schrift).
	column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0.0)
	center.add_child(column)
	var title: Label = UiTheme.label(Loc.t("Du bist gestorben"), 44, UiTheme.DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var detail: Label = UiTheme.label(text, 20)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(detail)
	if game_over:
		column.add_child(UiTheme.button(Loc.t("Zum Hauptmenü"), func() -> void: EventBus.return_to_menu_requested.emit(), 60.0))
	else:
		screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return screen
