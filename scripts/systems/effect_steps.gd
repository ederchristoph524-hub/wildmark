class_name EffectSteps
extends RefCounted
## Führt Wirkungsschritte aus Daten aus: Killer Moves, Ranggaben („extra", „impact"), neue Wirkformen und
## Bestien-Fähigkeiten. Ein Schritt ist ein Dictionary mit "t" (Art) und Parametern (GU_SYSTEM.md, Abschnitt 9).
## Schaden eines Treffers = ctx.damage × mult. Treffer-Parameter siehe make_hit.

const DEFAULT_TICK: float = 0.5
const EXECUTE_THRESHOLD: float = 0.3


static func run(steps: Array, ctx: EffectContext) -> void:
	for raw: Variant in steps:
		if raw is Dictionary and ctx.is_valid():
			run_step(raw, ctx)


static func run_step(step: Dictionary, ctx: EffectContext) -> void:
	match String(step.get("t", "")):
		"circle":
			_circle(step, ctx)
		"line":
			_line(step, ctx)
		"cone":
			_cone(step, ctx)
		"projectiles":
			_projectiles(step, ctx)
		"chain":
			_chain(step, ctx)
		"zone":
			EffectZone.spawn(step, ctx)
		"orbit":
			OrbitBlades.spawn(step, ctx)
		"trap":
			GuTrap.spawn(step, ctx)
		"delay":
			_delay(step, ctx)
		_:
			EffectStepsSelf.run_step(step, ctx)


## Treffer aus Schritt-Parametern: mult, tags, status, stacks, stun, knockback (+ weg, − heran), lifesteal,
## execute (Bonus unter 30 % Leben), pierce_armor, slow/slow_time, blind, freeze, set_stacks {Zustand: Stapel}.
static func make_hit(step: Dictionary, ctx: EffectContext) -> HitInfo:
	var source: Node3D = ctx.caster if ctx.is_valid() else null
	var hit := HitInfo.create(ctx.damage * float(step.get("mult", 1.0)), source, ctx.team).with_tags(tag_list(step.get("tags", [])))
	if step.has("status"):
		hit.with_status(StringName(step["status"]), int(step.get("stacks", 1)))
	hit.rank_factor = ctx.power
	hit.path = ctx.path
	hit.pierce_armor = hit.pierce_armor or bool(step.get("pierce_armor", false))
	hit.stun = float(step.get("stun", 0.0))
	hit.lifesteal = float(step.get("lifesteal", 0.0))
	hit.execute_bonus = float(step.get("execute", 0.0))
	return hit


## Wendet einen Treffer samt Nebenwirkungen des Schritts auf ein Ziel an. push_from = Ursprung für Rückstoß.
static func strike(target: Combatant, step: Dictionary, ctx: EffectContext, push_from: Vector3) -> void:
	var hit: HitInfo = make_hit(step, ctx)
	var push: float = float(step.get("knockback", 0.0))
	if push != 0.0:
		var away: Vector3 = target.global_position - push_from
		away.y = 0.0
		hit.knockback = away.normalized() * Balance.values.knockback_force * push
	if hit.damage > 0.0 or hit.status != &"" or hit.knockback != Vector3.ZERO or hit.stun > 0.0:
		target.receive_hit(hit)
	if target.is_dead():
		return
	if step.has("freeze"):
		target.status.freeze(float(step["freeze"]))
	if step.has("slow"):
		target.status.slow(float(step["slow"]), float(step.get("slow_time", 3.0)))
	if step.has("blind"):
		target.status.blind_time = maxf(target.status.blind_time, float(step["blind"]))
	var fixed: Variant = step.get("set_stacks", {})
	if fixed is Dictionary:
		for id: Variant in fixed:
			target.status.set_stacks(StringName(str(id)), int(fixed[id]))


static func tag_list(raw: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if raw is Array:
		for tag: Variant in raw:
			result.append(StringName(str(tag)))
	return result


static func step_color(step: Dictionary, ctx: EffectContext) -> Color:
	return Color.html(String(step["color"])) if step.has("color") else ctx.color


static func _circle(step: Dictionary, ctx: EffectContext) -> void:
	var tree: SceneTree = ctx.tree()
	var center: Vector3 = ctx.origin(step)
	var radius: float = float(step.get("radius", 4.0))
	for target: Combatant in Combat.in_radius(Combat.hostiles(tree, ctx.team), center, radius):
		strike(target, step, ctx, center)
	var color: Color = step_color(step, ctx)
	Fx.ring(tree, center, radius, color, 0.45)
	Fx.sphere(tree, center + Vector3.UP * 0.8, radius * 0.9, Color(color, 0.35), 0.4)


## Linie vom Wirker in Blickrichtung; mit "dash" gleitet der Wirker ans Ende.
static func _line(step: Dictionary, ctx: EffectContext) -> void:
	var tree: SceneTree = ctx.tree()
	var start: Vector3 = ctx.caster.aim_point()
	var end: Vector3 = start + ctx.aim * float(step.get("length", 10.0))
	var width: float = float(step.get("width", 2.0))
	for target: Combatant in Combat.on_line(Combat.hostiles(tree, ctx.team), start, end, width):
		strike(target, step, ctx, start)
	Fx.beam(tree, start, end, step_color(step, ctx), 0.45, width * 0.4)
	if bool(step.get("dash", false)):
		if ctx.caster.has_method("dash_to"):
			ctx.caster.call("dash_to", end - Vector3.UP * (start.y - ctx.caster.global_position.y))
		else:
			EffectStepsSelf.blink(ctx.caster, float(step.get("length", 10.0)) * 0.9, ctx.aim)


static func _cone(step: Dictionary, ctx: EffectContext) -> void:
	var tree: SceneTree = ctx.tree()
	var reach: float = float(step.get("reach", 6.0))
	var from: Vector3 = ctx.caster.global_position
	for target: Combatant in Combat.in_cone(Combat.hostiles(tree, ctx.team), from, ctx.aim, reach, float(step.get("angle", 80.0))):
		strike(target, step, ctx, from)
	var color: Color = step_color(step, ctx)
	for i: int in 3:
		Fx.sphere(tree, ctx.caster.aim_point() + ctx.aim * reach * (0.3 + i * 0.25), reach * (0.18 + i * 0.1), Color(color, 0.4), 0.3)


## Fächer aus Geschossen (anzahl, faecher in Grad); optional zielsuchend, durchbohrend oder explodierend.
static func _projectiles(step: Dictionary, ctx: EffectContext) -> void:
	var count: int = maxi(1, int(step.get("count", 3)))
	var spread: float = deg_to_rad(float(step.get("spread", 40.0)))
	var start: Vector3 = ctx.caster.aim_point() + ctx.aim * 0.6
	var config: Dictionary = {"range": float(step.get("range", 14.0)), "color": step_color(step, ctx), "pierce": int(step.get("pierce", 0)),
		"homing": bool(step.get("homing", false)), "explode_radius": float(step.get("explode", 0.0))}
	if step.has("speed"):
		config["speed"] = float(step["speed"])
	for i: int in count:
		var angle: float = 0.0 if count == 1 else lerpf(-spread * 0.5, spread * 0.5, i / float(count - 1))
		Projectile.launch(ctx.tree(), start, make_hit(step, ctx), ctx.aim.rotated(Vector3.UP, angle), config)


## Kettenschlag: trifft das Ziel (oder das nächste) und springt auf weitere in der Nähe.
static func _chain(step: Dictionary, ctx: EffectContext) -> void:
	var tree: SceneTree = ctx.tree()
	var radius: float = float(step.get("radius", 7.0))
	var hostiles: Array[Combatant] = Combat.hostiles(tree, ctx.team)
	var current: Combatant = ctx.target if ctx.target != null and is_instance_valid(ctx.target) and not ctx.target.is_dead() else Combat.nearest(Combat.in_radius(hostiles, ctx.origin(step), radius * 1.5), ctx.origin(step))
	var from: Vector3 = ctx.caster.aim_point()
	var struck: Array[Combatant] = []
	for jump: int in int(step.get("jumps", 3)) + 1:
		if current == null:
			return
		Fx.beam(tree, from, current.aim_point(), step_color(step, ctx), 0.3, 0.2)
		strike(current, step, ctx, from)
		struck.append(current)
		from = current.aim_point()
		var options: Array[Combatant] = []
		for other: Combatant in Combat.in_radius(hostiles, current.global_position, radius):
			if other not in struck and not other.is_dead():
				options.append(other)
		current = Combat.nearest(options, current.global_position)


static func _delay(step: Dictionary, ctx: EffectContext) -> void:
	var then: Array = step.get("then", [])
	ctx.tree().create_timer(float(step.get("time", 0.4))).timeout.connect(func() -> void: run(then, ctx))
