class_name DataImporter
extends RefCounted
## Liest docs/daten/*.json, prüft alle Verweise und schreibt die Resources nach res://data/.

const SOURCE_DIR := "res://docs/daten/"
## Nur diese Dateien werden gelesen; gu.json liefert Pfade und Lore, nicht die Gu selbst.
const SOURCE_FILES: Array[String] = ["gu_system", "gu", "gegner", "materialien", "welt", "fraktionen", "quests", "fortschritt", "gebiete"]
const TARGET_DIRS: Dictionary[String, String] = {
	"families": "res://data/gu/families/",
	"body": "res://data/gu/body/",
	"support": "res://data/gu/support/",
	"traits": "res://data/gu/traits/",
	"statuses": "res://data/combat/statuses/",
	"reactions": "res://data/combat/reactions/",
	"killer_moves": "res://data/killer_moves/",
	"enemies": "res://data/enemies/",
	"items": "res://data/items/",
	"regions": "res://data/regions/",
	"sects": "res://data/sects/",
	"quests": "res://data/quests/",
	"npcs": "res://data/npcs/",
	"areas": "res://data/areas/",
	"biomes": "res://data/biomes/",
	"builds": "res://data/builds/",
	"gu_masters": "res://data/gu_masters/",
	"standings": "res://data/standings/",
}
const GU_SYSTEM_PATH := "res://data/gu/gu_system.tres"
const PROGRESSION_PATH := "res://data/progression.tres"
const REGION_FILE_PREFIX := "region_"
const COUNT_LABELS: Dictionary[String, String] = {
	"families": "Familien",
	"body": "Körper-Gu",
	"support": "Hilfs-Gu",
	"statuses": "Zustände",
	"reactions": "Reaktionen",
	"traits": "Merkmale",
	"killer_moves": "Killer Moves",
	"enemies": "Gegner",
	"items": "Items",
	"regions": "Regionen",
	"sects": "Sekten",
	"standings": "Herkünfte",
	"quests": "Quests",
	"npcs": "NPC-Arten",
	"areas": "Gebiete",
	"biomes": "Biome",
	"builds": "Bauteile",
	"gu_masters": "Gu-Meister",
}

var report := ImportReport.new()
var _uid_regex := RegEx.create_from_string("uid=\"(uid://[^\"]+)\"")


## Führt den kompletten Import aus. Bei Fehlern wird nichts geschrieben.
func run() -> bool:
	print("Datenimport: lese ", SOURCE_DIR)
	var sources: Dictionary = _load_sources()
	if report.has_errors():
		return _finish(false)
	var built: Dictionary = GuImportBuilder.new(report, sources["gu"]).build(sources["gu_system"])
	built.merge(WorldImportBuilder.new(report).build(sources))
	var progression_builder := ProgressionImportBuilder.new(report)
	built["progression"] = progression_builder.build(sources["fortschritt"])
	progression_builder.add_sect_ranks(built["progression"], sources["fraktionen"])
	ImportValidator.new(report).validate(built, sources)
	if report.has_errors():
		return _finish(false)
	_write_all(built)
	if report.has_errors():
		return _finish(false)
	_print_counts(built)
	return _finish(true)


func _load_sources() -> Dictionary:
	var sources: Dictionary = {}
	for file_name: String in SOURCE_FILES:
		var path: String = SOURCE_DIR + file_name + ".json"
		if not FileAccess.file_exists(path):
			report.error("%s fehlt" % path)
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			report.error("%s: JSON-Fehler in Zeile %d: %s" % [path, json.get_error_line(), json.get_error_message()])
			continue
		if not json.data is Dictionary:
			report.error("%s: oberste Ebene ist kein Objekt" % path)
			continue
		sources[file_name] = json.data
	return sources


func _write_all(built: Dictionary) -> void:
	for type: String in TARGET_DIRS:
		var dir: String = TARGET_DIRS[type]
		if DirAccess.make_dir_recursive_absolute(dir) != OK:
			report.error("Ordner %s konnte nicht angelegt werden" % dir)
			continue
		var written: Dictionary = {}
		for resource: Resource in built[type]:
			var file_name: String = _file_name_for(type, resource)
			_save(resource, dir + file_name)
			written[file_name] = true
		_warn_stale_files(dir, written)
	_save(built["gu_system"], GU_SYSTEM_PATH)
	_save(built["progression"], PROGRESSION_PATH)


func _file_name_for(type: String, resource: Resource) -> String:
	var id: String = str(resource.get("id"))
	if type == "regions":
		id = REGION_FILE_PREFIX + id
	return id + ".tres"


## Speichert und behält die UID einer vorhandenen Datei bei. Headless vergibt ResourceSaver
## keine UIDs und ResourceLoader kennt sie nicht, darum wird die UID aus dem Dateikopf gelesen.
func _save(resource: Resource, path: String) -> void:
	var uid: int = _read_uid(path)
	var result: Error = ResourceSaver.save(resource, path)
	if result != OK:
		report.error("%s konnte nicht gespeichert werden (%s)" % [path, error_string(result)])
		return
	if _read_uid(path) != ResourceUID.INVALID_ID:
		return
	if uid == ResourceUID.INVALID_ID:
		uid = ResourceUID.create_id()
	result = ResourceSaver.set_uid(path, uid)
	if result != OK:
		report.error("%s: UID konnte nicht gesetzt werden (%s)" % [path, error_string(result)])


func _read_uid(path: String) -> int:
	if not FileAccess.file_exists(path):
		return ResourceUID.INVALID_ID
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ResourceUID.INVALID_ID
	var found: RegExMatch = _uid_regex.search(file.get_line())
	if found == null:
		return ResourceUID.INVALID_ID
	return ResourceUID.text_to_id(found.get_string(1))


## Dateien, deren ID nicht mehr in den Daten steht, werden nur gemeldet, nicht gelöscht.
func _warn_stale_files(dir: String, written: Dictionary) -> void:
	for file_name: String in DirAccess.get_files_at(dir):
		if file_name.ends_with(".tres") and not written.has(file_name):
			report.warn("%s%s gehört zu keiner ID mehr (bitte prüfen und ggf. löschen)" % [dir, file_name])


func _print_counts(built: Dictionary) -> void:
	var member_count: int = 0
	for family: GuFamilyData in built["families"]:
		member_count += family.members.size()
	print("Importiert:")
	for type: String in COUNT_LABELS:
		var line: String = "  %-13s %3d" % [COUNT_LABELS[type] + ":", (built[type] as Array).size()]
		if type == "families":
			line += "  (mit %d Gu)" % member_count
		print(line)
	var system: GuSystemData = built["gu_system"]
	print("  %-13s %3d Tags, %d Start-Familien, %d Pfade" % ["Gu-System:", system.tags.size(), system.start_families.size(), system.path_names.size()])
	var progression: ProgressionData = built["progression"]
	print("  %-13s %3d Ränge, %d Stufen, %d Talentgrade, %d Extreme Physiques" % ["Fortschritt:", progression.rank_names.size() - 1, progression.stage_names.size(), progression.rank_cap.size(), progression.physiques.size()])


func _finish(ok: bool) -> bool:
	report.print_messages()
	if ok:
		print("Datenimport erfolgreich: %d Fehler, %d Warnungen." % [report.errors.size(), report.warnings.size()])
	else:
		printerr("Datenimport ABGEBROCHEN: %d Fehler. Es wurde nichts geschrieben." % report.errors.size())
	return ok
