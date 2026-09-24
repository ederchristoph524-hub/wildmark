class_name GuData
extends Resource
## Ein einzelner Gu einer Familie auf einem bestimmten Rang (Mitglied von GuFamilyData).

@export var id: StringName
@export var display_name: String = ""
## ID der Familie; bewusst kein Resource-Verweis, weil die Familie ihre Mitglieder enthält.
@export var family: StringName
@export var rank: int = 1
## Zusätzliche Wirkung, die dieser Rang gegenüber dem vorherigen bringt (leer auf Rang 1).
@export var rank_gift: String = ""
@export_multiline var description: String = ""
@export_multiline var lore: String = ""
