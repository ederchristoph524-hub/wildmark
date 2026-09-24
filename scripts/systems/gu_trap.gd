class_name GuTrap
extends Node3D
## Gu-Falle (Schritt "trap", z. B. Verkohlte Donnerknolle): liegt verborgen am Boden und explodiert, sobald ein
## Gegner in trigger-Reichweite kommt. Parameter: count (im Kreis um den Zielpunkt verteilt), spacing, trigger,
## radius (Explosion), time (Lebensdauer), then (weitere Schritte am Explosionsort), dazu Treffer-Parameter.

const ARM_TIME: float = 0.6
const CHECK_INTERVAL: float = 0.15

var step: Dictionary = {}
var ctx: EffectContext = null
var trigger: float = 1.6
var radius: float = 3.0
var time_left: float = 20.0
var _arm: float = ARM_TIME
var _check: float = 0.0


static func spawn(trap_step: Dictionary, context: EffectContext) -> void:
	var count: int = maxi(1, int(trap_step.get("count", 1)))
	var spacing: float = float(trap_step.get("spacing", 2.5))
	var center: Vector3 = context.origin(trap_step)
	var world: World = context.tree().get_first_node_in_group(World.GROUP_WORLD) as World
	for i: int in count:
		var trap := GuTrap.new()
		trap.step = trap_step
		trap.ctx = context
		trap.trigger = float(trap_step.get("trigger", 1.6))
		trap.radius = float(trap_step.get("radius", 3.0))
		trap.time_left = float(trap_step.get("time", 20.0))
		Combat.fx_parent(context.tree()).add_child(trap)
		var offset: Vector3 = Vector3.ZERO if count == 1 else Vector3(spacing, 0.0, 0.0).rotated(Vector3.UP, i * TAU / count)
		var at: Vector3 = center + offset
		trap.global_position = world.ground_point(at.x, at.z) if world != null else at


func _ready() -> void:
	var mound := MeshInstance3D.new()
	mound.mesh = Fx.sphere_mesh()
	mound.material_override = Fx.material(Color(EffectSteps.step_color(step, ctx), 0.85))
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mound.scale = Vector3(0.55, 0.22, 0.55)
	mound.position.y = 0.08
	add_child(mound)


func _physics_process(delta: float) -> void:
	time_left -= delta
	_arm -= delta
	if time_left <= 0.0 or ctx == null or not is_instance_valid(ctx.caster):
		queue_free()
		return
	_check -= delta
	if _arm > 0.0 or _check > 0.0:
		return
	_check = CHECK_INTERVAL
	if not Combat.in_radius(Combat.hostiles(get_tree(), ctx.team), global_position, trigger).is_empty():
		_explode()


func _explode() -> void:
	var tree: SceneTree = get_tree()
	for target: Combatant in Combat.in_radius(Combat.hostiles(tree, ctx.team), global_position, radius):
		EffectSteps.strike(target, step, ctx, global_position)
	var color: Color = EffectSteps.step_color(step, ctx)
	Fx.sphere(tree, global_position + Vector3.UP * 0.6, radius, Color(color, 0.55), 0.35)
	Fx.ring(tree, global_position, radius, color, 0.4)
	if ctx.is_valid():
		EffectSteps.run(step.get("then", []), ctx.at_point(global_position))
	queue_free()
