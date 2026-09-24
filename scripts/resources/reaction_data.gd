class_name ReactionData
extends Resource
## Eine Reaktion: Ein Treffer mit einem Tag trifft ein Ziel mit einem bestimmten Zustand.

## Bedingungen, die kein eigener Zustand sind, sondern sich aus Zuständen ergeben
## (eingefroren: Frost mit vollen Stapeln oder Schockfrost).
const DERIVED_CONDITIONS: Array[StringName] = [&"eingefroren"]

@export var id: StringName
@export var display_name: String = ""
## Tag des Treffers, der die Reaktion auslöst.
@export var trigger_tag: StringName
## Zustands-ID oder abgeleitete Bedingung (z. B. &"eingefroren").
@export var target_status: StringName
## Mindestzahl an Stapeln des Zielzustands; 0 = beliebig.
@export var min_stacks: int = 0
@export_multiline var effect_text: String = ""
## Zustände, die durch die Reaktion enden.
@export var removes: Array[StringName] = []
## Parameter der Wirkung (gu_system.json → reaktionen[].regel): mult, freeze, apply, stun, spread_status …
@export var rule: Dictionary = {}
