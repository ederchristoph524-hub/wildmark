class_name StartFreeLife
extends VBoxContainer
## Freier Start, Kapitel Leben: Sekte und Sektenrang, Ruf (Ansehen, Berüchtigtheit), Dao (Hauptpfad und Beherrschung),
## Vermögen (Ursteine, Unsterblichen-Essenzsteine, Perlen) und Tageszeit der Geburt.

signal changed

const NONE: StringName = &""
const DEFAULT: int = -1
const RENOWN: Array[int] = [0, 100, 500, 2000, 10000]
const PRIMEVAL: Array[int] = [DEFAULT, 0, 100, 1000, 10000, 100000]
const IMMORTAL_STONES: Array[int] = [DEFAULT, 0, 100, 1000, 10000]
const BEADS: Array[int] = [0, 10, 100, 1000]
## Tageszeit 0–1 (Tag beginnt um 6 Uhr): Morgen, Mittag, Abend, Nacht.
const TIMES: Array[float] = [0.08, 0.25, 0.5, 0.75]
const TIME_NAMES: Array[String] = ["Morgen", "Mittag", "Abend", "Nacht"]

var sect: Dictionary = {NONE: true}
var sect_rank: int = 0
var fame: int = 0
var infamy: int = 0
var dao_path: Dictionary = {NONE: true}
var dao_level: int = 0
var stones: int = DEFAULT
var immortal_stones: int = DEFAULT
var beads: int = 0
var time: float = TIMES[0]
var rank: int = 1

var _folds: Array[VBoxContainer] = []
var _immortal_rows: Array[Control] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", 6)
	_folds.append(StartPick.fold(self, tr("Sekte"), _build_sect, func() -> String:
		return _sect_name() + ("" if sect.has(NONE) else " · " + tr(DataRegistry.progression().sect_rank(sect_rank).display_name))))
	_folds.append(StartPick.fold(self, tr("Ruf"), _build_renown, func() -> String:
		return tr("Ansehen %s · Berüchtigtheit %s") % [StartPick.short_number(fame), StartPick.short_number(infamy)]))
	_folds.append(StartPick.fold(self, tr("Dao"), _build_dao, func() -> String:
		return "%s · %s" % [_path_name(), tr(DataRegistry.gu_system().attain_names[dao_level])]))
	_folds.append(StartPick.fold(self, tr("Vermögen"), _build_wealth, func() -> String:
		return tr("Ursteine %s") % (tr("Standard") if stones == DEFAULT else StartPick.short_number(stones))))
	_folds.append(StartPick.fold(self, tr("Tageszeit"), _build_time, func() -> String: return tr(TIME_NAMES[TIMES.find(time)])))


func set_rank(value: int) -> void:
	rank = value
	for row: Control in _immortal_rows:
		if is_instance_valid(row):
			row.visible = rank >= Immortal.FIRST_RANK


func _changed() -> void:
	for fold: VBoxContainer in _folds:
		StartPick.refresh_fold(fold)
	changed.emit()


func _sect_name() -> String:
	if sect.has(NONE):
		return tr("keine")
	var data: SectData = DataRegistry.sect(sect.keys()[0])
	return tr(data.display_name) if data != null else String(sect.keys()[0])


func _path_name() -> String:
	return tr("wie erster Gu") if dao_path.has(NONE) else tr(DataRegistry.gu_system().path_name(dao_path.keys()[0]))


func _build_sect(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Du beginnst als Mitglied – mit Beitrittsgeschenk, Verdienst des gewählten Rangs und ab Kernschüler dem Signatur-Gu der Sekte."))
	var entries: Array = [{"id": NONE, "text": tr("keine Sekte")}]
	for resource: Resource in DataRegistry.all(&"sects"):
		var data: SectData = resource as SectData
		entries.append({"id": data.id, "text": tr(data.display_name)})
	StartPick.grid(parent, 2, entries, sect, false, _changed)
	var ranks: Array = []
	var labels: Array = []
	for i: int in DataRegistry.progression().sect_ranks.size():
		ranks.append(i)
		labels.append(tr(DataRegistry.progression().sect_ranks[i].display_name))
	parent.add_child(UiTheme.label(tr("Rang in der Sekte"), 18, UiTheme.ACCENT))
	StartPick.presets(parent, ranks, labels, sect_rank, func(value: Variant) -> void:
		sect_rank = int(value)
		_changed(), true)


func _build_renown(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Ansehen öffnet rechtschaffene Sekten, Berüchtigtheit macht dich zum Dämon: Kopfgeldjäger jagen dich, dämonische Sekten nehmen dich auf. Auf Rang 9 entscheidet der Ruf über Unsterblichen oder Dämonischen Ehrwürdigen."))
	var labels: Array = []
	for value: int in RENOWN:
		labels.append(StartPick.short_number(value))
	parent.add_child(UiTheme.label(tr("Ansehen"), 18, UiTheme.ACCENT))
	StartPick.presets(parent, RENOWN, labels, fame, func(value: Variant) -> void:
		fame = int(value)
		_changed())
	parent.add_child(UiTheme.label(tr("Berüchtigtheit"), 18, UiTheme.DANGER))
	StartPick.presets(parent, RENOWN, labels, infamy, func(value: Variant) -> void:
		infamy = int(value)
		_changed())


func _build_dao(parent: VBoxContainer) -> void:
	var system: GuSystemData = DataRegistry.gu_system()
	StartPick.hint(parent, tr("Der Hauptpfad formt deine Apertur als Unsterblicher und deinen Ehrwürdigen-Titel. Beherrschung senkt Kosten und Abklingzeit seiner Gu."))
	var paths: Array = system.path_names.keys()
	paths.sort_custom(func(a: StringName, b: StringName) -> bool: return tr(system.path_name(a)) < tr(system.path_name(b)))
	var entries: Array = [{"id": NONE, "text": tr("wie erster Gu")}]
	for path: StringName in paths:
		entries.append({"id": path, "text": tr(system.path_name(path)), "color": system.path_color(path)})
	StartPick.grid(parent, 3, entries, dao_path, false, _changed)
	parent.add_child(UiTheme.label(tr("Beherrschung"), 18, UiTheme.ACCENT))
	var levels: Array = []
	var labels: Array = []
	for i: int in system.attain_names.size():
		levels.append(i)
		labels.append(tr(system.attain_names[i]))
	StartPick.presets(parent, levels, labels, dao_level, func(value: Variant) -> void:
		dao_level = int(value)
		_changed(), true)


func _build_wealth(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("„Standard“ richtet sich nach deinem Rang."))
	parent.add_child(UiTheme.label(tr("Ursteine"), 18, UiTheme.ACCENT))
	StartPick.presets(parent, PRIMEVAL, _amount_labels(PRIMEVAL), stones, func(value: Variant) -> void:
		stones = int(value)
		_changed())
	var immortal_box := VBoxContainer.new()
	parent.add_child(immortal_box)
	_immortal_rows.append(immortal_box)
	immortal_box.add_child(UiTheme.label(tr("Unsterblichen-Essenzsteine"), 18, UiTheme.ACCENT))
	StartPick.presets(immortal_box, IMMORTAL_STONES, _amount_labels(IMMORTAL_STONES), immortal_stones, func(value: Variant) -> void:
		immortal_stones = int(value)
		_changed())
	immortal_box.add_child(UiTheme.label(tr("Zusätzliche Perlen"), 18, UiTheme.ACCENT))
	StartPick.presets(immortal_box, BEADS, _amount_labels(BEADS), beads, func(value: Variant) -> void:
		beads = int(value)
		_changed())
	set_rank(rank)


static func _amount_labels(values: Array[int]) -> Array:
	var labels: Array = []
	for value: int in values:
		labels.append(Loc.t("Standard") if value == DEFAULT else StartPick.short_number(value))
	return labels


func _build_time(parent: VBoxContainer) -> void:
	var labels: Array = []
	for name_text: String in TIME_NAMES:
		labels.append(tr(name_text))
	StartPick.presets(parent, TIMES, labels, time, func(value: Variant) -> void:
		time = float(value)
		_changed())


func options() -> Dictionary:
	return {
		"sect": sect.keys()[0], "sect_rank": sect_rank, "fame": fame, "infamy": infamy,
		"dao_path": dao_path.keys()[0], "dao_level": dao_level,
		"stones": stones, "immortal_stones": immortal_stones, "beads": beads, "time": time,
	}


func describe() -> String:
	var parts: PackedStringArray = []
	if not sect.has(NONE):
		parts.append(tr("Sekte: %s") % _sect_name())
	if fame > 0 or infamy > 0:
		parts.append(tr("Ansehen %d, Berüchtigtheit %d") % [fame, infamy])
	if not dao_path.has(NONE) or dao_level > 0:
		parts.append(tr("Dao: %s, %s") % [_path_name(), tr(DataRegistry.gu_system().attain_names[dao_level])])
	return " · ".join(parts)
