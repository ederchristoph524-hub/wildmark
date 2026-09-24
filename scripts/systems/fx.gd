class_name Fx
extends RefCounted
## Einfache, geteilte Effekte (Kugeln, Ringe, Strahlen) mit gecachten Materialien – ein Material pro Farbe.

static var _materials: Dictionary = {}
static var _sphere_mesh: SphereMesh = null
static var _ring_mesh: TorusMesh = null
static var _beam_mesh: CylinderMesh = null


## Unbeleuchtetes, leuchtendes Material (für Gu-Effekte vor der gedämpften Welt).
static func material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = mat
	return mat


static func sphere_mesh() -> SphereMesh:
	if _sphere_mesh == null:
		_sphere_mesh = SphereMesh.new()
		_sphere_mesh.radius = 0.5
		_sphere_mesh.height = 1.0
		_sphere_mesh.radial_segments = 12
		_sphere_mesh.rings = 6
	return _sphere_mesh


## Kugel, die kurz aufblitzt und verblasst.
static func sphere(tree: SceneTree, position: Vector3, radius: float, color: Color, duration: float) -> void:
	var node := MeshInstance3D.new()
	node.mesh = sphere_mesh()
	node.material_override = material(Color(color, minf(color.a, 0.55)))
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spawn(tree, node, position)
	node.scale = Vector3.ONE * radius * 0.6
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", Vector3.ONE * radius * 2.0, duration)
	tween.tween_callback(node.queue_free)


## Flacher Ring am Boden.
static func ring(tree: SceneTree, position: Vector3, radius: float, color: Color, duration: float) -> void:
	if _ring_mesh == null:
		_ring_mesh = TorusMesh.new()
		_ring_mesh.inner_radius = 0.9
		_ring_mesh.outer_radius = 1.0
		_ring_mesh.rings = 24
		_ring_mesh.ring_segments = 4
	var node := MeshInstance3D.new()
	node.mesh = _ring_mesh
	node.material_override = material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spawn(tree, node, position + Vector3.UP * 0.15)
	node.scale = Vector3(radius * 0.3, 1.0, radius * 0.3)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", Vector3(radius, 1.0, radius), duration)
	tween.tween_callback(node.queue_free)


## Strahl zwischen zwei Punkten.
static func beam(tree: SceneTree, from: Vector3, to: Vector3, color: Color, duration: float, width: float = 0.25) -> void:
	if _beam_mesh == null:
		_beam_mesh = CylinderMesh.new()
		_beam_mesh.top_radius = 0.5
		_beam_mesh.bottom_radius = 0.5
		_beam_mesh.height = 1.0
		_beam_mesh.radial_segments = 6
		_beam_mesh.rings = 1
	var length: float = from.distance_to(to)
	if length < 0.01:
		return
	var node := MeshInstance3D.new()
	node.mesh = _beam_mesh
	node.material_override = material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spawn(tree, node, (from + to) * 0.5)
	var up: Vector3 = (to - from).normalized()
	var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	node.global_basis = Basis(side * width, up * length, side.cross(up) * width)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", Vector3(0.05, length, 0.05), duration)
	tween.tween_callback(node.queue_free)


static func _spawn(tree: SceneTree, node: Node3D, position: Vector3) -> void:
	Combat.fx_parent(tree).add_child(node)
	node.global_position = position
