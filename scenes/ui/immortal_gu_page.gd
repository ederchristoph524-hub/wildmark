class_name ImmortalGuPage
extends RefCounted
## Seite „Unsterbliche Gu“ im Gu-Menü: unsterbliche Gu der Apertur (Tasten 5 und 6 belegen, Perlenkosten, Abklingzeit,
## Dauerwirkungen) und die Unsterblichen-Killer-Moves – Kern-Gu plus viele sterbliche Familien, fehlende Teile markiert.

const GOLD: Color = Color(1.0, 0.85, 0.45)
const SLOT_KEYS: Array[String] = ["5", "6"]
const PASSIVE_NAMES: Dictionary[String, String] = {
	"max_hp": "+%d %% Leben", "reduction": "%d %% weniger Schaden", "speed": "+%d %% Tempo", "regen": "%d %% Leben je Sekunde",
	"dao_mult": "+%d %% Dao-Markierungen", "crit": "%d %% kritische Treffer", "kalamitaet_schutz": "%d %% Kalamitäten-Schutz",
	"ertrag_mult": "+%d %% Ertrag des Landes", "perlen_ertrag": "+%d %% Perlen", "schaden": "+%d %% Schaden",
}
const FLAG_NAMES: Dictionary[String, String] = {
	"stealth": "Tarnung", "reflect": "Rückprall", "unstoppable": "unaufhaltsam", "sicht": "Weitsicht",
}
const WORLD_NAMES: Dictionary[StringName, String] = {
	&"reise": "Reisen ohne Weg", &"zeitruecksprung": "Rückkehr in der Zeit statt Tod", &"wiedergeburt": "Wiedergeburt",
	&"sicht": "Weitsicht",
}


static func build(player: Player, refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(UiTheme.label(Loc.t("Unsterbliche Gu"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Jeder unsterbliche Gu existiert nur einmal in der Welt. Aktive belegst du auf die Tasten 5 und 6 (Touch: goldene Knöpfe); passive und Gu-Häuser wirken von selbst. Sie brauchen weder Futter noch Uressenz – nur Perlen."), 16, UiTheme.MUTED))
	var state: ImmortalState = GameState.immortal
	if state.gu.is_empty():
		column.add_child(UiTheme.label(Loc.t("Noch keiner. Unsterbliche Gu findest du in Erbschaften der Ehrwürdigen, bei besiegten Unsterblichen und auf der Auktion des Schatzhimmels."), 17))
	for id: StringName in state.gu:
		if DataRegistry.has_immortal_gu(id):
			column.add_child(_gu_row(player, DataRegistry.immortal_gu(id), refresh))
	_killer_section(column, player, refresh)
	return column


static func _gu_row(player: Player, data: ImmortalGuData, refresh: Callable) -> Control:
	var panel := PanelContainer.new()
	var row := VBoxContainer.new()
	panel.add_child(row)
	var path_color: Color = DataRegistry.gu_system().path_color(data.path)
	var kind: String = {ImmortalGuData.KIND_ACTIVE: "aktiv", ImmortalGuData.KIND_PASSIVE: "passiv", ImmortalGuData.KIND_HOUSE: "Gu-Haus"}.get(data.kind, "")
	row.add_child(UiTheme.label("%s · Rang %d · %s · %s" % [Loc.t(data.display_name), data.rank, Loc.t(DataRegistry.gu_system().path_name(data.path)), Loc.t(kind)], 19, path_color.lerp(GOLD, 0.35)))
	row.add_child(UiTheme.label(Loc.t(data.description), 15))
	var effects: String = effects_text(data)
	if effects != "":
		row.add_child(UiTheme.label(effects, 15, UiTheme.ESSENCE))
	if data.owner != "" and not data.owner.begins_with("unbekannt"):
		row.add_child(UiTheme.label(Loc.t("Einst im Besitz von %s") % Loc.t(data.owner), 14, UiTheme.MUTED))
	if not data.is_usable():
		return panel
	var cost: String = Loc.t("%.2f Perlen %s · Abklingzeit %d s") % [Immortal.bead_cost(data.beads), Loc.t(Immortal.essence_name(data.rank)), roundi(data.cooldown)]
	var reason: String = player.immortal.controller.blocked_reason(data.id)
	row.add_child(UiTheme.label(cost + ("" if reason == "" else " · " + reason), 15, UiTheme.MUTED))
	var actions := HBoxContainer.new()
	row.add_child(actions)
	for slot: int in GameState.immortal.slots.size():
		var on_assign: Callable = func() -> void:
			ImmortalGu.assign(slot, data.id)
			refresh.call()
		var label: String = Loc.t("Taste %s ✓") % SLOT_KEYS[slot] if GameState.immortal.slots[slot] == data.id else Loc.t("Auf Taste %s") % SLOT_KEYS[slot]
		actions.add_child(UiTheme.button(label, on_assign))
	return panel


## Dauerwirkungen und Weltwirkung eines unsterblichen Gu als eine Zeile.
static func effects_text(data: ImmortalGuData) -> String:
	var parts: PackedStringArray = []
	for key: Variant in data.passive:
		var value: Variant = data.passive[key]
		if value is bool:
			if value and FLAG_NAMES.has(String(key)):
				parts.append(Loc.t(FLAG_NAMES[String(key)]))
		elif PASSIVE_NAMES.has(String(key)):
			parts.append(Loc.t(PASSIVE_NAMES[String(key)]) % roundi(float(value) * 100.0))
	if WORLD_NAMES.has(data.world):
		parts.append(Loc.t(WORLD_NAMES[data.world]))
	return " · ".join(parts)


# --- Killer Moves ---

static func _killer_section(column: VBoxContainer, player: Player, refresh: Callable) -> void:
	column.add_child(UiTheme.label(Loc.t("Unsterblichen-Killer-Moves"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Ein unsterblicher Gu als Kern und Dutzende sterbliche Gu als Glieder: Liegen Kern und alle sterblichen Familien in deiner Apertur, erkennst du den Zug durch Eingebung. T wirkt ihn, Y wechselt. Jede sterbliche Familie verstärkt ihn."), 16, UiTheme.MUTED))
	var shown: int = 0
	var current: ImmortalKillerData = player.immortal.controller.current()
	for resource: Resource in DataRegistry.all(&"immortal_killers"):
		var move: ImmortalKillerData = resource as ImmortalKillerData
		var known: bool = move.id in GameState.immortal.known_killers
		if not known and not ImmortalGu.owns(move.core):
			continue
		column.add_child(_killer_row(move, known, move == current, refresh))
		shown += 1
	if shown == 0:
		column.add_child(UiTheme.label(Loc.t("Besitzt du einen unsterblichen Gu, siehst du hier, welche Killer Moves er tragen kann."), 16))


static func _killer_row(move: ImmortalKillerData, known: bool, active: bool, refresh: Callable) -> Control:
	var panel := PanelContainer.new()
	var row := VBoxContainer.new()
	panel.add_child(row)
	var core: ImmortalGuData = DataRegistry.immortal_gu(move.core)
	var color: Color = DataRegistry.gu_system().path_color(move.path).lerp(GOLD, 0.4)
	var state_text: String = Loc.t("aktiv") if active else (Loc.t("bekannt") if known else Loc.t("unvollständig"))
	row.add_child(UiTheme.label("%s · %s" % [Loc.t(move.display_name), state_text], 19, color if known else UiTheme.MUTED))
	row.add_child(UiTheme.label(Loc.t(move.description), 15))
	var families: PackedStringArray = []
	var missing: Array[StringName] = ImmortalGu.missing_families(move)
	for family_id: StringName in move.mortal_families:
		var family: GuFamilyData = DataRegistry.family(family_id)
		var family_name: String = Loc.t(family.display_name) if family != null else String(family_id)
		families.append(("✗ " if family_id in missing else "✓ ") + family_name)
	var core_mark: String = "✓ " if ImmortalGu.owns(move.core) else "✗ "
	row.add_child(UiTheme.label(Loc.t("Kern: %s%s (Rang %d)") % [core_mark, Loc.t(core.display_name), core.rank], 15, GOLD))
	row.add_child(UiTheme.label(Loc.t("Sterbliche Glieder: %s") % " · ".join(families), 15, UiTheme.MUTED))
	var bonus: int = roundi(Balance.immortal.killer_component_bonus * move.mortal_families.size() * 100.0)
	row.add_child(UiTheme.label(Loc.t("%.1f Perlen · Ausholen %.1f s · Abklingzeit %d s · +%d %% durch Glieder") % [Immortal.bead_cost(move.beads), move.channel, roundi(move.cooldown), bonus], 15, UiTheme.MUTED))
	if known and not active and ImmortalGu.has_parts(move):
		var on_pick: Callable = func() -> void:
			_select(move.id)
			refresh.call()
		row.add_child(UiTheme.button(Loc.t("Als aktiven Killer Move wählen"), on_pick))
	return panel


static func _select(id: StringName) -> void:
	var player: Player = ImmortalWorld.player()
	if player == null:
		return
	var moves: Array[ImmortalKillerData] = player.immortal.controller.available()
	for i: int in moves.size():
		if moves[i].id == id:
			GameState.immortal.active_killer = i
