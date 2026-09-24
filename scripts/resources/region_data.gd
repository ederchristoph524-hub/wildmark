class_name RegionData
extends Resource
## Eine Region der Welt (die fünf Hauptregionen plus Sonderbereiche).

@export var id: int = 0
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export_multiline var description: String = ""
## Umriss auf der Weltkarte (0–1) und die Regionalmauer, die die Region umgibt.
@export var map_polygon: Array[Vector2] = []
@export var wall_name: String = ""
@export var wall_color: Color = Color.WHITE
