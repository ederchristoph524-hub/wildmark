class_name HouseStyles
extends RefCounted
## Wohnhaus-Varianten der Klan-Dörfer: Putzhaus mit Fachwerk, Bretterhaus, zweistöckiges Haus mit umlaufendem
## Vordach und Bambus-Pfahlhaus (typisch für die feuchten Täler der Südlichen Grenze). Jede Fassade bekommt einen
## leicht anderen Farbton, dazu Kleinkram vor dem Haus (Fässer, Brennholz, Krüge, Wäschestange).

enum Style { PLASTER, PLANKS, TWO_STORY, STILTS }

## Anteile der Stile (in Reihenfolge von Style).
const WEIGHTS: PackedFloat32Array = [0.38, 0.22, 0.2, 0.2]
const BAMBOO_WALL: Color = Color(0.66, 0.6, 0.42)
const BAMBOO_POLE: Color = Color(0.46, 0.5, 0.28)
const STILT_HEIGHT: float = 1.8
const UPPER_HEIGHT: float = 2.6
const POT: Color = Color(0.55, 0.33, 0.2)
const CLOTH: Array[Color] = [Color(0.78, 0.74, 0.66), Color(0.35, 0.45, 0.6), Color(0.62, 0.3, 0.26)]


## Baut ein Wohnhaus im zufälligen Stil; liefert Kollisionsquader wie Architecture.house.
static func build(b: MeshBuilder, t: Transform3D, width: float, depth: float, palette: Dictionary, rng: RandomNumberGenerator) -> Array[Array]:
	var p: Dictionary = palette.duplicate()
	var wall: Color = p["wand"]
	p["wand"] = wall.lerp(Color(wall.r * 1.04, wall.g * 0.97, wall.b * 0.9), rng.randf()).darkened(rng.randf_range(0.0, 0.12))
	p["dach"] = (p["dach"] as Color).darkened(rng.randf_range(-0.06, 0.12))
	var boxes: Array[Array] = []
	var style: int = rng.rand_weighted(WEIGHTS)
	# Firsthöhe für den Schornstein (Pfahlhäuser haben keinen).
	var ridge: float = Architecture.PLINTH + Architecture.WALL_HEIGHT + 2.4
	match style:
		Style.PLANKS:
			boxes = _planks(b, t, width, depth, p)
		Style.TWO_STORY:
			boxes = _two_story(b, t, width, depth, p)
			ridge = Architecture.PLINTH + Architecture.WALL_HEIGHT + 0.45 + UPPER_HEIGHT + 2.2
		Style.STILTS:
			boxes = _stilts(b, t, width * 0.85, depth * 0.85, p)
			ridge = 0.0
		_:
			boxes = Architecture.house(b, t, width, depth, p)
	var props_side: float = _props(b, t, width, depth, p, rng)
	if ridge > 0.0:
		VillageYards.chimney(b, t, Vector3(width * 0.28, ridge, -0.5), rng)
		boxes.append_array(VillageYards.yard(b, t, width, depth, p, rng, props_side))
	return boxes


## Zweistöckiges Haus ohne Zufall (Sekten-Hallen).
static func two_story(b: MeshBuilder, t: Transform3D, width: float, depth: float, palette: Dictionary) -> Array[Array]:
	return _two_story(b, t, width, depth, palette)


## Bambus-Pfahlhaus ohne Zufall (Inseldörfer).
static func stilts(b: MeshBuilder, t: Transform3D, width: float, depth: float, palette: Dictionary) -> Array[Array]:
	return _stilts(b, t, width, depth, palette)


## Bretterhaus: Wände aus dunklem Holz mit waagrechten Fugen.
static func _planks(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary) -> Array[Array]:
	var q: Dictionary = p.duplicate()
	q["wand"] = (p["holz"] as Color).lightened(0.28)
	var boxes: Array[Array] = Architecture.house(b, t, width, depth, q)
	var seam: Color = (p["holz"] as Color).darkened(0.2)
	for i: int in 5:
		var y: float = Architecture.PLINTH + 0.5 + i * 0.6
		for side: float in [-1.0, 1.0]:
			_box(b, t, Vector3(0, y, side * (depth * 0.5 + 0.01)), Vector3(width - 0.3, 0.05, 0.04), seam)
			_box(b, t, Vector3(side * (width * 0.5 + 0.01), y, 0), Vector3(0.04, 0.05, depth - 0.3), seam)
	return boxes


## Zweistöckiges Haus: Erdgeschoss wie ein Putzhaus, darüber ein Vordachkranz und ein schmaleres Obergeschoss.
static func _two_story(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary) -> Array[Array]:
	var ground: float = Architecture.PLINTH + Architecture.WALL_HEIGHT
	_box(b, t, Vector3(0, Architecture.PLINTH * 0.5, 0), Vector3(width + 0.4, Architecture.PLINTH, depth + 0.4), p["stein"])
	_box(b, t, Vector3(0, Architecture.PLINTH + Architecture.WALL_HEIGHT * 0.5, 0), Vector3(width, Architecture.WALL_HEIGHT, depth), p["wand"])
	_box(b, t, Vector3(0, Architecture.PLINTH + 1.1, depth * 0.5 + 0.03), Vector3(1.3, 2.2, 0.08), Architecture.DOOR)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(b, t, Vector3(sx * width * 0.5, ground * 0.5, sz * depth * 0.5), Vector3(0.28, ground, 0.28), p["holz"])
	# Vordachkranz: vier geneigte Bretter rund um das Haus.
	for side: int in 4:
		var along: float = width if side % 2 == 0 else depth
		var across: float = depth if side % 2 == 0 else width
		var rot := Basis(Vector3.UP, side * PI * 0.5)
		b.add(MeshBuilder.box(Vector3(along + 1.6, 0.12, 1.3)), t * Transform3D(rot * Basis(Vector3.RIGHT, 0.38), rot * Vector3(0, ground + 0.15, across * 0.5 + 0.35)), p["dach"])
	var upper_w: float = width - 1.4
	var upper_d: float = depth - 1.4
	_box(b, t, Vector3(0, ground + 0.45 + UPPER_HEIGHT * 0.5, 0), Vector3(upper_w, UPPER_HEIGHT, upper_d), p["wand"].lightened(0.04))
	for sx: float in [-1.0, 1.0]:
		_box(b, t, Vector3(sx * upper_w * 0.25, ground + 1.8, upper_d * 0.5 + 0.03), Vector3(1.2, 0.9, 0.08), Architecture.WINDOW, Architecture.window_glow(t, sx))
		_box(b, t, Vector3(sx * upper_w * 0.25, ground + 1.8, upper_d * 0.5 + 0.06), Vector3(1.0, 0.7, 0.04), Architecture.PAPER)
		for sz: float in [-1.0, 1.0]:
			_box(b, t, Vector3(sx * upper_w * 0.5, ground + 0.45 + UPPER_HEIGHT * 0.5, sz * upper_d * 0.5), Vector3(0.22, UPPER_HEIGHT, 0.22), p["holz"])
	Architecture.roof(b, t, Vector3(0, ground + 0.45 + UPPER_HEIGHT, 0), upper_w + 1.8, upper_d + 1.8, 2.2, p["dach"], p["holz"])
	return [[t, Vector3(width + 0.4, ground + UPPER_HEIGHT + 2.6, depth + 0.4)]]


## Bambus-Pfahlhaus: auf Stelzen, Bambuswände, Balkon mit Geländer, Treppe zur Tür, steiles Dach.
static func _stilts(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary) -> Array[Array]:
	var floor_y: float = STILT_HEIGHT
	for ix: int in 3:
		for iz: int in 3:
			var at := Vector3(lerpf(-width * 0.5, width * 0.5, ix * 0.5), floor_y * 0.5, lerpf(-depth * 0.5, depth * 0.5 + 1.4, iz * 0.5))
			b.add(MeshBuilder.cylinder(0.12, 0.14, floor_y + 0.1, 5), t * MeshBuilder.at(at), BAMBOO_POLE)
	_box(b, t, Vector3(0, floor_y, 0.7), Vector3(width + 0.4, 0.2, depth + 1.8), p["holz"])
	var wall_h: float = 2.7
	_box(b, t, Vector3(0, floor_y + wall_h * 0.5, 0), Vector3(width, wall_h, depth), BAMBOO_WALL)
	for i: int in 7:
		var x: float = lerpf(-width * 0.5, width * 0.5, i / 6.0)
		_box(b, t, Vector3(x, floor_y + wall_h * 0.5, depth * 0.5 + 0.04), Vector3(0.1, wall_h, 0.06), BAMBOO_POLE)
	_box(b, t, Vector3(0, floor_y + 1.05, depth * 0.5 + 0.08), Vector3(1.1, 2.0, 0.06), Architecture.DOOR)
	_box(b, t, Vector3(width * 0.3, floor_y + 1.6, depth * 0.5 + 0.08), Vector3(0.9, 0.7, 0.05), Architecture.PAPER)
	# Balkongeländer vorn.
	_box(b, t, Vector3(0, floor_y + 0.9, depth * 0.5 + 1.55), Vector3(width + 0.3, 0.1, 0.1), BAMBOO_POLE)
	for i: int in 6:
		_box(b, t, Vector3(lerpf(-width * 0.5, width * 0.5, i / 5.0), floor_y + 0.45, depth * 0.5 + 1.55), Vector3(0.08, 0.9, 0.08), BAMBOO_POLE)
	# Treppe seitlich am Balkon.
	for step: int in 5:
		var y: float = floor_y * (step + 0.5) / 5.0
		_box(b, t, Vector3(width * 0.5 + 0.9, y * 0.5, depth * 0.5 + 1.0 + (4 - step) * 0.45), Vector3(1.0, y, 0.45), p["holz"].darkened(0.08))
	Architecture.roof(b, t, Vector3(0, floor_y + wall_h, 0.3), width + 1.8, depth + 2.4, 2.9, p["dach"], p["holz"])
	return [[t.translated_local(Vector3(0, 0, 0.6)), Vector3(width + 0.6, floor_y + wall_h + 2.8, depth + 2.0)]]


## Kleinkram an der Hauswand: Fässer, Brennholzstapel, Krüge oder eine Wäschestange. Liefert die Seite (±1).
static func _props(b: MeshBuilder, t: Transform3D, width: float, depth: float, p: Dictionary, rng: RandomNumberGenerator) -> float:
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	var x: float = side * (width * 0.5 + 0.9)
	match rng.randi() % 4:
		0:
			for i: int in 2:
				b.add(MeshBuilder.cylinder(0.32, 0.36, 0.85, 7), t * MeshBuilder.at(Vector3(x, 0.42, depth * 0.2 - i * 0.8)), (p["holz"] as Color).lightened(0.15))
		1:
			for row: int in 3:
				for i: int in 3 - row:
					b.add(MeshBuilder.cylinder(0.14, 0.14, 1.6, 5), t * MeshBuilder.at(Vector3(x, 0.15 + row * 0.26, -depth * 0.3 + (i + row * 0.5) * 0.3), Vector3.ONE, Vector3(PI * 0.5, 0, 0)), (p["holz"] as Color).lightened(0.1 + i * 0.05))
		2:
			for i: int in 3:
				b.add(MeshBuilder.sphere(0.26 + i * 0.05, 6, 4), t * MeshBuilder.at(Vector3(x, 0.28, depth * 0.3 - i * 0.7), Vector3(1.0, 1.25, 1.0)), POT.darkened(i * 0.1))
		_:
			for end: float in [-1.0, 1.0]:
				b.add(MeshBuilder.cylinder(0.05, 0.05, 1.9, 4), t * MeshBuilder.at(Vector3(x, 0.95, end * 1.4)), p["holz"])
			b.add(MeshBuilder.cylinder(0.03, 0.03, 2.8, 4), t * MeshBuilder.at(Vector3(x, 1.85, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0)), p["holz"])
			for i: int in 2:
				_box(b, t, Vector3(x, 1.45, -0.6 + i * 1.1), Vector3(0.04, 0.8, 0.8), CLOTH[rng.randi() % CLOTH.size()])
	return side


static func _box(b: MeshBuilder, t: Transform3D, center: Vector3, box_size: Vector3, color: Color, glow: Vector2 = Vector2.ZERO) -> void:
	b.add(MeshBuilder.box(box_size), t * MeshBuilder.at(center), color, glow)
