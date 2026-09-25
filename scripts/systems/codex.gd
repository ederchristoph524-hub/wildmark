class_name Codex
extends RefCounted
## Gu-Lexikon: welche Gu du kennst. Bekannt wird ein Gu, sobald du ihn besitzt, ihn wild aus der Nähe siehst oder ein
## Gu-Meister ihn gegen dich einsetzt. Die Seite „Lexikon" im Gu-Menü zeigt alle Gu nach Pfaden; Unbekannte bleiben
## verborgen. Zustand in GameState.codex (gespeichert).


static func note(id: StringName) -> void:
	if id == &"" or String(id) in GameState.codex:
		return
	GameState.codex.append(String(id))


static func knows(id: StringName) -> bool:
	return String(id) in GameState.codex


## Alles, was du gerade besitzt, gilt als bekannt (Kauf, Rezept, Erbe, Belohnung – ohne jeden Weg einzeln zu melden).
static func sync_owned() -> void:
	for instance: GuInstance in GameState.gu:
		note(instance.gu_id)
	for instance: GuInstance in GameState.support:
		note(instance.gu_id)
	for id: StringName in GameState.body_gu:
		note(id)


## Anzahl aller Gu im Lexikon (aktive, Körper- und Hilfs-Gu).
static func total() -> int:
	return DataRegistry.all_gu().size() + DataRegistry.all(&"body").size() + DataRegistry.all(&"support").size()


static func known_count() -> int:
	var count: int = 0
	for id: String in GameState.codex:
		var key := StringName(id)
		if DataRegistry.has_gu(key) or DataRegistry.has(&"body", key) or DataRegistry.has(&"support", key):
			count += 1
	return count
