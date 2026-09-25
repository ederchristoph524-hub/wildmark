class_name GuSystemData
extends Resource
## Globale Tabellen des Gu-Systems: Tags, Merkmal-Chancen und Start-Familien.

## Tag-ID → Beschreibung der Wirkung.
@export var tags: Dictionary[StringName, String] = {}
## Chancen für Merkmale (z. B. eines, glaenzend).
@export var trait_chances: Dictionary[StringName, float] = {}
## Pfad-ID → Anzeigename und Farbe (aus gu.json → PATHS, PATH_COLOR).
@export var path_names: Dictionary[StringName, String] = {}
@export var path_colors: Dictionary[StringName, Color] = {}
## Pfad-ID → gegensätzliche Pfade (gu.json → PATH_CONFLICT).
@export var path_conflicts: Dictionary[StringName, Array] = {}
## Beherrschungsstufen eines Pfads (gu.json → ATTAIN): Name, nötige Dao-Markierungen, Farbe; Index = Stufe.
@export var attain_names: Array[String] = []
@export var attain_needs: Array[float] = []
@export var attain_colors: Array[Color] = []
## Verschmelzungs-Rezepte (gu_system.json → rezepte): {"result": ID, "inputs": Array[StringName] (Gu, die verbraucht
## werden), "materials": Dictionary[StringName, int], "chance": float, "hint": String}.
@export var recipes: Array[Dictionary] = []
## Familien, aus denen beim Erwachen gewählt werden kann.
@export var start_families: Array[StringName] = []


func path_color(path: StringName) -> Color:
	return path_colors.get(path, Color.WHITE)


func path_name(path: StringName) -> String:
	return path_names.get(path, String(path))
