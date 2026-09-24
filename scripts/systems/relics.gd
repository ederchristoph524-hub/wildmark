class_name Relics
extends RefCounted
## Relikt-Gu (Grünkupfer, Rotstahl, Weißsilber, Gelbgold, Lilakristall): Beim Verfeinern verfeinern sie die Aperturwand
## sofort um eine Stufe – aber nur, wenn ihr Rang dem eigenen entspricht (wie im Roman).

const PREFIX: String = "reliquie_"


static func is_relic(id: StringName) -> bool:
	return String(id).begins_with(PREFIX)


## Leer = verwendbar, sonst Grund für die Anzeige.
static func blocked_reason(id: StringName) -> String:
	var item: ItemData = DataRegistry.item(id)
	if item == null or not is_relic(id):
		return Loc.t("Kein Relikt-Gu")
	if item.rank != GameState.rank:
		return Loc.t("Nur auf Rang %d wirksam") % item.rank
	if GameState.stage >= Balance.values.max_stage:
		return Loc.t("Du stehst schon auf der Höchststufe")
	return ""


static func use(id: StringName, aperture: ApertureComponent) -> bool:
	if blocked_reason(id) != "" or not GameState.take_item(id, 1):
		return false
	return aperture.instant_stage()
