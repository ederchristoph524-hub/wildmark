class_name StartPick
extends RefCounted
## Bausteine für den freien Start: aufklappbare Kapitel (Inhalt wird erst beim ersten Öffnen gebaut, damit das Startmenü
## am Handy schnell bleibt), Auswahl-Raster mit Einfach- oder Mehrfachauswahl und Vorgabe-Knopfreihen.

const HEADER_COLOR: Color = Color(0.86, 0.72, 0.36)
const ROW_HEIGHT: float = 44.0


## Aufklappbares Kapitel. builder(body: VBoxContainer) füllt den Inhalt beim ersten Öffnen; summary() liefert die
## Kurzfassung hinter dem Titel (aktuelle Auswahl).
static func fold(parent: Control, title: String, builder: Callable, summary: Callable, open: bool = false) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	parent.add_child(box)
	var header: Button = UiTheme.button("", func() -> void: pass, 50.0)
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_color_override(&"font_color", HEADER_COLOR)
	box.add_child(header)
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 8)
	body.visible = false
	box.add_child(body)
	var update: Callable = func() -> void:
		header.text = "%s  %s · %s" % ["▾" if body.visible else "▸", title, String(summary.call())]
	header.pressed.connect(func() -> void:
		if body.get_child_count() == 0:
			builder.call(body)
		body.visible = not body.visible
		update.call())
	box.set_meta(&"update", update)
	update.call()
	if open:
		header.pressed.emit()
	return box


## Kurzfassung eines Kapitels neu schreiben (nach einer Auswahl).
static func refresh_fold(box: VBoxContainer) -> void:
	if box != null and box.has_meta(&"update"):
		(box.get_meta(&"update") as Callable).call()


## Raster aus Knöpfen. entries: [{id, text, color?}]. selected: Dictionary (Menge der gewählten IDs).
## multi = false: genau eine Auswahl. on_change wird nach jeder Änderung aufgerufen.
static func grid(parent: Control, columns: int, entries: Array, selected: Dictionary, multi: bool, on_change: Callable) -> GridContainer:
	var container := GridContainer.new()
	container.columns = columns
	parent.add_child(container)
	var buttons: Dictionary = {}
	var paint: Callable = func() -> void:
		for id: Variant in buttons:
			press(buttons[id] as Button, selected.has(id))
	for entry: Dictionary in entries:
		var id: Variant = entry["id"]
		var button: Button = UiTheme.button(String(entry["text"]), func() -> void:
			if multi:
				if selected.has(id):
					selected.erase(id)
				else:
					selected[id] = true
			else:
				selected.clear()
				selected[id] = true
			paint.call()
			on_change.call(), ROW_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		if entry.has("color"):
			button.add_theme_color_override(&"font_color", (entry["color"] as Color).lerp(UiTheme.TEXT, 0.35))
		container.add_child(button)
		buttons[id] = button
	paint.call()
	return container


## Reihe von Vorgaben (Zahlen oder IDs) mit Einfachauswahl; labels gleich lang wie values. wrapped = true bricht lange
## Beschriftungen in mehrere Zeilen um (sonst teilen sich die Knöpfe eine Zeile).
static func presets(parent: Control, values: Array, labels: Array, current: Variant, on_pick: Callable, wrapped: bool = false) -> Container:
	var row: Container = null
	if wrapped:
		row = HFlowContainer.new()
	else:
		row = HBoxContainer.new()
	parent.add_child(row)
	var buttons: Array[Button] = []
	for i: int in values.size():
		var value: Variant = values[i]
		var button: Button = UiTheme.button(String(labels[i]), func() -> void:
			for j: int in buttons.size():
				press(buttons[j], j == i)
			on_pick.call(value), ROW_HEIGHT)
		if not wrapped:
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
		row.add_child(button)
		buttons.append(button)
		press(button, typeof(value) == typeof(current) and value == current)
	return row


static func press(button: Button, pressed: bool) -> void:
	button.toggle_mode = true
	button.set_pressed_no_signal(pressed)


static func hint(parent: Control, text: String) -> void:
	parent.add_child(UiTheme.label(text, 15, UiTheme.MUTED))


## Zahl kurz: 1500 → „1.500“, 100000 → „100k“.
static func short_number(value: int) -> String:
	if value >= 100000:
		return "%dk" % floori(value / 1000.0)
	if value >= 1000:
		return "%d.%03d" % [floori(value / 1000.0), value % 1000]
	return str(value)
