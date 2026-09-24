class_name EffectContext
extends RefCounted
## Wer eine Wirkung auslöst und womit: Wirker, Grundschaden (schon mit Rangstärke), Blickrichtung, Ziel,
## Aufschlagpunkt, Farbe und Pfad. Wird an EffectSteps, Zonen, Fallen und kreisende Klingen weitergereicht.

var caster: Combatant = null
## Grundschaden eines Treffers mit mult 1 (Familien-Schaden × Stärke bzw. Killer-Move-Schaden).
var damage: float = 0.0
## Rangstärke für Schaden über Zeit (Brand × Rangfaktor).
var power: float = 1.0
var aim: Vector3 = Vector3.FORWARD
var target: Combatant = null
## Fester Punkt (Aufschlag eines Geschosses, Ende eines Strahls); INF-Vektor = keiner.
var point: Vector3 = Vector3.INF
var color: Color = Color.WHITE
var path: StringName = &""
var team: int = 0


static func create(who: Combatant, base_damage: float, direction: Vector3, effect_color: Color) -> EffectContext:
	var ctx := EffectContext.new()
	ctx.caster = who
	ctx.team = who.team
	ctx.damage = base_damage
	ctx.aim = Vector3(direction.x, 0.0, direction.z).normalized() if Vector2(direction.x, direction.z).length() > 0.01 else Vector3.FORWARD
	ctx.color = effect_color
	return ctx


## Kopie mit festem Punkt (für Aufschlag-Wirkungen).
func at_point(where: Vector3) -> EffectContext:
	var copy: EffectContext = EffectContext.new()
	copy.caster = caster
	copy.damage = damage
	copy.power = power
	copy.aim = aim
	copy.target = target
	copy.point = where
	copy.color = color
	copy.path = path
	copy.team = team
	return copy


func is_valid() -> bool:
	return caster != null and is_instance_valid(caster) and caster.is_inside_tree()


func tree() -> SceneTree:
	return caster.get_tree() if is_valid() else null


## Ort eines Schritts: "self" (Wirker), "target" (Ziel oder Blickpunkt), "aim" (Blickpunkt im Abstand distance),
## "point" (fester Punkt, sonst Blickpunkt). Standard: fester Punkt, falls gesetzt, sonst der Wirker.
func origin(step: Dictionary) -> Vector3:
	var mode: String = String(step.get("at", "point" if point != Vector3.INF else "self"))
	var distance: float = float(step.get("distance", 6.0))
	match mode:
		"target":
			if target != null and is_instance_valid(target) and not target.is_dead():
				return target.global_position
			return caster.global_position + aim * distance
		"aim":
			return caster.global_position + aim * distance
		"point":
			return point if point != Vector3.INF else caster.global_position + aim * distance
	return caster.global_position
