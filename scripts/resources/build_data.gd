class_name BuildData
extends Resource
## Ein Bauteil fürs Lager (materialien.json → BUILD).

@export var id: StringName
@export var display_name: String = ""
@export var cost: Dictionary[StringName, int] = {}
@export_multiline var description: String = ""
## Lichtradius in Metern (0 = kein Licht).
@export var light: float = 0.0
## Mindestrang zum Bauen (0 = keiner).
@export var min_rank: int = 0
