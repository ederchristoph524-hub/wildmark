class_name HitInfo
extends RefCounted
## Beschreibt einen Treffer: Schaden, Tags, ausgelöster Zustand, Rückstoß und Herkunft.

var damage: float = 0.0
var tags: Array[StringName] = []
## Zustand, den der Treffer auslöst; leer = keiner.
var status: StringName = &""
var status_stacks: int = 1
## Rangfaktor für Schaden über Zeit (Brand × Rangfaktor).
var rank_factor: float = 1.0
var source: Node3D = null
## Team des Angreifers (Combatant.TEAM_*).
var team: int = 0
var knockback: Vector3 = Vector3.ZERO
var pierce_armor: bool = false
## Schaden über Zeit löst keine Reaktionen aus und verbraucht keine Wunde.
var is_dot: bool = false
var can_react: bool = true
var is_fist: bool = false
## Pfad des auslösenden Gu (für Welt-Hindernisse wie das Blutsiegel).
var path: StringName = &""
## Ranggabe Giftskorpion: Gift springt beim Tod des Ziels über.
var spread_on_death: bool = false


static func create(amount: float, from: Node3D, from_team: int) -> HitInfo:
	var hit := HitInfo.new()
	hit.damage = amount
	hit.source = from
	hit.team = from_team
	return hit


func with_tags(new_tags: Array[StringName]) -> HitInfo:
	tags = new_tags.duplicate()
	pierce_armor = pierce_armor or &"durchbohren" in tags
	return self


func with_status(id: StringName, stacks: int) -> HitInfo:
	status = id
	status_stacks = stacks
	return self


## Kopie für Ketten- und Flächenschaden (ohne erneute Reaktionen).
func derived(amount: float) -> HitInfo:
	var copy := HitInfo.create(amount, source, team)
	copy.tags = tags.duplicate()
	copy.rank_factor = rank_factor
	copy.can_react = false
	return copy
