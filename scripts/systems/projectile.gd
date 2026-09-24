class_name Projectile
extends Node3D
## Ein Geschoss: fliegt geradeaus, trifft das erste feindliche Ziel (oder mehrere beim Durchdringen) und explodiert optional.

const WORLD_MASK: int = 1

var hit: HitInfo = null
var direction: Vector3 = Vector3.FORWARD
var speed: float = 24.0
var max_distance: float = 14.0
var radius: float = 0.35
var explode_radius: float = 0.0
## Wie viele Ziele es zusätzlich durchdringt.
var pierce: int = 0
var color: Color = Color.WHITE

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
	if direction.length_squared() > 0.0:
		look_at(global_position + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)


func _physics_process(delta: float) -> void:
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
		_already_hit.append(target)
		if explode_radius > 0.0:
			_finish(target.aim_point())
			return true
		target.receive_hit(_with_knockback(target))
		if pierce <= 0:
			queue_free()
			return true
		pierce -= 1
	return false


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
	queue_free()
