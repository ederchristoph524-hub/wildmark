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
	return " · ".join(parts)


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
	return "   ".join(parts)


static func center_info(player: Player) -> String:
	if player.is_dead():
		return ""
	if player.aperture.meditating:
		return Loc.t("Meditation … Aperturwand %d %% (bewegen zum Beenden)") % roundi(GameState.wall * 100.0)
	if player.eat_time_left > 0.0:
		return Loc.t("Du isst einen Urstein …")
	if player.aperture.can_break_through():
		var chance: float = DataRegistry.progression().breakthrough_chance.get(GameState.talent_grade, 0.5)
		return Loc.t("Durchbruch möglich – Erfolgschance %d %%, Scheitern kostet 60 %% Essenz") % roundi(chance * 100.0)
	return ""
