class_name ProgressionData
extends Resource
## Ränge, Stufen und Talentgrade aus fortschritt.json (Namen, Farben, Durchbruchschancen, Rang-Obergrenzen).

## Index = Rang (0 bleibt leer). Bewusst Array statt Packed*Array: Packed-Arrays gingen im Web-Export verloren.
@export var rank_names: Array[String] = []
@export var rank_colors: Array[Color] = []
@export var rank_essence_names: Array[String] = []
@export var stage_names: Array[String] = []
## Talentgrad → Durchbruchschance.
@export var breakthrough_chance: Dictionary[StringName, float] = {}
## Talentgrad → höchster erreichbarer sterblicher Rang.
@export var rank_cap: Dictionary[StringName, int] = {}
@export var talent_flavor: Dictionary[StringName, String] = {}
@export var talent_colors: Dictionary[StringName, Color] = {}
@export var awaken_age: int = 13
## Die Zehn Extremen Physiques (nur beim Talentgrad „Durchbrochen“).
@export var physiques: Array[PhysiqueData] = []
## Ränge in Sekten und Klans (aus fraktionen.json → SECTRANKS), Index 0 = Eintritt.
@export var sect_ranks: Array[SectRankData] = []


func rank_name(rank: int) -> String:
	return rank_names[rank] if rank >= 0 and rank < rank_names.size() else str(rank)


func rank_color(rank: int) -> Color:
	return rank_colors[rank] if rank >= 0 and rank < rank_colors.size() else Color.WHITE


## Eine Physique per ID, sonst null.
func physique(id: StringName) -> PhysiqueData:
	for entry: PhysiqueData in physiques:
		if entry.id == id:
			return entry
	return null


## Sektenrang per Index (auf die Liste begrenzt), null ohne Daten.
func sect_rank(index: int) -> SectRankData:
	if sect_ranks.is_empty():
		return null
	return sect_ranks[clampi(index, 0, sect_ranks.size() - 1)]


func stage_name(stage: int) -> String:
	return stage_names[stage] if stage >= 0 and stage < stage_names.size() else str(stage)
