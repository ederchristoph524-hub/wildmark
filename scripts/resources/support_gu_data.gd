class_name SupportGuData
extends Resource
## Ein passiver Hilfs-Gu mit eigenem Futterbedarf.

@export var id: StringName
@export var display_name: String = ""
@export var rank: int = 1
@export var path: StringName
@export_multiline var effect_text: String = ""
@export var feed_item: StringName
@export var feed_amount: int = 0
