class_name GuMenuPages
extends RefCounted
## Inhalte der Seiten im Gu-Menü.

const FOOD_HEAL: Dictionary[StringName, String] = {&"beeren": "berry_heal", &"fleisch": "meat_heal"}


static func gu_page(player: Player, refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	var capacity: int = Formulas.gu_capacity(Balance.values, GameState.rank, GameState.apt)
	column.add_child(UiTheme.label(Loc.t("Gu in deiner Apertur: %d / %d. Tippe eine Slot-Nummer, um den Gu dorthin zu legen.") % [GameState.gu.size(), capacity], 17, UiTheme.MUTED))
	for index: int in GameState.gu.size():
		column.add_child(_gu_row(player, index, refresh))
	if GameState.gu.is_empty():
		column.add_child(UiTheme.label(Loc.t("Du besitzt keine Gu.")))
	return column


static func _gu_row(player: Player, index: int, refresh: Callable) -> Control:
	var instance: GuInstance = GameState.gu[index]
	var holder: GuHolderComponent = player.holder
	var data: GuData = holder.gu_data(instance)
	var family: GuFamilyData = holder.family_of(instance)
	var panel := PanelContainer.new()
	var row := VBoxContainer.new()
	panel.add_child(row)
	var title: String = "%s · %s · %s %d" % [Loc.t(data.display_name), Loc.t(DataRegistry.gu_system().path_name(family.path)), Loc.t("Rang"), data.rank]
	if instance.trait_id != &"":
		var gu_trait: TraitData = DataRegistry.trait_data(instance.trait_id)
		title += " · " + Loc.t(gu_trait.display_name) + " (" + Loc.t(gu_trait.effect_text) + ")"
	row.add_child(UiTheme.label(title, 19, DataRegistry.gu_system().path_color(family.path).lightened(0.3)))
	var cost: String = Loc.t("%d Leben") % roundi(holder.hp_cost(instance)) if holder.hp_cost(instance) > 0.0 else Loc.t("%.1f Uressenz") % holder.essence_cost(instance)
	row.add_child(UiTheme.label("%s\n%s · %s %.1f s · %s" % [Loc.t(data.description), cost, Loc.t("Abklingzeit"), holder.cooldown_of(instance), Loc.t(family.role)], 16, UiTheme.MUTED))
	var hunger: String = Loc.t("ausgehungert!") if holder.is_starved(instance) else (Loc.t("hungrig") if holder.is_hungry(instance) else Loc.t("satt"))
	var item: ItemData = DataRegistry.item(holder.feed_item(instance))
	var actions := HBoxContainer.new()
	row.add_child(actions)
	var satiety: Label = UiTheme.label(Loc.t("Sättigung %d (%s)") % [roundi(instance.satiety), hunger], 16)
	satiety.autowrap_mode = TextServer.AUTOWRAP_OFF
	actions.add_child(satiety)
	var on_feed: Callable = func() -> void:
		holder.feed(index)
		refresh.call()
	actions.add_child(UiTheme.button(Loc.t("Füttern: %d %s (hast %d)") % [holder.feed_cost(instance), Loc.t(item.display_name), GameState.item_count(item.id)], on_feed))
	for slot: int in GameState.SLOT_COUNT:
		var on_assign: Callable = func() -> void:
			_assign(index, slot)
			refresh.call()
		var button: Button = UiTheme.button(str(slot + 1), on_assign, 48.0)
		button.toggle_mode = true
		button.button_pressed = GameState.slots[slot] == index
		button.custom_minimum_size.x = 48.0
		actions.add_child(button)
	return panel


static func _assign(index: int, slot: int) -> void:
	for other: int in GameState.SLOT_COUNT:
		if GameState.slots[other] == index:
			GameState.slots[other] = GameState.EMPTY_SLOT
	GameState.slots[slot] = index


static func combo_page() -> Control:
	var column := VBoxContainer.new()
	column.add_child(UiTheme.label(Loc.t("Killer Moves"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Setze zwei Gu kurz nacheinander ein – mit Glück begreifst du ihre Verbindung (Eingebung)."), 16, UiTheme.MUTED))
	for resource: Resource in DataRegistry.all(&"killer_moves"):
		var move: KillerMoveData = resource as KillerMoveData
		var names: String = "%s + %s" % [Loc.t(DataRegistry.family(move.family_a).display_name), Loc.t(DataRegistry.family(move.family_b).display_name)]
		if GameState.knows_killer_move(move.id):
			column.add_child(UiTheme.label("%s  (%s)\n%s" % [Loc.t(move.display_name), names, Loc.t(move.description)], 17))
		else:
			column.add_child(UiTheme.label("???  – %s" % Loc.t(move.hint), 17, UiTheme.MUTED))
	column.add_child(UiTheme.label(Loc.t("Reaktionen"), 22, UiTheme.ACCENT))
	for resource: Resource in DataRegistry.all(&"reactions"):
		var reaction: ReactionData = resource as ReactionData
		if reaction.id in GameState.seen_reactions:
			column.add_child(UiTheme.label("%s: %s" % [Loc.t(reaction.display_name), Loc.t(reaction.effect_text)], 17))
		else:
			column.add_child(UiTheme.label("??? " + Loc.t("(noch nicht entdeckt)"), 17, UiTheme.MUTED))
	return column


static func inventory_page(player: Player, refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	if GameState.inventory.is_empty():
		column.add_child(UiTheme.label(Loc.t("Dein Gepäck ist leer. Schlage Büsche, Steine, Kristalle und Totholz mit der Faust.")))
	var keys: Array = GameState.inventory.keys()
	keys.sort()
	for id: StringName in keys:
		var item: ItemData = DataRegistry.item(id)
		var row := HBoxContainer.new()
		column.add_child(row)
		var text: Label = UiTheme.label("%s × %d  %s" % [Loc.t(item.display_name) if item != null else String(id), GameState.item_count(id), Loc.t(item.description) if item != null else ""], 18)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		if FOOD_HEAL.has(id):
			var on_eat: Callable = func() -> void:
				if GameState.take_item(id, 1):
					player.heal(float(Balance.values.get(FOOD_HEAL[id])))
				refresh.call()
			row.add_child(UiTheme.button(Loc.t("Essen (heilt)"), on_eat))
	return column


static func cultivation_page(player: Player, refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	var progression: ProgressionData = DataRegistry.progression()
	var aperture: ApertureComponent = player.aperture
	var text: String = Loc.t("%s · %s\nTalent %s (%d %%) – höchstens Rang %d\nUressenz %.1f / %.1f · Regeneration %.2f/s\nAperturwand %d %%") % [
		Loc.t(progression.rank_name(GameState.rank)), Loc.t(progression.stage_name(GameState.stage)),
		GameState.talent_grade, roundi(GameState.apt), aperture.rank_cap(),
		aperture.essence(), aperture.capacity(), aperture.regeneration(), roundi(GameState.wall * 100.0)]
	column.add_child(UiTheme.label(text, 19))
	column.add_child(UiTheme.label(Loc.t(progression.talent_flavor.get(GameState.talent_grade, "")), 16, UiTheme.MUTED))
	column.add_child(UiTheme.label(Loc.t("Meditiere (M) an einem sicheren Ort: Deine Uressenz fließt gegen die Aperturwand. Ist sie verfeinert, steigst du eine Stufe auf. Auf der Höchststufe mit fast voller Apertur kannst du den Durchbruch wagen."), 16, UiTheme.MUTED))
	if aperture.can_break_through():
		var on_break: Callable = func() -> void:
			aperture.break_through()
			refresh.call()
		column.add_child(UiTheme.button(Loc.t("Durchbruch wagen"), on_break))
	return column
