class_name BodyGuData
extends Resource
## Ein Körper-Gu, der dauerhaft eingeprägt wird und feste Werte verleiht.

@export var id: StringName
@export var display_name: String = ""
@export var rank: int = 1
## Wirkungen als Schlüssel-Wert-Paare (z. B. grundschaden, max_hp, schaden_erlitten).
@export var effects: Dictionary[StringName, float] = {}
