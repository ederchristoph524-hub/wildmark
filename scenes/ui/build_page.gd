class_name BuildPage
extends RefCounted
## Seiten „Bauen" und „Aufgaben" im Gu-Menü.


## Bauteile mit Kosten; Bauen schließt das Menü und stellt das Teil vor dir auf.
static func build(player: Player, close_menu: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_child(UiTheme.label(Loc.t("Bauteile werden vor dir aufgestellt. Ein Bett wird zum Wiederbelebungspunkt, ein Lagerfeuer zum Ruheort."), 16, UiTheme.MUTED))
	for part: BuildData in BuildSystem.available_parts():
		var costs: PackedStringArray = []
		for item: StringName in part.cost:
			costs.append("%d %s (%d)" % [part.cost[item], Loc.t(DataRegistry.item(item).display_name), GameState.item_count(item)])
		var row := HBoxContainer.new()
		column.add_child(row)
		var text: Label = UiTheme.label("%s – %s\n%s" % [Loc.t(part.display_name), Loc.t(part.description), ", ".join(costs)], 16)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var reason: String = BuildSystem.blocked_reason(part)
		var on_build: Callable = func() -> void:
			close_menu.call()
			BuildSystem.build(part, player)
		var button: Button = UiTheme.button(Loc.t("Bauen") if reason == "" else Loc.t("Fehlt"), on_build)
		button.disabled = reason != "" and part.id != BuildSystem.DEMOLISH_ID
		row.add_child(button)
	return column


static func quests_page() -> Control:
	var column := VBoxContainer.new()
	if GameState.quests.is_empty():
		column.add_child(UiTheme.label(Loc.t("Noch keine Aufgaben. Sprich mit den Leuten im Dorf (Zeichen „!“)."), 17, UiTheme.MUTED))
	for id: StringName in GameState.quests:
		var quest: QuestData = DataRegistry.quest(id)
		var done: bool = Quests.state(id) == Quests.DONE
		var status: String = Loc.t("erledigt") if done else "%d/%d" % [mini(Quests.current(id), Quests.needed(id)), Quests.needed(id)]
		column.add_child(UiTheme.label("%s – %s (%s)" % [Loc.t(quest.display_name), Loc.t(quest.description), status], 17, UiTheme.MUTED if done else UiTheme.TEXT))
	return column
