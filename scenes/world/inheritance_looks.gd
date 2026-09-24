class_name InheritanceLooks
extends RefCounted
## Bauformen der Erben (gebiete.json → orte[].stil): Felsspalte („hoehle“), Grabhügel mit Steintür und Opferbecken
## („grab“), verfallener Tempel auf einer Terrasse („tempel“), Steinkreis mit Altar und Bestienstatuen („altar“) und
## Meeresgrotte mit Felsbogen („grotte“). Der Siegelstein steht bei allen vorn bei (0, 0, 1,6), damit Opfergabe,
## Wächter und Belohnung überall gleich funktionieren. Akzentfarbe (`akzent`) für Leuchtrunen, Laternen und Becken.

const STYLES: Array[StringName] = [&"hoehle", &"grab", &"tempel", &"altar", &"grotte"]
const CAVE: Color = Color(0.05, 0.04, 0.04)
const EARTH: Color = Color(0.36, 0.3, 0.22)
const GRASS: Color = Color(0.3, 0.42, 0.22)
const SHELL: Color = Color(0.93, 0.86, 0.8)
const VIEW: float = 140.0


## Baut Modell und Kollision als Kinder von parent.
static func build(parent: Node3D, style: StringName, rock: Color, accent: Color, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var b := MeshBuilder.new()
	var glow := MeshBuilder.new()
	var boxes: Array[Array] = []
	match style:
		&"grab":
			_tomb(b, glow, boxes, rock, rng)
		&"tempel":
			_temple(b, glow, boxes, rock, rng)
		&"altar":
			_circle(b, glow, boxes, rock, rng)
		&"grotte":
			_grotto(b, glow, boxes, rock, rng)
		_:
			_cave(b, boxes, rock, rng)
	_add(parent, b, WorldMaterials.vertex_colored())
	if style != &"hoehle":
		_add(parent, glow, WorldMaterials.glowing(accent))
	var body := StaticBody3D.new()
	for entry: Array in boxes:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = entry[1]
		shape.shape = box
		shape.transform = entry[0]
		body.add_child(shape)
	parent.add_child(body)


## Felshügel mit dunkler Spalte (Blumenwein-Mönch, Krokodilkönig, Lavadrache).
static func _cave(b: MeshBuilder, boxes: Array[Array], rock: Color, rng: RandomNumberGenerator) -> void:
	var rock_dark: Color = rock.darkened(0.28)
	for i: int in 9:
		var angle: float = PI + (i - 4) * 0.33
		var offset := Vector3(cos(angle) * 3.2, 0.0, sin(angle) * 2.4 - 1.2)
		b.add(MeshBuilder.sphere(rng.randf_range(1.6, 2.4), 7, 4), MeshBuilder.at(offset + Vector3(0, 1.2, 0), Vector3(1.0, rng.randf_range(1.2, 1.8), 1.0)), rock if i % 2 == 0 else rock_dark)
	b.add(MeshBuilder.sphere(3.0, 8, 4), MeshBuilder.at(Vector3(0, 2.6, -2.6), Vector3(1.4, 1.2, 1.0)), rock)
	b.add(MeshBuilder.box(Vector3(1.6, 2.6, 0.4)), MeshBuilder.at(Vector3(0, 1.3, 0.4)), CAVE)
	boxes.append([MeshBuilder.at(Vector3(0, 2.0, -1.8)), Vector3(7.0, 4.0, 4.0)])


## Grabhügel mit Steintür, Stelenreihen am Weg, Laternen und Opferbecken.
static func _tomb(b: MeshBuilder, glow: MeshBuilder, boxes: Array[Array], rock: Color, rng: RandomNumberGenerator) -> void:
	b.add(MeshBuilder.sphere(5.6, 12, 6), MeshBuilder.at(Vector3(0, -0.2, -4.5), Vector3(1.0, 0.5, 0.85)), EARTH)
	b.add(MeshBuilder.sphere(5.2, 12, 5), MeshBuilder.at(Vector3(0, 0.1, -4.7), Vector3(1.0, 0.64, 0.82)), GRASS)
	# Eingang: zwei Pfeiler, Sturz, dunkle Steintür.
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.box(Vector3(0.6, 3.0, 0.7)), MeshBuilder.at(Vector3(side * 1.3, 1.5, -0.3)), rock)
	b.add(MeshBuilder.box(Vector3(3.6, 0.6, 0.9)), MeshBuilder.at(Vector3(0, 3.2, -0.3)), rock.darkened(0.1))
	b.add(MeshBuilder.box(Vector3(2.0, 2.7, 0.3)), MeshBuilder.at(Vector3(0, 1.35, -0.45)), CAVE.lightened(0.12))
	glow.add(MeshBuilder.box(Vector3(0.9, 0.12, 0.05)), MeshBuilder.at(Vector3(0, 2.2, -0.28)), Color.WHITE)
	for row: int in 3:
		for side: float in [-1.0, 1.0]:
			var at := Vector3(side * (2.8 + rng.randf_range(-0.2, 0.2)), 0, 3.5 + row * 2.2)
			b.add(MeshBuilder.box(Vector3(0.5, rng.randf_range(1.0, 1.5), 0.2)), MeshBuilder.at(at + Vector3.UP * 0.6, Vector3.ONE, Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.1, 0.1))), rock.lightened(0.08))
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * 2.2, 0, 1.4)
		b.add(MeshBuilder.cylinder(0.12, 0.16, 1.1, 6), MeshBuilder.at(at + Vector3.UP * 0.55), rock)
		glow.add(MeshBuilder.box(Vector3(0.3, 0.3, 0.3)), MeshBuilder.at(at + Vector3.UP * 1.25), Color.WHITE)
		b.add(MeshBuilder.cylinder(0.0, 0.42, 0.3, 4), MeshBuilder.at(at + Vector3.UP * 1.55, Vector3.ONE, Vector3(0, PI * 0.25, 0)), rock.darkened(0.15))
	# Opferbecken seitlich vor dem Siegel.
	b.add(MeshBuilder.box(Vector3(1.6, 0.5, 1.0)), MeshBuilder.at(Vector3(-2.8, 0.25, 0.6)), rock.darkened(0.1))
	glow.add(MeshBuilder.box(Vector3(1.3, 0.05, 0.7)), MeshBuilder.at(Vector3(-2.8, 0.48, 0.6)), Color.WHITE)
	boxes.append([MeshBuilder.at(Vector3(0, 1.6, -4.3)), Vector3(9.0, 3.2, 7.0)])


## Terrasse mit Säulenreihen (teils eingestürzt), Rückwand mit Tor und Dachrest, Wächterstatuen an der Treppe.
static func _temple(b: MeshBuilder, glow: MeshBuilder, boxes: Array[Array], rock: Color, rng: RandomNumberGenerator) -> void:
	var stone: Color = rock.lightened(0.12)
	b.add(MeshBuilder.box(Vector3(12.0, 0.7, 9.0)), MeshBuilder.at(Vector3(0, 0.35, -5.0)), stone.darkened(0.1))
	for step: int in 2:
		b.add(MeshBuilder.box(Vector3(4.0, 0.25, 0.6)), MeshBuilder.at(Vector3(0, 0.12 + step * 0.23, -0.2 - step * 0.5)), stone)
	for row: int in 3:
		for side: float in [-1.0, 1.0]:
			var at := Vector3(side * 4.2, 0.7, -1.8 - row * 3.0)
			var broken: bool = rng.randf() < 0.35
			var height: float = rng.randf_range(1.2, 2.6) if broken else 5.0
			b.add(MeshBuilder.cylinder(0.42, 0.48, height, 8), MeshBuilder.at(at + Vector3.UP * height * 0.5), stone)
			b.add(MeshBuilder.box(Vector3(1.2, 0.3, 1.2)), MeshBuilder.at(at + Vector3.UP * 0.15), stone.darkened(0.12))
			if broken:
				b.add(MeshBuilder.cylinder(0.42, 0.42, 2.2, 8), MeshBuilder.at(at + Vector3(side * 1.6, 0.4, 0.4), Vector3.ONE, Vector3(0, rng.randf() * TAU, PI * 0.5)), stone.darkened(0.05))
			else:
				b.add(MeshBuilder.box(Vector3(1.1, 0.35, 1.1)), MeshBuilder.at(at + Vector3.UP * 5.15), stone.darkened(0.08))
	# Rückwand mit Tor und leuchtenden Schriftzeichen, darüber ein Rest des Walmdachs.
	b.add(MeshBuilder.box(Vector3(10.0, 4.6, 0.8)), MeshBuilder.at(Vector3(0, 3.0, -9.2)), stone.darkened(0.06))
	b.add(MeshBuilder.box(Vector3(2.2, 3.2, 0.2)), MeshBuilder.at(Vector3(0, 2.3, -8.75)), CAVE)
	for i: int in 3:
		glow.add(MeshBuilder.box(Vector3(0.18, 0.5, 0.05)), MeshBuilder.at(Vector3(-0.5 + i * 0.5, 4.3, -8.78)), Color.WHITE)
	ArchitectureExtra.hip_roof(b, Transform3D.IDENTITY, Vector3(0, 5.3, -9.2), 11.0, 1.8, Color(0.3, 0.28, 0.26))
	for side: float in [-1.0, 1.0]:
		_guardian(b, Vector3(side * 2.8, 0, 0.6), stone)
	boxes.append([MeshBuilder.at(Vector3(0, 0.35, -5.0)), Vector3(12.0, 0.7, 9.0)])
	boxes.append([MeshBuilder.at(Vector3(0, 3.0, -9.2)), Vector3(10.0, 4.6, 0.8)])


## Steinkreis auf runder Plattform, Menhire mit Leuchtrunen, Altarblock, Bestienstatuen am Zugang.
static func _circle(b: MeshBuilder, glow: MeshBuilder, boxes: Array[Array], rock: Color, rng: RandomNumberGenerator) -> void:
	var stone: Color = rock.lightened(0.05)
	b.add(MeshBuilder.cylinder(6.0, 6.3, 0.35, 16), MeshBuilder.at(Vector3(0, 0.17, -3.5)), stone.darkened(0.12))
	var count: int = 10
	for i: int in count:
		var angle: float = i * TAU / count + PI * 0.5
		if absf(angle_difference(angle, PI * 0.5)) < 0.3:
			continue
		var at := Vector3(cos(angle) * 5.4, 0.3, -3.5 + sin(angle) * 5.4)
		var height: float = rng.randf_range(2.6, 3.6)
		var t := Transform3D(Basis(Vector3.UP, -angle) * Basis(Vector3.RIGHT, rng.randf_range(-0.06, 0.06)), at)
		b.add(MeshBuilder.box(Vector3(0.9, height, 0.6)), t * MeshBuilder.at(Vector3(0, height * 0.5, 0)), stone.darkened(rng.randf_range(0.0, 0.15)))
		glow.add(MeshBuilder.box(Vector3(0.2, 0.7, 0.62)), t * MeshBuilder.at(Vector3(0, height * 0.6, 0)), Color.WHITE)
	b.add(MeshBuilder.box(Vector3(2.4, 1.0, 1.4)), MeshBuilder.at(Vector3(0, 0.85, -3.5)), stone.darkened(0.2))
	b.add(MeshBuilder.box(Vector3(2.8, 0.2, 1.8)), MeshBuilder.at(Vector3(0, 1.45, -3.5)), stone)
	glow.add(MeshBuilder.sphere(0.35, 7, 4), MeshBuilder.at(Vector3(0, 1.85, -3.5)), Color.WHITE)
	for side: float in [-1.0, 1.0]:
		_guardian(b, Vector3(side * 2.2, 0, 2.6), stone)
	boxes.append([MeshBuilder.at(Vector3(0, 0.9, -3.5)), Vector3(2.8, 1.8, 1.8)])


## Meeresgrotte: zwei hohe Felspfeiler mit Bogen, dunkler Schlund, Muscheln am Boden.
static func _grotto(b: MeshBuilder, glow: MeshBuilder, boxes: Array[Array], rock: Color, rng: RandomNumberGenerator) -> void:
	var rock_dark: Color = rock.darkened(0.25)
	for side: float in [-1.0, 1.0]:
		for k: int in 3:
			b.add(MeshBuilder.sphere(rng.randf_range(1.6, 2.1), 7, 4), MeshBuilder.at(Vector3(side * 3.2, 1.4 + k * 2.2, -1.5 - k * 0.4), Vector3(1.0, 1.3, 1.1)), rock if k % 2 == 0 else rock_dark)
	b.add(MeshBuilder.sphere(3.6, 9, 4), MeshBuilder.at(Vector3(0, 7.2, -2.3), Vector3(1.4, 0.55, 1.0)), rock)
	b.add(MeshBuilder.sphere(4.5, 9, 4), MeshBuilder.at(Vector3(0, 3.0, -6.0), Vector3(1.5, 1.2, 1.0)), rock_dark)
	b.add(MeshBuilder.box(Vector3(3.6, 5.0, 0.4)), MeshBuilder.at(Vector3(0, 2.5, -2.4)), CAVE)
	for i: int in 10:
		var at := Vector3(rng.randf_range(-4.0, 4.0), 0.05, rng.randf_range(-1.0, 3.5))
		b.add(MeshBuilder.sphere(rng.randf_range(0.15, 0.3), 6, 2), MeshBuilder.at(at, Vector3(1.0, 0.35, 1.3), Vector3(0, rng.randf() * TAU, 0)), SHELL.darkened(rng.randf_range(0.0, 0.2)))
	for i: int in 5:
		glow.add(MeshBuilder.sphere(0.12, 5, 3), MeshBuilder.at(Vector3(rng.randf_range(-1.4, 1.4), rng.randf_range(0.8, 4.0), -2.1)), Color.WHITE)
	for side: float in [-1.0, 1.0]:
		boxes.append([MeshBuilder.at(Vector3(side * 3.2, 3.5, -1.8)), Vector3(3.2, 7.0, 3.0)])
	boxes.append([MeshBuilder.at(Vector3(0, 3.0, -5.0)), Vector3(9.0, 6.0, 4.0)])


## Sitzende Wächterstatue (Löwe/Wolf) auf Sockel.
static func _guardian(b: MeshBuilder, at: Vector3, stone: Color) -> void:
	b.add(MeshBuilder.box(Vector3(1.1, 0.6, 1.4)), MeshBuilder.at(at + Vector3.UP * 0.3), stone.darkened(0.15))
	b.add(MeshBuilder.box(Vector3(0.8, 1.0, 1.0)), MeshBuilder.at(at + Vector3(0, 1.1, -0.1)), stone)
	b.add(MeshBuilder.sphere(0.45, 7, 4), MeshBuilder.at(at + Vector3(0, 1.85, 0.2)), stone)
	b.add(MeshBuilder.box(Vector3(0.35, 0.25, 0.35)), MeshBuilder.at(at + Vector3(0, 1.75, 0.6)), stone.darkened(0.08))
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.cylinder(0.0, 0.12, 0.3, 4), MeshBuilder.at(at + Vector3(side * 0.25, 2.3, 0.15)), stone)


static func _add(parent: Node3D, b: MeshBuilder, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = material
	node.visibility_range_end = VIEW
	parent.add_child(node)
