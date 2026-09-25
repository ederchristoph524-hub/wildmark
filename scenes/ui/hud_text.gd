class_name HudText
extends RefCounted
## Texte für das HUD (Uhrzeit, Zustände, Gu-Leiste, Hinweise), damit hud.gd schlank bleibt.

const DAY_START_HOUR: float = 6.0


static func clock() -> String:
	var b: BalanceData = Balance.values
	var minutes: int = floori(fmod(GameState.time_of_day * 24.0 + DAY_START_HOUR, 24.0) * 60.0)
	var night: bool = Formulas.is_night(b, GameState.time_of_day)
	return Loc.t("Tag %d · %02d:%02d · %s") % [GameState.day, floori(minutes / 60.0), minutes % 60, Loc.t("Nacht") if night else Loc.t("Tag")]


static func statuses(player: Player) -> String:
	var parts: PackedStringArray = []
	for id: StringName in player.status.active_statuses():
		var stacks: int = player.status.stacks_of(id)
		parts.append(Loc.t(DataRegistry.status(id).display_name) + ("×%d" % stacks if stacks > 1 else ""))
	if player.status.is_frozen():
		parts.append(Loc.t("Eingefroren"))
	for key: StringName in player.reductions:
		parts.append(Loc.t("Schild %d %%") % roundi(player.reductions[key] * 100.0))
	if GameState.passives_suspended:
		parts.append(Loc.t("Hilfs-Gu ruhen"))
	var stones: int = GameState.item_count(&"kristall")
	parts.append(Loc.t("Urstein: %d") % stones)
	var lines: PackedStringArray = [" · ".join(parts)]
	for extra: String in [SectLife.status_line(), Renown.status_line()]:
		if extra != "":
			lines.append(extra)
	return "\n".join(lines)


static func gu_bar(player: Player) -> String:
	if Childhood.is_child():
		return ""
	var parts: PackedStringArray = []
	for slot: int in GameState.SLOT_COUNT:
		var instance: GuInstance = GameState.slot_instance(slot)
		if instance == null:
			parts.append("[%d] –" % (slot + 1))
			continue
		var text: String = "[%d] %s" % [slot + 1, Loc.t(player.holder.gu_data(instance).display_name)]
		if instance.cooldown_left > 0.0:
			text += " %.1fs" % instance.cooldown_left
		elif not player.holder.is_ready(slot):
			text += " ✗"
		if player.holder.is_starved(instance):
			text += " " + Loc.t("(ausgehungert)")
		elif player.holder.is_hungry(instance):
			text += " " + Loc.t("(hungrig)")
		parts.append(text)
	var move: KillerMoveData = player.killer.current()
	if move != null:
		parts.append("[Q] " + Loc.t(move.display_name))
	if Immortal.is_immortal():
		parts.append(_immortal_bar(player))
	return "   ".join(parts)


## Unsterbliche Tasten: [5] [6] unsterbliche Gu, [T] Unsterblichen-Killer-Move.
static func _immortal_bar(player: Player) -> String:
	var parts: PackedStringArray = []
	var controller: ImmortalController = player.immortal.controller
	for slot: int in GameState.immortal.slots.size():
		var id: StringName = GameState.immortal.slots[slot]
		if id == &"" or not DataRegistry.has_immortal_gu(id):
			parts.append("[%d] –" % (slot + 5))
			continue
		var text: String = "[%d] %s" % [slot + 5, Loc.t(DataRegistry.immortal_gu(id).display_name)]
		if controller.cooldown_left(id) > 0.0:
			text += " %.0fs" % controller.cooldown_left(id)
		parts.append(text)
	var move: ImmortalKillerData = controller.current()
	if move != null:
		parts.append("[T] " + Loc.t(move.display_name))
	return "   ".join(parts)


## Balken und Ranganzeige eines Unsterblichen: Perlen statt Uressenz, Kalamitäten statt Aperturwand.
static func immortal_bars(bar: ProgressBar, text: Label, rank_text: Label) -> void:
	var state: ImmortalState = GameState.immortal
	var beads: float = state.beads_for(GameState.rank)
	var color: Color = Immortal.essence_color(GameState.rank)
	bar.max_value = maxf(beads, float(Immortal.land_grade().get("start_beads", 4.0)))
	bar.value = beads
	bar.add_theme_stylebox_override(&"fill", UiTheme.box(color, 6, Color(0, 0, 0, 0)))
	text.text = Loc.t("%.2f Perlen %s · Uressenz ∞") % [beads, Loc.t(Immortal.essence_name(GameState.rank))]
	var progression: ProgressionData = DataRegistry.progression()
	var per_stage: int = int(Immortal.rank_info().get("per_stage", 3))
	rank_text.text = Loc.t("%s · %s · Kalamitäten %d/%d") % [Loc.t(progression.rank_name(GameState.rank)), Loc.t(progression.stage_name(GameState.stage)),
		state.calamities_survived % per_stage if GameState.stage < Balance.values.max_stage else per_stage, per_stage]
	if state.venerable_title != "":
		rank_text.text = state.venerable_title
	rank_text.add_theme_color_override(&"font_color", color)


static func center_info(player: Player) -> String:
	if player.is_dead():
		return ""
	if player.aperture.meditating:
		if player.aperture.ritual_left > 0.0:
			return Loc.t("Durchbruch … %.1f s") % player.aperture.ritual_left
		if ImmortalAscension.is_gathering():
			return Loc.t("Kultivieren … Himmels-Qi %d · Erd-Qi %d · Menschen-Qi %d – voraussichtlich: %s") % [roundi(GameState.immortal.heaven_qi),
				roundi(GameState.immortal.earth_qi), roundi(ImmortalAscension.human_qi()), ImmortalAscension.grade_name(ImmortalAscension.predicted_grade())]
		if Immortal.is_immortal():
			return Loc.t("Kultivieren … Dao-Markierungen im Pfad des Ortes")
		if GameState.stage >= Balance.values.max_stage and GameState.rank >= player.aperture.rank_cap():
			return Loc.t("Kultivieren … Uressenz %d %% – Gipfel erreicht, kein höherer Rang möglich") % roundi(player.aperture.ratio() * 100.0)
		if GameState.stage >= Balance.values.max_stage:
			return Loc.t("Kultivieren … Uressenz %d %% – ab %d %% ist der Durchbruch möglich") % [roundi(player.aperture.ratio() * 100.0), roundi(Balance.values.breakthrough_min_essence * 100.0)]
		return Loc.t("Kultivieren … Aperturwand %d %% (bewegen zum Beenden)") % roundi(GameState.wall * 100.0)
	if player.eat_time_left > 0.0:
		return Loc.t("Du isst einen Urstein …")
	if player.aperture.can_break_through():
		var chance: float = DataRegistry.progression().breakthrough_chance.get(GameState.talent_grade, 0.5)
		return Loc.t("Durchbruch möglich – Erfolgschance %d %%, Scheitern kostet 60 %% Essenz") % roundi(chance * 100.0)
	return ""
