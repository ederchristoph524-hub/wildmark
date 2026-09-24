class_name GuInstance
extends Resource
## Laufzeit-Zustand eines Gu im Besitz einer Figur (wird gespeichert).

@export var gu_id: StringName
## ID des Merkmals (TraitData); leer, wenn der Gu keines hat.
@export var trait_id: StringName
@export var satiety: float = 1.0
@export var cooldown_left: float = 0.0
