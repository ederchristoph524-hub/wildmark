@tool
class_name ImportDataTool
extends EditorScript
## Editor-Einstieg für den Datenimport: Skript öffnen und „Datei → Ausführen“ (Strg+Umschalt+X).


func _run() -> void:
	var ok: bool = DataImporter.new().run()
	if ok:
		EditorInterface.get_resource_filesystem().scan()
