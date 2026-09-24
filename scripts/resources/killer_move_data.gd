class_name KillerMoveData
extends Resource
## Ein Killer Move, der aus der Kombination zweier Gu-Familien entsteht.

@export var id: StringName
@export var display_name: String = ""
@export var family_a: StringName
@export var family_b: StringName
## Kanalisierungszeit in Sekunden.
@export var channel_time: float = 0.0
@export var damage_mult: float = 1.0
@export_multiline var description: String = ""
## Rätselhafter Hinweis, wie man den Killer Move entdeckt.
@export var hint: String = ""
