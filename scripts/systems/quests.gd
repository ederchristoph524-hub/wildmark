class_name Quests
extends RefCounted
## Quests aus quests.json mit Bedingungen und Belohnungen aus Balance.quest_rules.

const ACTIVE: String = "active"
const DONE: String = "done"


static func state(id: StringName) -> String:
	return String(GameState.quests.get(id, {}).get("state", ""))


static func rule(id: StringName) -> Dictionary:
	return Balance.values.quest_rules.get(id, {})


## Aktueller Wert der Bedingung (für „x / y").
static func current(id: StringName) -> int:
	var r: Dictionary = rule(id)
	var begin: int = int(GameState.quests.get(id, {}).get("start", 0))
	match r.get("type", &""):
		&"item":
			return GameState.item_count(r["item"])
		&"kills":
			return GameState.kills - begin
		&"built":
			return GameState.built_count
		&"area":
			return 1 if String(r.get("area", "")) in GameState.visited_areas else 0
		&"day":
			return GameState.day
	return 0


static func needed(id: StringName) -> int:
	return int(rule(id).get("count", 1))


static func is_complete(id: StringName) -> bool:
	return state(id) == ACTIVE and current(id) >= needed(id)


static func start(id: StringName) -> void:
	var start_value: int = GameState.kills if rule(id).get("type", &"") == &"kills" else 0
	GameState.quests[id] = {"state": ACTIVE, "start": start_value}
	EventBus.message.emit(Loc.t("Neue Aufgabe: %s") % Loc.t(DataRegistry.quest(id).display_name), UiTheme.ACCENT)


## Schließt ab, nimmt abzugebende Gegenstände und gibt die Belohnung.
static func turn_in(id: StringName) -> bool:
	if not is_complete(id):
		return false
	var r: Dictionary = rule(id)
	if r.get("type", &"") == &"item":
		GameState.take_item(r["item"], needed(id))
	var reward: Dictionary = r.get("reward", {})
	var parts: PackedStringArray = []
	for item: Variant in reward:
		GameState.add_item(item, int(reward[item]))
		parts.append("%d %s" % [int(reward[item]), Loc.t(DataRegistry.item(item).display_name)])
	GameState.quests[id]["state"] = DONE
	EventBus.message.emit(Loc.t("Aufgabe erfüllt: %s – Belohnung: %s") % [Loc.t(DataRegistry.quest(id).display_name), ", ".join(parts)], Color(1.0, 0.85, 0.3))
	return true


## Kurzer Text für das HUD: aktive Aufgaben mit Fortschritt.
static func tracker_text() -> String:
	var lines: PackedStringArray = []
	for id: StringName in GameState.quests:
		if state(id) == ACTIVE:
			var mark: String = " ✓" if is_complete(id) else ""
			lines.append("%s %d/%d%s" % [Loc.t(DataRegistry.quest(id).display_name), mini(current(id), needed(id)), needed(id), mark])
	return "\n".join(lines)
