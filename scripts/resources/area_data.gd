class_name AreaData
extends Resource
## Ein bereisbares Gebiet der Gu-Welt (aus gebiete.json): Region, Lage auf der Weltkarte, empfohlene Ränge.

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
