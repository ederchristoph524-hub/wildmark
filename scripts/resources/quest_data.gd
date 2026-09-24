class_name QuestData
extends Resource
## Eine Quest; die Abschlussbedingung wird im Code umgesetzt (Referenzlogik im JSON).

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var reward_points: int = 0
## Bedingung und Belohnung aus quests.json → regel (type, item, count, area, reward); leer = Balance.quest_rules.
@export var rule: Dictionary = {}
