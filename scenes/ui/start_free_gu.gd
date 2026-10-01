class_name StartFreeGu
extends VBoxContainer
## Freier Start, Kapitel Gu: erster Gu aus allen 35 Familien, weitere sterbliche Gu (gezielt und/oder zufällig),
## Körper- und Hilfs-Gu sowie – ab Rang 6 – unsterbliche Gu gezielt nach Pfad oder zufällig.

signal changed

const MORTAL_RANDOM: Array[int] = [0, 4, 8, 16, 34]
const IMMORTAL_RANDOM: Array[int] = [0, 1, 3, 6, 12]
const ALL_PATHS: StringName = &""

var first_family: Dictionary = {}
var mortal: Dictionary = {}
var mortal_random: int = 4
var body: Dictionary = {}
var support: Dictionary = {}
var immortal: Dictionary = {}
var immortal_random: int = 3
## Aktueller Rang aus dem Kapitel Kultivierung (steuert, was angezeigt wird).
var rank: int = 1

var _folds: Array[VBoxContainer] = []
var _immortal_fold: VBoxContainer = null
var _immortal_list: VBoxContainer = null
var _filter: StringName = ALL_PATHS


func _ready() -> void:
	add_theme_constant_override(&"separation", 6)
	first_family[DataRegistry.gu_system().start_families[0]] = true
	_folds.append(StartPick.fold(self, tr("Erster Gu"), _build_first, func() -> String: return _family_name(first_family.keys()[0])))
	_folds.append(StartPick.fold(self, tr("Weitere sterbliche Gu"), _build_mortal, func() -> String:
		return tr("%d gewählt + %d zufällig") % [mortal.size(), mortal_random]))
	_folds.append(StartPick.fold(self, tr("Körper-Gu"), _build_body, func() -> String: return tr("%d gewählt") % body.size()))
	_folds.append(StartPick.fold(self, tr("Hilfs-Gu"), _build_support, func() -> String: return tr("%d gewählt") % support.size()))
	_immortal_fold = StartPick.fold(self, tr("Unsterbliche Gu"), _build_immortal, func() -> String:
		return tr("%d gewählt + %d zufällig") % [immortal.size(), immortal_random])
	_folds.append(_immortal_fold)
	set_rank(rank)


func set_rank(value: int) -> void:
	rank = value
	if _immortal_fold != null:
		_immortal_fold.visible = rank >= Immortal.FIRST_RANK


func _changed() -> void:
	for fold: VBoxContainer in _folds:
		StartPick.refresh_fold(fold)
	changed.emit()


static func _family_name(id: StringName) -> String:
	var family: GuFamilyData = DataRegistry.family(id)
	return Loc.t(family.display_name) if family != null else String(id)


func _family_entries() -> Array:
	var system: GuSystemData = DataRegistry.gu_system()
	var families: Array[Resource] = DataRegistry.all(&"families").duplicate()
	families.sort_custom(func(a: Resource, b: Resource) -> bool:
		var x: GuFamilyData = a as GuFamilyData
		var y: GuFamilyData = b as GuFamilyData
		return String(x.path) < String(y.path) if x.path != y.path else tr(x.display_name) < tr(y.display_name))
	var entries: Array = []
	for resource: Resource in families:
		var family: GuFamilyData = resource as GuFamilyData
		entries.append({"id": family.id, "text": "%s · %s" % [tr(family.display_name), tr(system.path_name(family.path))], "color": system.path_color(family.path)})
	return entries


func _build_first(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Jede Familie ist erlaubt. Der Gu wächst auf deinen Rang mit (ab Rang 5 das Rang-5-Mitglied) und bestimmt deinen Hauptpfad, wenn du unter „Dao“ nichts anderes wählst."))
	StartPick.grid(parent, 2, _family_entries(), first_family, false, _changed)


func _build_mortal(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Gezielt: jede Familie, die du antippst, kommt auf deinem Rang dazu. Zufällig: so viele weitere Familien. Die Apertur trägt nur begrenzt viele Gu (als Unsterblicher über hundert)."))
	var labels: Array = []
	for count: int in MORTAL_RANDOM:
		labels.append(tr("zufällig %d") % count if count > 0 else tr("keine zufälligen"))
	StartPick.presets(parent, MORTAL_RANDOM, labels, mortal_random, func(value: Variant) -> void:
		mortal_random = int(value)
		_changed())
	StartPick.grid(parent, 2, _family_entries(), mortal, true, _changed)


func _build_body(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Körper-Gu sind eingeprägt: kein Futter, kein Unterhalt, kein Platz."))
	var entries: Array = []
	for resource: Resource in DataRegistry.all(&"body"):
		var data: BodyGuData = resource as BodyGuData
		entries.append({"id": data.id, "text": tr("%s (R%d)") % [tr(data.display_name), data.rank]})
	StartPick.grid(parent, 2, entries, body, true, _changed)


func _build_support(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Hilfs-Gu wirken von selbst, brauchen aber Futter und Unterhalt (Futter für einige Tage liegt bei)."))
	var system: GuSystemData = DataRegistry.gu_system()
	var entries: Array = []
	for resource: Resource in DataRegistry.all(&"support"):
		var data: SupportGuData = resource as SupportGuData
		entries.append({"id": data.id, "text": tr("%s (R%d)") % [tr(data.display_name), data.rank], "color": system.path_color(data.path)})
	StartPick.grid(parent, 2, entries, support, true, _changed)


func _build_immortal(parent: VBoxContainer) -> void:
	StartPick.hint(parent, tr("Gezielt nach Pfad wählen und/oder zufällige dazunehmen (bevorzugt im Hauptpfad, samt allen sterblichen Gliedern ihrer Killer Moves). Gu über deinem Rang besitzt du, kannst sie aber erst ab ihrem Rang einsetzen."))
	var labels: Array = []
	for count: int in IMMORTAL_RANDOM:
		labels.append(tr("zufällig %d") % count if count > 0 else tr("keine zufälligen"))
	StartPick.presets(parent, IMMORTAL_RANDOM, labels, immortal_random, func(value: Variant) -> void:
		immortal_random = int(value)
		_changed())
	var system: GuSystemData = DataRegistry.gu_system()
	var counts: Dictionary = {}
	for resource: Resource in DataRegistry.all(&"immortal_gu"):
		var data: ImmortalGuData = resource as ImmortalGuData
		if data.kind != ImmortalGuData.KIND_CONCEPT:
			counts[data.path] = int(counts.get(data.path, 0)) + 1
	var paths: Array = counts.keys()
	paths.sort_custom(func(a: StringName, b: StringName) -> bool: return counts[a] > counts[b])
	var filters := HFlowContainer.new()
	parent.add_child(filters)
	var filter_ids: Array = [ALL_PATHS]
	filter_ids.append_array(paths)
	for path: StringName in filter_ids:
		var text: String = tr("alle") if path == ALL_PATHS else "%s (%d)" % [tr(system.path_name(path)), counts[path]]
		var button: Button = UiTheme.button(text, func() -> void:
			_filter = path
			for child: Node in filters.get_children():
				StartPick.press(child as Button, child.get_meta(&"path") == _filter)
			_fill_immortal(), StartPick.ROW_HEIGHT)
		button.set_meta(&"path", path)
		if path != ALL_PATHS:
			button.add_theme_color_override(&"font_color", system.path_color(path).lerp(UiTheme.TEXT, 0.35))
		StartPick.press(button, path == _filter)
		filters.add_child(button)
	_immortal_list = VBoxContainer.new()
	parent.add_child(_immortal_list)
	_fill_immortal()


func _fill_immortal() -> void:
	for child: Node in _immortal_list.get_children():
		child.queue_free()
	var system: GuSystemData = DataRegistry.gu_system()
	var list: Array[Resource] = DataRegistry.all(&"immortal_gu").duplicate()
	list.sort_custom(func(a: Resource, b: Resource) -> bool:
		var x: ImmortalGuData = a as ImmortalGuData
		var y: ImmortalGuData = b as ImmortalGuData
		return x.rank < y.rank if x.rank != y.rank else tr(x.display_name) < tr(y.display_name))
	var entries: Array = []
	for resource: Resource in list:
		var data: ImmortalGuData = resource as ImmortalGuData
		if data.kind == ImmortalGuData.KIND_CONCEPT or (_filter != ALL_PATHS and data.path != _filter):
			continue
		var kind: String = tr("passiv") if data.kind != ImmortalGuData.KIND_ACTIVE else ""
		entries.append({"id": data.id, "text": "R%d %s%s" % [data.rank, tr(data.display_name), " · " + kind if kind != "" else ""], "color": system.path_color(data.path)})
	StartPick.grid(_immortal_list, 2, entries, immortal, true, _changed)


func options() -> Dictionary:
	return {
		"first_family": first_family.keys()[0], "mortal": _ids(mortal), "mortal_random": mortal_random,
		"body": _ids(body), "support": _ids(support), "immortal_ids": _ids(immortal), "immortal_gu": immortal_random,
	}


static func _ids(selection: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: Variant in selection:
		result.append(StringName(id))
	return result


func describe() -> String:
	var parts: PackedStringArray = [tr("Erster Gu: %s") % _family_name(first_family.keys()[0])]
	parts.append(tr("%d sterbliche Gu gewählt, %d zufällig") % [mortal.size(), mortal_random])
	if not body.is_empty() or not support.is_empty():
		parts.append(tr("%d Körper-, %d Hilfs-Gu") % [body.size(), support.size()])
	if rank >= Immortal.FIRST_RANK:
		parts.append(tr("%d unsterbliche Gu gewählt, %d zufällig") % [immortal.size(), immortal_random])
	return " · ".join(parts)
