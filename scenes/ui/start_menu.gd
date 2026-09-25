class_name StartMenu
extends Control
## Neues-Spiel-Menü: Kindheit (spielbar oder übersprungen), Todesmodus, Herkunft im Klan, Talent samt Extremer
## Physique, erster Gu (nur beim Überspringen) oder Weiterspielen.

const GROUP: StringName = &"start_menu"
const TALENT_RANDOM: StringName = &"random"
const DEATH_MODES: Array[StringName] = [&"standard", &"relaxed", &"hardcore"]
const DEFAULT_STANDING: StringName = &"neben"

var _family: StringName = &""
var _talent: StringName = TALENT_RANDOM
var _death: StringName = &"standard"
var _childhood: bool = true
var _childhood_buttons: Array[Button] = []
## Erster Gu und Talent: nur sichtbar, wenn die Kindheit übersprungen wird (sonst Talenttest im Spiel).
var _skip_section: VBoxContainer = null
var _family_buttons: Dictionary[StringName, Button] = {}
var _talent_buttons: Dictionary[StringName, Button] = {}
## Extreme Physique (nur beim Talent „Extrem“); leer = zufällig.
var _physique: StringName = &""
var _physique_grid: GridContainer = null
var _physique_buttons: Dictionary[StringName, Button] = {}
var _physique_text: Label = null
var _death_buttons: Dictionary[StringName, Button] = {}
var _standing: StringName = DEFAULT_STANDING
var _standing_buttons: Dictionary[StringName, Button] = {}
var _description: Label = null


func _ready() -> void:
	theme = UiTheme.get_theme()
	add_to_group(GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(StartBackground.new())
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
	_build_standing_section(column)
	_build_talent_section(column)
	_skip_section = VBoxContainer.new()
	_skip_section.add_theme_constant_override(&"separation", 12)
	column.add_child(_skip_section)
	_build_skip_section(_skip_section)
	_description = UiTheme.label("", 18, UiTheme.MUTED)
	column.add_child(_description)


## Herkunft im Klan (fraktionen.json → STANDING).
func _build_standing_section(column: VBoxContainer) -> void:
	column.add_child(UiTheme.label(tr("Herkunft"), 24, UiTheme.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 3
	column.add_child(grid)
	var standings: Array[Resource] = DataRegistry.all(&"standings").duplicate()
	# Vom Hauptzweig bis zur Waise (nach Ansehen im Klan).
	standings.sort_custom(func(a: Resource, b: Resource) -> bool: return (a as StandingData).home_merit > (b as StandingData).home_merit)
	for resource: Resource in standings:
		var standing: StandingData = resource as StandingData
		var button: Button = UiTheme.button(tr(standing.display_name), _choose_standing.bind(standing.id))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(button)
		_standing_buttons[standing.id] = button


func _choose_standing(id: StringName) -> void:
	_standing = id
	_refresh()


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


## Talent: Zufall (Talenttest), D–A oder Extrem mit einer der Zehn Extremen Physiques.
func _build_talent_section(column: VBoxContainer) -> void:
	column.add_child(UiTheme.label(tr("Talent (Aptitude)"), 24, UiTheme.ACCENT))
	var talents := HBoxContainer.new()
	column.add_child(talents)
	var grades: Array[StringName] = [TALENT_RANDOM, &"D", &"C", &"B", &"A", PhysiqueEffects.GRADE]
	for grade: StringName in grades:
		var text: String = tr("Zufall") if grade == TALENT_RANDOM else (tr("Extrem") if grade == PhysiqueEffects.GRADE else String(grade))
		var button: Button = UiTheme.button(text, _choose_talent.bind(grade))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		talents.add_child(button)
		_talent_buttons[grade] = button
	_physique_grid = GridContainer.new()
	_physique_grid.columns = 2
	column.add_child(_physique_grid)
	var zufall: Button = UiTheme.button(tr("Zufällige Physique"), _choose_physique.bind(&""), 56.0)
	zufall.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_physique_grid.add_child(zufall)
	_physique_buttons[&""] = zufall
	for physique: PhysiqueData in DataRegistry.progression().physiques:
		var button: Button = UiTheme.button("%s\n%s" % [tr(physique.display_name), tr(physique.path_label)], _choose_physique.bind(physique.id), 56.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_physique_grid.add_child(button)
		_physique_buttons[physique.id] = button
	_physique_text = UiTheme.label("", 17, UiTheme.MUTED)
	column.add_child(_physique_text)


func _choose_physique(id: StringName) -> void:
	_physique = id
	_refresh()


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
	_physique_grid.visible = _talent == PhysiqueEffects.GRADE
	_physique_text.visible = _physique_grid.visible
	_physique_text.text = _physique_effects()
	for id: StringName in _physique_buttons:
		_physique_buttons[id].toggle_mode = true
		_physique_buttons[id].button_pressed = id == _physique
	for id: StringName in _death_buttons:
		_death_buttons[id].toggle_mode = true
		_death_buttons[id].button_pressed = id == _death
	for id: StringName in _standing_buttons:
		_standing_buttons[id].toggle_mode = true
		_standing_buttons[id].button_pressed = id == _standing
	_description.text = _childhood_text() if _childhood else _family_text()
	_description.text += "\n\n" + _talent_text() + "\n\n" + _death_text()
	if DataRegistry.has(&"standings", _standing):
		_description.text += "\n\n" + Origins.describe(DataRegistry.standing(_standing))


func _childhood_text() -> String:
	return tr("Du beginnst als Kind im Klan-Dorf: laufen, sprechen, sammeln. Am Ende weckt der Klanlehrer deine Apertur – dann entscheidet der Talenttest, und du wählst deinen ersten Gu.")


func _family_text() -> String:
	var family: GuFamilyData = DataRegistry.family(_family)
	var member: GuData = family.member_for_rank(1)
	var text: String = "%s – %s\n%s" % [tr(member.display_name), tr(DataRegistry.gu_system().path_name(family.path)), tr(member.description)]
	if not member.lore.is_empty():
		text += "\n" + tr(member.lore)
	return text


func _talent_text() -> String:
	if _talent == TALENT_RANDOM:
		return tr("Talent: Zufall – der Talenttest entscheidet (mit winziger Chance auf eine Extreme Physique).")
	return tr(DataRegistry.progression().talent_flavor.get(_talent, ""))


func _physique_effects() -> String:
	if _physique == &"":
		return tr("Eine der Zehn Extremen Physiques wird ausgewürfelt. Alle haben 100 % Apertur, und ihre Wand verfeinert sich von selbst.")
	var physique: PhysiqueData = DataRegistry.progression().physique(_physique)
	return "%s (%s)\n• %s" % [tr(physique.display_name), tr(physique.path_label), "\n• ".join(PhysiqueEffects.effect_lines(_physique))]


func _death_text() -> String:
	match _death:
		&"hardcore":
			return tr("Hardcore: Stirbst du, ist der Spielstand verloren.")
		&"relaxed":
			return tr("Entspannt: Nach dem Tod verlierst du die Hälfte deiner Materialien.")
	return tr("Standard: Nach dem Tod liegen deine Materialien im Beutesack, 30 % Uressenz sind weg und deine Gu hungern.")


## Mit Kindheit und Talent „Zufall“ würfelt erst der Talenttest beim Erwachen (talent_grade bleibt leer).
func _start() -> void:
	var b: BalanceData = Balance.values
	var options: Dictionary = {"childhood": _childhood, "first_family": &"" if _childhood else _family, "death_mode": _death, "talent_grade": &"", "physique": &"", "standing": _standing}
	if not (_childhood and _talent == TALENT_RANDOM):
		var talent: Dictionary = Formulas.roll_talent(b, randf() * 100.0, randf()) if _talent == TALENT_RANDOM else Formulas.talent_for_grade(b, _talent, randf())
		options["talent_grade"] = talent["grade"]
		options["apt"] = talent["apt"]
		if talent["grade"] == PhysiqueEffects.GRADE:
			options["physique"] = _physique if _physique != &"" and _talent == PhysiqueEffects.GRADE else PhysiqueEffects.roll()
	EventBus.new_game_requested.emit(options)
