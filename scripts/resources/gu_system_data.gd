class_name GuSystemData
extends Resource
## Globale Tabellen des Gu-Systems: Tags, Merkmal-Chancen und Start-Familien.

## Tag-ID → Beschreibung der Wirkung.
@export var tags: Dictionary[StringName, String] = {}
## Chancen für Merkmale (z. B. eines, glaenzend).
@export var trait_chances: Dictionary[StringName, float] = {}
## Familien, aus denen beim Erwachen gewählt werden kann.
@export var start_families: Array[StringName] = []
