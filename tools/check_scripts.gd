class_name CheckScripts
extends SceneTree
## Lädt alle GDScript-Dateien des Projekts (mit Autoloads) und meldet Kompilierfehler.
## Aufruf: godot --headless --path . --script res://tools/check_scripts.gd

const ROOTS: Array[String] = ["res://autoload/", "res://scripts/", "res://scenes/", "res://tools/", "res://tests/"]


func _init() -> void:
	# Autoloads sind erst nach dem ersten Frame als Bezeichner registriert.
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var failures: int = 0
	var count: int = 0
	for base_dir: String in ROOTS:
		for path: String in _collect(base_dir):
			if path == get_script().resource_path:
				continue
			count += 1
			var script: Script = ResourceLoader.load(path) as Script
			if script == null:
				printerr("KAPUTT: ", path)
				failures += 1
	print("check_scripts: %d Skripte, %d Fehler" % [count, failures])
	quit(0 if failures == 0 else 1)


func _collect(dir: String) -> Array[String]:
	var result: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			result.append(dir + file)
	for sub: String in DirAccess.get_directories_at(dir):
		result.append_array(_collect(dir + sub + "/"))
	return result
