class_name ImmortalGuData
extends Resource
## Ein unsterblicher Gu (Rang 6–9, unsterbliche_gu.json): einzigartig in der Welt, wirkt über Wirkungsschritte
## (aktiv, Kosten in Perlen) oder dauerhaft (passiv, Gu-Häuser). Konzept-Gu sind Geschichte und Lexikon.

const KIND_ACTIVE: StringName = &"aktiv"
const KIND_PASSIVE: StringName = &"passiv"
const KIND_CONCEPT: StringName = &"konzept"
const KIND_HOUSE: StringName = &"gu_haus"

@export var id: StringName
@export var display_name: String = ""
@export var name_en: String = ""
@export var rank: int = 6
@export var path: StringName
@export var category: StringName
@export var kind: StringName = KIND_ACTIVE
@export_multiline var description: String = ""
@export_multiline var lore: String = ""
@export var owner: String = ""
## Kosten in Perlen Unsterblichen-Essenz (des eigenen Rangs oder höher).
@export var beads: float = 1.0
@export var cooldown: float = 20.0
## Grundschaden der Schritte (× Unsterblichen-Kraft des Rangs × mult).
@export var base_damage: float = 40.0
## Wirkungsschritte (EffectSteps) für aktive Gu und Gu-Häuser mit Wirkung.
@export var steps: Array = []
## Dauerwirkungen (ImmortalPassives): max_hp, reduction, speed, regen, dao_mult, crit, stealth, reflect, unstoppable,
## kalamitaet_schutz, ertrag_mult, perlen_ertrag, schaden, sicht.
@export var passive: Dictionary = {}
## Weltwirkung: reise, zeitruecksprung, wiedergeburt, sicht (leer = keine).
@export var world: StringName = &""


func is_usable() -> bool:
	return not steps.is_empty()
