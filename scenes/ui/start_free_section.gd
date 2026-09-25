class_name StartFreeSection
extends VBoxContainer
## Startmenü „Freier Start“: Geburtsort (Gebiet und Siedlung), Rang 1–9 mit Stufe und – ab Rang 6 – Grad des Gesegneten
## Landes, Eingebung und Zahl der unsterblichen Gu. Liefert die Optionen für FreeStart.apply.

signal changed

const IMMORTAL_GU_COUNTS: Array[int] = [0, 1, 3, 6, 12]
const RANDOM: StringName = &""

var area_id: StringName = &"qing_mao"
var settlement_id: StringName = &""
var rank: int = 1
var stage: int = 0
var grade: int = 1
var inspiration: StringName = RANDOM
var immortal_gu: int = 3

var _area_buttons: Dictionary[StringName, Button] = {}
var _settlement_box: HFlowContainer = null
var _rank_buttons: Array[Button] = []
var _stage_buttons: Array[Button] = []
var _immortal_box: VBoxContainer = null
var _grade_buttons: Array[Button] = []
var _inspiration_buttons: Dictionary[StringName, Button] = {}
var _gu_buttons: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", 10)
	add_child(UiTheme.label(tr("Geburtsort"), 24, UiTheme.ACCENT))
	add_child(UiTheme.label(tr("Wo du zur Welt kommst – jedes Gebiet, auch Gesegnete Länder und abgeschottete Dimensionen (✦)."), 16, UiTheme.MUTED))
	_build_areas()
	_settlement_box = HFlowContainer.new()
	add_child(_settlement_box)
	add_child(UiTheme.label(tr("Kultivierung"), 24, UiTheme.ACCENT))
	_build_ranks()
	_immortal_box = VBoxContainer.new()
	_immortal_box.add_theme_constant_override(&"separation", 10)
	add_child(_immortal_box)
	_build_immortal()
	refresh()


func _build_areas() -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	add_child(grid)
	var areas: Array[Resource] = DataRegistry.all(&"areas").duplicate()
	areas.sort_custom(func(a: Resource, b: Resource) -> bool:
		var x: AreaData = a as AreaData
		var y: AreaData = b as AreaData
		if x.entry_rank() != y.entry_rank():
			return x.entry_rank() < y.entry_rank()
		return x.region < y.region if x.region != y.region else String(x.id) < String(y.id))
	for resource: Resource in areas:
		var area: AreaData = resource as AreaData
		var mark: String = " ✦" if not area.immortal.is_empty() else ""
		var button: Button = UiTheme.button(tr(area.display_name) + mark, _choose_area.bind(area.id), 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(button)
		_area_buttons[area.id] = button


func _build_ranks() -> void:
	var progression: ProgressionData = DataRegistry.progression()
	var ranks := GridContainer.new()
	ranks.columns = 5
	add_child(ranks)
	for r: int in range(1, 10):
		var button: Button = UiTheme.button(tr("Rang %d") % r, _choose_rank.bind(r), 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override(&"font_color", progression.rank_color(r).lerp(UiTheme.TEXT, 0.3))
		ranks.add_child(button)
		_rank_buttons.append(button)
	var stages := HBoxContainer.new()
	add_child(stages)
	for s: int in Balance.values.max_stage + 1:
		var button: Button = UiTheme.button(tr(progression.stage_name(s)), _choose_stage.bind(s), 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stages.add_child(button)
		_stage_buttons.append(button)


func _build_immortal() -> void:
	var system: ImmortalSystemData = DataRegistry.immortal()
	_immortal_box.add_child(UiTheme.label(tr("Gesegnetes Land"), 22, UiTheme.ACCENT))
	var grades := HBoxContainer.new()
	_immortal_box.add_child(grades)
	for i: int in system.land_grades.size():
		var button: Button = UiTheme.button(tr(String(system.land_grades[i].get("name", ""))), _choose_grade.bind(i), 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grades.add_child(button)
		_grade_buttons.append(button)
	_immortal_box.add_child(UiTheme.label(tr("Eingebung (Frage an Himmel und Erde)"), 22, UiTheme.ACCENT))
	var questions := GridContainer.new()
	questions.columns = 2
	_immortal_box.add_child(questions)
	var entries: Array = [{"id": RANDOM, "text": tr("Zufall")}]
	entries.append_array(system.inspirations)
	for entry: Dictionary in entries:
		var button: Button = UiTheme.button(tr(String(entry["text"])), _choose_inspiration.bind(entry["id"]), 52.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		questions.add_child(button)
		_inspiration_buttons[entry["id"]] = button
	_immortal_box.add_child(UiTheme.label(tr("Unsterbliche Gu zu Beginn (mit allen sterblichen Gliedern ihrer Killer Moves)"), 22, UiTheme.ACCENT))
	var counts := HBoxContainer.new()
	_immortal_box.add_child(counts)
	for count: int in IMMORTAL_GU_COUNTS:
		var button: Button = UiTheme.button(str(count), _choose_gu.bind(count), 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		counts.add_child(button)
		_gu_buttons.append(button)


func _choose_area(id: StringName) -> void:
	area_id = id
	settlement_id = &""
	refresh()


func _choose_settlement(id: StringName) -> void:
	settlement_id = id
	refresh()


func _choose_rank(value: int) -> void:
	rank = value
	refresh()


func _choose_stage(value: int) -> void:
	stage = value
	refresh()


func _choose_grade(value: int) -> void:
	grade = value
	refresh()


func _choose_inspiration(id: StringName) -> void:
	inspiration = id
	refresh()


func _choose_gu(count: int) -> void:
	immortal_gu = count
	refresh()


func refresh() -> void:
	for id: StringName in _area_buttons:
		_press(_area_buttons[id], id == area_id)
	_rebuild_settlements()
	for i: int in _rank_buttons.size():
		_press(_rank_buttons[i], i + 1 == rank)
	for i: int in _stage_buttons.size():
		_press(_stage_buttons[i], i == stage)
	_immortal_box.visible = rank >= Immortal.FIRST_RANK
	for i: int in _grade_buttons.size():
		_press(_grade_buttons[i], i == grade)
	for id: StringName in _inspiration_buttons:
		_press(_inspiration_buttons[id], id == inspiration)
	for i: int in _gu_buttons.size():
		_press(_gu_buttons[i], IMMORTAL_GU_COUNTS[i] == immortal_gu)
	changed.emit()


func _rebuild_settlements() -> void:
	for child: Node in _settlement_box.get_children():
		child.queue_free()
	var area: AreaData = DataRegistry.area(area_id)
	if area == null or area.settlements.is_empty():
		return
	var arrival: Button = UiTheme.button(tr("Ankunftspunkt"), _choose_settlement.bind(&""), 44.0)
	_press(arrival, settlement_id == &"")
	_settlement_box.add_child(arrival)
	for settlement: Dictionary in area.settlements:
		var sect: SectData = DataRegistry.sect(settlement["faction"])
		var title: String = tr(String(World.SETTLEMENT_TITLES.get(settlement["type"], "Dorf des %s"))) % (tr(sect.display_name) if sect != null else "")
		var button: Button = UiTheme.button(title, _choose_settlement.bind(settlement["id"]), 44.0)
		_press(button, settlement_id == settlement["id"])
		_settlement_box.add_child(button)


static func _press(button: Button, pressed: bool) -> void:
	button.toggle_mode = true
	button.set_pressed_no_signal(pressed)


func options() -> Dictionary:
	return {"rank": rank, "stage": stage, "grade": grade, "inspiration": inspiration, "immortal_gu": immortal_gu, "settlement": settlement_id}


func describe() -> String:
	var progression: ProgressionData = DataRegistry.progression()
	var area: AreaData = DataRegistry.area(area_id)
	var text: String = tr("Freier Start: geboren in %s als %s, %s.") % [tr(area.display_name) if area != null else String(area_id), tr(progression.rank_name(rank)), tr(progression.stage_name(stage))]
	if rank >= Immortal.FIRST_RANK:
		text += "\n" + tr("Unsterblicher mit %s, %d unsterblichen Gu und Dutzenden sterblichen Gu. Jede Perle %s ist für sterbliche Gu ein unerschöpfliches Meer an Uressenz.") % [
			tr(String(DataRegistry.immortal().grade(grade).get("name", ""))), immortal_gu, tr(Immortal.essence_name(rank))]
	return text
