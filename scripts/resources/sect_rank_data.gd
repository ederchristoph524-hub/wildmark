class_name SectRankData
extends Resource
## Ein Rang innerhalb einer Sekte oder eines Klans (fraktionen.json → SECTRANKS): ab wie viel Verdienst, was er
## beim Aufstieg schenkt und wie groß die tägliche Zuteilung ist.

@export var display_name: String = ""
@export var merit_needed: int = 0
@export var color: Color = Color.WHITE
@export_multiline var perk: String = ""
## Material-ID → Menge beim Aufstieg in diesen Rang.
@export var reward: Dictionary[StringName, int] = {}
## Faktor auf die tägliche Zuteilung (Balance.sect_stipend).
@export var stipend_mult: float = 1.0
