class_name EffectStepsSelf
extends RefCounted
## Wirkungsschritte, die den Wirker oder seine Verbündeten betreffen: Panzer, Heilung, Beschwörung, Stärkung,
## Tarnung, Teleport, Sprint, Reinigung, Unaufhaltsamkeit, Rückprall (Teil von EffectSteps).

const HEAL_COLOR: Color = Color(0.5, 1.0, 0.5)
const SUMMON_OFFSET: float = 2.2


static func run_step(step: Dictionary, ctx: EffectContext) -> void:
	var caster: Combatant = ctx.caster
	var tree: SceneTree = ctx.tree()
	match String(step.get("t", "")):
		"armor":
			_armor(step, ctx)
		"heal":
			_heal(step, ctx)
		"summon":
			_summon(step, ctx)
		"buff":
			caster.add_buff(StringName(str(step.get("key", "buff"))), float(step.get("damage", 1.0)), float(step.get("speed", 1.0)), float(step.get("time", 6.0)))
			if step.has("reduction"):
				caster.add_timed_reduction(&"buff_guard", float(step["reduction"]), float(step.get("time", 6.0)))
			Fx.sphere(tree, caster.aim_point(), 1.4, Color(EffectSteps.step_color(step, ctx), 0.35), 0.6)
		"stealth":
			caster.start_stealth(float(step.get("time", 5.0)))
		"teleport":
			if step.get("to") == "target" and ctx.target != null and is_instance_valid(ctx.target):
				_blink_to_target(caster, ctx.target, float(step.get("distance", 8.0)))
			else:
				blink(caster, float(step.get("distance", 8.0)), ctx.aim)
		"dash":
			if caster.has_method("dash_to"):
				caster.call("dash_to", caster.global_position + ctx.aim * float(step.get("distance", 6.0)))
		"cleanse":
			caster.status.clear_negative()
			Fx.ring(tree, caster.global_position, 1.4, HEAL_COLOR, 0.4)
		"unstoppable":
			caster.unstoppable_time = maxf(caster.unstoppable_time, float(step.get("time", 4.0)))
		"reflect":
			caster.reflect_time = maxf(caster.reflect_time, float(step.get("time", 4.0)))
		_:
			push_warning("EffectSteps: unbekannte Schrittart '%s'" % step.get("t", ""))


## Reaktive Panzer (nur Spieler): thorns (Dornen, value_mult × Schaden) oder thunder (Ladungsstapel = value).
static func _armor(step: Dictionary, ctx: EffectContext) -> void:
	var time: float = float(step.get("time", 6.0))
	var reduction: float = float(step.get("reduction", 0.3))
	var kind: StringName = StringName(str(step.get("kind", "thorns")))
	var value: float = ctx.damage * float(step["value_mult"]) if step.has("value_mult") else float(step.get("value", 0.0))
	if ctx.caster.has_method("start_reactive_armor"):
		ctx.caster.call("start_reactive_armor", kind, time, reduction, value)
	else:
		ctx.caster.add_timed_reduction(kind, reduction, time)
	Fx.sphere(ctx.tree(), ctx.caster.aim_point(), 1.6, Color(EffectSteps.step_color(step, ctx), 0.4), time)


## Heilung: frac des Maximallebens, sofort oder über time; mit allies auch Verbündete im Umkreis radius.
static func _heal(step: Dictionary, ctx: EffectContext) -> void:
	var receivers: Array[Combatant] = [ctx.caster]
	if bool(step.get("allies", false)):
		receivers = Combat.in_radius(Combat.members(ctx.tree(), ctx.team), ctx.caster.global_position, float(step.get("radius", 8.0)))
	for ally: Combatant in receivers:
		var amount: float = ally.health.max_hp * float(step.get("frac", 0.3))
		if float(step.get("time", 0.0)) > 0.0:
			ally.start_regeneration(amount, float(step["time"]))
		else:
			ally.heal(amount)
		Fx.ring(ctx.tree(), ally.global_position, 1.5, HEAL_COLOR, 0.6)


## Beschwörung: Spieler-Seite bekommt Gefährten auf Zeit, Bestien rufen Artgenossen.
static func _summon(step: Dictionary, ctx: EffectContext) -> void:
	var spawner: Node = ctx.tree().get_first_node_in_group(&"enemy_spawner")
	if spawner == null:
		return
	var id: StringName = StringName(str(step.get("enemy", "wolf")))
	for i: int in int(step.get("count", 1)):
		var offset: Vector3 = ctx.aim.rotated(Vector3.UP, (i + 1) * TAU / (int(step.get("count", 1)) + 1)) * SUMMON_OFFSET
		var at: Vector3 = ctx.caster.global_position + offset
		if ctx.team == Combatant.TEAM_PLAYER:
			spawner.call("spawn_companion", id, at, float(step.get("time", 20.0)), ctx.caster, ctx.power)
		else:
			spawner.call("spawn_minion", id, at, ctx.team)
	Fx.sphere(ctx.tree(), ctx.caster.aim_point(), 2.5, Color(EffectSteps.step_color(step, ctx), 0.35), 0.6)


## Taucht direkt vor dem Ziel wieder auf (Erdloch, Schattensprung); ist es weiter weg, nur so weit wie erlaubt.
static func _blink_to_target(caster: Combatant, target: Combatant, max_distance: float) -> void:
	var offset: Vector3 = target.global_position - caster.global_position
	offset.y = 0.0
	var gap: float = target.body_radius + caster.body_radius + 0.3
	var travel: float = clampf(offset.length() - gap, 0.0, max_distance)
	if travel > 0.5:
		blink(caster, travel, offset.normalized())


## Sofortiger Ortswechsel in Blickrichtung (auch durch Gitter und Tore); landet auf dem Gelände.
static func blink(caster: Combatant, distance: float, aim: Vector3) -> void:
	var world: World = caster.get_tree().get_first_node_in_group(World.GROUP_WORLD) as World
	var from: Vector3 = caster.global_position
	var to: Vector3 = from + aim * distance
	if world != null:
		if not world.terrain.is_inside(to.x, to.z, 2.0):
			return
		to = world.ground_point(to.x, to.z) + Vector3.UP * 0.2
	Fx.sphere(caster.get_tree(), caster.aim_point(), 1.0, Color(0.7, 0.6, 1.0, 0.5), 0.3)
	caster.global_position = to
	caster.velocity = Vector3.ZERO
	Fx.ring(caster.get_tree(), to, 1.4, Color(0.7, 0.6, 1.0), 0.35)
