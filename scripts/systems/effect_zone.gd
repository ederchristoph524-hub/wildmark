class_name EffectZone
extends Node3D
## Wirkungsfläche auf Zeit (Schritt "zone"): trifft Gegner darin in Takten (Schaden, Zustand, Verlangsamung, Sog),
## heilt optional Verbündete. Mit "follow" folgt sie dem Wirker (Aura, z. B. Menschenfackel).
## Parameter: radius, time, tick, mult (pro Takt), tags, status, stacks, slow, pull, heal (Anteil Maximalleben pro Takt), follow,
## ally_reduction (Verbündete darin nehmen weniger Schaden, Qi-Schirm), end (Schritte am Ort, wenn die Zone vergeht).

const DISC_HEIGHT: float = 0.06
const PULL_FORCE: float = 0.35
const GUARD_KEY: StringName = &"qi_schirm"

var step: Dictionary = {}
var ctx: EffectContext = null
var radius: float = 3.0
var time_left: float = 4.0
var tick: float = 0.5
var follow: bool = false
var _tick_left: float = 0.0
var _disc: MeshInstance3D = null


static func spawn(zone_step: Dictionary, context: EffectContext) -> EffectZone:
	var zone := EffectZone.new()
	zone.step = zone_step
	zone.ctx = context
	zone.radius = float(zone_step.get("radius", 3.0))
	zone.time_left = float(zone_step.get("time", 4.0))
	zone.tick = float(zone_step.get("tick", EffectSteps.DEFAULT_TICK))
	zone.follow = bool(zone_step.get("follow", false))
	Combat.fx_parent(context.tree()).add_child(zone)
	zone.global_position = context.caster.global_position if zone.follow else context.origin(zone_step)
	return zone


func _ready() -> void:
	var color: Color = EffectSteps.step_color(step, ctx)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = DISC_HEIGHT
	mesh.radial_segments = 24
	mesh.rings = 1
	_disc = MeshInstance3D.new()
	_disc.mesh = mesh
	_disc.material_override = Fx.material(Color(color, 0.28))
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = 0.12
	add_child(_disc)
	Fx.ring(get_tree(), global_position, radius, color, 0.4)
	var tags: Array[StringName] = []
	for tag: Variant in step.get("tags", []):
		tags.append(StringName(str(tag)))
	GuVfx.zone(self, GuVfx.style_of(ctx.path if ctx != null else &"", tags), radius)


func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0 or ctx == null:
		# Zum Schluss (Formation bricht zusammen, Qi-Hülle platzt): Schritte am Ort der Zone.
		if ctx != null and ctx.is_valid() and step.get("end") is Array:
			EffectSteps.run(step["end"], ctx.at_point(global_position))
		queue_free()
		return
	if follow:
		if not ctx.is_valid() or ctx.caster.is_dead():
			queue_free()
			return
		global_position = ctx.caster.global_position
	_disc.scale = Vector3.ONE * (0.94 + 0.06 * sin(time_left * 6.0))
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = tick
	_pulse()


func _pulse() -> void:
	var tree: SceneTree = get_tree()
	var center: Vector3 = global_position
	var pull: float = float(step.get("pull", 0.0))
	for target: Combatant in Combat.in_radius(Combat.hostiles(tree, ctx.team), center, radius):
		EffectSteps.strike(target, step, ctx, center)
		if pull > 0.0 and not target.is_dead():
			var inward: Vector3 = center - target.global_position
			inward.y = 0.0
			var tug := HitInfo.create(0.0, null, ctx.team)
			tug.can_react = false
			tug.knockback = inward.normalized() * Balance.values.knockback_force * PULL_FORCE * pull
			target.receive_hit(tug)
	var guard: float = float(step.get("ally_reduction", 0.0))
	if guard > 0.0:
		for ally: Combatant in Combat.in_radius(Combat.members(tree, ctx.team), center, radius):
			ally.add_timed_reduction(GUARD_KEY, guard, tick * 1.5)
	var heal: float = float(step.get("heal", 0.0))
	if heal > 0.0:
		for ally: Combatant in Combat.in_radius(Combat.members(tree, ctx.team), center, radius):
			ally.heal(ally.health.max_hp * heal)
