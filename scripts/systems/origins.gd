class_name Origins
extends RefCounted
## Herkunft beim Erwachen anwenden (StandingData): Startgeschenk, Talentbonus und Ansehen im Heimatklan.

## Der Klan des Startdorfs, in dem die Herkunft zählt.
const HOME_SECT: StringName = &"gu_yue"
const MAX_APT: float = 100.0


static func apply() -> void:
	if GameState.standing == &"" or not DataRegistry.has(&"standings", GameState.standing):
		return
	var standing: StandingData = DataRegistry.standing(GameState.standing)
	for item: StringName in standing.gift:
		GameState.add_item(item, standing.gift[item])
	GameState.apt = minf(MAX_APT, GameState.apt + standing.apt_bonus)
	if standing.home_merit > 0 and DataRegistry.has(&"sects", HOME_SECT):
		SectLife.join(DataRegistry.sect(HOME_SECT))
		SectLife.add_merit(standing.home_merit)
	EventBus.message.emit(Loc.t("Herkunft: %s") % Loc.t(standing.display_name), UiTheme.ACCENT)


## Kurzbeschreibung für das Startmenü.
static func describe(standing: StandingData) -> String:
	var parts: PackedStringArray = []
	for item: StringName in standing.gift:
		parts.append("%d %s" % [standing.gift[item], Loc.t(DataRegistry.item(item).display_name)])
	var text: String = "%s: %s\n%s: %s" % [Loc.t(standing.display_name), Loc.t(standing.description), Loc.t("Startgeschenk"), ", ".join(parts)]
	if standing.apt_bonus > 0.0:
		text += " · " + Loc.t("Talent +%d %%") % roundi(standing.apt_bonus)
	if standing.home_merit > 0:
		text += " · " + Loc.t("Mitglied des Gu-Yue-Klans mit %d Verdienst") % standing.home_merit
	return text
