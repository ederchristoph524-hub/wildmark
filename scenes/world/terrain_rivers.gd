class_name TerrainRivers
extends RefCounted
## Flüsse (gebiete.json → fluesse): graben ein flaches Bett mit Uferböschung ins Gelände (Wasserspiegel = tiefste
## Stelle der Mittellinie, damit das Band nirgends schwebt), färben Bett und Ufer, liefern die Wasserfläche als Band
## und Holzbrücken dort, wo ein Weg den Fluss kreuzt. Man kann durch den Fluss waten (höchstens DEPTH tief).

const DEPTH: float = 1.1
## Talflanken: bis so weit neben dem Bett wird Gelände, das über der Böschungslinie liegt, abgetragen (kein
## senkrechter Schnitt, wenn der Fluss einen Hügel durchbricht).
const BANK: float = 34.0
const BANK_SLOPE: float = 0.55
const SAMPLE_STEP: float = 3.0
## Tempo der Schaumstreifen (UV-Einheiten je Sekunde).
const FLOW_SPEED: float = 1.6
## Glättung des Wasserspiegels: so viele Messpunkte zu jeder Seite.
const SMOOTH: int = 16
const WATER_MARGIN: float = 1.2
const BRIDGE_WOOD: Color = Color(0.45, 0.3, 0.18)
const BRIDGE_RAIL: Color = Color(0.36, 0.22, 0.13)
const BRIDGE_WIDTH: float = 3.2
## Die Brücke reicht so weit über das Bett hinaus aufs Ufer (beide Seiten zusammen).
const BRIDGE_OVERHANG: float = 8.0


## Gräbt alle Flüsse ein; merkt je Gitterpunkt den Abstand zur Mitte relativ zur halben Breite (river_mask).
## Der Wasserspiegel folgt dem geglätteten Gelände und fällt von der Quelle (höheres Ende) stetig zur Mündung –
## Hügel im Weg werden zum Durchbruchstal, statt dass der ganze Fluss in einer Schlucht liegt.
static func carve(t: Terrain) -> void:
	t.river_mask.resize(t.resolution * t.resolution)
	t.river_mask.fill(99.0)
	t.river_courses.clear()
	for river: Dictionary in t.area.rivers:
		var half: float = float(river["width"]) * 0.5
		var course: Dictionary = _course(t, river["points"])
		t.river_courses.append(course)
		var samples: Array[Vector2] = course["samples"]
		var levels: PackedFloat32Array = course["levels"]
		for i: int in samples.size():
			_carve_around(t, samples[i], half, levels[i])


## Punkte alle SAMPLE_STEP Meter entlang der Linie und ihr Wasserspiegel.
static func _course(t: Terrain, points: Array) -> Dictionary:
	var samples: Array[Vector2] = []
	for i: int in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var steps: int = maxi(1, ceili(a.distance_to(b) / SAMPLE_STEP))
		for s: int in steps:
			samples.append(a.lerp(b, float(s) / steps))
	samples.append(points[points.size() - 1])
	var raw := PackedFloat32Array()
	for p: Vector2 in samples:
		raw.append(t.grid_height(p.x, p.y))
	# Glätten (gleitender Mittelwert), dann stetig fallend von der höheren Seite.
	var levels := PackedFloat32Array()
	levels.resize(raw.size())
	for i: int in raw.size():
		var total: float = 0.0
		var count: int = 0
		for k: int in range(maxi(0, i - SMOOTH), mini(raw.size(), i + SMOOTH + 1)):
			total += raw[k]
			count += 1
		levels[i] = total / count - 0.6
	var forward: bool = levels[0] >= levels[levels.size() - 1]
	for step: int in range(1, levels.size()):
		var i: int = step if forward else levels.size() - 1 - step
		var previous: int = i - 1 if forward else i + 1
		levels[i] = minf(levels[i], levels[previous])
	return {"samples": samples, "levels": levels}


static func _carve_around(t: Terrain, center: Vector2, half: float, level: float) -> void:
	var reach: float = half + BANK
	var grid_half: float = t.size * 0.5
	var min_ix: int = maxi(0, floori((center.x - reach + grid_half) / Terrain.CELL))
	var max_ix: int = mini(t.resolution - 1, ceili((center.x + reach + grid_half) / Terrain.CELL))
	var min_iz: int = maxi(0, floori((center.y - reach + grid_half) / Terrain.CELL))
	var max_iz: int = mini(t.resolution - 1, ceili((center.y + reach + grid_half) / Terrain.CELL))
	for iz: int in range(min_iz, max_iz + 1):
		for ix: int in range(min_ix, max_ix + 1):
			var d: float = Vector2(ix * Terrain.CELL - grid_half, iz * Terrain.CELL - grid_half).distance_to(center)
			if d >= reach:
				continue
			var index: int = iz * t.resolution + ix
			var target: float = level - DEPTH * (1.0 - pow(d / half, 2.0)) - 0.15 if d < half else level + 0.3 + (d - half) * BANK_SLOPE
			t.heights[index] = minf(t.heights[index], target)
			t.river_mask[index] = minf(t.river_mask[index], d / half)


## Bett und Ufer: nasse Erde und Kies statt Gras.
static func tint(t: Terrain, index: int, color: Color) -> Color:
	if t.river_mask.is_empty():
		return color
	var mask: float = t.river_mask[index]
	if mask > 1.9:
		return color
	var bed: Color = t.biome.color(&"erde").darkened(0.25)
	return color.lerp(bed, clampf(1.9 - mask, 0.0, 0.85))


## Im Flussbett (für in_water)?
static func in_river(t: Terrain, x: float, z: float) -> bool:
	if t.river_mask.is_empty():
		return false
	var grid_half: float = t.size * 0.5
	var ix: int = clampi(roundi((x + grid_half) / Terrain.CELL), 0, t.resolution - 1)
	var iz: int = clampi(roundi((z + grid_half) / Terrain.CELL), 0, t.resolution - 1)
	return t.river_mask[iz * t.resolution + ix] < 1.0


## Wasserflächen (ein Band je Fluss) und Brücken über die Wege.
static func build(world: World) -> void:
	var t: Terrain = world.terrain
	for i: int in world.area.rivers.size():
		var river: Dictionary = world.area.rivers[i]
		var half: float = float(river["width"]) * 0.5
		var water := MeshInstance3D.new()
		water.mesh = _ribbon(t.river_courses[i], half + WATER_MARGIN)
		water.material_override = WaterSurface.material(t.biome.water, 0.0, FLOW_SPEED)
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(water)
		for crossing: Array in _crossings(t.paths, river["points"]):
			_bridge(world, crossing[0], crossing[1], half)


## Band entlang des Laufs auf Wasserhöhe (Richtung aus den Nachbarpunkten, damit es an Knicken nicht aufreißt).
static func _ribbon(course: Dictionary, half: float) -> ArrayMesh:
	var samples: Array[Vector2] = course["samples"]
	var levels: PackedFloat32Array = course["levels"]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var travelled: float = 0.0
	for i: int in samples.size():
		var p: Vector2 = samples[i]
		if i > 0:
			travelled += p.distance_to(samples[i - 1])
		var along: Vector2 = (samples[mini(samples.size() - 1, i + 1)] - samples[maxi(0, i - 1)]).normalized()
		var side := Vector2(-along.y, along.x) * half
		vertices.append(Vector3(p.x + side.x, levels[i], p.y + side.y))
		vertices.append(Vector3(p.x - side.x, levels[i], p.y - side.y))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		# Längs fließt es von der Quelle (höherer Spiegel) weg.
		var v: float = travelled / 4.0 * (1.0 if levels[0] >= levels[levels.size() - 1] else -1.0)
		uvs.append(Vector2(0.0, v))
		uvs.append(Vector2(1.0, v))
		if i > 0:
			var k: int = (i - 1) * 2
			indices.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Schnittpunkte der Wege mit dem Fluss: [Punkt, Wegrichtung].
static func _crossings(roads: Array, points: Array) -> Array[Array]:
	var result: Array[Array] = []
	for road: Variant in roads:
		var path: Array = road
		for i: int in path.size() - 1:
			for j: int in points.size() - 1:
				var hit: Variant = Geometry2D.segment_intersects_segment(path[i], path[i + 1], points[j], points[j + 1])
				if hit is Vector2 and not _near_any(result, hit):
					result.append([hit, ((path[i + 1] as Vector2) - (path[i] as Vector2)).normalized()])
	return result


static func _near_any(found: Array[Array], point: Vector2) -> bool:
	for entry: Array in found:
		if (entry[0] as Vector2).distance_to(point) < 6.0:
			return true
	return false


## Holzbrücke mit leichtem Bogen, Geländern und begehbarem Steg (flache Kollision zwischen den Ufern).
static func _bridge(world: World, at: Vector2, direction: Vector2, half: float) -> void:
	var span: float = half * 2.0 + BRIDGE_OVERHANG
	var start: Vector3 = world.ground_point(at.x - direction.x * span * 0.5, at.y - direction.y * span * 0.5)
	var finish: Vector3 = world.ground_point(at.x + direction.x * span * 0.5, at.y + direction.y * span * 0.5)
	var b := MeshBuilder.new()
	var segments: int = 10
	var yaw: float = atan2(direction.x, direction.y)
	for s: int in segments:
		var f: float = (s + 0.5) / segments
		var at3: Vector3 = start.lerp(finish, f) + Vector3.UP * (0.25 + sin(f * PI) * 0.7)
		var tilt: float = cos(f * PI) * 0.22
		b.add(MeshBuilder.box(Vector3(BRIDGE_WIDTH, 0.18, span / segments + 0.05)), MeshBuilder.at(at3, Vector3.ONE, Vector3(-tilt, yaw, 0.0)), BRIDGE_WOOD.darkened(0.08 * (s % 2)))
		for side: float in [-1.0, 1.0]:
			var offset := Vector3(cos(yaw), 0.0, -sin(yaw)) * side * (BRIDGE_WIDTH * 0.5 - 0.1)
			b.add(MeshBuilder.box(Vector3(0.1, 0.9, 0.1)), MeshBuilder.at(at3 + offset + Vector3.UP * 0.5), BRIDGE_RAIL)
			b.add(MeshBuilder.box(Vector3(0.08, 0.08, span / segments + 0.05)), MeshBuilder.at(at3 + offset + Vector3.UP * 0.92, Vector3.ONE, Vector3(-tilt, yaw, 0.0)), BRIDGE_RAIL)
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = WorldMaterials.props()
	world.add_child(node)
	# Begehbar: ein flacher Steg von Ufer zu Ufer (die Wölbung ist nur Optik).
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BRIDGE_WIDTH, 0.3, start.distance_to(finish))
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
	body.global_transform = Transform3D(Basis.looking_at(finish - start, Vector3.UP), (start + finish) * 0.5 + Vector3.UP * 0.1)
