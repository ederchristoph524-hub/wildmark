class_name OrbitBlades
extends Node3D
## Kreisende Klingen, Knochenräder oder Sterne um den Wirker (Schritt "orbit"): treffen alles, was sie streifen
## (je Ziel höchstens einmal pro Takt). Parameter: count, radius, time, speed (Umdrehungen/s), tick, reduction
## (Schutz, solange sie kreisen), size, dazu Treffer-Parameter wie bei EffectSteps.make_hit.

const HIT_RADIUS: float = 0.8
const HEIGHT: float = 1.1

var step: Dictionary = {}
var ctx: EffectContext = null
var count: int = 3
var radius: float = 2.2
var time_left: float = 6.0
var speed: float = 0.6
var tick: float = 0.5
var _angle: float = 0.0
var _blades: Array[MeshInstance3D] = []
var _last_hit: Dictionary = {}


static func spawn(orbit_step: Dictionary, context: EffectContext) -> OrbitBlades:
	var orbit := OrbitBlades.new()
	orbit.step = orbit_step
	orbit.ctx = context
	orbit.count = maxi(1, int(orbit_step.get("count", 3)))
	orbit.radius = float(orbit_step.get("radius", 2.2))
	orbit.time_left = float(orbit_step.get("time", 6.0))
	orbit.speed = float(orbit_step.get("speed", 0.6))
	orbit.tick = float(orbit_step.get("tick", EffectSteps.DEFAULT_TICK))
	Combat.fx_parent(context.tree()).add_child(orbit)
	orbit.global_position = context.caster.global_position
	if orbit_step.has("reduction"):
		context.caster.add_timed_reduction(&"orbit", float(orbit_step["reduction"]), orbit.time_left)
	return orbit


func _ready() -> void:
	var color: Color = EffectSteps.step_color(step, ctx)
	var size: float = float(step.get("size", 0.35))
	for i: int in count:
		var blade := MeshInstance3D.new()
		blade.mesh = Fx.sphere_mesh()
		blade.material_override = Fx.material(color)
		blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		blade.scale = Vector3(size * 0.5, size * 0.5, size * 2.2)
		add_child(blade)
		_blades.append(blade)


func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0 or not ctx.is_valid() or ctx.caster.is_dead():
		queue_free()
		return
	global_position = ctx.caster.global_position
	_angle += delta * speed * TAU
	var now: float = Time.get_ticks_msec() / 1000.0
	var hostiles: Array[Combatant] = Combat.hostiles(get_tree(), ctx.team)
	for i: int in _blades.size():
		var angle: float = _angle + i * TAU / _blades.size()
		var offset := Vector3(cos(angle) * radius, HEIGHT, sin(angle) * radius)
		_blades[i].position = offset
		_blades[i].rotation.y = -angle
		for target: Combatant in Combat.in_radius(hostiles, global_position + offset, HIT_RADIUS + target_radius_hint()):
			var id: int = target.get_instance_id()
			if now - float(_last_hit.get(id, -10.0)) < tick:
				continue
			_last_hit[id] = now
			EffectSteps.strike(target, step, ctx, global_position)


## Etwas Spielraum für große Ziele.
func target_radius_hint() -> float:
	return 0.3
