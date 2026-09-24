class_name StatusData
extends Resource
## Ein Zustand (z. B. Brand, Nass, Frost), den Treffer auf Zielen auslösen können.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var effect_text: String = ""
@export var max_stacks: int = 1
## Zustände, die diesen Zustand beenden.
@export var removed_by: Array[StringName] = []
## Regeln aus gu_system.json → zustaende[].regel.
@export var duration: float = 4.0
## Schaden pro Sekunde und Stapel (× Rangfaktor).
@export var dps: float = 0.0
## Tempo-Änderung pro Stapel (Frost −0,2; Verwurzelt −1).
@export var speed_per_stack: float = 0.0
## Heilungsfaktor, solange aktiv (Gift 0,5).
@export var heal_mult: float = 1.0
## Zusätzlich erlittener Schaden pro Stapel (Schwäche +0,15).
@export var damage_taken_per_stack: float = 0.0
## Was bei vollen Stapeln passiert: freeze, discharge oder leer.
@export var on_max: StringName = &""
## Das Ziel flieht, solange der Zustand aktiv ist (Furcht).
@export var flee: bool = false
