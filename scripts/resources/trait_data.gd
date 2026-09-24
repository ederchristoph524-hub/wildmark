class_name TraitData
extends Resource
## Ein zufälliges Merkmal, das ein Gu beim Verfeinern oder Einfangen erhalten kann.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var effect_text: String = ""
## Gewicht für die Zufallsauswahl.
@export var weight: int = 1
