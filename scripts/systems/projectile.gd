class_name Projectile
extends Node3D
## Ein Geschoss: fliegt geradeaus (oder zielsuchend), trifft das erste feindliche Ziel (oder mehrere beim Durchdringen),
## explodiert optional, springt als Kette weiter und löst am Aufschlag Wirkungsschritte aus (impact).

const WORLD_MASK: int = 1
const HOMING_TURN: float = 5.0
const CHAIN_FALLOFF: float = 0.8

var hit: HitInfo = null
var direction: Vector3 = Vector3.FORWARD
var speed: float = 24.0
var max_distance: float = 14.0
var radius: float = 0.35
var explode_radius: float = 0.0
## Wie viele Ziele es zusätzlich durchdringt.
var pierce: int = 0
var color: Color = Color.WHITE
var homing: bool = false
## Kettensprünge nach dem Treffer (Kettenblitz) und ihr Umkreis.
var chain: int = 0
var chain_radius: float = 6.0
## Wirkungsschritte am Aufschlagpunkt (Ranggabe impact) samt Kontext.
var impact: Array = []
var impact_ctx: EffectContext = null

var _trail: CPUParticles3D = null
var _travelled: float = 0.0
var _already_hit: Array[Combatant] = []


static func launch(tree: SceneTree, from: Vector3, template: HitInfo, dir: Vector3, config: Dictionary) -> Projectile:
	var projectile := Projectile.new()
	projectile.hit = template
	projectile.direction = dir.normalized()
	projectile.speed = config.get("speed", Balance.values.projectile_speed)
	projectile.max_distance = config.get("range", 14.0)
	projectile.explode_radius = config.get("explode_radius", 0.0)
	projectile.pierce = config.get("pierce", 0)
	projectile.color = config.get("color", Color.WHITE)
	projectile.radius = config.get("radius", Balance.values.projectile_radius)
	projectile.homing = config.get("homing", false)
	projectile.chain = config.get("chain", 0)
	projectile.chain_radius = config.get("chain_radius", 6.0)
	projectile.impact = config.get("impact", [])
	projectile.impact_ctx = config.get("impact_ctx", null)
	Combat.fx_parent(tree).add_child(projectile)
	projectile.global_position = from
	return projectile


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = Fx.sphere_mesh()
	mesh.material_override = Fx.material(color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.scale = Vector3(radius, radius, radius * 2.2) * 1.4
	add_child(mesh)
	_trail = GuVfx.trail(self, GuVfx.style_of(hit.path, hit.tags), radius / 0.35)
	if direction.length_squared() > 0.0:
		look_at(global_position + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)


func _physics_process(delta: float) -> void:
	if homing:
		_steer(delta)
	var step: float = speed * delta
	var from: Vector3 = global_position
	var to: Vector3 = from + direction * step
	if _check_targets(from, to):
		return
	if _hits_world(from, to):
		_finish(to)
		return
	global_position = to
	_travelled += step
	if _travelled >= max_distance:
		_finish(global_position)


func _check_targets(from: Vector3, to: Vector3) -> bool:
	for target: Combatant in Combat.on_line(Combat.hostiles(get_tree(), hit.team), from, to, radius * 2.0):
		if target in _already_hit:
			continue
		if target.reflect_time > 0.0:
			_reflect(target)
			return false
		_already_hit.append(target)
		if explode_radius > 0.0:
			_finish(target.aim_point())
			return true
		target.receive_hit(_with_knockback(target))
		if chain > 0:
			_chain_from(target)
		if pierce <= 0:
			_run_impact(target.global_position)
			GuVfx.release(_trail)
			queue_free()
			return true
		pierce -= 1
	return false


## Eisenhaut: Das Geschoss fliegt zurück und gehört nun dem Getroffenen.
func _reflect(target: Combatant) -> void:
	direction = -direction
	hit.team = target.team
	hit.source = target
	_already_hit.clear()
	_already_hit.append(target)
	_travelled = 0.0
	Fx.ring(get_tree(), global_position, 0.8, Color(0.8, 0.8, 0.9), 0.2)


func _hits_world(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _with_knockback(target: Combatant) -> HitInfo:
	if hit.knockback != Vector3.ZERO:
		var push: Vector3 = (target.global_position - global_position)
		push.y = 0.0
		hit.knockback = push.normalized() * hit.knockback.length()
	return hit


func _finish(point: Vector3) -> void:
	if explode_radius > 0.0:
		for target: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), hit.team), point, explode_radius):
			target.receive_hit(hit)
		Fx.sphere(get_tree(), point, explode_radius, Color(color, 0.6), 0.3)
	var style: StringName = GuVfx.style_of(hit.path, hit.tags)
	GuVfx.burst(get_tree(), point, style, maxf(1.0, explode_radius / 1.5), 1.2 if explode_radius > 0.0 else 0.7)
	_run_impact(point)
	GuVfx.release(_trail)
	queue_free()


## Zielsuchend: lenkt sanft zum nächsten Gegner vor sich.
func _steer(delta: float) -> void:
	var ahead: Vector3 = global_position + direction * 6.0
	var candidates: Array[Combatant] = []
	for other: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), hit.team), ahead, 8.0):
		if other not in _already_hit and other.team != Combatant.TEAM_WORLD:
			candidates.append(other)
	var goal: Combatant = Combat.nearest(candidates, global_position)
	if goal != null:
		direction = direction.slerp((goal.aim_point() - global_position).normalized(), clampf(delta * HOMING_TURN, 0.0, 1.0)).normalized()


## Kettenblitz: springt vom getroffenen Ziel auf die nächsten (je Sprung etwas schwächer).
func _chain_from(first: Combatant) -> void:
	var from: Combatant = first
	var struck: Array[Combatant] = [first]
	for jump: int in chain:
		var options: Array[Combatant] = []
		for other: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), hit.team), from.global_position, chain_radius):
			if other not in struck:
				options.append(other)
		var next: Combatant = Combat.nearest(options, from.global_position)
		if next == null:
			return
		Fx.beam(get_tree(), from.aim_point(), next.aim_point(), color, 0.25, 0.18)
		next.receive_hit(hit.derived(hit.damage * pow(CHAIN_FALLOFF, jump + 1)))
		struck.append(next)
		from = next
	chain = 0


func _run_impact(point: Vector3) -> void:
	if impact.is_empty() or impact_ctx == null or not impact_ctx.is_valid():
		return
	EffectSteps.run(impact, impact_ctx.at_point(point))
	impact = []
