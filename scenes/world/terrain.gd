class_name Terrain
extends StaticBody3D
## Low-Poly-Gelände der Südlichen Grenze aus festem Rauschen: flach schattiertes Mesh, passende Kollision, Höhenabfrage.

const SIZE: float = 240.0
const CELL: float = 2.0
const NOISE_SEED: int = 4711
const HEIGHT_SCALE: float = 7.0
const EDGE_START: float = 96.0
const EDGE_HEIGHT: float = 26.0
const CAMP_RADIUS: float = 16.0
const GRASS_DARK: Color = Color(0.2, 0.42, 0.22)
const GRASS_LIGHT: Color = Color(0.34, 0.56, 0.28)
const MOSS: Color = Color(0.4, 0.5, 0.2)
const DIRT: Color = Color(0.42, 0.34, 0.22)
const ROCK: Color = Color(0.36, 0.36, 0.33)

var resolution: int = int(SIZE / CELL) + 1
var heights: PackedFloat32Array = PackedFloat32Array()
var _noise: FastNoiseLite = null
var _detail: FastNoiseLite = null


func _init() -> void:
	name = "Terrain"
	collision_layer = 1
	collision_mask = 0
	_noise = FastNoiseLite.new()
	_noise.seed = NOISE_SEED
	_noise.frequency = 0.011
	_noise.fractal_octaves = 3
	_detail = FastNoiseLite.new()
	_detail.seed = NOISE_SEED + 1
	_detail.frequency = 0.08
	_generate_heights()


func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_mesh()
	mesh_instance.material_override = WorldMaterials.vertex_colored()
	add_child(mesh_instance)
	var shape := HeightMapShape3D.new()
	shape.map_width = resolution
	shape.map_depth = resolution
	shape.map_data = heights
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3(CELL, 1.0, CELL)
	add_child(collision)


## Rohe Höhe aus Rauschen, Randgebirge und flachem Lagerplatz in der Mitte.
func raw_height(x: float, z: float) -> float:
	var h: float = _noise.get_noise_2d(x, z) * HEIGHT_SCALE + _detail.get_noise_2d(x, z) * 0.6
	var edge: float = maxf(absf(x), absf(z))
	h += smoothstep(EDGE_START, SIZE * 0.5, edge) * EDGE_HEIGHT
	var camp: float = Vector2(x, z).length()
	var camp_height: float = _noise.get_noise_2d(0.0, 0.0) * HEIGHT_SCALE
	return lerpf(camp_height, h, smoothstep(CAMP_RADIUS * 0.6, CAMP_RADIUS * 1.6, camp))


func _generate_heights() -> void:
	heights.resize(resolution * resolution)
	var half: float = SIZE * 0.5
	for iz: int in resolution:
		for ix: int in resolution:
			heights[iz * resolution + ix] = raw_height(ix * CELL - half, iz * CELL - half)


## Höhe an einer Weltposition, bilinear aus demselben Raster wie Mesh und Kollision.
func height_at(x: float, z: float) -> float:
	var half: float = SIZE * 0.5
	var fx: float = clampf((x + half) / CELL, 0.0, resolution - 1.001)
	var fz: float = clampf((z + half) / CELL, 0.0, resolution - 1.001)
	var ix: int = floori(fx)
	var iz: int = floori(fz)
	var tx: float = fx - ix
	var tz: float = fz - iz
	var h00: float = heights[iz * resolution + ix]
	var h10: float = heights[iz * resolution + ix + 1]
	var h01: float = heights[(iz + 1) * resolution + ix]
	var h11: float = heights[(iz + 1) * resolution + ix + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func slope_at(x: float, z: float) -> float:
	var dx: float = height_at(x + 1.0, z) - height_at(x - 1.0, z)
	var dz: float = height_at(x, z + 1.0) - height_at(x, z - 1.0)
	return Vector2(dx, dz).length() * 0.5


func is_inside(x: float, z: float, margin: float = 0.0) -> bool:
	return absf(x) < EDGE_START - margin and absf(z) < EDGE_START - margin


func _build_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var half: float = SIZE * 0.5
	for iz: int in resolution - 1:
		for ix: int in resolution - 1:
			var p00 := Vector3(ix * CELL - half, heights[iz * resolution + ix], iz * CELL - half)
			var p10 := Vector3((ix + 1) * CELL - half, heights[iz * resolution + ix + 1], iz * CELL - half)
			var p01 := Vector3(ix * CELL - half, heights[(iz + 1) * resolution + ix], (iz + 1) * CELL - half)
			var p11 := Vector3((ix + 1) * CELL - half, heights[(iz + 1) * resolution + ix + 1], (iz + 1) * CELL - half)
			_add_triangle(vertices, normals, colors, p00, p10, p11)
			_add_triangle(vertices, normals, colors, p00, p11, p01)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Ein Dreieck mit eigener Normale (flache Facetten) und Farbe nach Neigung und Höhe.
func _add_triangle(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a).normalized()
	var center: Vector3 = (a + b + c) / 3.0
	var color: Color = _color_for(center, normal)
	for point: Vector3 in [a, b, c]:
		vertices.append(point)
		normals.append(normal)
		colors.append(color)


func _color_for(center: Vector3, normal: Vector3) -> Color:
	var steep: float = 1.0 - normal.y
	var variation: float = (_detail.get_noise_2d(center.x * 0.7, center.z * 0.7) + 1.0) * 0.5
	var color: Color = GRASS_DARK.lerp(GRASS_LIGHT, variation)
	if variation > 0.78:
		color = color.lerp(MOSS, 0.5)
	if Vector2(center.x, center.z).length() < CAMP_RADIUS * 0.7:
		color = color.lerp(DIRT, 0.55)
	if steep > 0.18:
		color = color.lerp(DIRT, clampf((steep - 0.18) * 4.0, 0.0, 1.0))
	if steep > 0.35 or center.y > 12.0:
		color = color.lerp(ROCK, clampf((steep - 0.3) * 3.0 + (center.y - 12.0) * 0.1, 0.0, 1.0))
	return color
