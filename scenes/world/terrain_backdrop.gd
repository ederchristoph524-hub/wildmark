class_name TerrainBackdrop
extends RefCounted
## Fernansicht in einem Mesh (ein Draw Call): innen das Gebiet grob und etwas abgesenkt (erst jenseits der Sichtweite
## der Nahkacheln zu sehen), außen ein Gebirgskranz bis zum Horizont. Ferne Wälder erscheinen als dunkles Laubdach.
## Höhe des Kranzes aus relief.horizont (Standard 150 m).

const INNER_CELL: float = 10.0
## So weit liegt die Fernansicht unter dem Nahgelände.
const SINK: float = 1.0
const REACH: float = 950.0
const FIRST_STEP: float = 14.0
const STEP_GROWTH: float = 1.2
const MOUNTAIN_RISE: float = 260.0
## Im Östlichen Meer sinkt der Grund nach außen ab; nur einzelne ferne Inseln ragen heraus.
const SEA_DROP: float = 14.0
## Fels und Schnee ab diesen Anteilen der Kranzhöhe (über dem Randgebirge).
const ROCK_SHARE: float = 0.5
const SNOW_SHARE: float = 0.88


static func build(terrain: Terrain, material: Material) -> MeshInstance3D:
	var half: float = terrain.size * 0.5
	var coords: PackedFloat32Array = _coords(half)
	var n: int = coords.size()
	var ridges := FastNoiseLite.new()
	ridges.seed = terrain.area.terrain_seed + 31
	ridges.frequency = 0.0024
	ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridges.fractal_octaves = 4
	var tone := FastNoiseLite.new()
	tone.seed = terrain.area.terrain_seed + 32
	tone.frequency = 0.012
	var mountains: float = terrain.area.relief.get(&"horizont", 150.0)
	var heights := PackedFloat32Array()
	var colors := PackedColorArray()
	for iz: int in n:
		for ix: int in n:
			var x: float = coords[ix]
			var z: float = coords[iz]
			var outside: float = maxf(absf(x), absf(z)) - half
			var h: float = 0.0
			if outside <= 0.0:
				h = _lowest_near(terrain, x, z) - SINK
			else:
				var rise: float = smoothstep(0.0, MOUNTAIN_RISE, outside)
				h = terrain.raw_height(x, z) - SINK + (ridges.get_noise_2d(x, z) * 0.5 + 0.5) * mountains * rise
				if terrain.has_sea():
					h -= SEA_DROP * rise
				else:
					h += outside * 0.04
			heights.append(h)
			colors.append(_color(terrain, x, z, h, outside, tone.get_noise_2d(x, z) * 0.5 + 0.5, mountains))
	return _mesh(coords, heights, colors, material)


## Gitterlinien: innen gleichmäßig, außen mit wachsendem Abstand bis zum Horizont.
static func _coords(half: float) -> PackedFloat32Array:
	var outer: Array[float] = []
	var distance: float = 0.0
	var step: float = FIRST_STEP
	while distance < REACH:
		distance += step
		step *= STEP_GROWTH
		outer.append(distance)
	var result := PackedFloat32Array()
	for i: int in range(outer.size() - 1, -1, -1):
		result.append(-half - outer[i])
	var cells: int = ceili(half * 2.0 / INNER_CELL)
	for i: int in cells + 1:
		result.append(-half + half * 2.0 * i / cells)
	for d: float in outer:
		result.append(half + d)
	return result


## Tiefster Punkt im Umkreis einer Grobzelle, damit die Fernansicht nirgends durch das Nahgelände sticht.
static func _lowest_near(terrain: Terrain, x: float, z: float) -> float:
	var lowest: float = INF
	for dz: float in [-INNER_CELL, -INNER_CELL * 0.5, 0.0, INNER_CELL * 0.5, INNER_CELL]:
		for dx: float in [-INNER_CELL, -INNER_CELL * 0.5, 0.0, INNER_CELL * 0.5, INNER_CELL]:
			lowest = minf(lowest, terrain.height_at(x + dx, z + dz))
	return lowest


static func _color(terrain: Terrain, x: float, z: float, h: float, outside: float, tone: float, mountains: float) -> Color:
	var biome: BiomeData = terrain.biome
	var canopy: Color = biome.color(&"gras_dunkel").darkened(0.12).lerp(biome.color(&"moos"), tone * 0.5)
	if outside <= 0.0:
		var ground: Color = terrain.ground_color(x, z)
		if terrain.in_water(x, z) or terrain.near_path(x, z) or terrain.slope_at(x, z) > 0.55:
			return ground
		return ground.lerp(canopy, 0.35 + 0.3 * tone)
	if terrain.has_sea() and h < biome.sea_level + Terrain.BEACH_HEIGHT:
		return biome.color(&"strand", biome.color(&"erde")).darkened(clampf((biome.sea_level - h) * 0.05, 0.0, 0.5))
	var color: Color = canopy
	var above: float = h - terrain.area.relief.get(&"randhoehe", 30.0)
	var rock_line: float = mountains * ROCK_SHARE
	var snow_line: float = mountains * SNOW_SHARE
	if above > rock_line:
		color = color.lerp(biome.color(&"fels"), clampf((above - rock_line) / 40.0, 0.0, 0.85))
	if above > snow_line:
		color = color.lerp(biome.color(&"gipfel").lightened(0.45), clampf((above - snow_line) / 25.0, 0.0, 0.9))
	return color


static func _mesh(coords: PackedFloat32Array, heights: PackedFloat32Array, colors: PackedColorArray, material: Material) -> MeshInstance3D:
	var n: int = coords.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for iz: int in n:
		for ix: int in n:
			vertices.append(Vector3(coords[ix], heights[iz * n + ix], coords[iz]))
	for iz: int in n:
		for ix: int in n:
			var left: Vector3 = vertices[iz * n + maxi(ix - 1, 0)]
			var right: Vector3 = vertices[iz * n + mini(ix + 1, n - 1)]
			var back: Vector3 = vertices[maxi(iz - 1, 0) * n + ix]
			var front: Vector3 = vertices[mini(iz + 1, n - 1) * n + ix]
			normals.append((front - back).cross(right - left).normalized())
	for row: int in n - 1:
		for col: int in n - 1:
			var a: int = row * n + col
			indices.append_array([a, a + 1, a + n + 1, a, a + n + 1, a + n])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = "Backdrop"
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
