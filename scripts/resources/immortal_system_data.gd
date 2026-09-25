class_name ImmortalSystemData
extends Resource
## Regeln des Unsterblichen-Reichs aus unsterblich.json (docs/UNSTERBLICH.md): Ränge 6–9 mit Essenz und Kalamitäten-Zyklus,
## Kalamitäten, Grade des Gesegneten Landes, Aufstieg, Eingebungen, Schatzhimmel, Landgeist, Biome der eigenen Apertur
## und die Platzierung der NPC-Unsterblichen.

## Je Rang (6–9): rank, essence, color, days (Kalamität alle n Tage), cycle (Array[StringName]), per_stage,
## breakthrough {dao, stones, attain, text}.
@export var ranks: Array[Dictionary] = []
## Kalamität-ID → {name, color, warning, waves, duration, quakes, bolts, dao}.
@export var calamities: Dictionary = {}
## Rang → Bestien-IDs der Kalamitätswesen.
@export var calamity_beasts: Dictionary = {}
## Grade des Gesegneten Landes (Index 0–3): id, name, color, size, stones_per_day, time_flow, start_beads, yield.
@export var land_grades: Array[Dictionary] = []
@export var ascension: Dictionary = {}
## Eingebungen beim Aufstieg: id, question, text, effect (Dictionary).
@export var inspirations: Array[Dictionary] = []
@export var treasure: Dictionary = {}
@export var land_spirit: Dictionary = {}
## Hauptpfad → Biom der eigenen Apertur (_standard als Rückfall).
@export var path_biomes: Dictionary = {}
## NPC-Unsterbliche: master, area, settlement, role (sanctum, wanderer, waechter).
@export var placements: Array[Dictionary] = []


func rank_info(rank: int) -> Dictionary:
	for entry: Dictionary in ranks:
		if int(entry["rank"]) == rank:
			return entry
	return {}


func essence_name(rank: int) -> String:
	return String(rank_info(rank).get("essence", "Unsterblichen-Essenz"))


func essence_color(rank: int) -> Color:
	return rank_info(rank).get("color", Color.WHITE)


func grade(index: int) -> Dictionary:
	return land_grades[clampi(index, 0, land_grades.size() - 1)] if not land_grades.is_empty() else {}


func calamity(id: StringName) -> Dictionary:
	return calamities.get(id, {})
