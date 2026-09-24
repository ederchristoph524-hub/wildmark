class_name Vegetation
extends Node3D
## Dschungel-Vegetation als MultiMesh in Kacheln (Sichtweite je Art begrenzt), dazu Kollision für Baumstämme.

const SEED: int = 1234
## Kachelgröße je Art: große Kacheln für weit sichtbare Bäume (wenige Draw Calls), kleine für Gras (früh ausgeblendet).
const CHUNK_LARGE: float = 80.0
const CHUNK_SMALL: float = 30.0
const TREE_COUNT: int = 380
const BUSH_COUNT: int = 320
const ROCK_COUNT: int = 90
const GRASS_COUNT: int = 2400
const CAMP_CLEAR: float = 19.0
const TRUNK: Color = Color(0.36, 0.26, 0.17)
const LEAF_DARK: Color = Color(0.13, 0.32, 0.16)
const LEAF_MID: Color = Color(0.2, 0.42, 0.18)
const LEAF_LIGHT: Color = Color(0.32, 0.52, 0.2)
const ROCK_COLOR: Color = Color(0.45, 0.45, 0.42)

var terrain: Terrain = null
## Kreise (x, _, z, Radius) ohne Bewuchs.
var clearings: Array[Vector4] = []
var _rng := RandomNumberGenerator.new()
var _colliders: StaticBody3D = null


func _init(world_terrain: Terrain, free_areas: Array[Vector4]) -> void:
	terrain = world_terrain
	clearings = free_areas
	name = "Vegetation"


func _ready() -> void:
	_rng.seed = SEED
	_colliders = StaticBody3D.new()
	_colliders.collision_layer = 1
	_colliders.collision_mask = 0
	add_child(_colliders)
	var tree_meshes: Array[Mesh] = [_broadleaf_mesh(), _palm_mesh(), _cone_tree_mesh()]
	var tree_positions: Array[Transform3D] = _scatter(TREE_COUNT, CAMP_CLEAR, 0.55, Vector2(0.8, 1.35))
	var per_type: Array = [[], [], []]
	for placement: Transform3D in tree_positions:
		var kind: int = _rng.randi_range(0, 2) if placement.origin.y < 9.0 else 2
		(per_type[kind] as Array).append(placement)
		_add_trunk_collider(placement)
	for kind: int in tree_meshes.size():
		_place_chunked(tree_meshes[kind], per_type[kind], 125.0, true, CHUNK_LARGE)
	_place_chunked(_bush_mesh(), _scatter(BUSH_COUNT, 8.0, 0.6, Vector2(0.7, 1.4)), 60.0, false, CHUNK_LARGE)
	_place_chunked(_rock_mesh(), _scatter(ROCK_COUNT, 12.0, 0.9, Vector2(0.5, 2.2)), 100.0, false, CHUNK_LARGE)
	_place_chunked(_grass_mesh(), _scatter(GRASS_COUNT, 4.0, 0.5, Vector2(0.7, 1.3)), 32.0, false, CHUNK_SMALL)


## Zufällige Positionen auf dem Gelände (fester Seed, außerhalb des Lagers, nicht zu steil).
func _scatter(count: int, clear_radius: float, max_slope: float, scale_range: Vector2) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var half: float = Terrain.SIZE * 0.5 - 4.0
	var attempts: int = 0
	while result.size() < count and attempts < count * 6:
		attempts += 1
		var x: float = _rng.randf_range(-half, half)
		var z: float = _rng.randf_range(-half, half)
		if Vector2(x, z).length() < clear_radius or terrain.slope_at(x, z) > max_slope or _in_clearing(x, z):
			continue
		var size: float = _rng.randf_range(scale_range.x, scale_range.y)
		var orientation := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size)
		result.append(Transform3D(orientation, Vector3(x, terrain.height_at(x, z) - 0.1, z)))
	return result


func _in_clearing(x: float, z: float) -> bool:
	for clearing: Vector4 in clearings:
		if Vector2(x - clearing.x, z - clearing.z).length() < clearing.w:
			return true
	return false


## Verteilt Instanzen auf Kacheln, damit ferne Kacheln nicht gezeichnet werden.
func _place_chunked(mesh: Mesh, transforms: Array, view_distance: float, shadows: bool, chunk: float) -> void:
	var chunks: Dictionary = {}
	for placement: Transform3D in transforms:
		var key := Vector2i(floori(placement.origin.x / chunk), floori(placement.origin.z / chunk))
		if not chunks.has(key):
			chunks[key] = []
		(chunks[key] as Array).append(placement)
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = list.size()
		var center := Vector3((key.x + 0.5) * chunk, 0.0, (key.y + 0.5) * chunk)
		for i: int in list.size():
			var local: Transform3D = list[i]
			local.origin -= center
			multimesh.set_instance_transform(i, local)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = WorldMaterials.vertex_colored()
		instance.position = center
		instance.visibility_range_end = view_distance
		instance.visibility_range_end_margin = 8.0
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)


func _add_trunk_collider(placement: Transform3D) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.4 * placement.basis.get_scale().x
	cylinder.height = 4.0
	shape.shape = cylinder
	shape.position = placement.origin + Vector3.UP * 2.0
	_colliders.add_child(shape)


func _broadleaf_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.22, 0.38, 5.2), MeshBuilder.at(Vector3(0, 2.6, 0)), TRUNK)
	b.add(MeshBuilder.sphere(2.3), MeshBuilder.at(Vector3(0, 5.4, 0), Vector3(1.0, 0.5, 1.0)), LEAF_DARK)
	b.add(MeshBuilder.sphere(1.8), MeshBuilder.at(Vector3(0.9, 6.0, 0.4), Vector3(1.0, 0.55, 1.0)), LEAF_MID)
	b.add(MeshBuilder.sphere(1.5), MeshBuilder.at(Vector3(-0.8, 6.3, -0.5), Vector3(1.0, 0.6, 1.0)), LEAF_LIGHT)
	return b.build()


func _palm_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.16, 0.28, 6.5), MeshBuilder.at(Vector3(0.2, 3.25, 0), Vector3.ONE, Vector3(0, 0, 0.06)), TRUNK)
	for i: int in 6:
		var angle: float = i * TAU / 6.0
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		b.add(MeshBuilder.box(Vector3(0.7, 0.08, 2.6)), MeshBuilder.at(Vector3(0.4, 6.4, 0) + dir * 1.1, Vector3.ONE, Vector3(0.35, -angle + PI * 0.5, 0)), LEAF_MID if i % 2 == 0 else LEAF_LIGHT)
	return b.build()


func _cone_tree_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.18, 0.3, 2.0), MeshBuilder.at(Vector3(0, 1.0, 0)), TRUNK)
	b.add(MeshBuilder.cylinder(0.0, 1.9, 3.2, 7), MeshBuilder.at(Vector3(0, 3.2, 0)), LEAF_DARK)
	b.add(MeshBuilder.cylinder(0.0, 1.4, 2.6, 7), MeshBuilder.at(Vector3(0, 4.8, 0)), LEAF_MID)
	return b.build()


func _bush_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.sphere(0.7, 6, 3), MeshBuilder.at(Vector3(0, 0.45, 0), Vector3(1.2, 0.8, 1.0)), LEAF_MID)
	b.add(MeshBuilder.sphere(0.5, 6, 3), MeshBuilder.at(Vector3(0.5, 0.55, 0.2)), LEAF_LIGHT)
	return b.build()


func _rock_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.sphere(0.8, 6, 3), MeshBuilder.at(Vector3(0, 0.3, 0), Vector3(1.3, 0.7, 1.0)), ROCK_COLOR)
	return b.build()


func _grass_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 3:
		b.add(MeshBuilder.cylinder(0.0, 0.07, 0.6, 3), MeshBuilder.at(Vector3(i * 0.12 - 0.12, 0.3, 0), Vector3.ONE, Vector3(0, 0, (i - 1) * 0.3)), LEAF_LIGHT)
	return b.build()
