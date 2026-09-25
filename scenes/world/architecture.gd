class_name Architecture
extends RefCounted
## Gebäude im Stil der Südlichen Grenze in realistischer Größe (Spieler 1,8 m): Wohnhäuser, Ahnenhalle, Akademie,
## Wachtürme, Tore, Mauern, Brunnen, Marktstände, Laternen, Banner. Alles wird in einen MeshBuilder gebaut
## (eine Siedlung = ein Draw Call); zurückgegeben werden Kollisionsquader (Transform, Größe).
## Rahmen jedes Gebäudes: Ursprung am Boden in der Mitte, vorn = +Z, Breite entlang X.
## Farbpalette: dach, wand, holz, saeule, banner, stein.

const DOOR: Color = Color(0.16, 0.11, 0.08)
const WINDOW: Color = Color(0.2, 0.15, 0.1)
const PAPER: Color = Color(0.93, 0.88, 0.74)
const LANTERN: Color = Color(0.95, 0.3, 0.18)
## Laternen leuchten nachts in ihrer eigenen Farbe (UV2.y = 0).
const LANTERN_GLOW: Vector2 = Vector2(1.0, 0.0)
const PLINTH: float = 0.4
const WALL_HEIGHT: float = 3.2
const EAVE: float = 0.9
const TILE_ROWS: int = 4


## Wohnhaus: Steinsockel, verputzte Wände mit Holzrahmen, Tür, Gitterfenster, Satteldach mit geschwungenen Traufen.
static func house(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary) -> Array[Array]:
	_box(b, t, Vector3(0, PLINTH * 0.5, 0), Vector3(width + 0.4, PLINTH, depth + 0.4), p["stein"])
	_box(b, t, Vector3(0, PLINTH + WALL_HEIGHT * 0.5, 0), Vector3(width, WALL_HEIGHT, depth), p["wand"])
	_frame(b, t, width, depth, WALL_HEIGHT, p["holz"])
	door(b, t, Vector3(0, PLINTH, depth * 0.5), 1.3, 2.2, p["holz"])
	for side: float in [-1.0, 1.0]:
		window(b, t, Vector3(side * width * 0.3, PLINTH + 1.9, depth * 0.5), 1.0, 0.9, p["holz"], window_glow(t, side))
		_box(b, t, Vector3(side * (width * 0.5 + 0.03), PLINTH + 1.9, 0), Vector3(0.08, 0.9, 1.0), WINDOW, window_glow(t, side + 2.0))
		_box(b, t, Vector3(side * (width * 0.5 + 0.06), PLINTH + 1.9, 0), Vector3(0.04, 0.7, 0.8), PAPER)
	roof(b, t, Vector3(0, PLINTH + WALL_HEIGHT, 0), width + EAVE * 2.0, depth + EAVE * 2.0, 2.4, p["dach"], p["holz"])
	rafters(b, t, Vector3(0, PLINTH + WALL_HEIGHT, 0), width, depth, p["holz"])
	return [[t, Vector3(width + 0.4, PLINTH + WALL_HEIGHT + 2.0, depth + 0.4)]]


## Tür in der Front (Mitte unten bei at): Holzrahmen mit Sturz, Türblatt, Steinschwelle.
static func door(b: MeshBuilder, t: Transform3D, at: Vector3, width: float, height: float, wood: Color) -> void:
	_box(b, t, at + Vector3(0, height * 0.5, 0.03), Vector3(width, height, 0.08), DOOR)
	for side: float in [-1.0, 1.0]:
		_box(b, t, at + Vector3(side * (width * 0.5 + 0.06), height * 0.5, 0.06), Vector3(0.12, height, 0.14), wood)
	_box(b, t, at + Vector3(0, height + 0.08, 0.06), Vector3(width + 0.4, 0.16, 0.16), wood)
	_box(b, t, at + Vector3(0, 0.06, 0.25), Vector3(width + 0.5, 0.12, 0.5), Color(0.5, 0.5, 0.48))
	# Türgriff.
	_box(b, t, at + Vector3(width * 0.3, height * 0.45, 0.09), Vector3(0.05, 0.14, 0.05), Color(0.75, 0.6, 0.3))


## Fenster in der Front (Mitte bei at): Holzrahmen, Papierbespannung, Gitterstäbe; glow = Nachtlicht (UV2).
static func window(b: MeshBuilder, t: Transform3D, at: Vector3, width: float, height: float, wood: Color, glow: Vector2) -> void:
	_box(b, t, at + Vector3(0, 0, 0.03), Vector3(width, height, 0.08), WINDOW, glow)
	_box(b, t, at + Vector3(0, 0, 0.06), Vector3(width - 0.2, height - 0.2, 0.04), PAPER, glow)
	for side: float in [-1.0, 1.0]:
		_box(b, t, at + Vector3(side * width * 0.5, 0, 0.06), Vector3(0.08, height + 0.08, 0.1), wood)
		_box(b, t, at + Vector3(0, side * height * 0.5, 0.06), Vector3(width + 0.08, 0.08, 0.1), wood)
		_box(b, t, at + Vector3(side * width * 0.17, 0, 0.085), Vector3(0.03, height - 0.2, 0.02), wood.darkened(0.2))
	_box(b, t, at + Vector3(0, 0, 0.085), Vector3(width - 0.2, 0.03, 0.02), wood.darkened(0.2))
	# Fensterbrett.
	_box(b, t, at + Vector3(0, -height * 0.5 - 0.06, 0.12), Vector3(width + 0.3, 0.06, 0.22), wood)


## Sparrenköpfe unter der Traufe (vorn und hinten), alle 1,2 m.
static func rafters(b: MeshBuilder, t: Transform3D, base: Vector3, width: float, depth: float, wood: Color) -> void:
	var count: int = maxi(2, floori(width / 1.2))
	for i: int in count + 1:
		var x: float = -width * 0.5 + width * float(i) / count
		for front: float in [-1.0, 1.0]:
			_box(b, t, base + Vector3(x, -0.12, front * (depth * 0.5 + EAVE * 0.5)), Vector3(0.12, 0.12, EAVE), wood.darkened(0.1))


## Ahnenhalle: Steinplattform mit Treppe, rote Säulen vor der Front, Doppeldach, Ehrentafel.
static func hall(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary) -> Array[Array]:
	var base: float = 1.0
	_box(b, t, Vector3(0, base * 0.5, 0), Vector3(width + 5.0, base, depth + 5.0), p["stein"])
	for step: int in 3:
		_box(b, t, Vector3(0, base * (step + 1) / 4.0 * 0.9, depth * 0.5 + 2.5 + (3 - step) * 0.45), Vector3(5.0, base * (step + 1) / 4.0 * 1.8, 0.45), p["stein"].lightened(0.1))
	var wall_h: float = 4.6
	_box(b, t, Vector3(0, base + wall_h * 0.5, -0.8), Vector3(width, wall_h, depth - 1.6), p["wand"])
	_frame(b, t, width, depth - 1.6, wall_h, p["holz"], base, -0.8)
	var columns: int = 6
	for i: int in columns:
		var x: float = lerpf(-width * 0.5 + 0.4, width * 0.5 - 0.4, i / float(columns - 1))
		_cylinder(b, t, Vector3(x, base + wall_h * 0.5, depth * 0.5 - 0.3), 0.28, wall_h, p["saeule"])
	_box(b, t, Vector3(0, base + 1.5, depth * 0.5 - 1.55), Vector3(2.2, 3.0, 0.1), DOOR)
	_box(b, t, Vector3(0, base + wall_h - 0.6, depth * 0.5 - 0.25), Vector3(2.6, 0.9, 0.12), p["banner"])
	roof(b, t, Vector3(0, base + wall_h, 0), width + 3.0, depth + 3.0, 2.2, p["dach"], p["holz"])
	_box(b, t, Vector3(0, base + wall_h + 2.2, 0), Vector3(width * 0.62, 1.4, depth * 0.55), p["wand"].darkened(0.1))
	roof(b, t, Vector3(0, base + wall_h + 2.9, 0), width * 0.75, depth * 0.7, 2.6, p["dach"], p["holz"])
	return [[t.translated_local(Vector3(0, 0, -0.4)), Vector3(width + 1.0, base + wall_h + 5.0, depth)], [t, Vector3(width + 5.0, base, depth + 5.0)]]


## Wachturm: vier Pfosten mit Streben, Plattform mit Geländer, Pyramidendach.
static func tower(b: MeshBuilder, t: Transform3D, p: Dictionary) -> Array[Array]:
	var height: float = 7.5
	var half: float = 1.6
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_cylinder(b, t, Vector3(sx * half, height * 0.5, sz * half), 0.2, height, p["holz"])
	for level: float in [2.5, 5.0]:
		_box(b, t, Vector3(0, level, half), Vector3(half * 2.0, 0.16, 0.16), p["holz"])
		_box(b, t, Vector3(0, level, -half), Vector3(half * 2.0, 0.16, 0.16), p["holz"])
		_box(b, t, Vector3(half, level, 0), Vector3(0.16, 0.16, half * 2.0), p["holz"])
		_box(b, t, Vector3(-half, level, 0), Vector3(0.16, 0.16, half * 2.0), p["holz"])
	_box(b, t, Vector3(0, height - 1.5, 0), Vector3(half * 2.6, 0.25, half * 2.6), p["holz"].darkened(0.1))
	for side: int in 4:
		var rot := Basis(Vector3.UP, side * PI * 0.5)
		b.add(MeshBuilder.box(Vector3(half * 2.6, 0.9, 0.12)), t * Transform3D(rot, rot * Vector3(0, height - 0.95, half * 1.3)), p["holz"])
	b.add(MeshBuilder.cylinder(0.0, half * 2.1, 2.0, 4), t * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0, height + 0.9, 0)), p["dach"])
	b.add(MeshBuilder.sphere(0.35, 6, 4), t * MeshBuilder.at(Vector3(0, height + 2.0, 0)), p["banner"])
	return [[t, Vector3(half * 2.4, height + 2.0, half * 2.4)]]


## Torhaus: zwei Säulen, Querbalken, kleines Dach, Namenstafel. Durchgang bleibt frei.
static func gate(b: MeshBuilder, t: Transform3D, width: float, p: Dictionary) -> Array[Array]:
	var height: float = 5.0
	var boxes: Array[Array] = []
	for side: float in [-1.0, 1.0]:
		_box(b, t, Vector3(side * (width * 0.5 + 0.6), 0.4, 0), Vector3(1.4, 0.8, 1.4), p["stein"])
		_cylinder(b, t, Vector3(side * (width * 0.5 + 0.6), height * 0.5, 0), 0.4, height, p["saeule"])
		boxes.append([t.translated_local(Vector3(side * (width * 0.5 + 0.6), 0, 0)), Vector3(1.4, height, 1.4)])
	_box(b, t, Vector3(0, height - 0.3, 0), Vector3(width + 3.0, 0.5, 0.7), p["holz"])
	plaque(b, t, Vector3(0, height - 1.1, 0.4), width * 0.45, 0.8, p["banner"])
	roof(b, t, Vector3(0, height, 0), width + 4.0, 2.6, 1.4, p["dach"], p["holz"])
	return boxes


## Namenstafel: dunkel lackiertes Brett mit Rahmen in der Klanfarbe und goldenen Zeichenfeldern.
static func plaque(b: MeshBuilder, t: Transform3D, at: Vector3, width: float, height: float, frame: Color) -> void:
	_box(b, t, at, Vector3(width, height, 0.1), Color(0.1, 0.08, 0.08))
	for side: float in [-1.0, 1.0]:
		_box(b, t, at + Vector3(side * width * 0.5, 0, 0.02), Vector3(0.1, height + 0.1, 0.12), frame)
		_box(b, t, at + Vector3(0, side * height * 0.5, 0.02), Vector3(width + 0.1, 0.1, 0.12), frame)
	var count: int = maxi(2, floori(width / 0.7))
	for i: int in count:
		var x: float = lerpf(-width * 0.5 + 0.4, width * 0.5 - 0.4, float(i) / (count - 1))
		_box(b, t, at + Vector3(x, 0, 0.055), Vector3(0.36, height * 0.55, 0.02), Color(0.85, 0.68, 0.25))


## Mauerstück von a nach c (Bodenpunkte): Steinsockel, Stampflehm, Ziegelkappe.
static func wall(b: MeshBuilder, a: Vector3, c: Vector3, p: Dictionary) -> Array[Array]:
	var length: float = Vector2(c.x - a.x, c.z - a.z).length()
	var basis := Basis(Vector3.UP, atan2(c.x - a.x, c.z - a.z) + PI * 0.5)
	var bottom: float = minf(a.y, c.y) - 0.6
	var mid := Vector3((a.x + c.x) * 0.5, bottom, (a.z + c.z) * 0.5)
	var t := Transform3D(basis, mid)
	var top: float = maxf(a.y, c.y) - bottom + 3.0
	_box(b, t, Vector3(0, 0.5, 0), Vector3(length + 0.3, 1.0 + 0.6, 1.0), p["stein"])
	_box(b, t, Vector3(0, top * 0.5, 0), Vector3(length + 0.2, top, 0.7), p["wand"].darkened(0.18))
	b.add(MeshBuilder.box(Vector3(length + 0.6, 0.35, 1.15)), t * MeshBuilder.at(Vector3(0, top + 0.15, 0)), p["dach"])
	return [[t.translated_local(Vector3(0, 0, 0)), Vector3(length + 0.2, top + 0.4, 0.9)]]


static func well(b: MeshBuilder, t: Transform3D, p: Dictionary) -> Array[Array]:
	b.add(MeshBuilder.cylinder(1.0, 1.1, 0.9, 10), t * MeshBuilder.at(Vector3(0, 0.45, 0)), p["stein"])
	b.add(MeshBuilder.cylinder(0.8, 0.8, 0.05, 10), t * MeshBuilder.at(Vector3(0, 0.9, 0)), Color(0.1, 0.18, 0.2))
	for side: float in [-1.0, 1.0]:
		_cylinder(b, t, Vector3(side * 1.0, 1.3, 0), 0.1, 2.6, p["holz"])
	_box(b, t, Vector3(0, 2.4, 0), Vector3(2.3, 0.12, 0.12), p["holz"])
	roof(b, t, Vector3(0, 2.5, 0), 2.8, 1.8, 0.8, p["dach"], p["holz"])
	return [[t, Vector3(2.2, 2.0, 2.2)]]


static func stall(b: MeshBuilder, t: Transform3D, p: Dictionary, goods: Color) -> Array[Array]:
	_box(b, t, Vector3(0, 0.45, 0), Vector3(2.8, 0.9, 1.2), p["holz"])
	for i: int in 4:
		b.add(MeshBuilder.sphere(0.2, 6, 3), t * MeshBuilder.at(Vector3(-1.0 + i * 0.66, 1.0, 0.1)), goods.lightened(i * 0.08))
	for sx: float in [-1.3, 1.3]:
		for sz: float in [-0.9, 0.7]:
			_cylinder(b, t, Vector3(sx, 1.2, sz), 0.07, 2.4 if sz < 0.0 else 2.0, p["holz"])
	b.add(MeshBuilder.box(Vector3(3.2, 0.08, 2.2)), t * MeshBuilder.at(Vector3(0, 2.25, -0.1), Vector3.ONE, Vector3(0.18, 0, 0)), p["banner"])
	return [[t, Vector3(2.8, 1.0, 1.2)]]


## Laternenfüße der Siedlung, die gerade gebaut wird (LanternLights holt sie sich in Settlement.finish).
static var lantern_points: Array[Vector3] = []


## Laternenpfahl: Ausleger mit Papierlaterne (Deckel, Bodenring, Quaste); der Fuß wird für LanternLights gemerkt.
static func lantern_post(b: MeshBuilder, t: Transform3D, p: Dictionary) -> void:
	lantern_points.append(t * Vector3(0.0, 0.0, 0.6))
	_cylinder(b, t, Vector3(0, 1.4, 0), 0.08, 2.8, p["holz"])
	_box(b, t, Vector3(0, 2.75, 0.3), Vector3(0.08, 0.08, 0.7), p["holz"])
	_box(b, t, Vector3(0, 2.55, 0.12), Vector3(0.05, 0.05, 0.4), p["holz"].darkened(0.1))
	_cylinder(b, t, Vector3(0, 2.63, 0.6), 0.015, 0.18, Color(0.2, 0.15, 0.1))
	b.add(MeshBuilder.sphere(0.22, 8, 5), t * MeshBuilder.at(Vector3(0, 2.32, 0.6), Vector3(1.0, 1.25, 1.0)), LANTERN, LANTERN_GLOW)
	b.add(MeshBuilder.cylinder(0.1, 0.16, 0.1, 8), t * MeshBuilder.at(Vector3(0, 2.57, 0.6)), Color(0.15, 0.1, 0.05))
	b.add(MeshBuilder.cylinder(0.1, 0.08, 0.06, 8), t * MeshBuilder.at(Vector3(0, 2.05, 0.6)), Color(0.15, 0.1, 0.05))
	_box(b, t, Vector3(0, 1.88, 0.6), Vector3(0.05, 0.28, 0.05), Color(0.85, 0.65, 0.2))


static func banner_pole(b: MeshBuilder, t: Transform3D, p: Dictionary) -> void:
	_cylinder(b, t, Vector3(0, 3.5, 0), 0.1, 7.0, p["holz"])
	_box(b, t, Vector3(0.55, 5.2, 0), Vector3(1.0, 3.0, 0.05), p["banner"])
	b.add(MeshBuilder.sphere(0.16, 6, 3), t * MeshBuilder.at(Vector3(0, 7.1, 0)), p["saeule"])


static func training_dummy(b: MeshBuilder, t: Transform3D, p: Dictionary) -> void:
	_cylinder(b, t, Vector3(0, 0.9, 0), 0.14, 1.8, p["holz"])
	_box(b, t, Vector3(0, 1.35, 0), Vector3(1.1, 0.14, 0.14), p["holz"])
	b.add(MeshBuilder.sphere(0.22, 6, 3), t * MeshBuilder.at(Vector3(0, 1.95, 0)), PAPER.darkened(0.2))


## Satteldach (First entlang X) mit Überstand, Firstbalken, hochgezogenen Ecken und Firstenden.
static func roof(b: MeshBuilder, t: Transform3D, base: Vector3, width: float, depth: float, height: float, color: Color, wood: Color) -> void:
	var prism := PrismMesh.new()
	prism.size = Vector3(depth, height, width)
	b.add(prism, t * Transform3D(Basis(Vector3.UP, PI * 0.5), base + Vector3(0, height * 0.5, 0)), color)
	b.add(MeshBuilder.box(Vector3(width + 0.4, 0.28, 0.35)), t * MeshBuilder.at(base + Vector3(0, height + 0.05, 0)), color.darkened(0.25))
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.box(Vector3(0.3, 0.7, 0.3)), t * MeshBuilder.at(base + Vector3(side * (width * 0.5 + 0.1), height + 0.3, 0), Vector3.ONE, Vector3(0, 0, side * 0.35)), color.darkened(0.3))
		for front: float in [-1.0, 1.0]:
			b.add(MeshBuilder.box(Vector3(0.9, 0.18, 0.5)), t * MeshBuilder.at(base + Vector3(side * width * 0.5, 0.18, front * depth * 0.5), Vector3.ONE, Vector3(-front * 0.5, 0, -side * 0.5)), color.darkened(0.15))
	# Ziegelreihen: flache Leisten auf beiden Dachflächen.
	var slope: float = atan2(height, depth * 0.5)
	for side: float in [-1.0, 1.0]:
		for row: int in TILE_ROWS:
			var f: float = (row + 0.5) / TILE_ROWS
			var at: Vector3 = base + Vector3(0, height * f + 0.04, side * depth * 0.5 * (1.0 - f))
			b.add(MeshBuilder.box(Vector3(width - 0.1, 0.07, 0.16)), t * MeshBuilder.at(at, Vector3.ONE, Vector3(side * slope, 0, 0)), color.darkened(0.18))
	b.add(MeshBuilder.box(Vector3(width - 0.2, 0.2, 0.2)), t * MeshBuilder.at(base + Vector3(0, -0.05, depth * 0.5 - 0.1)), wood)
	b.add(MeshBuilder.box(Vector3(width - 0.2, 0.2, 0.2)), t * MeshBuilder.at(base + Vector3(0, -0.05, -depth * 0.5 + 0.1)), wood)


## Eckpfosten und Balken aus Holz um eine Wandfläche.
static func _frame(b: MeshBuilder, t: Transform3D, width: float, depth: float, height: float, wood: Color, bottom: float = PLINTH, z_offset: float = 0.0) -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(b, t, Vector3(sx * width * 0.5, bottom + height * 0.5, z_offset + sz * depth * 0.5), Vector3(0.28, height, 0.28), wood)
	_box(b, t, Vector3(0, bottom + height - 0.15, z_offset + depth * 0.5 + 0.02), Vector3(width + 0.2, 0.3, 0.1), wood)
	_box(b, t, Vector3(0, bottom + height - 0.15, z_offset - depth * 0.5 - 0.02), Vector3(width + 0.2, 0.3, 0.1), wood)
	_box(b, t, Vector3(0, bottom + 0.15, z_offset + depth * 0.5 + 0.02), Vector3(width + 0.2, 0.2, 0.08), wood)


static func _box(b: MeshBuilder, t: Transform3D, center: Vector3, box_size: Vector3, color: Color, glow: Vector2 = Vector2.ZERO) -> void:
	b.add(MeshBuilder.box(box_size), t * MeshBuilder.at(center), color, glow)


## Nachtlicht eines Fensters (UV2 für den Siedlungs-Shader): etwa zwei von drei Fenstern sind erleuchtet, unterschiedlich hell.
static func window_glow(t: Transform3D, salt: float) -> Vector2:
	var roll: int = absi(hash(Vector3i(roundi(t.origin.x * 3.0 + salt * 7.0), roundi(t.origin.y), roundi(t.origin.z * 3.0))))
	if roll % 3 == 0:
		return Vector2.ZERO
	return Vector2(0.55 + float(roll % 50) / 110.0, 1.0)


static func _cylinder(b: MeshBuilder, t: Transform3D, center: Vector3, radius: float, height: float, color: Color) -> void:
	b.add(MeshBuilder.cylinder(radius, radius, height, 8), t * MeshBuilder.at(center), color)
