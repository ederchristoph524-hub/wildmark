class_name SectData
extends Resource
## Ein Klan, eine Sekte oder ein Stamm, dem man beitreten kann.

@export var id: StringName
@export var display_name: String = ""
@export var icon: String = ""
## Fraktion (righteous, demonic).
@export var faction: StringName
## Organisationsform (klan, sekte, stamm).
@export var org_type: StringName
## Regions-ID.
@export var region: int = 0
@export var immortals: int = 0
@export var power: int = 0
@export var rivals: Array[StringName] = []
## Mindestrang für den Beitritt; 0 = keine Bedingung.
@export var min_rank: int = 0
## Material-ID → Menge als Beitrittsgeschenk.
@export var join_gift: Dictionary[StringName, int] = {}
@export var signature_gu: StringName
@export_multiline var politics: String = ""
@export_multiline var description: String = ""
