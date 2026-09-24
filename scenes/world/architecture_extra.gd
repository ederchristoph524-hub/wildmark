class_name ArchitectureExtra
extends RefCounted
## Bauten der übrigen Regionen in realistischer Größe: Jurten (Nördliche Ebene), Lehmhäuser und Kuppeltempel
## (Westliche Wüste), Pagoden, Arena, Stadttürme und Torbögen (Shang-Stadt, Sekten), Terrassen mit Rampen,
## Palisaden, Stege und Boote (Östliches Meer). Wie Architecture: alles in einen MeshBuilder, zurück kommen
## Kollisionsquader [Transform, Größe] (Ursprung am Boden, vorn = +Z).

const DOOR: Color = Color(0.16, 0.11, 0.08)
const FELT: Color = Color(0.86, 0.82, 0.72)
const WATER_DARK: Color = Color(0.1, 0.2, 0.25)
const SAIL: Color = Color(0.88, 0.84, 0.74)


## Jurte: runde Filzwand, Kegeldach mit Rauchring, bemalte Tür, zwei Bänder.
static func yurt(b: MeshBuilder, t: Transform3D, radius: float, p: Dictionary) -> Array[Array]:
	var wall_h: float = 2.1
	b.add(MeshBuilder.cylinder(radius, radius, wall_h, 14), t * MeshBuilder.at(Vector3(0, wall_h * 0.5, 0)), FELT.lerp(p["wand"], 0.3))
	for band: float in [0.5, 1.7]:
		b.add(MeshBuilder.cylinder(radius + 0.03, radius + 0.03, 0.14, 14), t * MeshBuilder.at(Vector3(0, band, 0)), p["banner"])
	b.add(MeshBuilder.cylinder(0.35, radius + 0.25, radius * 0.55, 14), t * MeshBuilder.at(Vector3(0, wall_h + radius * 0.275, 0)), p["dach"])
	b.add(MeshBuilder.cylinder(0.3, 0.3, 0.3, 8), t * MeshBuilder.at(Vector3(0, wall_h + radius * 0.55 + 0.1, 0)), p["holz"])
	_box(b, t, Vector3(0, 0.95, radius - 0.02), Vector3(1.0, 1.8, 0.2), p["holz"])
	_box(b, t, Vector3(0, 0.9, radius + 0.06), Vector3(0.8, 1.6, 0.06), p["saeule"])
	return [[t, Vector3(radius * 1.6, wall_h + radius * 0.5, radius * 1.6)]]


## Lehmhaus: dicke Wände, Flachdach mit Brüstung, vorstehende Balken, Tür und kleine Fenster.
static func adobe_house(b: MeshBuilder, t: Transform3D, width: float, depth: float, height: float, p: Dictionary) -> Array[Array]:
	var wall: Color = p["wand"]
	_box(b, t, Vector3(0, height * 0.5, 0), Vector3(width, height, depth), wall)
	_box(b, t, Vector3(0, height + 0.1, 0), Vector3(width + 0.3, 0.2, depth + 0.3), wall.darkened(0.08))
	for side: float in [-1.0, 1.0]:
		_box(b, t, Vector3(side * width * 0.5, height + 0.45, 0), Vector3(0.3, 0.5, depth + 0.3), wall.darkened(0.04))
		_box(b, t, Vector3(0, height + 0.45, side * depth * 0.5), Vector3(width + 0.3, 0.5, 0.3), wall.darkened(0.04))
	var beams: int = maxi(3, roundi(width / 1.4))
	for i: int in beams:
		var x: float = lerpf(-width * 0.4, width * 0.4, i / float(beams - 1))
		b.add(MeshBuilder.cylinder(0.09, 0.09, 0.7, 5), t * MeshBuilder.at(Vector3(x, height - 0.25, depth * 0.5 + 0.2), Vector3.ONE, Vector3(PI * 0.5, 0, 0)), p["holz"])
	_box(b, t, Vector3(width * 0.2, 1.05, depth * 0.5 + 0.02), Vector3(1.1, 2.1, 0.1), DOOR)
	_box(b, t, Vector3(-width * 0.25, height * 0.62, depth * 0.5 + 0.02), Vector3(0.6, 0.5, 0.1), DOOR)
	return [[t, Vector3(width, height + 0.7, depth)]]


## Kuppeltempel: quadratischer Sockel, Trommel, Kuppel, Spitze; vier Eckpfeiler.
static func dome_temple(b: MeshBuilder, t: Transform3D, size: float, p: Dictionary) -> Array[Array]:
	var base_h: float = 4.0
	_box(b, t, Vector3(0, 0.3, 0), Vector3(size + 2.0, 0.6, size + 2.0), p["stein"])
	_box(b, t, Vector3(0, 0.6 + base_h * 0.5, 0), Vector3(size, base_h, size), p["wand"])
	b.add(MeshBuilder.cylinder(size * 0.38, size * 0.4, 1.4, 16), t * MeshBuilder.at(Vector3(0, 0.6 + base_h + 0.7, 0)), p["wand"].darkened(0.05))
	b.add(MeshBuilder.sphere(size * 0.38, 16, 8), t * MeshBuilder.at(Vector3(0, 0.6 + base_h + 1.4, 0), Vector3(1.0, 0.9, 1.0)), p["dach"])
	b.add(MeshBuilder.cylinder(0.0, 0.25, 1.8, 6), t * MeshBuilder.at(Vector3(0, 0.6 + base_h + 1.4 + size * 0.34 + 0.9, 0)), p["saeule"])
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.add(MeshBuilder.cylinder(0.5, 0.6, base_h + 2.4, 8), t * MeshBuilder.at(Vector3(sx * size * 0.5, 0.6 + (base_h + 2.4) * 0.5, sz * size * 0.5)), p["wand"].lightened(0.05))
			b.add(MeshBuilder.sphere(0.55, 8, 4), t * MeshBuilder.at(Vector3(sx * size * 0.5, 0.6 + base_h + 2.5, sz * size * 0.5)), p["dach"])
	_box(b, t, Vector3(0, 0.6 + 1.6, size * 0.5 + 0.03), Vector3(2.0, 3.2, 0.1), DOOR)
	return [[t, Vector3(size + 1.0, base_h + 3.0, size + 1.0)]]


## Pagode: Stockwerke werden nach oben schmaler, jedes mit geschwungenem Vierseit-Dach, oben eine Spitze.
static func pagoda(b: MeshBuilder, t: Transform3D, tiers: int, width: float, p: Dictionary) -> Array[Array]:
	var y: float = 0.0
	_box(b, t, Vector3(0, 0.4, 0), Vector3(width + 2.5, 0.8, width + 2.5), p["stein"])
	y = 0.8
	for tier: int in tiers:
		var w: float = width * (1.0 - tier * 0.13)
		var h: float = 3.0 if tier == 0 else 2.4
		_box(b, t, Vector3(0, y + h * 0.5, 0), Vector3(w, h, w), p["wand"])
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_box(b, t, Vector3(sx * w * 0.5, y + h * 0.5, sz * w * 0.5), Vector3(0.3, h, 0.3), p["saeule"])
		if tier == 0:
			_box(b, t, Vector3(0, y + 1.2, w * 0.5 + 0.02), Vector3(1.4, 2.4, 0.1), DOOR)
		y += h
		hip_roof(b, t, Vector3(0, y, 0), w + 2.2, 1.3, p["dach"])
		y += 0.6
	b.add(MeshBuilder.cylinder(0.05, 0.22, 2.6, 6), t * MeshBuilder.at(Vector3(0, y + 1.3, 0)), p["saeule"])
	for i: int in 3:
		b.add(MeshBuilder.sphere(0.28 - i * 0.05, 8, 4), t * MeshBuilder.at(Vector3(0, y + 0.6 + i * 0.6, 0)), p["banner"])
	return [[t, Vector3(width + 2.0, y + 2.6, width + 2.0)]]


## Vierseitiges Walmdach (Pyramide) mit hochgezogenen Ecken.
static func hip_roof(b: MeshBuilder, t: Transform3D, base: Vector3, width: float, height: float, color: Color) -> void:
	b.add(MeshBuilder.cylinder(width * 0.08, width * 0.707, height, 4), t * Transform3D(Basis(Vector3.UP, PI * 0.25), base + Vector3(0, height * 0.5, 0)), color)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.add(MeshBuilder.box(Vector3(0.9, 0.16, 0.3)), t * MeshBuilder.at(base + Vector3(sx * width * 0.48, 0.12, sz * width * 0.48), Vector3.ONE, Vector3(0, atan2(sx, sz) + PI * 0.5, 0.5)), color.darkened(0.2))


## Arena: Ring aus Steinmauern mit zwei Sitzstufen, zwei Eingängen (vorn, hinten) und Bannern.
static func arena(b: MeshBuilder, t: Transform3D, radius: float, p: Dictionary) -> Array[Array]:
	var boxes: Array[Array] = []
	var segments: int = 24
	for i: int in segments:
		var angle: float = (i + 0.5) * TAU / segments
		if absf(angle_difference(angle, PI * 0.5)) < 0.2 or absf(angle_difference(angle, PI * 1.5)) < 0.2:
			continue
		var rot := Basis(Vector3.UP, -angle + PI * 0.5)
		var length: float = 2.0 * radius * sin(PI / segments) + 0.3
		for tier: int in 2:
			var r: float = radius + tier * 1.4
			var h: float = 1.0 + tier * 1.0
			var at := Vector3(cos(angle) * r, h * 0.5, sin(angle) * r)
			b.add(MeshBuilder.box(Vector3(length + tier * 0.4, h, 1.4)), t * Transform3D(rot, at), p["stein"].lightened(tier * 0.05))
		var wall_at := Vector3(cos(angle) * (radius + 2.8), 1.8, sin(angle) * (radius + 2.8))
		b.add(MeshBuilder.box(Vector3(length + 0.8, 3.6, 0.8)), t * Transform3D(rot, wall_at), p["wand"])
		boxes.append([t * Transform3D(rot, Vector3(cos(angle) * (radius + 1.4), 0, sin(angle) * (radius + 1.4))), Vector3(length + 0.8, 3.6, 3.6)])
		if i % 4 == 0:
			b.add(MeshBuilder.cylinder(0.08, 0.08, 5.0, 5), t * MeshBuilder.at(wall_at + Vector3(0, 2.5, 0)), p["holz"])
			b.add(MeshBuilder.box(Vector3(0.9, 1.6, 0.05)), t * Transform3D(rot, wall_at + Vector3(0, 4.0, 0) + rot * Vector3(0.5, 0, 0)), p["banner"])
	b.add(MeshBuilder.cylinder(radius, radius, 0.06, 24), t * MeshBuilder.at(Vector3(0, 0.03, 0)), p["platz"] if p.has("platz") else p["stein"].lightened(0.2))
	return boxes


## Stadtturm: quadratisch, zwei Geschosse, Zinnen und Walmdach.
static func city_tower(b: MeshBuilder, t: Transform3D, width: float, height: float, p: Dictionary) -> Array[Array]:
	_box(b, t, Vector3(0, height * 0.5, 0), Vector3(width, height, width), p["stein"])
	_box(b, t, Vector3(0, height + 1.2, 0), Vector3(width - 1.0, 2.4, width - 1.0), p["wand"])
	for i: int in 4:
		var rot := Basis(Vector3.UP, i * PI * 0.5)
		for k: int in 3:
			b.add(MeshBuilder.box(Vector3(0.7, 0.7, 0.5)), t * Transform3D(rot, rot * Vector3(-width * 0.33 + k * width * 0.33, height + 0.35, width * 0.5 - 0.25)), p["stein"].darkened(0.1))
	hip_roof(b, t, Vector3(0, height + 2.4, 0), width + 1.2, 2.2, p["dach"])
	return [[t, Vector3(width, height + 2.4, width)]]


## Torbogen (Paifang): zwei rote Säulen, zwei Querbalken, Tafel und kleines Dach.
static func paifang(b: MeshBuilder, t: Transform3D, width: float, p: Dictionary) -> Array[Array]:
	var height: float = 6.0
	var boxes: Array[Array] = []
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.cylinder(0.35, 0.4, height, 8), t * MeshBuilder.at(Vector3(side * width * 0.5, height * 0.5, 0)), p["saeule"])
		_box(b, t, Vector3(side * width * 0.5, 0.4, 0), Vector3(1.2, 0.8, 1.2), p["stein"])
		boxes.append([t.translated_local(Vector3(side * width * 0.5, 0, 0)), Vector3(1.0, height, 1.0)])
	_box(b, t, Vector3(0, height - 1.4, 0), Vector3(width + 1.2, 0.4, 0.5), p["saeule"])
	_box(b, t, Vector3(0, height - 0.2, 0), Vector3(width + 2.2, 0.5, 0.7), p["holz"])
	_box(b, t, Vector3(0, height - 0.8, 0.3), Vector3(width * 0.35, 0.9, 0.1), p["banner"])
	Architecture.roof(b, t, Vector3(0, height + 0.05, 0), width + 3.0, 1.8, 1.0, p["dach"], p["holz"])
	return boxes


## Steinterrasse mit Rampe vorn (Kollision als Schräge, sichtbar als Treppe).
static func terrace(b: MeshBuilder, t: Transform3D, width: float, depth: float, height: float, p: Dictionary) -> Array[Array]:
	_box(b, t, Vector3(0, height * 0.5, 0), Vector3(width, height, depth), p["stein"])
	_box(b, t, Vector3(0, height + 0.05, 0), Vector3(width + 0.3, 0.1, depth + 0.3), p["stein"].lightened(0.12))
	var run: float = height * 2.2
	var steps: int = maxi(3, roundi(height / 0.3))
	for i: int in steps:
		var h: float = height * (i + 1) / steps
		_box(b, t, Vector3(0, h * 0.5, depth * 0.5 + run * (1.0 - (i + 0.5) / steps)), Vector3(4.0, h, run / steps + 0.02), p["stein"].lightened(0.06))
	for side: float in [-1.0, 1.0]:
		_box(b, t, Vector3(side * 2.2, height * 0.5 + 0.2, depth * 0.5 + run * 0.5), Vector3(0.4, height + 0.4, run), p["stein"].darkened(0.1))
	var slope: float = atan2(height, run)
	var ramp_len: float = Vector2(run, height).length()
	var ramp := t * Transform3D(Basis(Vector3.RIGHT, slope), Vector3(0, height * 0.5 - 0.5 * cos(slope) * 0.2, depth * 0.5 + run * 0.5))
	return [[t, Vector3(width, height, depth)], [ramp.translated_local(Vector3(0, -0.1, 0)), Vector3(4.0, 0.2, ramp_len)]]


## Palisade aus angespitzten Pfählen zwischen zwei Bodenpunkten.
static func palisade(b: MeshBuilder, a: Vector3, c: Vector3, p: Dictionary) -> Array[Array]:
	var length: float = Vector2(c.x - a.x, c.z - a.z).length()
	var count: int = maxi(2, roundi(length / 0.45))
	for i: int in count:
		var point: Vector3 = a.lerp(c, (i + 0.5) / count)
		var height: float = 2.4 + (i % 3) * 0.2
		b.add(MeshBuilder.cylinder(0.18, 0.2, height, 5), MeshBuilder.at(point + Vector3(0, height * 0.5 - 0.2, 0)), p["holz"].darkened((i % 2) * 0.1))
		b.add(MeshBuilder.cylinder(0.0, 0.18, 0.5, 5), MeshBuilder.at(point + Vector3(0, height + 0.05, 0)), p["holz"].lightened(0.1))
	var basis := Basis(Vector3.UP, atan2(c.x - a.x, c.z - a.z) + PI * 0.5)
	return [[Transform3D(basis, Vector3((a.x + c.x) * 0.5, minf(a.y, c.y) - 0.2, (a.z + c.z) * 0.5)), Vector3(length, 2.8, 0.5)]]


## Steg auf Pfählen, vom Ursprung aus nach vorn (+Z) ins Wasser.
static func dock(b: MeshBuilder, t: Transform3D, length: float, deck_height: float, p: Dictionary) -> Array[Array]:
	_box(b, t, Vector3(0, deck_height, length * 0.5), Vector3(2.2, 0.16, length), p["holz"].lightened(0.1))
	var posts: int = maxi(2, roundi(length / 2.5))
	for i: int in posts + 1:
		for side: float in [-1.0, 1.0]:
			b.add(MeshBuilder.cylinder(0.12, 0.12, deck_height + 2.5, 5), t * MeshBuilder.at(Vector3(side * 1.0, deck_height - 1.2, length * i / posts)), p["holz"].darkened(0.15))
	return [[t.translated_local(Vector3(0, deck_height - 0.4, length * 0.5)), Vector3(2.2, 0.5, length)]]


## Fischerboot mit Mast und Segel.
static func boat(b: MeshBuilder, t: Transform3D, p: Dictionary) -> void:
	_box(b, t, Vector3(0, 0.25, 0), Vector3(1.6, 0.5, 5.0), p["holz"])
	_box(b, t, Vector3(0, 0.3, 2.7), Vector3(1.0, 0.45, 0.8), p["holz"].darkened(0.1))
	_box(b, t, Vector3(0, 0.3, -2.6), Vector3(1.2, 0.45, 0.6), p["holz"].darkened(0.1))
	_box(b, t, Vector3(0, 0.45, 0), Vector3(1.3, 0.1, 4.4), WATER_DARK)
	b.add(MeshBuilder.cylinder(0.07, 0.09, 4.0, 5), t * MeshBuilder.at(Vector3(0, 2.4, 0.4)), p["holz"])
	_box(b, t, Vector3(0, 2.6, 0.2), Vector3(0.05, 2.6, 1.8), SAIL.lerp(p["banner"], 0.25))


## Totem- oder Bannerpfahl der Steppe mit Tierschädel.
static func totem(b: MeshBuilder, t: Transform3D, p: Dictionary) -> void:
	b.add(MeshBuilder.cylinder(0.14, 0.18, 4.5, 6), t * MeshBuilder.at(Vector3(0, 2.25, 0)), p["holz"])
	b.add(MeshBuilder.sphere(0.35, 7, 4), t * MeshBuilder.at(Vector3(0, 4.3, 0), Vector3(1.0, 0.8, 1.3)), Color(0.9, 0.87, 0.8))
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.cylinder(0.0, 0.08, 0.7, 4), t * MeshBuilder.at(Vector3(side * 0.35, 4.55, 0), Vector3.ONE, Vector3(0, 0, -side * 0.9)), Color(0.9, 0.87, 0.8))
	for i: int in 3:
		_box(b, t, Vector3(0.22, 3.2 - i * 0.5, 0), Vector3(0.05, 0.4, 0.3), p["banner"].darkened(i * 0.1))


static func _box(b: MeshBuilder, t: Transform3D, center: Vector3, box_size: Vector3, color: Color) -> void:
	b.add(MeshBuilder.box(box_size), t * MeshBuilder.at(center), color)
