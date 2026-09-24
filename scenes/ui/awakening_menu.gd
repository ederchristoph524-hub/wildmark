class_name AwakeningMenu
extends Control
## Ende der Kindheit: Der Klanlehrer weckt die Apertur – Talenttest (ausgewürfelt) und Wahl des ersten Gu.

signal closed
signal awakened(first_family: StringName, grade: StringName, apt: float)

var _grade: StringName = &"C"
var _apt: float = 50.0
var _family: StringName = &""
var _family_buttons: Dictionary[StringName, Button] = {}
var _description: Label = null


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.05, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(640.0, 0.0)
	column.add_theme_constant_override(&"separation", 12)
	center.add_child(column)
	var talent: Dictionary = Formulas.roll_talent(Balance.values, randf() * 100.0, randf())
	_grade = talent["grade"]
	_apt = talent["apt"]
	_family = DataRegistry.gu_system().start_families[0]
	_build(column)
	_refresh()


func _build(column: VBoxContainer) -> void:
	var progression: ProgressionData = DataRegistry.progression()
	column.add_child(UiTheme.label(tr("Das Erwachen"), 40, UiTheme.ACCENT))
	column.add_child(UiTheme.label(tr("Der Klanlehrer legt dir die Hand auf den Bauch. Ein Lichtstrahl sinkt in dich – deine Apertur öffnet sich."), 18, UiTheme.MUTED))
	column.add_child(UiTheme.label(tr("Talenttest: Grad %s (%d %%)") % [_grade, roundi(_apt)], 28, progression.talent_colors.get(_grade, UiTheme.ACCENT)))
	column.add_child(UiTheme.label(tr(progression.talent_flavor.get(_grade, "")), 17, UiTheme.MUTED))
	column.add_child(UiTheme.label(tr("Wähle deinen ersten Gu"), 24, UiTheme.ACCENT))
	var families := GridContainer.new()
	families.columns = 2
	column.add_child(families)
	for family_id: StringName in DataRegistry.gu_system().start_families:
		var family: GuFamilyData = DataRegistry.family(family_id)
		var member: GuData = family.member_for_rank(1)
		var button: Button = UiTheme.button("%s\n%s" % [tr(member.display_name), tr(family.role)], _choose.bind(family_id), 70.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		families.add_child(button)
		_family_buttons[family_id] = button
	_description = UiTheme.label("", 17, UiTheme.MUTED)
	column.add_child(_description)
	column.add_child(UiTheme.button(tr("Diesen Gu verfeinern"), confirm, 60.0))


func _choose(id: StringName) -> void:
	_family = id
	_refresh()


func _refresh() -> void:
	for id: StringName in _family_buttons:
		_family_buttons[id].button_pressed = id == _family
	var family: GuFamilyData = DataRegistry.family(_family)
	var member: GuData = family.member_for_rank(1)
	_description.text = "%s – %s\n%s" % [tr(member.display_name), tr(DataRegistry.gu_system().path_name(family.path)), tr(member.description)]


## Wahl bestätigen (auch für Tests): Kindheit endet mit gewähltem Gu und gewürfeltem Talent.
func confirm() -> void:
	awakened.emit(_family, _grade, _apt)
	closed.emit()
	queue_free()


## Wählt einen Gu per ID (für Tests und Tastatur).
func choose(id: StringName) -> void:
	_choose(id)
