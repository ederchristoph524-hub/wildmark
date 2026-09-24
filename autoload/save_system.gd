extends Node
## Speichert und lädt den GameState als JSON in user:// – mit save_version und Migrationen bei Formatänderungen.

const SAVE_PATH: String = "user://wildmark_save.json"
## Tests setzen einen eigenen Pfad, damit sie keinen echten Spielstand löschen.
var save_path: String = SAVE_PATH
## Bei jeder Formatänderung erhöhen und in _migrate() nachziehen.
const SAVE_VERSION: int = 1


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> bool:
	if not GameState.active:
		return false
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: Speichern fehlgeschlagen (%s)" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify({"save_version": SAVE_VERSION, "state": GameState.to_dict()}))
	file.close()
	EventBus.saved.emit()
	return true


## Lädt den Spielstand in den GameState. Liefert false, wenn keiner da oder er unlesbar ist.
func load_game() -> bool:
	if not has_save():
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK or not json.data is Dictionary:
		push_error("SaveSystem: Spielstand beschädigt (%s)" % json.get_error_message())
		return false
	var data: Dictionary = _migrate(json.data)
	GameState.from_dict(data.get("state", {}))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


## Hebt ältere Spielstände schrittweise auf SAVE_VERSION an.
func _migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("save_version", 1))
	if version > SAVE_VERSION:
		push_warning("SaveSystem: Spielstand stammt aus einer neueren Version (%d)" % version)
	return data
