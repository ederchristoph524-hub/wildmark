class_name VillageYards
extends RefCounted
## Hofleben der Klan-Dörfer: Zäune mit Törchen vor den Häusern, Gemüsebeete, Steinplattenwege von der Tür zur
## Straße, Schornsteine, Bänke am Brunnen und Schattenbäume auf dem Dorfplatz. Zäune, Beete, Wege und Bänke liegen im
## Siedlungs-Mesh (kein zusätzlicher Draw Call); die Bäume sind ein MultiMesh, der Herdrauch ein Partikelsystem
## je Siedlung (Austrittspunkte = Schornsteine, gesammelt in chimney_points wie Architecture.lantern_points).

const FENCE_HEIGHT: float = 1.0
const FENCE_STEP: float = 1.5
const FENCE_GATE: float = 1.4
## Abstand des Zauns vor der Hausfront (Häuser an der Hauptstraße stehen 12,5 m von der Straßenmitte).
const FENCE_OFFSET: float = 2.6
const FENCE_CHANCE: float = 0.6
const GARDEN_CHANCE: float = 0.5
const CHIMNEY_CHANCE: float = 0.7
const SOIL: Color = Color(0.3, 0.19, 0.17)
const SPROUTS: Array[Color] = [Color(0.3, 0.5, 0.2), Color(0.36, 0.55, 0.22), Color(0.26, 0.44, 0.19)]
const CHIMNEY: Color = Color(0.45, 0.43, 0.4)
const SLAB: Color = Color(0.52, 0.51, 0.48)
const SMOKE: Color = Color(0.58, 0.58, 0.6)
const SMOKE_PER_CHIMNEY: int = 14
const SMOKE_LIFE: float = 8.0
const TREE_TRUNK_RADIUS: float = 0.35

## Schornsteinköpfe (Weltpositionen) der Siedlung, die gerade gebaut wird.
static var chimney_points: Array[Vector3] = []
static var _smoke_texture: GradientTexture2D = null


## Hof eines Wohnhauses (Rahmen wie Architecture.house: Ursprung Bodenmitte, vorn = +Z). props_side = Seite, an der
## HouseStyles schon Kleinkram steht (+1/−1); das Beet kommt auf die andere. Liefert Kollisionsquader der Zäune.
static func yard(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary, rng: RandomNumberGenerator, props_side: float) -> Array[Array]:
	var boxes: Array[Array] = []
	var wood: Color = (p["holz"] as Color).lightened(0.12)
	if rng.randf() < FENCE_CHANCE:
		boxes = fence_front(b, t, width + 2.4, depth * 0.5 + FENCE_OFFSET, wood)
		slab_path(b, t, depth * 0.5 + 0.6, depth * 0.5 + FENCE_OFFSET - 0.3, rng)
	if rng.randf() < GARDEN_CHANCE:
		garden(b, t, Vector3(-props_side * (width * 0.5 + 1.6), 0.0, 0.0), Vector2(2.0, 3.4), rng)
	return boxes


## Zaun vor der Front: Latten links und rechts eines Törchens, dazu zwei kurze Seitenstücke zurück zum Haus.
static func fence_front(b: MeshBuilder, t: Transform3D, length: float, z: float, wood: Color) -> Array[Array]:
	var boxes: Array[Array] = []
	var half: float = length * 0.5
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * FENCE_GATE * 0.5, 0.0, z)
		var to := Vector3(side * half, 0.0, z)
		boxes.append(fence(b, t, from, to, wood))
		boxes.append(fence(b, t, to, Vector3(side * half, 0.0, z - 2.2), wood))
	# Torpfosten etwas höher, mit Kugelknauf.
	for side: float in [-1.0, 1.0]:
		var post := Vector3(side * FENCE_GATE * 0.5, 0.0, z)
		b.add(MeshBuilder.box(Vector3(0.16, FENCE_HEIGHT + 0.25, 0.16)), t * MeshBuilder.at(post + Vector3(0.0, (FENCE_HEIGHT + 0.25) * 0.5, 0.0)), wood.darkened(0.1))
		b.add(MeshBuilder.sphere(0.1, 5, 3), t * MeshBuilder.at(post + Vector3(0.0, FENCE_HEIGHT + 0.32, 0.0)), wood.darkened(0.2))
	return boxes


## Zaunstück von a nach c (lokale Bodenpunkte): Pfosten alle FENCE_STEP Meter, zwei Riegel. Liefert den Kollisionsquader.
static func fence(b: MeshBuilder, t: Transform3D, a: Vector3, c: Vector3, wood: Color) -> Array:
	var length: float = a.distance_to(c)
	var count: int = maxi(1, ceili(length / FENCE_STEP))
	for i: int in count + 1:
		var at: Vector3 = a.lerp(c, float(i) / count)
		b.add(MeshBuilder.box(Vector3(0.12, FENCE_HEIGHT, 0.12)), t * MeshBuilder.at(at + Vector3(0.0, FENCE_HEIGHT * 0.5, 0.0)), wood)
	var mid: Vector3 = (a + c) * 0.5
	var along := Basis(Vector3.UP, atan2(c.x - a.x, c.z - a.z) + PI * 0.5)
	for y: float in [0.42, 0.82]:
		b.add(MeshBuilder.box(Vector3(length + 0.12, 0.07, 0.06)), t * Transform3D(along, mid + Vector3(0.0, y, 0.0)), wood.lightened(0.05))
	return [t * Transform3D(along, mid), Vector3(length, FENCE_HEIGHT, 0.2)]


## Steinplattenweg von der Tür (z0) bis zum Törchen (z1), Platten leicht verdreht.
static func slab_path(b: MeshBuilder, t: Transform3D, z0: float, z1: float, rng: RandomNumberGenerator) -> void:
	var z: float = z0
	while z < z1:
		var twist: float = rng.randf_range(-0.2, 0.2)
		b.add(MeshBuilder.box(Vector3(0.85, 0.06, 0.6)), t * MeshBuilder.at(Vector3(rng.randf_range(-0.08, 0.08), 0.03, z), Vector3.ONE, Vector3(0.0, twist, 0.0)), SLAB.darkened(rng.randf_range(0.0, 0.1)))
		z += 0.72


## Gemüsebeet: aufgeschüttete Erde mit Reihen junger Pflanzen und zwei Bohnenstangen.
static func garden(b: MeshBuilder, t: Transform3D, at: Vector3, size: Vector2, rng: RandomNumberGenerator) -> void:
	b.add(MeshBuilder.box(Vector3(size.x, 0.3, size.y)), t * MeshBuilder.at(at + Vector3(0.0, 0.12, 0.0)), SOIL)
	var rows: int = 3
	var per_row: int = 4
	for row: int in rows:
		var x: float = at.x + lerpf(-size.x * 0.34, size.x * 0.34, float(row) / (rows - 1))
		for i: int in per_row:
			var z: float = at.z + lerpf(-size.y * 0.38, size.y * 0.38, float(i) / (per_row - 1))
			var r: float = rng.randf_range(0.16, 0.24)
			b.add(MeshBuilder.sphere(r, 6, 3), t * MeshBuilder.at(Vector3(x, 0.27 + r * 0.6, z), Vector3(1.0, 0.8, 1.0)), SPROUTS[(row + i) % SPROUTS.size()].darkened(rng.randf_range(0.0, 0.1)))
	var stake: Color = Color(0.5, 0.42, 0.3)
	for i: int in 2:
		var z: float = at.z + (i - 0.5) * size.y * 0.5
		b.add(MeshBuilder.cylinder(0.03, 0.04, 1.6, 4), t * MeshBuilder.at(Vector3(at.x, 0.9, z), Vector3.ONE, Vector3(0.0, 0.0, 0.12)), stake)


## Schornstein aus Stein knapp hinter dem First (at = Firsthöhe an x/z; der Schaft reicht bis unter die Dachfläche);
## meldet den Kopf als Rauchpunkt.
static func chimney(b: MeshBuilder, t: Transform3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	b.add(MeshBuilder.box(Vector3(0.55, 1.8, 0.55)), t * MeshBuilder.at(at), CHIMNEY)
	b.add(MeshBuilder.box(Vector3(0.75, 0.16, 0.75)), t * MeshBuilder.at(at + Vector3(0.0, 0.95, 0.0)), CHIMNEY.darkened(0.15))
	if rng.randf() < CHIMNEY_CHANCE:
		chimney_points.append(t * (at + Vector3(0.0, 1.05, 0.0)))


## Holzbank: Sitzbrett auf zwei Böcken, Blickrichtung +Z.
static func bench(b: MeshBuilder, t: Transform3D, wood: Color) -> Array[Array]:
	b.add(MeshBuilder.box(Vector3(1.8, 0.07, 0.42)), t * MeshBuilder.at(Vector3(0.0, 0.46, 0.0)), wood.lightened(0.08))
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.box(Vector3(0.12, 0.43, 0.38)), t * MeshBuilder.at(Vector3(side * 0.7, 0.215, 0.0)), wood)
	return [[t, Vector3(1.8, 0.5, 0.42)]]


## Schattenbäume in der Siedlung als ein MultiMesh (Laubmaterial, Biom-Tönung); Stämme bekommen Kollisionsquader.
static func trees(world: World, points: Array[Vector3], boxes: Array[Array]) -> void:
	if points.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = VegetationMeshes.round_tree()
	multimesh.instance_count = points.size()
	var tint: Color = world.biome.plant_tint if world.biome != null else Color.WHITE
	for i: int in points.size():
		var scale: float = 1.15 + 0.25 * float(i % 3)
		var basis := Basis(Vector3.UP, float(i) * 2.1).scaled(Vector3(scale, scale * 0.95, scale))
		multimesh.set_instance_transform(i, Transform3D(basis, points[i]))
		multimesh.set_instance_color(i, tint)
		boxes.append([Transform3D(Basis.IDENTITY, points[i]), Vector3(TREE_TRUNK_RADIUS * 2.0 * scale, 4.0, TREE_TRUNK_RADIUS * 2.0 * scale)])
	var instance := MultiMeshInstance3D.new()
	instance.name = "SettlementTrees"
	instance.multimesh = multimesh
	instance.material_override = WorldMaterials.vegetation(&"leafy")
	instance.visibility_range_end = Settlement.VIEW_DISTANCE
	world.add_child(instance)


## Herdrauch aller gemeldeten Schornsteine: ein Partikelsystem, das aus allen Köpfen zugleich steigt.
static func smoke(world: World, points: Array[Vector3]) -> void:
	if points.is_empty():
		return
	var particles := CPUParticles3D.new()
	particles.name = "ChimneySmoke"
	particles.amount = points.size() * SMOKE_PER_CHIMNEY
	particles.lifetime = SMOKE_LIFE
	particles.preprocess = SMOKE_LIFE
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	particles.emission_points = PackedVector3Array(points)
	particles.direction = Vector3.UP
	particles.spread = 10.0
	# Leichter Wind: der Rauch zieht schräg ab und wird dabei langsamer.
	particles.gravity = Vector3(0.3, 0.3, 0.12)
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.5
	particles.damping_min = 0.08
	particles.damping_max = 0.14
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.0
	var grow := Curve.new()
	grow.max_value = 3.0
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 2.6))
	particles.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(SMOKE, 0.0))
	fade.set_color(1, Color(SMOKE, 0.0))
	fade.add_point(0.1, Color(SMOKE, 0.6))
	fade.add_point(0.5, Color(SMOKE, 0.35))
	particles.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 1.4
	particles.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_texture = _puff()
	particles.material_override = material
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_range_end = Settlement.VIEW_DISTANCE * 0.5
	world.add_child(particles)


static func _puff() -> GradientTexture2D:
	if _smoke_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.45, Color(1.0, 1.0, 1.0, 0.55))
		_smoke_texture = GradientTexture2D.new()
		_smoke_texture.gradient = gradient
		_smoke_texture.fill = GradientTexture2D.FILL_RADIAL
		_smoke_texture.fill_from = Vector2(0.5, 0.5)
		_smoke_texture.fill_to = Vector2(1.0, 0.5)
		_smoke_texture.width = 64
		_smoke_texture.height = 64
	return _smoke_texture
