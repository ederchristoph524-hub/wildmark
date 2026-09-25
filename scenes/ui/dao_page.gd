class_name DaoPage
extends RefCounted
## Seite „Dao" im Gu-Menü: Markierungen und Beherrschung je Pfad, dazu Kosten, Abklingzeit und Pfadkonflikte.


static func build() -> Control:
	var column := VBoxContainer.new()
	var system: GuSystemData = DataRegistry.gu_system()
	column.add_child(UiTheme.label(Loc.t("Dao-Markierungen"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Jeder Gu-Einsatz prägt Markierungen in seinen Pfad. Beherrschung senkt Essenzkosten und Abklingzeit; Markierungen gegensätzlicher Pfade verteuern ihn. Spezialisierung wird belohnt."), 16, UiTheme.MUTED))
	var paths: Array = GameState.dao.keys()
	paths.sort_custom(func(a: StringName, b: StringName) -> bool: return Dao.marks(a) > Dao.marks(b))
	if paths.is_empty():
		column.add_child(UiTheme.label(Loc.t("Noch keine Markierungen – setze Gu ein."), 17))
	for path: StringName in paths:
		column.add_child(_row(system, path))
	if not SectLife.is_member():
		return column
	column.add_child(UiTheme.label(Loc.t("Sekte"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(SectLife.status_line(), 17, SectLife.current_rank().color))
	return column


static func _row(system: GuSystemData, path: StringName) -> Control:
	var level: int = Dao.attain(path)
	var next: float = Dao.next_need(path)
	var progress: String = "%d / %d" % [roundi(Dao.marks(path)), roundi(next)] if next > 0.0 else str(roundi(Dao.marks(path)))
	var text: String = "%s · %s · %s" % [Loc.t(system.path_name(path)), Loc.t(system.attain_names[level]), progress]
	var effects: String = Loc.t("Kosten ×%.2f · Abklingzeit ×%.2f") % [Dao.cost_mult(path), Dao.cooldown_mult(path)]
	var conflict: float = Dao.conflict(path)
	if conflict > 0.0:
		effects += " · " + Loc.t("Konflikt +%d %%") % roundi(conflict * Balance.values.dao_conflict_cost * 100.0)
	var row := VBoxContainer.new()
	row.add_child(UiTheme.label(text, 18, system.attain_colors[level].lerp(system.path_color(path), 0.3)))
	row.add_child(UiTheme.label(effects, 15, UiTheme.MUTED))
	return row
