class_name Vegetation
extends Node3D
## Vegetation eines Gebiets nach Biom (Baumarten und Dichten aus gebiete.json) als MultiMesh in Kacheln
## (Sichtweite je Art begrenzt), dazu Kollision für Baumstämme. Siedlungen, Orte und Seen bleiben frei.

const SEED: int = 1234
## Kachelgröße je Art: große Kacheln für weit sichtbare Bäume (wenige Draw Calls), kleine für Gras (früh ausgeblendet).
const CHUNK_LARGE: float = 80.0
const CHUNK_SMALL: float = 30.0
const TREE_VIEW: float = 150.0
const TRUNK: Color = Color(0.36, 0.26, 0.17)
const LEAF_DARK: Color = Color(0.12, 0.27, 0.14)
const LEAF_MID: Color = Color(0.18, 0.35, 0.16)
const LEAF_LIGHT: Color = Color(0.27, 0.43, 0.18)
const BAMBOO: Color = Color(0.42, 0.52, 0.27)
const BAMBOO_DARK: Color = Color(0.3, 0.4, 0.2)
const ROCK_COLOR: Color = Color(0.45, 0.45, 0.42)
## Oberhalb dieser Höhe wachsen nur noch Nadelbäume.
const TREE_LINE: float = 18.0

var terrain: Terrain = null
var biome: BiomeData = null
## Kreise (x, _, z, Radius) ohne Bewuchs.
var clearings: Array[Vector4] = []
var _rng := RandomNumberGenerator.new()
var _colliders: StaticBody3D = null


func _init(world_terrain: Terrain, free_areas: Array[Vector4], biome_data: BiomeData) -> void:
	terrain = world_terrain
	clearings = free_areas
	biome = biome_data
	name = "Vegetation"


func _ready() -> void:
	_rng.seed = SEED + terrain.area.terrain_seed
	_colliders = StaticBody3D.new()
	_colliders.collision_layer = 1
	_colliders.collision_mask = 0
	add_child(_colliders)
	var area_k: float = pow(terrain.size - terrain.area.relief.get(&"rand", 40.0), 2.0) / 1000.0
	_place_trees(roundi(biome.trees_per_1000 * area_k))
	_place_chunked(_bush_mesh(), _scatter(roundi(biome.bushes_per_1000 * area_k), 0.6, Vector2(0.7, 1.4)), 70.0, false, CHUNK_LARGE)
	_place_chunked(_rock_mesh(), _scatter(roundi(biome.rocks_per_1000 * area_k), 0.9, Vector2(0.5, 2.4)), 110.0, false, CHUNK_LARGE)
	_place_chunked(_grass_mesh(), _scatter(roundi(biome.grass_per_1000 * area_k), 0.5, Vector2(0.7, 1.3)), 32.0, false, CHUNK_SMALL)


## Baumarten nach Biom-Anteilen; über der Baumgrenze nur Nadelbäume.
func _place_trees(count: int) -> void:
	var meshes: Dictionary[StringName, Mesh] = {&"laubbaum": _broadleaf_mesh(), &"palme": _palm_mesh(), &"nadelbaum": _cone_tree_mesh(), &"bambus": _bamboo_mesh()}
	var kinds: Array[StringName] = []
	var weights: Array[float] = []
	for kind: StringName in biome.vegetation:
		if meshes.has(kind):
			kinds.append(kind)
			weights.append(biome.vegetation[kind])
	if kinds.is_empty():
		return
	var per_type: Dictionary[StringName, Array] = {}
	for placement: Transform3D in _scatter(count, 0.55, Vector2(0.8, 1.35)):
		var kind: StringName = kinds[_rng.rand_weighted(PackedFloat32Array(weights))] if placement.origin.y < TREE_LINE else &"nadelbaum"
		if not per_type.has(kind):
			per_type[kind] = []
		per_type[kind].append(placement)
		_add_trunk_collider(placement, 0.25 if kind == &"bambus" else 0.4)
	for kind: StringName in per_type:
		_place_chunked(meshes.get(kind, meshes[&"nadelbaum"]), per_type[kind], TREE_VIEW, true, CHUNK_LARGE)


## Zufällige Positionen im begehbaren Bereich (fester Seed, nicht zu steil, nicht auf Plätzen oder im Wasser).
func _scatter(count: int, max_slope: float, scale_range: Vector2) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var half: float = terrain.size * 0.5 - 4.0
	var attempts: int = 0
	while result.size() < count and attempts < count * 5:
		attempts += 1
		var x: float = _rng.randf_range(-half, half)
		var z: float = _rng.randf_range(-half, half)
		if terrain.slope_at(x, z) > max_slope or _in_clearing(x, z) or terrain.in_water(x, z) or terrain.near_path(x, z):
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


func _add_trunk_collider(placement: Transform3D, radius: float) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius * placement.basis.get_scale().x
	cylinder.height = 4.0
	shape.shape = cylinder
	shape.position = placement.origin + Vector3.UP * 2.0
	_colliders.add_child(shape)


## Bambushain: schlanke, leicht geneigte Halme mit Knoten und hängenden Blattbüscheln (wenige Dreiecke).
func _bamboo_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 5:
		var angle: float = i * TAU / 5.0 + 0.3
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * (0.3 + (i % 3) * 0.28)
		var height: float = 6.5 + (i % 3) * 1.4
		var tilt := Vector3(sin(angle) * 0.07, 0.0, -cos(angle) * 0.07)
		var tip: Vector3 = offset + Basis.from_euler(tilt) * Vector3(0, height, 0)
		b.add(MeshBuilder.cylinder(0.06, 0.09, height, 4), MeshBuilder.at(offset + Basis.from_euler(tilt) * Vector3(0, height * 0.5, 0), Vector3.ONE, tilt), BAMBOO if i % 2 == 0 else BAMBOO_DARK)
		for leaf: int in 3:
			var leaf_angle: float = angle + leaf * 2.1
			var dir := Vector3(cos(leaf_angle), 0.0, sin(leaf_angle))
			b.add(MeshBuilder.box(Vector3(0.18, 0.04, 1.3)), Transform3D(Basis(Vector3.UP, -leaf_angle + PI * 0.5) * Basis(Vector3.RIGHT, 0.5), tip - Vector3(0, 0.4 + leaf * 0.5, 0) + dir * 0.5), LEAF_MID if leaf % 2 == 0 else LEAF_LIGHT)
	return b.build()


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
	for i: int in 5:
		var angle: float = i * TAU / 5.0
		var height: float = 0.45 + (i % 3) * 0.12
		b.add(MeshBuilder.cylinder(0.0, 0.05, height, 3), MeshBuilder.at(Vector3(cos(angle) * 0.08, height * 0.5, sin(angle) * 0.08), Vector3.ONE, Vector3(sin(angle) * 0.35, 0, -cos(angle) * 0.35)), LEAF_MID if i % 2 == 0 else LEAF_LIGHT)
	return b.build()
