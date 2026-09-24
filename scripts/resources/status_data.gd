class_name StatusData
extends Resource
## Ein Zustand (z. B. Brand, Nass, Frost), den Treffer auf Zielen auslösen können.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var effect_text: String = ""
@export var max_stacks: int = 1
## Zustände, die diesen Zustand beenden.
@export var removed_by: Array[StringName] = []
