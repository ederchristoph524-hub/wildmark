class_name ImmortalPage
extends RefCounted
## Seite „Unsterblich“ im Gu-Menü (docs/UNSTERBLICH.md): vor dem Aufstieg die drei Qi, das Gleichgewicht und der
## voraussichtliche Grad samt Aufstieg; danach Rang, Essenz, Perlen, Kalamitäten, Durchbruch, Gesegnetes Land und Apertur.

const QI_HEAVEN: Color = Color(0.62, 0.8, 1.0)
const QI_EARTH: Color = Color(0.85, 0.65, 0.36)
const QI_HUMAN: Color = Color(0.95, 0.5, 0.55)


static func build(player: Player, refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	if Immortal.is_immortal():
		_immortal_status(column)
		_calamity_block(column)
		_breakthrough_block(column, refresh)
		_land_block(column, refresh)
	else:
		_ascension_block(column, player, refresh)
	_essence_legend(column)
	return column


# --- vor dem Aufstieg ---

static func _ascension_block(column: VBoxContainer, player: Player, refresh: Callable) -> void:
	column.add_child(UiTheme.label(Loc.t("Der Weg zur Unsterblichkeit"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Auf Rang 5, Höchststufe, zerbricht der Gu-Meister seine sterbliche Apertur. Himmel, Erde und Mensch – drei Qi – formen daraus ein Gesegnetes Land. Je mehr Qi und je ausgewogener, desto höher sein Grad. Wer zu einseitig sammelt, wird verworfen."), 16, UiTheme.MUTED))
	var state: ImmortalState = GameState.immortal
	var qi_max: float = float(ImmortalAscension.config().get("qi_max", 1000.0))
	_qi_row(column, Loc.t("Himmels-Qi (hoch oben kultivieren, Himmels-Qi-Kristalle)"), state.heaven_qi, qi_max, QI_HEAVEN)
	_qi_row(column, Loc.t("Erd-Qi (in Tälern, an Adern, Erd-Qi-Kristalle)"), state.earth_qi, qi_max, QI_EARTH)
	_qi_row(column, Loc.t("Menschen-Qi (Ruf, Siege, Dao, Gu, Erbschaften)"), ImmortalAscension.human_qi(), qi_max, QI_HUMAN)
	var grade: int = ImmortalAscension.predicted_grade()
	var grade_color: Color = UiTheme.DANGER if grade < 0 else DataRegistry.immortal().grade(grade).get("color", UiTheme.ACCENT)
	column.add_child(UiTheme.label(Loc.t("Gleichgewicht %d %% · Wert %d · voraussichtlich: %s") % [
		roundi(ImmortalAscension.balance() * 100.0), roundi(ImmortalAscension.score()), ImmortalAscension.grade_name(grade)], 18, grade_color))
	if GameState.physique != &"":
		column.add_child(UiTheme.label(Loc.t("Deine Extreme Physique zerbricht beim Aufstieg – Himmel und Erde schenken dir dafür ein Land höchsten Grades."), 16, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Kultiviere auf der Höchststufe (M), um Qi zu sammeln: auf Gipfeln Himmels-Qi, in der Tiefe und an Urstein-Adern Erd-Qi."), 16, UiTheme.MUTED))
	var crystals: int = GameState.item_count(&"himmelsqi") + GameState.item_count(&"erdqi")
	if crystals > 0:
		var on_absorb: Callable = func() -> void:
			var used: int = ImmortalAscension.absorb_crystals()
			EventBus.message.emit(Loc.t("%d Qi-Kristalle aufgenommen.") % used, QI_HEAVEN)
			refresh.call()
		column.add_child(UiTheme.button(Loc.t("Qi-Kristalle aufnehmen (%d)") % crystals, on_absorb))
	var reason: String = ImmortalAscension.blocked_reason(player)
	if reason != "":
		column.add_child(UiTheme.label(reason, 16, UiTheme.MUTED))
		return
	var on_ascend: Callable = func() -> void:
		refresh.call()
		ImmortalAscension.start(player)
	column.add_child(UiTheme.button(Loc.t("Aufstieg wagen – Erdkalamität und Himmlische Trübsal"), on_ascend))


static func _qi_row(column: VBoxContainer, title: String, value: float, qi_max: float, color: Color) -> void:
	column.add_child(UiTheme.label("%s: %d" % [title, roundi(value)], 16, color))
	var bar: ProgressBar = UiTheme.bar(color)
	bar.max_value = qi_max
	bar.value = value
	bar.custom_minimum_size.y = 14.0
	column.add_child(bar)


# --- als Unsterblicher ---

static func _immortal_status(column: VBoxContainer) -> void:
	var state: ImmortalState = GameState.immortal
	var color: Color = Immortal.essence_color(GameState.rank)
	var progression: ProgressionData = DataRegistry.progression()
	column.add_child(UiTheme.label("%s · %s" % [Loc.t(progression.rank_name(GameState.rank)), Loc.t(progression.stage_name(GameState.stage))], 24, color))
	if state.venerable_title != "":
		column.add_child(UiTheme.label(state.venerable_title, 20, color))
	column.add_child(UiTheme.label(Loc.t("Jede Perle %s ist ein Meer aus Uressenz: sterbliche Gu kosten dich fast nichts mehr. Unsterbliche Gu und Unsterblichen-Killer-Moves zahlst du in Perlen.") % Loc.t(Immortal.essence_name(GameState.rank)), 16, UiTheme.MUTED))
	var ranks: Array = state.beads.keys()
	ranks.sort()
	for rank: int in ranks:
		if state.beads[rank] > 0.0:
			column.add_child(UiTheme.label(Loc.t("%s: %.2f Perlen") % [Loc.t(Immortal.essence_name(rank)), state.beads[rank]], 18, Immortal.essence_color(rank)))
	if state.bead_total() <= 0.0:
		column.add_child(UiTheme.label(Loc.t("Keine Perlen mehr! Verdichte Essenzsteine in deiner Apertur (Landgeist)."), 17, UiTheme.DANGER))
	var inspiration: Dictionary = {}
	for entry: Dictionary in DataRegistry.immortal().inspirations:
		if entry["id"] == state.inspiration:
			inspiration = entry
	if not inspiration.is_empty():
		column.add_child(UiTheme.label(Loc.t("Eingebung: %s") % Loc.t(inspiration["text"]), 16, UiTheme.ACCENT))
	var power: String = Loc.t("Unsterblichen-Kraft ×%.0f · +%d Leben · +%d Grundschaden · gegen Sterbliche ×%.0f Schaden") % [
		Immortal.power(GameState.rank), roundi(Immortal.base_hp(GameState.rank)), roundi(Immortal.flat_damage(GameState.rank)),
		Immortal.damage_mult(GameState.rank, Immortal.MORTAL_PEAK)]
	column.add_child(UiTheme.label(power, 16))


static func _calamity_block(column: VBoxContainer) -> void:
	var state: ImmortalState = GameState.immortal
	column.add_child(UiTheme.label(Loc.t("Kalamitäten"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Himmel und Erde dulden kein zweites Reich: In festen Abständen treffen Kalamitäten deine Apertur – nachts, angekündigt am Morgen. Bist du dabei, kämpfst du um dein Land; bist du fort, verlierst du Erträge. Jede überstandene Kalamität bringt Dao-Markierungen, drei ergeben eine Stufe."), 16, UiTheme.MUTED))
	var per_stage: int = int(Immortal.rank_info().get("per_stage", 3))
	column.add_child(UiTheme.label(Loc.t("Überstanden auf diesem Rang: %d (je Stufe %d)") % [state.calamities_survived, per_stage], 17))
	var bar: ProgressBar = UiTheme.bar(Immortal.essence_color(GameState.rank))
	bar.max_value = 1.0
	bar.value = Immortal.stage_progress()
	bar.custom_minimum_size.y = 12.0
	column.add_child(bar)
	if state.pending_calamity != &"":
		var info: Dictionary = DataRegistry.immortal().calamity(state.pending_calamity)
		column.add_child(UiTheme.label(Loc.t("%s naht – heute Nacht! %s") % [Loc.t(String(info.get("name", ""))), Loc.t(String(info.get("warning", "")))], 17, info.get("color", UiTheme.DANGER)))
	elif state.next_calamity_day >= 0:
		var next_id: StringName = ImmortalProgress.next_calamity()
		var next_name: String = String(DataRegistry.immortal().calamity(next_id).get("name", ""))
		column.add_child(UiTheme.label(Loc.t("Nächste Kalamität: %s, angekündigt an Tag %d (heute: %d).") % [Loc.t(next_name), state.next_calamity_day, GameState.day], 17))


static func _breakthrough_block(column: VBoxContainer, refresh: Callable) -> void:
	column.add_child(UiTheme.label(Loc.t("Durchbruch"), 22, UiTheme.ACCENT))
	var info: Dictionary = Immortal.rank_info()
	var need: Dictionary = info.get("breakthrough", {})
	if need.has("text"):
		column.add_child(UiTheme.label(Loc.t(String(need["text"])), 16, UiTheme.MUTED))
	var reason: String = ImmortalProgress.breakthrough_reason()
	if reason != "":
		column.add_child(UiTheme.label(reason, 16, UiTheme.MUTED))
		return
	var on_break: Callable = func() -> void:
		refresh.call()
		ImmortalProgress.start_breakthrough()
	column.add_child(UiTheme.button(Loc.t("Trübsal zu Rang %d herausfordern") % (GameState.rank + 1), on_break))


static func _land_block(column: VBoxContainer, refresh: Callable) -> void:
	var state: ImmortalState = GameState.immortal
	var grade: Dictionary = Immortal.land_grade()
	column.add_child(UiTheme.label(ImmortalAperture.title(), 22, grade.get("color", UiTheme.ACCENT)))
	var lines: PackedStringArray = [
		Loc.t("%.0f m Kantenlänge · Zeitfluss 1 : %d · %d Essenzsteine am Tag") % [ImmortalAperture.size(), roundi(float(grade.get("time_flow", 1.0))), roundi(float(grade.get("stones_per_day", 3)))],
		Loc.t("Essenzsteine im Gepäck: %d · %d Steine ergeben eine Perle") % [GameState.item_count(ImmortalAperture.STONE_ITEM), ImmortalAperture.stones_per_bead()],
	]
	if not state.annexed.is_empty():
		var names: PackedStringArray = []
		for id: StringName in state.annexed:
			var area: AreaData = DataRegistry.area(id)
			names.append(Loc.t(area.display_name) if area != null else String(id))
		lines.append(Loc.t("Eingegliedert: %s") % ", ".join(names))
	var stored: int = int(state.land_store.get(ImmortalAperture.STONE_ITEM, 0))
	if stored > 0:
		lines.append(Loc.t("Der Landgeist verwahrt %d Essenzsteine und weitere Erträge.") % stored)
	column.add_child(UiTheme.label("\n".join(lines), 16))
	var close_then: Callable = func(action: Callable) -> Callable:
		return func() -> void:
			action.call()
			refresh.call()
	if ImmortalAperture.is_inside():
		column.add_child(UiTheme.button(Loc.t("Erträge einsammeln"), close_then.call(func() -> void: EventBus.message.emit(ImmortalAperture.collect(), LandSpirit.COLOR))))
		column.add_child(UiTheme.button(Loc.t("Essenzsteine zu Perlen verdichten"), close_then.call(_condense)))
		column.add_child(UiTheme.button(Loc.t("Apertur verlassen"), close_then.call(ImmortalAperture.leave)))
	else:
		column.add_child(UiTheme.label(Loc.t("Ein Gedanke genügt, und du stehst in deinem eigenen Land – von überall, außer aus abgeschotteten Dimensionen."), 16, UiTheme.MUTED))
		column.add_child(UiTheme.button(Loc.t("Apertur betreten"), close_then.call(ImmortalAperture.enter)))


static func _condense() -> void:
	var made: int = ImmortalAperture.condense()
	if made > 0:
		EventBus.message.emit(Loc.t("%d Perlen %s verdichtet.") % [made, Loc.t(Immortal.essence_name(GameState.rank))], Immortal.essence_color(GameState.rank))
	else:
		EventBus.message.emit(Loc.t("Nicht genug Essenzsteine."), UiTheme.MUTED)


static func _essence_legend(column: VBoxContainer) -> void:
	column.add_child(UiTheme.label(Loc.t("Unsterblichen-Ränge"), 20, UiTheme.ACCENT))
	for info: Dictionary in DataRegistry.immortal().ranks:
		var rank: int = int(info["rank"])
		var marker: String = " ◀" if rank == GameState.rank else ""
		column.add_child(UiTheme.label(Loc.t("Rang %d · %s · Kalamität alle %d Tage%s") % [rank, Loc.t(String(info["essence"])), int(info.get("days", 3)), marker], 16, info.get("color", UiTheme.TEXT)))
