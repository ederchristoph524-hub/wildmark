class_name SettlementOutposts
extends RefCounted
## Kleinere Siedlungsarten: Zeltlager der Steppe (Palisade, Jurten, Häuptlingsjurte, Totems), Oasenstadt der Wüste
## (Lehmmauer, Lehmhäuser, Kuppeltempel am Teich, Palmen), Inseldorf (Pfahlhäuser, Stege, Boote) und Versteck einer
## Dämonensekte (verfallene Mauer, dunkle Pagode, Blutbecken).

const PALISADE_SEGMENTS: int = 28
const PALM_VIEW: float = 160.0
const BLOOD_POOL: Color = Color(0.35, 0.03, 0.05)


static func build(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	match data["type"]:
		&"zeltlager":
			_camp(world, data, center, b, boxes, rng, anchors)
		&"oasenstadt":
			_oasis(world, data, center, b, boxes, rng, anchors)
		&"inseldorf":
			_island(world, data, center, b, boxes, rng, anchors)
		&"versteck":
			_hideout(world, data, center, b, boxes, rng, anchors)


## Palisadenring mit Öffnung nach vorn, Jurtenkreis, große Häuptlingsjurte, Totems, Pferche und Übungsplatz.
static func _camp(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var r: float = data["radius"]
	var base := Transform3D(Basis.IDENTITY, center)
	var ring: float = r * 0.92
	var step: float = TAU / PALISADE_SEGMENTS
	for i: int in PALISADE_SEGMENTS:
		var a0: float = (i - 0.5) * step
		if absf(angle_difference(i * step, PI * 0.5)) < step * 0.9:
			continue
		var g0: Vector3 = world.ground_point(center.x + cos(a0) * ring, center.z + sin(a0) * ring)
		var g1: Vector3 = world.ground_point(center.x + cos(a0 + step) * ring, center.z + sin(a0 + step) * ring)
		boxes.append_array(ArchitectureExtra.palisade(b, g0, g1, p))
	var chief_at := Vector3(0, 0, -r * 0.4)
	boxes.append_array(ArchitectureExtra.yurt(b, base.translated_local(chief_at), 6.0, p))
	var count: int = int(data["houses"])
	for i: int in count:
		var angle: float = PI * 0.5 + (i + 1) * TAU / (count + 1)
		var at := Vector3(cos(angle) * r * 0.62, 0, sin(angle) * r * 0.62)
		boxes.append_array(ArchitectureExtra.yurt(b, base * Transform3D(Basis(Vector3.UP, -angle - PI * 0.5), at), rng.randf_range(3.0, 3.8), p))
	for side: float in [-1.0, 1.0]:
		ArchitectureExtra.totem(b, base.translated_local(Vector3(side * 5.0, 0, ring - 1.0)), p)
		ArchitectureExtra.totem(b, base.translated_local(Vector3(side * 4.0, 0, chief_at.z + 8.0)), p)
	var pen := Vector3(r * 0.3, 0, r * 0.15)
	for corner: Array in [[Vector3(-4, 0, -3), Vector3(4, 0, -3)], [Vector3(4, 0, -3), Vector3(4, 0, 3)], [Vector3(-4, 0, 3), Vector3(-4, 0, -3)]]:
		var a: Vector3 = center + pen + (corner[0] as Vector3)
		var c: Vector3 = center + pen + (corner[1] as Vector3)
		boxes.append_array(ArchitectureExtra.palisade(b, world.ground_point(a.x, a.z), world.ground_point(c.x, c.z), p))
	var training_at := Vector3(-r * 0.3, 0, r * 0.15)
	for i: int in 3:
		Architecture.training_dummy(b, base.translated_local(training_at + Vector3(-3.0 + i * 3.0, 0, -2.0)), p)
	boxes.append_array(Architecture.stall(b, base.translated_local(Vector3(6.0, 0, r * 0.45)), p, Color(0.75, 0.55, 0.35)))
	anchors["hall"] = center + chief_at + Vector3(2.5, 0, 8.5)
	anchors["gate"] = center + Vector3(3.5, 0, ring - 3.0)
	anchors["gate_outside"] = center + Vector3(-5.0, 0, ring + 5.0)
	anchors["back_gate"] = center + Vector3(0, 0, -r * 0.1)
	anchors["market"] = center + Vector3(6.0, 0, r * 0.45 + 2.5)
	anchors["training"] = center + training_at + Vector3(0, 0, 2.5)
	anchors["arena"] = anchors["training"]
	anchors["well"] = center + Vector3(0, 0, r * 0.12)
	anchors["tower"] = center + Vector3(-4.0, 0, chief_at.z + 10.0)
	anchors["academy"] = anchors["tower"]
	anchors["garden"] = center + pen + Vector3(0, 0, 5.0)
	anchors["fire"] = center + Vector3(0, 0, r * 0.12)


## Lehmmauer mit Toren und Türmen, Teich in der Mitte, Kuppeltempel, Lehmhäuser im Ring, Marktstände, Palmen.
static func _oasis(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var r: float = data["radius"]
	var base := Transform3D(Basis.IDENTITY, center)
	Settlement.walls_and_gates(b, boxes, world, center, r, p, anchors)
	var pond: float = float(data.get("pond", 8.0))
	var temple_at := Vector3(0, 0, -pond - 12.0)
	boxes.append_array(ArchitectureExtra.dome_temple(b, base.translated_local(temple_at), 11.0, p))
	var count: int = int(data["houses"])
	var placed: int = 0
	var ring_radius: float = pond + 14.0
	while placed < count and ring_radius < r * 0.8:
		var around: int = floori(TAU * ring_radius / 13.0)
		for i: int in around:
			if placed >= count:
				break
			var angle: float = (i + 0.5 * (floori(ring_radius) % 2)) * TAU / around
			var at := Vector3(cos(angle) * ring_radius, 0, sin(angle) * ring_radius)
			if absf(at.x) < 6.0 and at.z > 0.0 or at.distance_to(temple_at) < 12.0:
				continue
			var height: float = 3.2 if rng.randf() < 0.7 else 5.6
			boxes.append_array(ArchitectureExtra.adobe_house(b, base * Transform3D(Basis(Vector3.UP, -angle - PI * 0.5), at), rng.randf_range(6.5, 8.5), rng.randf_range(5.5, 7.0), height, p))
			placed += 1
		ring_radius += 13.0
	for i: int in 3:
		boxes.append_array(Architecture.stall(b, base * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(8.0, 0, r * 0.55 - i * 4.5)), p, Color(0.85, 0.6 - i * 0.15, 0.3)))
	_palms(world, center, pond + 3.5, 10, rng)
	anchors["hall"] = center + temple_at + Vector3(2.5, 0, 9.5)
	anchors["academy"] = center + temple_at + Vector3(-5.0, 0, 9.5)
	anchors["market"] = center + Vector3(5.5, 0, r * 0.5)
	anchors["well"] = center + Vector3(pond + 2.0, 0, 0)
	anchors["training"] = center + Vector3(-pond - 4.0, 0, 3.0)
	anchors["arena"] = anchors["training"]
	anchors["garden"] = center + Vector3(0, 0, pond + 3.0)
	anchors["fire"] = center + Vector3(-5.0, 0, pond + 6.0)


## Palmen um den Teich als eigenes MultiMesh (die Vegetation lässt Siedlungen frei).
static func _palms(world: World, center: Vector3, radius: float, count: int, rng: RandomNumberGenerator) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = VegetationMeshes.palm()
	multimesh.instance_count = count
	for i: int in count:
		var angle: float = i * TAU / count + rng.randf_range(-0.2, 0.2)
		var at: Vector3 = world.ground_point(center.x + cos(angle) * radius, center.z + sin(angle) * radius)
		multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.9, 1.2)), at - center))
	var node := MultiMeshInstance3D.new()
	node.multimesh = multimesh
	node.material_override = WorldMaterials.vegetation(&"leafy")
	node.visibility_range_end = PALM_VIEW
	world.add_child(node)
	node.position = center


## Pfahlhäuser im Ring, Halle in der Mitte, Stege zum Wasser mit Booten, Trockengestelle.
static func _island(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var r: float = data["radius"]
	var base := Transform3D(Basis.IDENTITY, center)
	boxes.append_array(Architecture.house(b, base, 11.0, 8.0, p))
	var count: int = int(data["houses"])
	for i: int in count:
		var angle: float = (i + 0.5) * TAU / count
		var at := Vector3(cos(angle) * r * 0.6, 0, sin(angle) * r * 0.6)
		boxes.append_array(HouseStyles.stilts(b, base * Transform3D(Basis(Vector3.UP, -angle + PI * 0.5), at), rng.randf_range(6.0, 7.0), rng.randf_range(5.0, 6.0), p))
	var sea: float = world.biome.sea_level if world.terrain.has_sea() else center.y - 1.0
	for i: int in 3:
		var angle: float = PI * 0.5 + (i - 1) * 1.1
		var dir := Vector3(cos(angle), 0, sin(angle))
		var shore: Vector3 = _shore(world, center, dir, sea, r * 2.0)
		var t := Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), Vector3(shore.x, sea, shore.z))
		boxes.append_array(ArchitectureExtra.dock(b, t, 12.0, 0.8, p))
		ArchitectureExtra.boat(b, t.translated_local(Vector3(2.4, 0.0, 9.0)), p)
		if i == 1:
			anchors["gate"] = shore - dir * 2.0
			anchors["gate_outside"] = shore - dir * 4.0 + dir.cross(Vector3.UP) * 3.0
	for i: int in 2:
		var at := Vector3(-r * 0.25 + i * r * 0.5, 0, -r * 0.3)
		for side: float in [-1.0, 1.0]:
			b.add(MeshBuilder.cylinder(0.06, 0.06, 2.2, 4), base * MeshBuilder.at(at + Vector3(side * 1.2, 1.1, 0)), p["holz"])
		b.add(MeshBuilder.box(Vector3(2.6, 0.06, 0.06)), base * MeshBuilder.at(at + Vector3(0, 2.1, 0)), p["holz"])
		for k: int in 4:
			b.add(MeshBuilder.box(Vector3(0.12, 0.5, 0.05)), base * MeshBuilder.at(at + Vector3(-0.9 + k * 0.6, 1.8, 0)), Color(0.75, 0.7, 0.6))
	anchors["hall"] = center + Vector3(2.5, 0, 6.0)
	anchors["market"] = center + Vector3(-4.0, 0, 6.5)
	anchors["well"] = center + Vector3(5.0, 0, -2.0)
	anchors["training"] = center + Vector3(-5.0, 0, -6.0)
	anchors["arena"] = anchors["training"]
	anchors["tower"] = center + Vector3(0, 0, -r * 0.35)
	anchors["garden"] = anchors["tower"]
	if not anchors.has("gate"):
		anchors["gate"] = center + Vector3(0, 0, r * 0.8)
	anchors["fire"] = center + Vector3(0, 0, 9.0)


## Erster Punkt in Richtung dir, an dem das Gelände unter den Meeresspiegel sinkt.
static func _shore(world: World, center: Vector3, dir: Vector3, sea: float, max_distance: float) -> Vector3:
	var distance: float = 4.0
	while distance < max_distance:
		var point: Vector3 = center + dir * distance
		if world.terrain.height_at(point.x, point.z) < sea + 0.3:
			return point
		distance += 1.0
	return center + dir * max_distance


## Versteck einer Dämonensekte: verfallener Mauerring mit Lücken, dunkle Pagode, zweistöckige Hallen, Blutbecken
## im Hof, Banner und Fackeln.
static func _hideout(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var r: float = data["radius"]
	var base := Transform3D(Basis.IDENTITY, center)
	var segments: int = 16
	var step: float = TAU / segments
	for i: int in segments:
		var angle: float = i * step
		if absf(angle_difference(angle, PI * 0.5)) < step * 0.8 or rng.randf() < 0.2:
			continue
		var a: Vector3 = world.ground_point(center.x + cos(angle) * r, center.z + sin(angle) * r)
		var c: Vector3 = world.ground_point(center.x + cos(angle + step * rng.randf_range(0.55, 0.95)) * r, center.z + sin(angle + step * 0.8) * r)
		boxes.append_array(ArchitectureExtra.high_wall(b, a, c, rng.randf_range(2.2, 4.8), p))
	var pagoda_at := Vector3(0, 0, -r * 0.45)
	boxes.append_array(ArchitectureExtra.pagoda(b, base.translated_local(pagoda_at), 3, 7.0, p))
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * r * 0.5, 0, -r * 0.05)
		boxes.append_array(HouseStyles.two_story(b, base * Transform3D(Basis(Vector3.UP, -side * PI * 0.5), at), 10.0, 7.5, p))
	# Blutbecken: Steinring mit dunkelroter Füllung.
	var pool := Vector3(0, 0, r * 0.15)
	b.add(MeshBuilder.cylinder(3.2, 3.4, 0.7, 12), base * MeshBuilder.at(pool + Vector3.UP * 0.35), p["stein"])
	b.add(MeshBuilder.cylinder(2.7, 2.7, 0.1, 12), base * MeshBuilder.at(pool + Vector3.UP * 0.66), BLOOD_POOL)
	boxes.append([base.translated_local(pool + Vector3.UP * 0.35), Vector3(6.4, 0.7, 6.4)])
	for side: float in [-1.0, 1.0]:
		Architecture.banner_pole(b, base.translated_local(Vector3(side * 5.0, 0, r * 0.7)), p)
		Architecture.lantern_post(b, base * Transform3D(Basis(Vector3.UP, PI * 0.5 * side), Vector3(side * 4.0, 0, pool.z + 5.0)), p)
	anchors["gate"] = center + Vector3(3.0, 0, r * 0.85)
	anchors["gate_outside"] = center + Vector3(-4.0, 0, r + 5.0)
	anchors["hall"] = center + pagoda_at + Vector3(2.5, 0, 6.5)
	anchors["academy"] = anchors["hall"]
	anchors["market"] = center + Vector3(-5.0, 0, r * 0.5)
	anchors["training"] = center + pool + Vector3(0, 0, 5.0)
	anchors["arena"] = anchors["training"]
	anchors["well"] = center + pool + Vector3(4.0, 0, 0)
	anchors["tower"] = center + pagoda_at + Vector3(-6.0, 0, 4.0)
	anchors["garden"] = anchors["tower"]
	anchors["fire"] = center + Vector3(3.0, 0, r * 0.45)
