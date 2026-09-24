class_name StartMenu
extends Control
## Neues-Spiel-Menü: Kindheit (spielbar oder übersprungen), erster Gu und Talent (nur beim Überspringen), Todesmodus oder Weiterspielen.

const TALENT_RANDOM: StringName = &"random"
const DEATH_MODES: Array[StringName] = [&"standard", &"relaxed", &"hardcore"]

var _family: StringName = &""
var _talent: StringName = TALENT_RANDOM
var _death: StringName = &"standard"
var _childhood: bool = true
var _childhood_buttons: Array[Button] = []
## Erster Gu und Talent: nur sichtbar, wenn die Kindheit übersprungen wird (sonst Talenttest im Spiel).
var _skip_section: VBoxContainer = null
var _family_buttons: Dictionary[StringName, Button] = {}
var _talent_buttons: Dictionary[StringName, Button] = {}
var _death_buttons: Dictionary[StringName, Button] = {}
var _description: Label = null


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.03, 0.06, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(680.0, 0.0)
	column.add_theme_constant_override(&"separation", 12)
	center.add_child(column)
	_build(column)
	_family = DataRegistry.gu_system().start_families[0]
	_refresh()


func _build(column: VBoxContainer) -> void:
	column.add_child(UiTheme.label(tr("WILDMARK"), 56, UiTheme.ACCENT))
	column.add_child(UiTheme.label(tr("Die Südliche Grenze. Deine Apertur erwacht bald – die Welt wartet nicht auf dich."), 18, UiTheme.MUTED))
	if SaveSystem.has_save():
		column.add_child(UiTheme.button(tr("Weiterspielen"), func() -> void: EventBus.continue_requested.emit(), 60.0))
	column.add_child(UiTheme.label(tr("Kindheit"), 24, UiTheme.ACCENT))
	var childhood := HBoxContainer.new()
	column.add_child(childhood)
	for playable: bool in [true, false]:
		var button: Button = UiTheme.button(tr("Spielbar (kurzes Tutorial im Dorf)") if playable else tr("Überspringen"), _choose_childhood.bind(playable))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		childhood.add_child(button)
		_childhood_buttons.append(button)
	column.add_child(UiTheme.label(tr("Todesmodus"), 24, UiTheme.ACCENT))
	var deaths := HBoxContainer.new()
	column.add_child(deaths)
	var death_names: Dictionary[StringName, String] = {&"standard": tr("Standard"), &"relaxed": tr("Entspannt"), &"hardcore": tr("Hardcore")}
	for mode: StringName in DEATH_MODES:
		var button: Button = UiTheme.button(death_names[mode], _choose_death.bind(mode))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		deaths.add_child(button)
		_death_buttons[mode] = button
	var start_text: String = tr("Neues Spiel") + (tr(" (überschreibt den Spielstand)") if SaveSystem.has_save() else "")
	# Start-Knopf vor den Erklärungen, damit er am Handy quer ohne Scrollen sichtbar bleibt.
	column.add_child(UiTheme.button(start_text, _start, 64.0))
	_skip_section = VBoxContainer.new()
	_skip_section.add_theme_constant_override(&"separation", 12)
	column.add_child(_skip_section)
	_build_skip_section(_skip_section)
	_description = UiTheme.label("", 18, UiTheme.MUTED)
	column.add_child(_description)


func _build_skip_section(column: VBoxContainer) -> void:
	column.add_child(UiTheme.label(tr("Dein erster Gu"), 24, UiTheme.ACCENT))
	var families := GridContainer.new()
	families.columns = 2
	column.add_child(families)
	for family_id: StringName in DataRegistry.gu_system().start_families:
		var family: GuFamilyData = DataRegistry.family(family_id)
		var member: GuData = family.member_for_rank(1)
		var button: Button = UiTheme.button("%s\n%s" % [tr(member.display_name), tr(family.role)], _choose_family.bind(family_id), 70.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		families.add_child(button)
		_family_buttons[family_id] = button
	column.add_child(UiTheme.label(tr("Talent (Aptitude)"), 24, UiTheme.ACCENT))
	var talents := HBoxContainer.new()
	column.add_child(talents)
	var grades: Array[StringName] = [TALENT_RANDOM, &"D", &"C", &"B", &"A"]
	for grade: StringName in grades:
		var button: Button = UiTheme.button(tr("Zufall") if grade == TALENT_RANDOM else String(grade), _choose_talent.bind(grade))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		talents.add_child(button)
		_talent_buttons[grade] = button


func _choose_childhood(playable: bool) -> void:
	_childhood = playable
	_refresh()


func _choose_family(id: StringName) -> void:
	_family = id
	_refresh()


func _choose_talent(grade: StringName) -> void:
	_talent = grade
	_refresh()


func _choose_death(mode: StringName) -> void:
	_death = mode
	_refresh()


func _refresh() -> void:
	for i: int in _childhood_buttons.size():
		_childhood_buttons[i].toggle_mode = true
		_childhood_buttons[i].button_pressed = (i == 0) == _childhood
	_skip_section.visible = not _childhood
	for id: StringName in _family_buttons:
		_family_buttons[id].button_pressed = id == _family
		_family_buttons[id].toggle_mode = true
	for id: StringName in _talent_buttons:
		_talent_buttons[id].toggle_mode = true
		_talent_buttons[id].button_pressed = id == _talent
	for id: StringName in _death_buttons:
		_death_buttons[id].toggle_mode = true
		_death_buttons[id].button_pressed = id == _death
	_description.text = _childhood_text() if _childhood else _family_text()
	_description.text += "\n\n" + _death_text()


func _childhood_text() -> String:
	return tr("Du beginnst als Kind im Klan-Dorf: laufen, sprechen, sammeln. Am Ende weckt der Klanlehrer deine Apertur – dann entscheidet der Talenttest, und du wählst deinen ersten Gu.")


func _family_text() -> String:
	var family: GuFamilyData = DataRegistry.family(_family)
	var member: GuData = family.member_for_rank(1)
	var text: String = "%s – %s\n%s" % [tr(member.display_name), tr(DataRegistry.gu_system().path_name(family.path)), tr(member.description)]
	if not member.lore.is_empty():
		text += "\n" + tr(member.lore)
	if _talent != TALENT_RANDOM:
		text += "\n" + tr(DataRegistry.progression().talent_flavor.get(_talent, ""))
	return text


func _death_text() -> String:
	match _death:
		&"hardcore":
			return tr("Hardcore: Stirbst du, ist der Spielstand verloren.")
		&"relaxed":
			return tr("Entspannt: Nach dem Tod verlierst du die Hälfte deiner Materialien.")
	return tr("Standard: Nach dem Tod liegen deine Materialien im Beutesack, 30 % Uressenz sind weg und deine Gu hungern.")


func _start() -> void:
	var b: BalanceData = Balance.values
	var talent: Dictionary = Formulas.roll_talent(b, randf() * 100.0, randf()) if _talent == TALENT_RANDOM else Formulas.talent_for_grade(b, _talent, randf())
	EventBus.new_game_requested.emit({
		"childhood": _childhood,
		"first_family": &"" if _childhood else _family,
		"talent_grade": talent["grade"],
		"apt": talent["apt"],
		"death_mode": _death,
	})
