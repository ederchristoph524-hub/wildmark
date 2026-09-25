class_name ImmortalKillerData
extends Resource
## Ein Unsterblichen-Killer-Move: ein unsterblicher Gu als Kern und drei bis acht sterbliche Gu-Familien.

@export var id: StringName
@export var display_name: String = ""
@export var name_en: String = ""
@export var path: StringName
## Unsterblicher Kern-Gu (ImmortalGuData-ID).
@export var core: StringName
## Sterbliche Familien (GuFamilyData-IDs), gleich welchen Rangs in der Apertur.
@export var mortal_families: Array[StringName] = []
@export var beads: float = 3.0
@export var cooldown: float = 60.0
## Ausholzeit in Sekunden (verwundbar, durch Treffer nicht unterbrochen).
@export var channel: float = 1.0
@export var base_damage: float = 50.0
@export var steps: Array = []
@export_multiline var description: String = ""
@export_multiline var lore: String = ""
@export var owner: String = ""
