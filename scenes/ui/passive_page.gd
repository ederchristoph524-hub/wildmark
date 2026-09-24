class_name PassivePage
extends RefCounted
## Seite „Passive Gu" im Gu-Menü: eingeprägte Körper-Gu und Hilfs-Gu mit Sättigung, Fütterung und Unterhalt.


static func build(player: Player, refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_child(UiTheme.label(Loc.t("Körper-Gu"), 22, UiTheme.ACCENT))
	if GameState.body_gu.is_empty():
		column.add_child(UiTheme.label(Loc.t("Noch keiner eingeprägt. Körper-Gu kosten weder Futter noch Unterhalt noch Platz."), 16, UiTheme.MUTED))
	for id: StringName in GameState.body_gu:
		var data: BodyGuData = DataRegistry.body_gu(id)
		column.add_child(UiTheme.label("%s · %s" % [Loc.t(data.display_name), _effects_text(data)], 17))
	column.add_child(UiTheme.label(Loc.t("Hilfs-Gu"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Hilfs-Gu wirken von selbst, solange sie satt sind, ihr Rang höchstens 1 über deinem liegt und deine Essenz den Unterhalt trägt."), 16, UiTheme.MUTED))
	for index: int in GameState.support.size():
		column.add_child(_support_row(player, index, refresh))
	return column


static func _support_row(player: Player, index: int, refresh: Callable) -> Control:
	var instance: GuInstance = GameState.support[index]
	var data: SupportGuData = DataRegistry.support_gu(instance.gu_id)
	var panel := PanelContainer.new()
	var row := VBoxContainer.new()
	panel.add_child(row)
	var state: String = Loc.t("wirkt") if PassiveGu.is_active(instance) else Loc.t("ruht")
	var upkeep: String = Loc.t("kein Unterhalt") if data.id in Balance.values.upkeep_free else Loc.t("Unterhalt %.2f/s") % (data.rank * Balance.values.support_upkeep_per_rank)
	row.add_child(UiTheme.label("%s · %s · %s (%s)" % [Loc.t(data.display_name), Loc.t(data.effect_text), upkeep, state], 17))
	var actions := HBoxContainer.new()
	row.add_child(actions)
	var satiety: Label = UiTheme.label(Loc.t("Sättigung %d") % roundi(instance.satiety), 16)
	satiety.autowrap_mode = TextServer.AUTOWRAP_OFF
	actions.add_child(satiety)
	var item: ItemData = DataRegistry.item(data.feed_item)
	var on_feed: Callable = func() -> void:
		player.holder.feed_support(index)
		refresh.call()
	actions.add_child(UiTheme.button(Loc.t("Füttern: %d %s (hast %d)") % [player.holder.support_feed_cost(data), Loc.t(item.display_name), GameState.item_count(item.id)], on_feed))
	return panel


static func _effects_text(data: BodyGuData) -> String:
	var parts: PackedStringArray = []
	for key: StringName in data.effects:
		var value: float = data.effects[key]
		match key:
			&"grundschaden":
				parts.append(Loc.t("+%d Schaden") % roundi(value))
			&"max_hp":
				parts.append(Loc.t("+%d Leben") % roundi(value))
			&"schaden_erlitten":
				parts.append(Loc.t("%d %% weniger Schaden") % roundi(-value * 100.0))
	return ", ".join(parts)
