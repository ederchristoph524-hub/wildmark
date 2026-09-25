class_name AreaData
extends Resource
## Ein bereisbares Gebiet der Gu-Welt (aus gebiete.json): Lage auf der Weltkarte, Gelände, Siedlungen, Orte, Gegner und Funde.
## Koordinaten im Gebiet in Metern (x nach Osten, z nach Süden, Mitte = 0,0).

@export var id: StringName
@export var display_name: String = ""
## ID der Region (RegionData).
@export var region: int = 1
## Position auf der Weltkarte (0–1, x nach Osten, y nach Süden).
@export var map_position: Vector2 = Vector2(0.5, 0.5)
@export var rank_min: int = 1
@export var rank_max: int = 1
## Schon bereisbar (sonst nur als unerforschter Ort auf der Karte).
@export var open: bool = false
@export_multiline var description: String = ""

@export_group("Gelände")
## Kantenlänge in Metern.
@export var size: float = 240.0
@export var terrain_seed: int = 1
@export var biome: StringName
## hoehe, frequenz, detail, berge, rand, randhoehe, horizont (Gebirgskranz), basis (Grundhöhe, negativ = Meer).
@export var relief: Dictionary[StringName, float] = {}
## Erhebungen (x, z, Radius, Höhe): Inseln, Sektenberg-Gipfel, Tafelberge; weich ins Gelände geblendet.
@export var hills: Array[Vector4] = []
## Ankunftspunkt (x, z) bei Reisen und neuem Spiel.
@export var arrival: Vector2 = Vector2.ZERO
## Wege als Listen von Punkten (Vector2).
@export var paths: Array = []
## Flüsse (TerrainRivers): {"points": Array[Vector2], "width": float}.
@export var rivers: Array[Dictionary] = []

@export_group("Inhalte")
## Je Siedlung: id, type, faction, position (Vector2), radius, houses, colors, residents.
@export var settlements: Array[Dictionary] = []
## Je Ort: type, name, position, radius und typabhängige Felder (item, count, offering, guards, reward, text).
@export var places: Array[Dictionary] = []
## Hindernis-Orte: id, kind, reward (Gu-ID), angle (Grad), distance.
@export var obstacles: Array[Dictionary] = []
## Gegenstand → [Anzahl, Ertrag].
@export var resources: Dictionary[StringName, Vector2i] = {}
## Zonengrenzen (Abstand von der Mitte) und je Zone die erlaubten Gefahrenzonen (int, Feld z in gegner.json) oder Bestien-IDs (StringName).
@export var enemy_radii: Array[float] = []
@export var enemy_zones: Array = []
@export var wild_gu_rank: int = 1
@export var wild_gu_range: Vector2 = Vector2(60.0, 200.0)
## Passive wilde Gu: [id, body|support, min, max, versteckt].
@export var wild_passives: Array = []
## Bestienflut (gebiete.json → flut): {"beasts": Array[StringName], "leader": StringName, "count": int, "every": int
## (alle n Tage, nachts), "target": StringName (Siedlungs-ID), "reward": Dictionary[StringName, int]}; leer = keine.
@export var tide: Dictionary = {}
## Klanfehde (ClanFeud): name, attacker (Sekte), target (Siedlung), masters, count, every, offset, reward; leer = keine.
@export var feud: Dictionary = {}
## Wandernde Gu-Meister auf den Straßen (gebiete.json → wanderer: meister, anzahl gleichzeitig), siehe Wanderers.
@export var wanderers: Array[StringName] = []
@export var wanderer_count: int = 0


## Siedlung per ID (leer, wenn es sie nicht gibt).
func settlement(settlement_id: StringName) -> Dictionary:
	for entry: Dictionary in settlements:
		if entry.get("id") == settlement_id:
			return entry
	return {}
