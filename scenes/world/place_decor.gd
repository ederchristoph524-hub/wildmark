class_name PlaceDecor
extends RefCounted
## Ausstattung der Materialorte (WorldAreas): Schlackenfeld mit verkohlten Stümpfen und glühenden Rissen, alter
## Friedhof mit Grabreihen, Steinlaternen, Schrein und Mauerresten, Frostquelle mit Eisspitzen und Schneewehen,
## Urstein-Ader mit Stollen, leuchtenden Adern im Fels, Lore auf Schienen und Abraumhalden.
## Je Ort ein Mesh mit Vertex-Farben und eines für die leuchtenden Teile (zwei Draw Calls).

const CHAR: Color = Color(0.13, 0.1, 0.08)
const ASH: Color = Color(0.26, 0.25, 0.24)
const SLAG: Color = Color(0.2, 0.18, 0.17)
const EMBER: Color = Color(1.0, 0.42, 0.12)
const GRAVE_STONE: Color = Color(0.55, 0.55, 0.52)
const GRAVE_MOSS: Color = Color(0.33, 0.42, 0.26)
const GRAVE_EARTH: Color = Color(0.3, 0.24, 0.18)
const DEAD_WOOD: Color = Color(0.3, 0.26, 0.22)
const LANTERN_GLOW: Color = Color(1.0, 0.75, 0.4)
const SHRINE_WOOD: Color = Color(0.42, 0.2, 0.14)
const SHRINE_ROOF: Color = Color(0.25, 0.25, 0.28)
const SNOW: Color = Color(0.76, 0.82, 0.88)
const FROST_ROCK: Color = Color(0.62, 0.7, 0.78)
const ICE: Color = Color(0.7, 0.92, 1.0)
const VEIN_ROCK: Color = Color(0.33, 0.32, 0.31)
const SHAFT: Color = Color(0.05, 0.045, 0.04)
const TIMBER: Color = Color(0.42, 0.29, 0.17)
const RAIL: Color = Color(0.32, 0.32, 0.34)
## Urstein: milchig weißgrün, leuchtet sanft.
const PRIMEVAL: Color = Color(0.78, 1.0, 0.86)
const VIEW: float = 110.0


static func ash_field(world: World, center: Vector2, radius: float) -> void:
	var rng := _rng(center)
	var b := MeshBuilder.new()
	var glow := MeshBuilder.new()
	for i: int in 9:
		var at: Vector3 = _point(world, center, radius * 0.95, rng)
		var height: float = rng.randf_range(0.5, 1.7)
		b.add(MeshBuilder.cylinder(0.22, 0.38, height, 6), MeshBuilder.at(at + Vector3.UP * height * 0.5, Vector3.ONE, Vector3(rng.randf_range(-0.1, 0.1), 0, rng.randf_range(-0.1, 0.1))), CHAR)
		# Gesplitterte Spitze.
		for k: int in 2:
			b.add(MeshBuilder.cylinder(0.0, 0.12, 0.5, 4), MeshBuilder.at(at + Vector3(0.1 - k * 0.2, height + 0.2, 0.05), Vector3.ONE, Vector3(0.3 - k * 0.6, 0, 0.2)), CHAR.lightened(0.05))
	for i: int in 4:
		var at: Vector3 = _point(world, center, radius * 0.8, rng)
		b.add(MeshBuilder.cylinder(0.2, 0.26, rng.randf_range(2.2, 3.6), 6), MeshBuilder.at(at + Vector3.UP * 0.2, Vector3.ONE, Vector3(PI * 0.5, rng.randf() * TAU, 0)), CHAR.lightened(0.03))
	for i: int in 10:
		var at: Vector3 = _point(world, center, radius, rng)
		b.add(MeshBuilder.sphere(rng.randf_range(0.7, 1.3), 7, 3), MeshBuilder.at(at, Vector3(1.3, 0.28, 1.0), Vector3(0, rng.randf() * TAU, 0)), ASH.darkened(rng.randf_range(0.0, 0.2)))
	for i: int in 7:
		var at: Vector3 = _point(world, center, radius * 0.85, rng)
		var size: float = rng.randf_range(0.4, 0.9)
		b.add(MeshBuilder.sphere(size, 5, 3), MeshBuilder.at(at + Vector3.UP * size * 0.3, Vector3(1.2, 0.7, 1.0), Vector3(0, rng.randf() * TAU, 0.2)), SLAG)
		# Glühende Risse über den Schlackebrocken und daneben im Boden.
		glow.add(MeshBuilder.box(Vector3(size * 1.4, 0.05, 0.07)), MeshBuilder.at(at + Vector3.UP * size * 0.62, Vector3.ONE, Vector3(0, rng.randf() * TAU, 0)), EMBER)
		glow.add(MeshBuilder.box(Vector3(rng.randf_range(0.8, 1.6), 0.04, 0.08)), MeshBuilder.at(at + Vector3(size + 0.6, 0.04, 0.3), Vector3.ONE, Vector3(0, rng.randf() * TAU, 0)), EMBER)
	for i: int in 12:
		var at: Vector3 = _point(world, center, radius * 0.9, rng)
		glow.add(MeshBuilder.sphere(rng.randf_range(0.06, 0.12), 4, 2), MeshBuilder.at(at + Vector3.UP * 0.06), EMBER)
	_add(world, b, WorldMaterials.props())
	_add(world, glow, WorldMaterials.glowing(EMBER))


static func graveyard(world: World, center: Vector2, radius: float) -> void:
	var rng := _rng(center)
	var b := MeshBuilder.new()
	var glow := MeshBuilder.new()
	# Grabreihen links und rechts eines Mittelwegs, der zum Schrein führt.
	var rows: int = maxi(2, floori(radius * 1.4 / 3.2))
	for row: int in rows:
		var z: float = -radius * 0.55 + row * 3.2
		for side: float in [-1.0, 1.0]:
			for k: int in 2:
				var x: float = side * (2.2 + k * 2.6) + rng.randf_range(-0.3, 0.3)
				if Vector2(x, z).length() > radius * 0.95:
					continue
				_grave(b, world.ground_point(center.x + x, center.y + z), rng)
	var shrine: Vector3 = world.ground_point(center.x, center.y - radius * 0.8)
	_shrine(b, glow, shrine)
	for side: float in [-1.0, 1.0]:
		_stone_lantern(b, glow, world.ground_point(center.x + side * 1.6, center.y + radius * 0.75))
	# Mauerreste am Rand, mit Lücken.
	var segments: int = 18
	for i: int in segments:
		if rng.randf() < 0.45:
			continue
		var angle: float = i * TAU / segments
		var at: Vector3 = world.ground_point(center.x + cos(angle) * radius * 1.05, center.y + sin(angle) * radius * 1.05)
		var length: float = radius * TAU / segments * rng.randf_range(0.5, 0.9)
		b.add(MeshBuilder.box(Vector3(length, rng.randf_range(0.35, 0.8), 0.4)), MeshBuilder.at(at + Vector3.UP * 0.25, Vector3.ONE, Vector3(0, -angle + PI * 0.5, 0)), GRAVE_STONE.darkened(rng.randf_range(0.1, 0.25)))
	for i: int in 2:
		var angle: float = rng.randf() * TAU
		_dead_tree(b, world.ground_point(center.x + cos(angle) * radius * 0.9, center.y + sin(angle) * radius * 0.9), rng)
	_add(world, b, WorldMaterials.props())
	_add(world, glow, WorldMaterials.glowing(LANTERN_GLOW))


static func frost_spring(world: World, center: Vector2, radius: float) -> void:
	var rng := _rng(center)
	var b := MeshBuilder.new()
	var glow := MeshBuilder.new()
	var pool: Vector3 = world.ground_point(center.x, center.y)
	# Zugefrorener Quelltopf (nicht leuchtend, sonst überstrahlt er alles); nur die Eisspitzen glimmen.
	b.add(MeshBuilder.cylinder(radius * 0.3, radius * 0.32, 0.08, 10), MeshBuilder.at(pool + Vector3.UP * 0.05), ICE.darkened(0.1))
	for i: int in 14:
		var at: Vector3 = _point(world, center, radius, rng)
		if at.distance_to(pool) < radius * 0.35:
			continue
		var height: float = rng.randf_range(0.8, 2.4)
		glow.add(MeshBuilder.cylinder(0.0, rng.randf_range(0.25, 0.45), height, 5), MeshBuilder.at(at + Vector3.UP * height * 0.45, Vector3.ONE, Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))), ICE)
	for i: int in 6:
		var at: Vector3 = _point(world, center, radius * 0.9, rng)
		var size: float = rng.randf_range(0.5, 1.0)
		b.add(MeshBuilder.sphere(size, 6, 3), MeshBuilder.at(at + Vector3.UP * size * 0.3, Vector3(1.3, 0.75, 1.0), Vector3(0, rng.randf() * TAU, 0.1)), FROST_ROCK)
		b.add(MeshBuilder.sphere(size * 0.8, 6, 2), MeshBuilder.at(at + Vector3.UP * size * 0.75, Vector3(1.4, 0.3, 1.1)), SNOW)
	for i: int in 6:
		var at: Vector3 = _point(world, center, radius * 1.1, rng)
		b.add(MeshBuilder.sphere(rng.randf_range(0.6, 1.2), 7, 3), MeshBuilder.at(at, Vector3(1.4, 0.22, 1.0), Vector3(0, rng.randf() * TAU, 0)), SNOW.darkened(rng.randf_range(0.0, 0.08)))
	_add(world, b, WorldMaterials.props())
	_add(world, glow, WorldMaterials.glowing(ICE))


## Urstein-Ader: Felsbuckel im Norden mit Stolleneingang (Holzrahmen, dunkler Schacht), Ursteinadern im Fels, Schienen
## mit Lore zum Platz, Abraumhalden, Kisten und eine Spitzhacke.
static func stone_vein(world: World, center: Vector2, radius: float) -> void:
	var rng := _rng(center)
	var b := MeshBuilder.new()
	var glow := MeshBuilder.new()
	var back := Vector2(center.x, center.y - radius * 0.8)
	for i: int in 13:
		var offset := Vector2(rng.randf_range(-radius * 0.95, radius * 0.95), rng.randf_range(-5.0, 0.5))
		if absf(offset.x) < 2.6 and offset.y > -2.5:
			offset.y -= 3.0
		var at: Vector3 = world.ground_point(back.x + offset.x, back.y + offset.y)
		var size: float = rng.randf_range(2.8, 4.8) * (1.25 if absf(offset.x) < radius * 0.4 else 1.0)
		var middle: Vector3 = at + Vector3.UP * size * 0.35
		b.add(MeshBuilder.sphere(size, 7, 4), MeshBuilder.at(middle, Vector3(1.2, 0.9, 1.0)), VEIN_ROCK.darkened(rng.randf_range(0.0, 0.2)))
		# Adern auf der Vorderseite (zum Platz hin).
		for k: int in 3:
			var lift: float = size * rng.randf_range(0.0, 0.55)
			var depth: float = size * sqrt(maxf(0.0, 1.0 - pow(lift / (size * 0.9), 2.0))) * 0.96
			var side: float = rng.randf_range(-0.6, 0.6) * size
			glow.add(MeshBuilder.box(Vector3(rng.randf_range(0.6, 1.4), 0.1, 0.14)), MeshBuilder.at(middle + Vector3(side, lift, depth * cos(side / size)), Vector3.ONE, Vector3(0, 0, rng.randf_range(-0.7, 0.7))), PRIMEVAL)
	var mouth: Vector3 = world.ground_point(back.x, back.y + 1.5)
	b.add(MeshBuilder.box(Vector3(2.8, 3.0, 0.6)), MeshBuilder.at(mouth + Vector3(0, 1.5, -0.4)), SHAFT)
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.box(Vector3(0.35, 3.4, 0.35)), MeshBuilder.at(mouth + Vector3(side * 1.6, 1.7, 0.0)), TIMBER)
		b.add(MeshBuilder.box(Vector3(0.25, 1.6, 0.25)), MeshBuilder.at(mouth + Vector3(side * 1.1, 2.9, 0.05), Vector3.ONE, Vector3(0, 0, side * 0.9)), TIMBER.darkened(0.1))
	b.add(MeshBuilder.box(Vector3(4.2, 0.42, 0.5)), MeshBuilder.at(mouth + Vector3(0, 3.5, 0.0)), TIMBER.darkened(0.05))
	glow.add(MeshBuilder.sphere(0.18, 5, 3), MeshBuilder.at(mouth + Vector3(0, 3.0, 0.3)), PRIMEVAL)
	_rails(world, b, glow, Vector2(back.x, back.y + 1.5), radius, rng)
	for i: int in 5:
		var at: Vector3 = _point(world, center, radius * 0.9, rng)
		if at.distance_to(mouth) < 4.0:
			continue
		var size: float = rng.randf_range(0.8, 1.5)
		b.add(MeshBuilder.sphere(size, 6, 3), MeshBuilder.at(at, Vector3(1.4, 0.45, 1.1), Vector3(0, rng.randf() * TAU, 0)), VEIN_ROCK.darkened(rng.randf_range(0.15, 0.3)))
	for i: int in 3:
		var at: Vector3 = world.ground_point(back.x + 3.2 + i * 0.9, back.y + 3.0 + rng.randf() * 0.6)
		b.add(MeshBuilder.box(Vector3(0.8, 0.7, 0.8)), MeshBuilder.at(at + Vector3.UP * 0.35, Vector3.ONE, Vector3(0, rng.randf_range(-0.3, 0.3), 0)), TIMBER.lightened(0.08))
	var pick: Vector3 = world.ground_point(back.x - 2.6, back.y + 2.2)
	b.add(MeshBuilder.cylinder(0.05, 0.05, 1.3, 5), MeshBuilder.at(pick + Vector3(0, 0.6, 0), Vector3.ONE, Vector3(0.35, 0, 0.2)), TIMBER)
	b.add(MeshBuilder.box(Vector3(0.9, 0.1, 0.1)), MeshBuilder.at(pick + Vector3(0.1, 1.22, 0.2), Vector3.ONE, Vector3(0.35, 0, 0.2)), RAIL)
	_add(world, b, WorldMaterials.props())
	_add(world, glow, WorldMaterials.glowing(PRIMEVAL))


## Schienen vom Stollen zum Platz, darauf eine Lore mit Ursteinbrocken.
static func _rails(world: World, b: MeshBuilder, glow: MeshBuilder, start: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	var length: float = radius * 1.1
	var steps: int = floori(length / 0.9)
	for i: int in steps:
		var at: Vector3 = world.ground_point(start.x, start.y + 0.5 + i * 0.9)
		b.add(MeshBuilder.box(Vector3(1.5, 0.08, 0.22)), MeshBuilder.at(at + Vector3.UP * 0.05), TIMBER.darkened(0.2))
		for side: float in [-0.5, 0.5]:
			b.add(MeshBuilder.box(Vector3(0.08, 0.1, 0.95)), MeshBuilder.at(at + Vector3(side, 0.14, 0.0)), RAIL)
	var cart: Vector3 = world.ground_point(start.x, start.y + length * 0.45)
	b.add(MeshBuilder.box(Vector3(1.2, 0.7, 1.5)), MeshBuilder.at(cart + Vector3.UP * 0.65), TIMBER.darkened(0.15))
	for x: float in [-0.62, 0.62]:
		for z: float in [-0.5, 0.5]:
			b.add(MeshBuilder.cylinder(0.22, 0.22, 0.1, 8), MeshBuilder.at(cart + Vector3(x, 0.25, z), Vector3.ONE, Vector3(0, 0, PI * 0.5)), RAIL.darkened(0.3))
	for i: int in 5:
		glow.add(MeshBuilder.sphere(rng.randf_range(0.14, 0.24), 5, 3), MeshBuilder.at(cart + Vector3(rng.randf_range(-0.4, 0.4), 1.05, rng.randf_range(-0.5, 0.5))), PRIMEVAL)


## Grab: Stele mit Kappe, abgerundeter Stein oder Erdhügel mit kleinem Stein; leicht schief, teils bemoost.
static func _grave(b: MeshBuilder, at: Vector3, rng: RandomNumberGenerator) -> void:
	var stone: Color = GRAVE_STONE.darkened(rng.randf_range(0.0, 0.2))
	var t := Transform3D(Basis(Vector3.UP, rng.randf_range(-0.12, 0.12)) * Basis(Vector3.RIGHT, rng.randf_range(-0.08, 0.08)), at)
	match rng.randi() % 3:
		0:
			b.add(MeshBuilder.box(Vector3(0.9, 0.2, 0.5)), t * MeshBuilder.at(Vector3(0, 0.1, 0)), stone.darkened(0.1))
			b.add(MeshBuilder.box(Vector3(0.55, 1.15, 0.2)), t * MeshBuilder.at(Vector3(0, 0.75, 0)), stone)
			b.add(MeshBuilder.box(Vector3(0.75, 0.09, 0.32)), t * MeshBuilder.at(Vector3(0, 1.37, 0)), stone.darkened(0.15))
		1:
			b.add(MeshBuilder.box(Vector3(0.6, 0.65, 0.18)), t * MeshBuilder.at(Vector3(0, 0.33, 0)), stone)
			b.add(MeshBuilder.cylinder(0.3, 0.3, 0.18, 8), t * MeshBuilder.at(Vector3(0, 0.65, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0)), stone)
		_:
			b.add(MeshBuilder.sphere(0.7, 7, 3), t * MeshBuilder.at(Vector3(0, 0.02, 0.6), Vector3(0.9, 0.35, 1.6)), GRAVE_EARTH)
			b.add(MeshBuilder.box(Vector3(0.35, 0.5, 0.14)), t * MeshBuilder.at(Vector3(0, 0.25, -0.5)), stone)
	if rng.randf() < 0.5:
		b.add(MeshBuilder.sphere(0.2, 5, 2), t * MeshBuilder.at(Vector3(0.15, 0.08, 0.3), Vector3(1.4, 0.4, 1.0)), GRAVE_MOSS)


## Steinlaterne: Sockel, Säule, Leuchtkammer, Dach.
static func _stone_lantern(b: MeshBuilder, glow: MeshBuilder, at: Vector3) -> void:
	b.add(MeshBuilder.cylinder(0.35, 0.42, 0.25, 6), MeshBuilder.at(at + Vector3.UP * 0.12), GRAVE_STONE.darkened(0.1))
	b.add(MeshBuilder.cylinder(0.13, 0.16, 0.9, 6), MeshBuilder.at(at + Vector3.UP * 0.7), GRAVE_STONE)
	b.add(MeshBuilder.box(Vector3(0.55, 0.08, 0.55)), MeshBuilder.at(at + Vector3.UP * 1.18), GRAVE_STONE.darkened(0.05))
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		b.add(MeshBuilder.box(Vector3(0.07, 0.4, 0.07)), MeshBuilder.at(at + Vector3(corner.x * 0.2, 1.42, corner.y * 0.2)), GRAVE_STONE)
	glow.add(MeshBuilder.box(Vector3(0.3, 0.3, 0.3)), MeshBuilder.at(at + Vector3.UP * 1.42), LANTERN_GLOW)
	b.add(MeshBuilder.cylinder(0.0, 0.5, 0.35, 4), MeshBuilder.at(at + Vector3.UP * 1.8, Vector3.ONE, Vector3(0, PI * 0.25, 0)), GRAVE_STONE.darkened(0.15))


## Kleiner Ahnenschrein: Steinsockel, Holzgehäuse, Satteldach, Räucherschale mit Glut.
static func _shrine(b: MeshBuilder, glow: MeshBuilder, at: Vector3) -> void:
	b.add(MeshBuilder.box(Vector3(2.6, 0.4, 1.8)), MeshBuilder.at(at + Vector3.UP * 0.2), GRAVE_STONE.darkened(0.12))
	b.add(MeshBuilder.box(Vector3(1.6, 1.4, 1.1)), MeshBuilder.at(at + Vector3(0, 1.1, -0.2)), SHRINE_WOOD)
	b.add(MeshBuilder.box(Vector3(0.9, 0.8, 0.05)), MeshBuilder.at(at + Vector3(0, 1.05, 0.37)), Color(0.12, 0.08, 0.06))
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.box(Vector3(1.2, 0.08, 1.7)), MeshBuilder.at(at + Vector3(side * 0.5, 2.05, -0.2), Vector3.ONE, Vector3(0, 0, side * -0.5)), SHRINE_ROOF)
	b.add(MeshBuilder.cylinder(0.22, 0.16, 0.2, 7), MeshBuilder.at(at + Vector3(0, 0.5, 0.65)), Color(0.45, 0.35, 0.2))
	glow.add(MeshBuilder.sphere(0.1, 5, 3), MeshBuilder.at(at + Vector3(0, 0.62, 0.65)), LANTERN_GLOW)
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.cylinder(0.12, 0.1, 0.12, 6), MeshBuilder.at(at + Vector3(side * 0.7, 0.46, 0.6)), Color(0.75, 0.72, 0.65))


## Kahler Baum aus drei Stammstücken und Ästen.
static func _dead_tree(b: MeshBuilder, at: Vector3, rng: RandomNumberGenerator) -> void:
	var lean := Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
	var points: Array[Vector3] = [at, at + Vector3(0, 2.2, 0) + lean, at + Vector3(0, 4.0, 0) + lean * 2.2, at + Vector3(0, 5.2, 0) + lean * 2.8]
	for i: int in 3:
		b.add(MeshBuilder.cylinder(0.16 - i * 0.04, 0.28 - i * 0.06, points[i].distance_to(points[i + 1]) + 0.1, 5), MeshBuilder.between(points[i], points[i + 1]), DEAD_WOOD)
	for i: int in 4:
		var from: Vector3 = points[1 + i % 2].lerp(points[2 + i % 2], 0.4)
		var angle: float = rng.randf() * TAU
		var to: Vector3 = from + Vector3(cos(angle) * 1.3, rng.randf_range(0.5, 1.2), sin(angle) * 1.3)
		b.add(MeshBuilder.cylinder(0.04, 0.08, from.distance_to(to), 4), MeshBuilder.between(from, to), DEAD_WOOD.darkened(0.1))


static func _point(world: World, center: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector3:
	var angle: float = rng.randf() * TAU
	var distance: float = sqrt(rng.randf()) * radius
	return world.ground_point(center.x + cos(angle) * distance, center.y + sin(angle) * distance)


## Gleiche Anordnung bei jedem Besuch.
static func _rng(center: Vector2) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(roundi(center.x), roundi(center.y)))
	return rng


static func _add(world: World, b: MeshBuilder, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = material
	node.visibility_range_end = VIEW
	world.add_child(node)
