class_name GuMasterData
extends Resource
## Ein NPC-Gu-Meister (gegner.json → GUMASTER): Name, Farbe, Fraktion und seine Gu.

@export var id: StringName
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export var faction: StringName
## Gu-IDs; nur solche aus dem Gu-System (Familien- oder Körper-Gu) werden im Spiel genutzt.
@export var gu: Array[StringName] = []
