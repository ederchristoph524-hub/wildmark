class_name VegetationMeshes
extends RefCounted
## Low-Poly-Pflanzen und Felsen der Südlichen Grenze als Vertex-Farben-Meshes (je Art ein Mesh, als MultiMesh verteilt):
## Urwaldbaum mit Brettwurzeln, runder Laubbaum, Palme mit hängenden Wedeln, Kiefer, Bambushain, Busch, Farn, Gras, Blumen, Fels.

const TRUNK: Color = Color(0.33, 0.24, 0.16)
const TRUNK_DARK: Color = Color(0.25, 0.18, 0.12)
const LEAF_DARK: Color = Color(0.11, 0.25, 0.13)
const LEAF_MID: Color = Color(0.17, 0.33, 0.15)
const LEAF_LIGHT: Color = Color(0.26, 0.41, 0.17)
const LEAF_OLIVE: Color = Color(0.32, 0.38, 0.16)
const BAMBOO: Color = Color(0.42, 0.52, 0.27)
const BAMBOO_DARK: Color = Color(0.3, 0.4, 0.2)
const ROCK: Color = Color(0.31, 0.3, 0.27)
const ROCK_DARK: Color = Color(0.23, 0.22, 0.2)
const MOSS: Color = Color(0.25, 0.33, 0.16)
const CACTUS: Color = Color(0.3, 0.45, 0.25)
const DEAD_WOOD: Color = Color(0.42, 0.36, 0.3)
const BLOSSOM: Color = Color(0.93, 0.66, 0.76)
const BLOSSOM_LIGHT: Color = Color(0.98, 0.86, 0.9)
const BLOSSOM_DEEP: Color = Color(0.86, 0.5, 0.64)
const FLOWER_COLORS: Array[Color] = [Color(0.85, 0.25, 0.3), Color(0.95, 0.8, 0.3), Color(0.7, 0.45, 0.85), Color(0.95, 0.95, 0.9)]


## Hoher Urwaldbaum: leicht geneigter Stamm, Brettwurzeln, zwei Äste, unregelmäßige Krone aus mehreren Ballen.
static func broadleaf() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.24, 0.42, 7.0, 6), MeshBuilder.at(Vector3(0.1, 3.5, 0), Vector3.ONE, Vector3(0, 0, 0.03)), TRUNK)
	for i: int in 3:
		var angle: float = i * TAU / 3.0
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		b.add(MeshBuilder.box(Vector3(0.14, 1.1, 0.9)), Transform3D(Basis(Vector3.UP, -angle), dir * 0.45 + Vector3(0, 0.45, 0)).rotated_local(Vector3.FORWARD, 0.0), TRUNK_DARK)
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.cylinder(0.08, 0.14, 2.6, 5), MeshBuilder.at(Vector3(side * 0.9, 6.0, 0.2), Vector3.ONE, Vector3(0, 0, -side * 0.75)), TRUNK)
	var blobs: Array[Array] = [[Vector3(0, 7.4, 0), 2.4, LEAF_DARK], [Vector3(1.8, 7.0, 0.6), 1.8, LEAF_MID], [Vector3(-1.7, 7.2, -0.5), 1.9, LEAF_MID],
		[Vector3(0.4, 8.5, -0.9), 1.6, LEAF_LIGHT], [Vector3(-0.6, 8.2, 1.2), 1.5, LEAF_OLIVE], [Vector3(1.0, 6.4, -1.5), 1.3, LEAF_DARK]]
	for blob: Array in blobs:
		b.add(MeshBuilder.sphere(blob[1] * 0.85, 6, 4), MeshBuilder.at(blob[0], Vector3(1.0, 0.62, 1.0)), (blob[2] as Color).darkened(0.15))
		_crown_cards(b, blob[0], blob[1], blob[2], 7, blobs.find(blob) + 3)
	return b.build()


## Runder, niedriger Laubbaum.
static func round_tree() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.18, 0.3, 3.4, 6), MeshBuilder.at(Vector3(0, 1.7, 0)), TRUNK)
	b.add(MeshBuilder.sphere(1.7, 7, 4), MeshBuilder.at(Vector3(0, 4.2, 0), Vector3(1.0, 0.8, 1.0)), LEAF_MID.darkened(0.15))
	_crown_cards(b, Vector3(0, 4.2, 0), 2.0, LEAF_MID, 9, 11)
	_crown_cards(b, Vector3(0.9, 4.9, 0.5), 1.3, LEAF_LIGHT, 5, 12)
	_crown_cards(b, Vector3(-0.8, 3.8, -0.7), 1.2, LEAF_DARK, 5, 13)
	return b.build()


## Blütenbaum (Kranichtal): geschwungener dunkler Stamm, Krone aus rosa und weißen Blütenballen.
static func blossom_tree() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.16, 0.3, 3.6, 6), MeshBuilder.at(Vector3(0, 1.8, 0), Vector3.ONE, Vector3(0, 0, 0.08)), TRUNK_DARK)
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.cylinder(0.06, 0.12, 2.2, 5), MeshBuilder.at(Vector3(side * 0.7, 3.8, 0.1), Vector3.ONE, Vector3(0, 0, -side * 0.8)), TRUNK_DARK)
	var blobs: Array[Array] = [[Vector3(0, 4.6, 0), 1.9, BLOSSOM], [Vector3(1.5, 4.3, 0.4), 1.4, BLOSSOM_LIGHT], [Vector3(-1.4, 4.4, -0.4), 1.5, BLOSSOM],
		[Vector3(0.3, 5.4, -0.7), 1.2, BLOSSOM_LIGHT], [Vector3(-0.5, 5.1, 0.9), 1.1, BLOSSOM_DEEP]]
	for blob: Array in blobs:
		b.add(MeshBuilder.sphere(blob[1] * 0.8, 6, 4), MeshBuilder.at(blob[0], Vector3(1.0, 0.7, 1.0)), (blob[2] as Color).darkened(0.1))
		_crown_cards(b, blob[0], blob[1], blob[2], 6, blobs.find(blob) + 21)
	return b.build()


## Palme: gebogener Stamm aus drei Stücken, acht hängende, gefaltete Wedel.
static func palm() -> ArrayMesh:
	var b := MeshBuilder.new()
	var points: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0.25, 2.4, 0), Vector3(0.65, 4.6, 0), Vector3(1.2, 6.6, 0)]
	for i: int in 3:
		b.add(MeshBuilder.cylinder(0.17 - i * 0.03, 0.26 - i * 0.03, points[i].distance_to(points[i + 1]) + 0.1, 6), MeshBuilder.between(points[i], points[i + 1]), TRUNK if i % 2 == 0 else TRUNK_DARK)
	var top: Vector3 = points[3]
	for i: int in 8:
		var angle: float = i * TAU / 8.0 + (i % 2) * 0.2
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var mid: Vector3 = top + dir * 1.4 + Vector3(0, 0.3, 0)
		var tip: Vector3 = top + dir * 2.8 - Vector3(0, 0.8, 0)
		var color: Color = LEAF_MID if i % 2 == 0 else LEAF_LIGHT
		_frond(b, [top, mid, tip], 0.55, color)
	b.add(MeshBuilder.sphere(0.35, 5, 3), MeshBuilder.at(top), TRUNK_DARK)
	return b.build()


## Kiefer: vier gestufte Kegel über sichtbarem Stamm.
static func pine() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.16, 0.3, 3.0, 6), MeshBuilder.at(Vector3(0, 1.5, 0)), TRUNK)
	var tiers: Array[Array] = [[2.2, 2.0, 3.2], [1.8, 1.8, 4.5], [1.35, 1.6, 5.7], [0.85, 1.4, 6.8]]
	for i: int in tiers.size():
		var tier: Array = tiers[i]
		b.add(MeshBuilder.cylinder(0.0, tier[0], tier[1], 7), MeshBuilder.at(Vector3(0, tier[2], 0), Vector3.ONE, Vector3(0, i * 0.4, 0)), LEAF_DARK if i % 2 == 0 else LEAF_MID)
	return b.build()


## Bambushain: sechs schlanke, geneigte Halme mit Knoten und Büscheln schmaler, hängender Blätter.
static func bamboo() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 6:
		var angle: float = i * TAU / 6.0 + 0.3
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * (0.25 + (i % 3) * 0.25)
		var height: float = 6.8 + (i % 3) * 1.3
		var lean := Basis.from_euler(Vector3(sin(angle) * 0.09, 0.0, -cos(angle) * 0.09))
		for part: int in 3:
			var from: Vector3 = offset + lean * Vector3(0, height * part / 3.0, 0)
			var to: Vector3 = offset + lean * Vector3(0, height * (part + 1) / 3.0, 0)
			b.add(MeshBuilder.cylinder(0.055, 0.07, from.distance_to(to), 4), MeshBuilder.between(from, to), BAMBOO if (i + part) % 2 == 0 else BAMBOO_DARK)
		for node: int in 4:
			var at: Vector3 = offset + lean * Vector3(0, height * (0.55 + node * 0.14), 0)
			for leaf: int in 4:
				var leaf_angle: float = angle + leaf * PI * 0.5 + node * 0.7
				var dir := Vector3(cos(leaf_angle), 0.0, sin(leaf_angle))
				_leaf(b, at, dir, 1.0, 0.17, 0.45, LEAF_LIGHT if (leaf + node) % 3 == 0 else LEAF_MID)
	return b.build()


static func bush() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.sphere(0.6, 6, 4), MeshBuilder.at(Vector3(0, 0.45, 0), Vector3(1.25, 0.8, 1.05)), LEAF_DARK.darkened(0.1))
	_crown_cards(b, Vector3(0, 0.5, 0), 0.8, LEAF_DARK, 6, 31)
	_crown_cards(b, Vector3(0.55, 0.6, 0.2), 0.5, LEAF_MID, 4, 32)
	_crown_cards(b, Vector3(-0.45, 0.55, -0.3), 0.45, LEAF_OLIVE, 4, 33)
	return b.build()


## Farn: zehn gebogene Wedel aus der Mitte.
static func fern() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 10:
		var angle: float = i * TAU / 10.0 + (i % 2) * 0.2
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var mid: Vector3 = dir * 0.45 + Vector3(0, 0.55, 0)
		var tip: Vector3 = dir * 1.0 + Vector3(0, 0.25, 0)
		var color: Color = LEAF_MID if i % 3 != 0 else LEAF_LIGHT
		b.add(MeshBuilder.box(Vector3(0.22, 0.03, 0.75)), _along(Vector3(0, 0.05, 0), mid), color)
		b.add(MeshBuilder.box(Vector3(0.18, 0.03, 0.62)), _along(mid, tip), color.darkened(0.08))
	return b.build()


## Grasbüschel: drei gekreuzte Karten mit Halm-Textur (Material „grass“ schneidet sie aus).
static func grass() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 3:
		var angle: float = i * PI / 3.0
		var right := Vector3(cos(angle), 0.0, sin(angle)) * 0.32
		var top := Vector3(0.0, 0.62, 0.0)
		b.add_card([-right, right, right + top, -right + top], LEAF_MID if i % 2 == 0 else LEAF_LIGHT, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	return b.build()


## Grasbüschel mit kleinen Blüten in vier Farben.
static func flowers() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 4:
		var angle: float = i * TAU / 4.0 + 0.4
		var at := Vector3(cos(angle) * 0.18, 0.0, sin(angle) * 0.18)
		b.add(MeshBuilder.cylinder(0.012, 0.012, 0.45, 3), MeshBuilder.at(at + Vector3(0, 0.22, 0)), LEAF_MID)
		b.add(MeshBuilder.sphere(0.06, 5, 3), MeshBuilder.at(at + Vector3(0, 0.46, 0)), FLOWER_COLORS[i])
	b.add(MeshBuilder.cylinder(0.0, 0.05, 0.35, 3), MeshBuilder.at(Vector3(0, 0.17, 0)), LEAF_LIGHT)
	return b.build()


## Fels: zwei verschmolzene Blöcke, obenauf Moos (oder in trockenen Biomen derselbe Stein heller).
static func rock(stone: Color = ROCK, top: Color = MOSS) -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.sphere(0.8, 6, 3), MeshBuilder.at(Vector3(0, 0.3, 0), Vector3(1.3, 0.75, 1.0), Vector3(0, 0.4, 0.1)), stone)
	b.add(MeshBuilder.sphere(0.55, 5, 3), MeshBuilder.at(Vector3(0.6, 0.25, 0.35), Vector3(1.1, 0.8, 1.0)), stone.darkened(0.25))
	b.add(MeshBuilder.sphere(0.5, 5, 2), MeshBuilder.at(Vector3(-0.1, 0.72, 0.0), Vector3(1.4, 0.25, 1.1)), top)
	return b.build()


## Säulenkaktus mit zwei Armen.
static func cactus() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add(MeshBuilder.cylinder(0.26, 0.3, 3.2, 7), MeshBuilder.at(Vector3(0, 1.6, 0)), CACTUS)
	b.add(MeshBuilder.sphere(0.26, 7, 3), MeshBuilder.at(Vector3(0, 3.2, 0)), CACTUS)
	for side: float in [-1.0, 1.0]:
		var height: float = 1.4 if side < 0.0 else 1.9
		b.add(MeshBuilder.cylinder(0.16, 0.16, 0.6, 6), MeshBuilder.at(Vector3(side * 0.42, height, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5)), CACTUS.darkened(0.08))
		b.add(MeshBuilder.cylinder(0.15, 0.17, 1.0, 6), MeshBuilder.at(Vector3(side * 0.7, height + 0.45, 0)), CACTUS.darkened(0.08))
		b.add(MeshBuilder.sphere(0.15, 6, 3), MeshBuilder.at(Vector3(side * 0.7, height + 0.95, 0)), CACTUS.darkened(0.08))
	b.add(MeshBuilder.sphere(0.12, 5, 3), MeshBuilder.at(Vector3(0, 3.42, 0)), Color(0.9, 0.5, 0.6))
	return b.build()


## Toter Baum: kahler, verdrehter Stamm mit gebrochenen Ästen.
static func dead_tree() -> ArrayMesh:
	var b := MeshBuilder.new()
	var points: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0.2, 2.0, 0.1), Vector3(-0.1, 3.6, 0.3), Vector3(0.3, 4.8, 0.1)]
	for i: int in 3:
		b.add(MeshBuilder.cylinder(0.16 - i * 0.04, 0.26 - i * 0.05, points[i].distance_to(points[i + 1]) + 0.1, 5), MeshBuilder.between(points[i], points[i + 1]), DEAD_WOOD)
	var branches: Array[Array] = [[Vector3(0.2, 2.2, 0.1), Vector3(1.3, 3.1, 0.2)], [Vector3(-0.05, 3.2, 0.25), Vector3(-1.2, 4.0, -0.3)], [Vector3(0.2, 4.2, 0.2), Vector3(0.9, 5.0, 0.8)]]
	for branch: Array in branches:
		b.add(MeshBuilder.cylinder(0.05, 0.09, (branch[0] as Vector3).distance_to(branch[1]), 4), MeshBuilder.between(branch[0], branch[1]), DEAD_WOOD.darkened(0.1))
	return b.build()


## Hohes Steppengras: zehn schlanke, gebogene Halme.
static func tall_grass() -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in 10:
		var angle: float = i * TAU / 10.0 + (i % 3) * 0.2
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var height: float = 0.8 + (i % 4) * 0.15
		_leaf(b, dir * 0.05, (dir * 0.35 + Vector3.UP * height).normalized(), height, 0.07, 0.15, LEAF_OLIVE if i % 2 == 0 else LEAF_LIGHT)
	return b.build()


## Blattkarten um eine Krone: count Vierecke in zufälligen Richtungen um center, nach außen versetzt und gedreht;
## der Vegetations-Shader schneidet aus jeder Karte ein Blattbüschel aus.
static func _crown_cards(b: MeshBuilder, center: Vector3, radius: float, color: Color, count: int, salt: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt
	for i: int in count:
		var dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 0.7), rng.randf_range(-1.0, 1.0)).normalized()
		var at: Vector3 = center + dir * radius * 0.5
		var size: float = radius * rng.randf_range(1.0, 1.4)
		var right: Vector3 = dir.cross(Vector3.UP)
		if right.length() < 0.1:
			right = Vector3.RIGHT
		right = right.normalized()
		var up: Vector3 = right.cross(dir).normalized()
		var spin := Basis(dir, rng.randf() * TAU)
		right = spin * right * size * 0.5
		up = spin * up * size * 0.5
		b.add_card([at - right - up, at + right - up, at + right + up, at - right + up], color.darkened(rng.randf_range(0.0, 0.12)))


## Schmales, hängendes Blatt (Raute, beidseitig) vom Ansatz in Richtung dir.
static func _leaf(b: MeshBuilder, base: Vector3, dir: Vector3, length: float, width: float, droop: float, color: Color) -> void:
	var side: Vector3 = Vector3.UP.cross(dir).normalized() * width * 0.5
	var mid: Vector3 = base + dir * length * 0.45 - Vector3(0, droop * 0.25, 0)
	var tip: Vector3 = base + dir * length - Vector3(0, droop, 0)
	b.add_triangles(PackedVector3Array([base, mid + side, tip, base, tip, mid - side]), color)


## Palmwedel entlang einer Mittelrippe (Punkte), leicht V-förmig gefaltet, zur Spitze schmaler.
static func _frond(b: MeshBuilder, spine: Array[Vector3], width: float, color: Color) -> void:
	var points := PackedVector3Array()
	for i: int in spine.size() - 1:
		var a: Vector3 = spine[i]
		var c: Vector3 = spine[i + 1]
		var side: Vector3 = Vector3.UP.cross(c - a).normalized() * width * (1.0 - i * 0.35)
		var edge: Vector3 = (a + c) * 0.5 - Vector3(0, 0.15, 0)
		points.append_array([a, edge + side, c, a, c, edge - side])
	b.add_triangles(points, color)


## Transformation, die eine Box (Länge entlang Z) von a nach c legt.
static func _along(a: Vector3, c: Vector3) -> Transform3D:
	var forward: Vector3 = (c - a).normalized()
	var side: Vector3 = Vector3.UP.cross(forward).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var up: Vector3 = forward.cross(side).normalized()
	return Transform3D(Basis(side, up, forward), (a + c) * 0.5)
