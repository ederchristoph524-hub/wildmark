class_name NpcTypeData
extends Resource
## Eine NPC-Art (gegner.json → NPCTYPE): Name, Farbe, Gesprächszeilen und Tauschangebot.

@export var id: StringName
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export var region: int = 0
## Seite (righteous, demonic).
@export var side: StringName
@export var lines: Array[String] = []
## Tausch: Gegenstand → Menge, die der Spieler gibt bzw. bekommt.
@export var trade_give: Dictionary[StringName, int] = {}
@export var trade_get: Dictionary[StringName, int] = {}
## Anzahl zufälliger Gu, die der Tausch liefert (Dämonischer Kultivierender).
@export var trade_gu: int = 0
## Rang der getauschten Gu (Auktionshäuser höherer Gebiete verkaufen stärkere Gu).
@export var trade_gu_rank: int = 1
@export var trade_text: String = ""
