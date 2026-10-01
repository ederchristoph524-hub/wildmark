class_name StartFreeSection
extends VBoxContainer
## Startmenü „Freier Start“: alles vor dem Spiel festlegen – Geburtsort (Gebiet und Siedlung), Kultivierung (Rang 1–9,
## Stufe, Talent in Prozent), Unsterblichkeit (Grad des Landes, Eingebung), Gu (StartFreeGu) und Leben (StartFreeLife:
## Sekte, Ruf, Dao, Vermögen, Tageszeit). Jedes Kapitel klappt auf; options() liefert alles für FreeStart.apply.

signal changed
## Talent im Regler geändert (Grad für die Talent-Knöpfe des Startmenüs).
signal apt_changed(grade: StringName)
signal start_requested

const RANDOM: StringName = &""
const APT_DEFAULT: int = 70

var area_id: StringName = &"qing_mao"
var settlement_id: StringName = &""
var rank: int = 1
var stage: int = 0
var apt: int = APT_DEFAULT
var grade: int = 1
var inspiration: StringName = RANDOM
var gu: StartFreeGu = null
var life: StartFreeLife = null

var _folds: Array[VBoxContainer] = []
var _immortal_fold: VBoxContainer = null
var _settlement_box: VBoxContainer = null
var _apt_slider: HSlider = null
var _apt_label: Label = null
var _rank_row: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", 8)
	add_child(UiTheme.label(tr("Freier Start – alles selbst festlegen"), 26, UiTheme.ACCENT))
	StartPick.hint(self, tr("Tippe ein Kapitel an, um es aufzuklappen. Was du nicht änderst, bleibt beim Standard. Herkunft, Talentgrad samt Extremer Physique und Todesmodus stehen oben."))
	_folds.append(StartPick.fold(self, tr("Geburtsort"), _build_birth, _birth_summary))
	_folds.append(StartPick.fold(self, tr("Kultivierung"), _build_cultivation, _cultivation_summary, true))
	_immortal_fold = StartPick.fold(self, tr("Unsterblichkeit"), _build_immortal, _immortal_summary)
	_folds.append(_immortal_fold)
	gu = StartFreeGu.new()
	gu.changed.connect(_emit)
	add_child(gu)
	life = StartFreeLife.new()
	life.changed.connect(_emit)
	add_child(life)
	var start: Button = UiTheme.button(tr("Mit diesen Einstellungen starten"), func() -> void: start_requested.emit(), 64.0)
	add_child(start)
	_apply_rank()


func _emit() -> void:
	for fold: VBoxContainer in _folds:
		StartPick.refresh_fold(fold)
	changed.emit()


# --- Geburtsort ---

func _birth_summary() -> String:
	var area: AreaData = DataRegistry.area(area_id)
	var text: String = tr(area.display_name) if area != null else String(area_id)
	if settlement_id != &"" and area != null:
		text += " · " + _settlement_title(area.settlement(settlement_id))
	return text


func _build_birth(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Jedes Gebiet, auch Gesegnete Länder und abgeschottete Dimensionen (✦). Danach: Ankunftspunkt oder eine Siedlung."))
	var areas: Array[Resource] = DataRegistry.all(&"areas").duplicate()
	areas.sort_custom(func(a: Resource, b: Resource) -> bool:
		var x: AreaData = a as AreaData
		var y: AreaData = b as AreaData
		if x.entry_rank() != y.entry_rank():
			return x.entry_rank() < y.entry_rank()
		return x.region < y.region if x.region != y.region else String(x.id) < String(y.id))
	var entries: Array = []
	for resource: Resource in areas:
		var area: AreaData = resource as AreaData
		entries.append({"id": area.id, "text": tr(area.display_name) + (" ✦" if not area.immortal.is_empty() else "")})
	var selected: Dictionary = {area_id: true}
	StartPick.grid(parent, 2, entries, selected, false, func() -> void:
		area_id = selected.keys()[0]
		settlement_id = &""
		_rebuild_settlements()
		_emit())
	_settlement_box = VBoxContainer.new()
	parent.add_child(_settlement_box)
	_rebuild_settlements()


func _rebuild_settlements() -> void:
	if _settlement_box == null:
		return
	for child: Node in _settlement_box.get_children():
		child.queue_free()
	var area: AreaData = DataRegistry.area(area_id)
	if area == null or area.settlements.is_empty():
		return
	var entries: Array = [{"id": &"", "text": tr("Ankunftspunkt")}]
	for settlement: Dictionary in area.settlements:
		entries.append({"id": settlement["id"], "text": _settlement_title(settlement)})
	var selected: Dictionary = {settlement_id: true}
	StartPick.grid(_settlement_box, 2, entries, selected, false, func() -> void:
		settlement_id = selected.keys()[0]
		_emit())


static func _settlement_title(settlement: Dictionary) -> String:
	if settlement.is_empty():
		return ""
	var sect: SectData = DataRegistry.sect(settlement["faction"])
	return Loc.t(String(World.SETTLEMENT_TITLES.get(settlement["type"], "Dorf des %s"))) % (Loc.t(sect.display_name) if sect != null else "")


# --- Kultivierung ---

func _cultivation_summary() -> String:
	var progression: ProgressionData = DataRegistry.progression()
	return "%s · %s · %s %d %%" % [tr(progression.rank_name(rank)), tr(progression.stage_name(stage)), tr("Talent"), apt]


func _build_cultivation(parent: VBoxContainer) -> void:
	var progression: ProgressionData = DataRegistry.progression()
	var ranks := GridContainer.new()
	ranks.columns = 5
	parent.add_child(ranks)
	for r: int in range(1, 10):
		var button: Button = UiTheme.button(tr("Rang %d") % r, _choose_rank.bind(r), StartPick.ROW_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override(&"font_color", progression.rank_color(r).lerp(UiTheme.TEXT, 0.3))
		ranks.add_child(button)
		_rank_row.append(button)
	var stages: Array = []
	var labels: Array = []
	for s: int in Balance.values.max_stage + 1:
		stages.append(s)
		labels.append(tr(progression.stage_name(s)))
	StartPick.presets(parent, stages, labels, stage, func(value: Variant) -> void:
		stage = int(value)
		_emit())
	_apt_label = UiTheme.label("", 18, UiTheme.ACCENT)
	parent.add_child(_apt_label)
	_apt_slider = HSlider.new()
	_apt_slider.min_value = 1
	_apt_slider.max_value = 100
	_apt_slider.step = 1
	_apt_slider.value = apt
	_apt_slider.custom_minimum_size = Vector2(0.0, 40.0)
	_apt_slider.value_changed.connect(func(value: float) -> void: set_apt(roundi(value)))
	parent.add_child(_apt_slider)
	StartPick.hint(parent, tr("100 % = Extreme Physique (welche, wählst du oben unter „Talent“). Das Talent bestimmt Apertur-Größe, Regeneration und wie viele Gu du tragen kannst."))
	_paint_ranks()
	_update_apt_label()


func _choose_rank(value: int) -> void:
	rank = value
	_apply_rank()
	_emit()


func _apply_rank() -> void:
	_paint_ranks()
	if _immortal_fold != null:
		_immortal_fold.visible = rank >= Immortal.FIRST_RANK
	if gu != null:
		gu.set_rank(rank)
	if life != null:
		life.set_rank(rank)


func _paint_ranks() -> void:
	for i: int in _rank_row.size():
		StartPick.press(_rank_row[i], i + 1 == rank)


## Talent in Prozent (1–100); meldet den passenden Grad.
func set_apt(value: int) -> void:
	apt = clampi(value, 1, 100)
	if _apt_slider != null and roundi(_apt_slider.value) != apt:
		_apt_slider.set_value_no_signal(apt)
	_update_apt_label()
	apt_changed.emit(grade_for_apt(apt))
	_emit()


func _update_apt_label() -> void:
	if _apt_label != null:
		_apt_label.text = tr("Talent: %d %% (Grad %s)") % [apt, tr(String(grade_for_apt(apt)))]


## Talentgrad zu einem Prozentwert (Spannen aus BalanceData; unter der kleinsten Spanne der niedrigste Grad).
static func grade_for_apt(value: int) -> StringName:
	var b: BalanceData = Balance.values
	for i: int in b.talent_grades.size():
		if value >= b.talent_pct_min[i] and value <= b.talent_pct_max[i]:
			return StringName(b.talent_grades[i])
	return StringName(b.talent_grades[b.talent_grades.size() - 1])


## Mitte der Spanne eines Grades (für die Talent-Knöpfe des Startmenüs).
static func apt_for_grade(talent: StringName) -> int:
	var b: BalanceData = Balance.values
	var index: int = b.talent_grades.find(String(talent))
	if index < 0:
		return APT_DEFAULT
	return floori((b.talent_pct_min[index] + b.talent_pct_max[index]) / 2.0)


# --- Unsterblichkeit ---

func _immortal_summary() -> String:
	var name_text: String = tr(String(DataRegistry.immortal().grade(grade).get("name", "")))
	return "%s · %s" % [name_text, tr("Eingebung zufällig") if inspiration == RANDOM else tr("Eingebung gewählt")]


func _build_immortal(parent: VBoxContainer) -> void:
	var system: ImmortalSystemData = DataRegistry.immortal()
	parent.add_child(UiTheme.label(tr("Gesegnetes Land"), 18, UiTheme.ACCENT))
	StartPick.hint(parent, tr("Der Grad bestimmt Größe, Zeitfluss, Essenzsteine am Tag und deine Startperlen."))
	var grades: Array = []
	var labels: Array = []
	for i: int in system.land_grades.size():
		grades.append(i)
		labels.append(tr(String(system.land_grades[i].get("name", ""))))
	StartPick.presets(parent, grades, labels, grade, func(value: Variant) -> void:
		grade = int(value)
		_emit(), true)
	parent.add_child(UiTheme.label(tr("Eingebung (Frage an Himmel und Erde)"), 18, UiTheme.ACCENT))
	var entries: Array = [{"id": RANDOM, "text": tr("Zufall")}]
	for entry: Dictionary in system.inspirations:
		entries.append({"id": entry["id"], "text": tr(String(entry["text"]))})
	var selected: Dictionary = {inspiration: true}
	var container: GridContainer = StartPick.grid(parent, 1, entries, selected, false, func() -> void:
		inspiration = selected.keys()[0]
		_emit())
	for button: Node in container.get_children():
		(button as Button).clip_text = false
		(button as Button).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# --- Ergebnis ---

func options() -> Dictionary:
	var result: Dictionary = {"rank": rank, "stage": stage, "grade": grade, "inspiration": inspiration, "settlement": settlement_id, "apt": apt}
	result.merge(gu.options(), true)
	result.merge(life.options(), true)
	return result


func describe() -> String:
	var progression: ProgressionData = DataRegistry.progression()
	var text: String = tr("Freier Start: geboren in %s als %s, %s, Talent %d %%.") % [_birth_summary(), tr(progression.rank_name(rank)), tr(progression.stage_name(stage)), apt]
	if rank >= Immortal.FIRST_RANK:
		text += "\n" + tr("Unsterblicher mit %s. Jede Perle %s ist für sterbliche Gu ein unerschöpfliches Meer an Uressenz.") % [
			tr(String(DataRegistry.immortal().grade(grade).get("name", ""))), tr(Immortal.essence_name(rank))]
	for extra: String in [gu.describe() if gu != null else "", life.describe() if life != null else ""]:
		if extra != "":
			text += "\n" + extra
	return text
