class_name Childhood
extends RefCounted
## Spielbare Kindheit (KAMPFSYSTEM, Abschnitt 10): kurzes Tutorial im Klan-Dorf – Bewegung, Gespräch, Sammeln –, endet mit dem Erwachen der Apertur.

const KIND_TALK: StringName = &"talk"
const KIND_ITEM: StringName = &"item"
const KIND_AWAKEN: StringName = &"awaken"
## Schritte: Art, Hinweistext, Ziel (NPC über seine Aufgabe bzw. Gegenstand und Anzahl).
const STEPS: Array[Dictionary] = [
	{"kind": KIND_TALK, "text": "Sprich mit dem Dorfältesten beim Feuer (E / Aktion)", "npc_quest": &"bau"},
	{"kind": KIND_ITEM, "text": "Sammle %d Beeren an den Büschen im Dorf (Faust / Linksklick)", "item": &"beeren", "count": 6},
	{"kind": KIND_AWAKEN, "text": "Geh zum Klanlehrer – heute ist dein Erwachen (E / Aktion)"},
]
## Was Dorfbewohner einem Kind sagen (Aufgabe des NPC → Zeile); sonst die allgemeine Zeile.
const LINES: Dictionary[StringName, String] = {
	&"bau": "Heute ist der Tag deines Erwachens. Sammle vorher Beeren für das Fest – die Büsche stehen innerhalb der Palisade. Dann geh zum Klanlehrer.",
}
const DEFAULT_LINE: String = "Bald bist du ein Gu-Meister wie wir alle. Hör auf den Dorfältesten."


static func is_child() -> bool:
	return GameState.childhood_step >= 0


static func current() -> Dictionary:
	if not is_child() or GameState.childhood_step >= STEPS.size():
		return {}
	return STEPS[GameState.childhood_step]


static func is_awakening_step() -> bool:
	return current().get("kind", &"") == KIND_AWAKEN


## Text für die Aufgabenanzeige im HUD.
static func tracker_text() -> String:
	var step: Dictionary = current()
	if step.is_empty():
		return ""
	var text: String = Loc.t(String(step["text"]))
	if step["kind"] == KIND_ITEM:
		var needed: int = int(step["count"])
		text = text % needed + " %d/%d" % [mini(GameState.item_count(step["item"]), needed), needed]
	return Loc.t("Kindheit") + ": " + text


## Jeden Frame: Sammelschritte prüfen.
static func update() -> void:
	var step: Dictionary = current()
	if not step.is_empty() and step["kind"] == KIND_ITEM and GameState.item_count(step["item"]) >= int(step["count"]):
		advance()


## Gespräch mit einem Dorfbewohner (NPC mit dieser Aufgabe) erfüllt den Gesprächsschritt.
static func on_dialog(quest_of_npc: StringName) -> void:
	var step: Dictionary = current()
	if not step.is_empty() and step["kind"] == KIND_TALK and step["npc_quest"] == quest_of_npc:
		advance()


static func line_for(quest_of_npc: StringName) -> String:
	return LINES.get(quest_of_npc, DEFAULT_LINE)


static func advance() -> void:
	GameState.childhood_step += 1
	var step: Dictionary = current()
	if not step.is_empty():
		EventBus.message.emit(Loc.t("Nächster Schritt: %s") % tracker_text().trim_prefix(Loc.t("Kindheit") + ": "), UiTheme.ACCENT)


## Nach dem Erwachen: Kindheit vorbei, Talent und erster Gu stehen fest.
static func finish(first_family: StringName, grade: StringName, apt: float, physique: StringName) -> void:
	GameState.childhood_step = -1
	GameState.first_family = first_family
	GameState.talent_grade = grade
	GameState.apt = apt
	GameState.physique = physique
