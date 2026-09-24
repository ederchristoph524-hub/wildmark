class_name Terrain
extends StaticBody3D
## Gelände eines Gebiets aus Rauschen und Gebietsdaten: Berge, Randgebirge, eingeebnete Plätze für Siedlungen und Orte,
## Seen und Wege. Gezeichnet in Kacheln (Sichtweite begrenzt), eine Höhenfeld-Kollision, Höhen- und Farbabfrage für Karten.

const TERRAIN_SHADER: Shader = preload("res://assets/shaders/terrain.gdshader")
const CELL: float = 2.5
## Zellen pro Kachel (Kachel = 80 m) und Sichtweite der Kacheln.
const CHUNK_CELLS: int = 32
const CHUNK_VIEW: float = 260.0
const PATH_WIDTH: float = 2.6
const LAKE_DEPTH: float = 1.4
const PEAK_HEIGHT: float = 26.0

var area: AreaData = null
var biome: BiomeData = null
var size: float = 240.0
var resolution: int = 97
var heights: PackedFloat32Array = PackedFloat32Array()
var colors: PackedColorArray = PackedColorArray()
## Eingeebnete Flächen: (x, z, Radius, Übergang); Seen: (x, z, Radius, Wasserhöhe nach dem Bau).
var flats: Array[Vector4] = []
var lakes: Array[Vector4] = []
## Flächen mit Platz-Farbe (Siedlungen): (x, z, Radius, 0).
var plazas: Array[Vector4] = []
var paths: Array = []
## Gitterpunkte auf Wegen (vorab berechnet, spart beim Einfärben die Suche über alle Wegstücke).
var _path_mask: PackedByteArray = PackedByteArray()
var _noise := FastNoiseLite.new()
var _ridges := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _material: ShaderMaterial = null


func _init(area_data: AreaData, biome_data: BiomeData) -> void:
	name = "Terrain"
	collision_layer = 1
	collision_mask = 0
	area = area_data
	biome = biome_data
	size = area.size
	resolution = int(size / CELL) + 1
	_noise.seed = area.terrain_seed
	_noise.frequency = area.relief.get(&"frequenz", 0.005)
	_noise.fractal_octaves = 4
	_ridges.seed = area.terrain_seed + 7
	_ridges.frequency = area.relief.get(&"frequenz", 0.005) * 1.7
	_ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridges.fractal_octaves = 3
	_detail.seed = area.terrain_seed + 1
	_detail.frequency = 0.08


## Baut Höhen und Farben (nach dem Eintragen von Plätzen, Seen und Wegen aufrufen).
func generate() -> void:
	heights.resize(resolution * resolution)
	var half: float = size * 0.5
	for iz: int in resolution:
		for ix: int in resolution:
			heights[iz * resolution + ix] = raw_height(ix * CELL - half, iz * CELL - half)
	_apply_flats()
	_apply_lakes()
	_paint()


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = TERRAIN_SHADER
	var chunks: int = ceili(float(resolution - 1) / CHUNK_CELLS)
	for cz: int in chunks:
		for cx: int in chunks:
			add_child(_build_chunk(cx, cz))
	add_child(TerrainBackdrop.build(self, _material))
	var shape := HeightMapShape3D.new()
	shape.map_width = resolution
	shape.map_depth = resolution
	shape.map_data = heights
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3(CELL, 1.0, CELL)
	add_child(collision)


## Rohe Höhe: weite Hügel, Bergkämme (nur wo das Grundrauschen hoch ist), Feinheit und Randgebirge.
func raw_height(x: float, z: float) -> float:
	var base: float = _noise.get_noise_2d(x, z)
	var h: float = base * area.relief.get(&"hoehe", 10.0)
	var ridge_mask: float = smoothstep(0.0, 0.45, base + 0.1)
	h += (_ridges.get_noise_2d(x, z) * 0.5 + 0.5) * area.relief.get(&"berge", 0.0) * ridge_mask
	h += _detail.get_noise_2d(x, z) * area.relief.get(&"detail", 0.6)
	var edge: float = maxf(absf(x), absf(z))
	var rim: float = area.relief.get(&"rand", 40.0)
	h += smoothstep(size * 0.5 - rim, size * 0.5, edge) * area.relief.get(&"randhoehe", 30.0)
	return h


func _apply_flats() -> void:
	for flat: Vector4 in flats:
		var target: float = _average_height(flat.x, flat.y, flat.z * 0.6)
		_blend_region(flat, func(h: float, weight: float) -> float: return lerpf(h, target, weight))


func _apply_lakes() -> void:
	for i: int in lakes.size():
		var lake: Vector4 = lakes[i]
		var rim: float = _average_height(lake.x, lake.y, lake.z)
		var region := Vector4(lake.x, lake.y, lake.z + 6.0, 10.0)
		_blend_region(region, func(h: float, weight: float) -> float: return lerpf(h, rim, weight))
		var half: float = size * 0.5
		for iz: int in resolution:
			for ix: int in resolution:
				var d: float = Vector2(ix * CELL - half - lake.x, iz * CELL - half - lake.y).length()
				if d < lake.z:
					var bowl: float = LAKE_DEPTH * (1.0 - pow(d / lake.z, 2.0))
					heights[iz * resolution + ix] = minf(heights[iz * resolution + ix], rim - bowl)
		lakes[i] = Vector4(lake.x, lake.y, lake.z, rim - 0.25)


## Wendet eine Funktion (Höhe, Gewicht) → Höhe auf einen Kreis mit weichem Rand an.
func _blend_region(region: Vector4, blend: Callable) -> void:
	var half: float = size * 0.5
	var reach: float = region.z + region.w
	var min_ix: int = maxi(0, floori((region.x - reach + half) / CELL))
	var max_ix: int = mini(resolution - 1, ceili((region.x + reach + half) / CELL))
	var min_iz: int = maxi(0, floori((region.y - reach + half) / CELL))
	var max_iz: int = mini(resolution - 1, ceili((region.y + reach + half) / CELL))
	for iz: int in range(min_iz, max_iz + 1):
		for ix: int in range(min_ix, max_ix + 1):
			var d: float = Vector2(ix * CELL - half - region.x, iz * CELL - half - region.y).length()
			var weight: float = 1.0 - smoothstep(region.z, maxf(reach, region.z + 0.01), d)
			if weight > 0.0:
				heights[iz * resolution + ix] = blend.call(heights[iz * resolution + ix], weight)


func _average_height(x: float, z: float, radius: float) -> float:
	var total: float = 0.0
	for i: int in 9:
		var angle: float = i * TAU / 8.0
		var r: float = 0.0 if i == 8 else radius
		total += raw_height(x + cos(angle) * r, z + sin(angle) * r)
	return total / 9.0


## Farbe je Gitterpunkt: Gras, Moos, Erde an Hängen, Fels, Gipfel, Plätze, Wege, Seeufer.
func _paint() -> void:
	colors.resize(resolution * resolution)
	_mark_paths()
	var half: float = size * 0.5
	for iz: int in resolution:
		for ix: int in resolution:
			var x: float = ix * CELL - half
			var z: float = iz * CELL - half
			colors[iz * resolution + ix] = _color_at(x, z, _grid_normal(ix, iz), heights[iz * resolution + ix], _path_mask[iz * resolution + ix] == 1)


func _grid_normal(ix: int, iz: int) -> Vector3:
	var left: float = heights[iz * resolution + maxi(ix - 1, 0)]
	var right: float = heights[iz * resolution + mini(ix + 1, resolution - 1)]
	var up: float = heights[maxi(iz - 1, 0) * resolution + ix]
	var down: float = heights[mini(iz + 1, resolution - 1) * resolution + ix]
	return Vector3(left - right, CELL * 2.0, up - down).normalized()


func _color_at(x: float, z: float, normal: Vector3, h: float, on_path: bool) -> Color:
	var steep: float = 1.0 - normal.y
	var variation: float = (_detail.get_noise_2d(x * 0.7, z * 0.7) + 1.0) * 0.5
	var color: Color = biome.color(&"gras_dunkel").lerp(biome.color(&"gras_hell"), variation)
	if variation > 0.74:
		color = color.lerp(biome.color(&"moos"), 0.5)
	if steep > 0.16:
		color = color.lerp(biome.color(&"erde"), clampf((steep - 0.16) * 4.0, 0.0, 1.0))
	if steep > 0.32:
		color = color.lerp(biome.color(&"fels"), clampf((steep - 0.32) * 3.5, 0.0, 1.0))
	if h > PEAK_HEIGHT:
		color = color.lerp(biome.color(&"gipfel"), clampf((h - PEAK_HEIGHT) * 0.08, 0.0, 0.9))
	for plaza: Vector4 in plazas:
		var d: float = Vector2(x - plaza.x, z - plaza.y).length()
		if d < plaza.z:
			color = color.lerp(biome.color(&"platz"), (1.0 - smoothstep(plaza.z * 0.75, plaza.z, d)) * (0.55 + 0.35 * variation))
	for lake: Vector4 in lakes:
		var shore: float = Vector2(x - lake.x, z - lake.y).length() - lake.z
		if shore < 3.0:
			color = color.lerp(biome.color(&"erde"), clampf(1.0 - shore / 3.0, 0.0, 0.8))
	if on_path:
		color = color.lerp(biome.color(&"weg"), 0.8)
	return color


## Markiert alle Gitterpunkte nahe eines Wegstücks (nur im Umkreis jedes Stücks gesucht).
func _mark_paths() -> void:
	_path_mask.resize(resolution * resolution)
	_path_mask.fill(0)
	var half: float = size * 0.5
	for path: Array in paths:
		for i: int in path.size() - 1:
			var a: Vector2 = path[i]
			var b: Vector2 = path[i + 1]
			var min_ix: int = maxi(0, floori((minf(a.x, b.x) - PATH_WIDTH + half) / CELL))
			var max_ix: int = mini(resolution - 1, ceili((maxf(a.x, b.x) + PATH_WIDTH + half) / CELL))
			var min_iz: int = maxi(0, floori((minf(a.y, b.y) - PATH_WIDTH + half) / CELL))
			var max_iz: int = mini(resolution - 1, ceili((maxf(a.y, b.y) + PATH_WIDTH + half) / CELL))
			for iz: int in range(min_iz, max_iz + 1):
				for ix: int in range(min_ix, max_ix + 1):
					var point := Vector2(ix * CELL - half, iz * CELL - half)
					if Geometry2D.get_closest_point_to_segment(point, a, b).distance_to(point) < PATH_WIDTH:
						_path_mask[iz * resolution + ix] = 1


## Liegt der Punkt auf einem Weg (nächster Gitterpunkt)?
func near_path(x: float, z: float) -> bool:
	if _path_mask.is_empty():
		return false
	var half: float = size * 0.5
	var ix: int = clampi(roundi((x + half) / CELL), 0, resolution - 1)
	var iz: int = clampi(roundi((z + half) / CELL), 0, resolution - 1)
	return _path_mask[iz * resolution + ix] == 1


## Eine Kachel als indiziertes Mesh mit Normalen aus dem Höhenraster.
func _build_chunk(cx: int, cz: int) -> MeshInstance3D:
	var half: float = size * 0.5
	var x0: int = cx * CHUNK_CELLS
	var z0: int = cz * CHUNK_CELLS
	var x1: int = mini(x0 + CHUNK_CELLS, resolution - 1)
	var z1: int = mini(z0 + CHUNK_CELLS, resolution - 1)
	var width: int = x1 - x0 + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var vertex_colors := PackedColorArray()
	var indices := PackedInt32Array()
	var center := Vector3((x0 + x1) * 0.5 * CELL - half, 0.0, (z0 + z1) * 0.5 * CELL - half)
	for iz: int in range(z0, z1 + 1):
		for ix: int in range(x0, x1 + 1):
			vertices.append(Vector3(ix * CELL - half, heights[iz * resolution + ix], iz * CELL - half) - center)
			normals.append(_grid_normal(ix, iz))
			vertex_colors.append(colors[iz * resolution + ix])
	for row: int in z1 - z0:
		for col: int in x1 - x0:
			var a: int = row * width + col
			indices.append_array([a, a + 1, a + width + 1, a, a + width + 1, a + width])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = vertex_colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.material_override = _material
	instance.visibility_range_end = CHUNK_VIEW
	instance.visibility_range_end_margin = 20.0
	return instance


## Höhe an einer Weltposition, bilinear aus demselben Raster wie Mesh und Kollision.
func height_at(x: float, z: float) -> float:
	var half: float = size * 0.5
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


## Im begehbaren Bereich (innerhalb des Randgebirges)?
func is_inside(x: float, z: float, margin: float = 0.0) -> bool:
	var limit: float = size * 0.5 - area.relief.get(&"rand", 40.0) - margin
	return absf(x) < limit and absf(z) < limit


## Liegt der Punkt in einem See?
func in_water(x: float, z: float) -> bool:
	for lake: Vector4 in lakes:
		if Vector2(x - lake.x, z - lake.y).length() < lake.z + 0.5:
			return true
	return false


## Farbe für die Karte: Bodenfarbe mit Hangschattierung (Licht von Nordwesten), Seen in Wasserfarbe.
func map_color(x: float, z: float) -> Color:
	if in_water(x, z):
		return biome.water
	var half: float = size * 0.5
	var ix: int = clampi(roundi((x + half) / CELL), 1, resolution - 2)
	var iz: int = clampi(roundi((z + half) / CELL), 1, resolution - 2)
	var dx: float = heights[iz * resolution + ix + 1] - heights[iz * resolution + ix - 1]
	var dz: float = heights[(iz + 1) * resolution + ix] - heights[(iz - 1) * resolution + ix]
	var shade: float = clampf(0.8 + (-dx - dz) * 0.1, 0.5, 1.15)
	var color: Color = colors[iz * resolution + ix]
	return Color(color.r * shade, color.g * shade, color.b * shade)


## Bodenfarbe (sRGB) am nächsten Gitterpunkt.
func ground_color(x: float, z: float) -> Color:
	var half: float = size * 0.5
	var ix: int = clampi(roundi((x + half) / CELL), 0, resolution - 1)
	var iz: int = clampi(roundi((z + half) / CELL), 0, resolution - 1)
	return colors[iz * resolution + ix]


## Kantenlänge des Gebiets (für Karten).
func map_size() -> float:
	return size


## See an einer Stelle (x, z, Radius, Wasserhöhe); leer, wenn dort keiner ist.
func lake_at(center: Vector2) -> Vector4:
	for lake: Vector4 in lakes:
		if Vector2(lake.x, lake.y).distance_to(center) < 1.0:
			return lake
	return Vector4.ZERO
