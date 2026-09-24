class_name ImportDataCli
extends SceneTree
## Headless-Einstieg für den Datenimport:
## godot --headless --path . --script res://tools/import_data_cli.gd  (Exit-Code 1 bei Fehlern)


func _init() -> void:
	var ok: bool = DataImporter.new().run()
	quit(0 if ok else 1)
