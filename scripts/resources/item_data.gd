class_name ItemData
extends Resource
## Ein Inventar-Gegenstand: Grundressource oder Verfeinerungs-Material.

@export var id: StringName
@export var display_name: String = ""
## Platzhalter-Icon (Emoji) bis zum echten Icon.
@export var icon: String = ""
## &"basis" für Grundressourcen, &"material" für Verfeinerungs-Materialien.
@export var category: StringName
@export var rank: int = 0
@export var path: StringName
@export var immortal: bool = false
## Fundort.
@export var source: String = ""
@export_multiline var description: String = ""
