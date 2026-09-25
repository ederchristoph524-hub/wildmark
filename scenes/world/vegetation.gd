class_name Vegetation
extends Node3D
## Vegetation eines Gebiets nach Biom (Baumarten und Dichten aus gebiete.json) als MultiMesh in Kacheln
## (Sichtweite je Art begrenzt), dazu Kollision für Baumstämme. Siedlungen, Orte und Seen bleiben frei.

const SEED: int = 1234
## Kachelgröße je Art: große Kacheln für weit sichtbare Bäume (wenige Draw Calls), kleine für Gras (früh ausgeblendet).
const CHUNK_LARGE: float = 80.0
const CHUNK_SMALL: float = 30.0
const TREE_VIEW: float = 135.0
## Oberhalb dieser Höhe wachsen nur noch Nadelbäume.
const TREE_LINE: float = 18.0
## Mindestabstand zwischen Stämmen (keine Bäume ineinander).
const TREE_SPACING: float = 3.2
## Helligkeitsstreuung je Pflanze.
const COLOR_JITTER: float = 0.09

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
	var bushes: Array[Transform3D] = _scatter(roundi(biome.bushes_per_1000 * area_k), 0.6, Vector2(0.7, 1.4))
	var half: int = floori(bushes.size() / 2.0)
	_place_chunked(VegetationMeshes.bush(), bushes.slice(0, half), 70.0, false, CHUNK_LARGE)
	_place_chunked(VegetationMeshes.fern(), bushes.slice(half), 60.0, false, CHUNK_LARGE)
	var stone: Color = biome.color(&"fels", VegetationMeshes.ROCK)
	var dry: bool = biome.vegetation.has(&"kaktus")
	var rock_mesh: ArrayMesh = VegetationMeshes.rock(stone, stone.lightened(0.15) if dry else VegetationMeshes.MOSS)
	_place_chunked(rock_mesh, _scatter(roundi(biome.rocks_per_1000 * area_k), 0.9, Vector2(0.5, 2.4)), 110.0, false, CHUNK_LARGE, false)
	var grass: Array[Transform3D] = _scatter(roundi(biome.grass_per_1000 * area_k * GraphicsSettings.grass_mult()), 0.5, Vector2(0.7, 1.3))
	var flowers: int = floori(grass.size() / 8.0)
	var tall: bool = biome.vegetation.has(&"steppengras")
	_place_chunked(VegetationMeshes.tall_grass() if tall else VegetationMeshes.grass(), grass.slice(flowers), 32.0 if not tall else 45.0, false, CHUNK_SMALL)
	_place_chunked(VegetationMeshes.flowers(), grass.slice(0, flowers), 32.0, false, CHUNK_SMALL)


## Baumarten nach Biom-Anteilen; über der Baumgrenze nur Nadelbäume.
func _place_trees(count: int) -> void:
	var meshes: Dictionary[StringName, Mesh] = {&"laubbaum": VegetationMeshes.broadleaf(), &"laubbaum_rund": VegetationMeshes.round_tree(), &"palme": VegetationMeshes.palm(),
		&"nadelbaum": VegetationMeshes.pine(), &"bambus": VegetationMeshes.bamboo(), &"kaktus": VegetationMeshes.cactus(), &"totholz": VegetationMeshes.dead_tree()}
	var kinds: Array[StringName] = []
	var weights: Array[float] = []
	for kind: StringName in biome.vegetation:
		if meshes.has(kind):
			kinds.append(kind)
			weights.append(biome.vegetation[kind])
	if kinds.is_empty():
		return
	var per_type: Dictionary[StringName, Array] = {}
	for placement: Transform3D in _spaced(_scatter(count, 0.55, Vector2(0.8, 1.35)), TREE_SPACING):
		var above_line: bool = placement.origin.y >= TREE_LINE and biome.vegetation.has(&"nadelbaum")
		var kind: StringName = &"nadelbaum" if above_line else kinds[_rng.rand_weighted(PackedFloat32Array(weights))]
		if kind == &"laubbaum" and _rng.randf() < 0.45:
			kind = &"laubbaum_rund"
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


## Verwirft Positionen, die näher als spacing an einer schon gewählten liegen (Raster als Suchhilfe).
func _spaced(placements: Array[Transform3D], spacing: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var grid: Dictionary[Vector2i, Array] = {}
	for placement: Transform3D in placements:
		var cell := Vector2i(floori(placement.origin.x / spacing), floori(placement.origin.z / spacing))
		var free: bool = true
		for dz: int in range(-1, 2):
			for dx: int in range(-1, 2):
				for other: Vector3 in grid.get(cell + Vector2i(dx, dz), []):
					if Vector2(other.x - placement.origin.x, other.z - placement.origin.z).length() < spacing:
						free = false
		if not free:
			continue
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(placement.origin)
		result.append(placement)
	return result


func _in_clearing(x: float, z: float) -> bool:
	for clearing: Vector4 in clearings:
		if Vector2(x - clearing.x, z - clearing.z).length() < clearing.w:
			return true
	return false


## Verteilt Instanzen auf Kacheln, damit ferne Kacheln nicht gezeichnet werden. Pflanzen erhalten die Tönung des
## Bioms und je Instanz eine leichte Farbabweichung (tinted = false für Felsen).
func _place_chunked(mesh: Mesh, transforms: Array, view_distance: float, shadows: bool, chunk: float, tinted: bool = true) -> void:
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
		multimesh.use_colors = true
		multimesh.mesh = mesh
		multimesh.instance_count = list.size()
		var center := Vector3((key.x + 0.5) * chunk, 0.0, (key.y + 0.5) * chunk)
		for i: int in list.size():
			var local: Transform3D = list[i]
			local.origin -= center
			multimesh.set_instance_transform(i, local)
			var shade: float = _rng.randf_range(1.0 - COLOR_JITTER, 1.0 + COLOR_JITTER)
			var tint: Color = biome.plant_tint if tinted else Color.WHITE
			multimesh.set_instance_color(i, Color(tint.r * shade, tint.g * shade * _rng.randf_range(0.97, 1.03), tint.b * shade))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = WorldMaterials.vertex_colored()
		instance.position = center
		instance.visibility_range_end = view_distance * GraphicsSettings.view_mult()
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
