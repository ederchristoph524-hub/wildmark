class_name EnemyModel
extends Node3D
## Platzhalter-Modelle für Bestien aus einfachen Formen, je nach Feld shape in gegner.json, eingefärbt mit ihrer Farbe.

const EYE_COLOR: Color = Color(1.0, 0.85, 0.3)

var color: Color = Color.WHITE
var size: float = 1.0
var _parts: Node3D = null
## Alle Teile werden zu einem Mesh zusammengefügt (ein Draw Call), die Augen zu einem zweiten.
var _body: MeshBuilder = MeshBuilder.new()
var _eye_builder: MeshBuilder = MeshBuilder.new()
var _time: float = 0.0
var _flying: bool = false


func build(shape: StringName, body_color: Color, radius: float, flying: bool) -> void:
	color = body_color
	size = radius
	_flying = flying
	_parts = Node3D.new()
	add_child(_parts)
	match shape:
		&"slime":
			_part(_sphere(1.0), Vector3(0, 0.55, 0), Vector3(1.0, 0.75, 1.0), color)
			_eyes(Vector3(0, 0.75, -0.75), 0.35)
		&"quad":
			_quad()
		&"wolf":
			_wolf(false)
		&"cat":
			_wolf(true)
		&"boar":
			_boar()
		&"pilz":
			_part(_cylinder(0.35, 0.45, 0.9), Vector3(0, 0.45, 0), Vector3.ONE, Color(0.92, 0.88, 0.78))
			_part(_sphere(1.0), Vector3(0, 1.0, 0), Vector3(1.1, 0.55, 1.1), color)
			_eyes(Vector3(0, 0.6, -0.4), 0.2)
		&"spider":
			_spider()
		&"skel", &"imp":
			_humanoid()
		&"bat":
			_part(_sphere(0.5), Vector3(0, 0.6, 0), Vector3.ONE, color)
			_part(_box(), Vector3(-0.7, 0.65, 0), Vector3(1.0, 0.06, 0.55), color.darkened(0.2))
			_part(_box(), Vector3(0.7, 0.65, 0), Vector3(1.0, 0.06, 0.55), color.darkened(0.2))
			_eyes(Vector3(0, 0.7, -0.45), 0.18)
		&"ghost":
			_part(_cylinder(0.2, 0.7, 1.8), Vector3(0, 0.9, 0), Vector3.ONE, color)
			_eyes(Vector3(0, 1.5, -0.35), 0.2)
		&"snake":
			_snake()
		&"monkey":
			_humanoid()
			_part(_box(), Vector3(0, 0.75, 0.45), Vector3(0.08, 0.08, 0.8), color.darkened(0.2), Vector3(0.6, 0, 0))
		&"bear":
			_bear()
		&"croc":
			_croc()
		&"scorpion":
			_spider()
			for i: int in 3:
				_part(_sphere(0.2), Vector3(0, 0.75 + i * 0.25, 0.55 + i * 0.12), Vector3.ONE, color.darkened(0.1 * i))
			_part(_cylinder(0.0, 0.1, 0.35), Vector3(0, 1.45, 0.45), Vector3.ONE, Color(0.9, 0.8, 0.3), Vector3(-1.0, 0, 0))
		&"bird":
			_part(_sphere(0.45), Vector3(0, 0.6, 0), Vector3(0.9, 0.8, 1.3), color)
			_part(_cylinder(0.0, 0.1, 0.35), Vector3(0, 0.7, -0.7), Vector3.ONE, Color(0.9, 0.75, 0.3), Vector3(-PI * 0.5, 0, 0))
			for side: float in [-1.0, 1.0]:
				_part(_box(), Vector3(side * 0.85, 0.7, 0.05), Vector3(1.3, 0.05, 0.6), color.darkened(0.15), Vector3(0, 0, side * 0.25))
			_part(_box(), Vector3(0, 0.62, 0.7), Vector3(0.5, 0.05, 0.5), color.darkened(0.25))
			_eyes(Vector3(0, 0.78, -0.5), 0.22)
		_:
			_golem()
	_finish_mesh(_body, WorldMaterials.vertex_colored())
	_finish_mesh(_eye_builder, Fx.material(EYE_COLOR))
	_parts.scale = Vector3.ONE * size


func _finish_mesh(builder: MeshBuilder, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = builder.build()
	node.material_override = material
	_parts.add_child(node)


## Leichte Bewegung: Wippen beim Laufen, Schweben bei Fliegern, Zittern beim Ausholen.
func animate(delta: float, speed: float, winding_up: bool) -> void:
	_time += delta
	var hover: float = (1.2 + sin(_time * 3.0) * 0.15) if _flying else 0.0
	_parts.position.y = hover + absf(sin(_time * speed * 2.5)) * 0.05 * size
	_parts.position.x = sin(_time * 60.0) * 0.03 if winding_up else 0.0


func _quad() -> void:
	_part(_box(), Vector3(0, 0.55, 0.05), Vector3(0.7, 0.5, 1.2), color)
	_part(_box(), Vector3(0, 0.75, -0.7), Vector3(0.45, 0.4, 0.45), color.lightened(0.08))
	for x: float in [-0.25, 0.25]:
		for z: float in [-0.4, 0.45]:
			_part(_box(), Vector3(x, 0.2, z), Vector3(0.14, 0.4, 0.14), color.darkened(0.25))
	_eyes(Vector3(0, 0.82, -0.93), 0.2)


## Wolf (oder mit cat = true eine Großkatze): gestreckter Rumpf mit tiefer Brust, gebogener Hals, Kopf mit
## Schnauze und spitzen Ohren, schlanke Läufe, buschiger bzw. langer Schwanz; Rücken dunkler als der Bauch.
func _wolf(cat: bool) -> void:
	var back: Color = color.darkened(0.18)
	var belly: Color = color.lightened(0.12)
	_part(_sphere(0.42), Vector3(0, 0.78, -0.35), Vector3(0.95, 1.0, 1.1), color)
	_part(_sphere(0.36), Vector3(0, 0.74, 0.35), Vector3(0.9, 0.9, 1.2), back)
	_part(_box(), Vector3(0, 0.62, 0.0), Vector3(0.5, 0.3, 0.9), belly)
	_part(_cylinder(0.16, 0.22, 0.5), Vector3(0, 1.0, -0.7), Vector3.ONE, color, Vector3(-0.8, 0, 0))
	var head := Vector3(0, 1.12 if not cat else 1.05, -0.95)
	_part(_sphere(0.24), head, Vector3(1.0, 0.9, 1.05), color.lightened(0.05))
	var snout_length: float = 0.18 if cat else 0.34
	_part(_cylinder(0.07, 0.14, snout_length), head + Vector3(0, -0.06, -0.14 - snout_length * 0.5), Vector3.ONE, belly, Vector3(-PI * 0.5, 0, 0))
	_part(_sphere(0.05), head + Vector3(0, -0.04, -0.16 - snout_length), Vector3.ONE, Color(0.1, 0.08, 0.08))
	for side: float in [-1.0, 1.0]:
		var ear: Vector3 = head + Vector3(side * 0.13, 0.2, 0.02)
		_part(_cylinder(0.0, 0.08 if not cat else 0.07, 0.22 if not cat else 0.14), ear, Vector3.ONE, back, Vector3(0, 0, side * -0.25))
		for z: float in [-0.45, 0.42]:
			_part(_cylinder(0.06, 0.08, 0.62), Vector3(side * 0.2, 0.31, z), Vector3.ONE, back.darkened(0.1), Vector3(0.1 if z < 0.0 else -0.12, 0, 0))
			_part(_sphere(0.08), Vector3(side * 0.2, 0.04, z - 0.04), Vector3(1.0, 0.6, 1.3), back.darkened(0.2))
	if cat:
		_part(_cylinder(0.04, 0.07, 0.9), Vector3(0, 0.62, 1.0), Vector3.ONE, back, Vector3(2.2, 0, 0))
		# Streifen an beiden Flanken und quer über den Rücken.
		for i: int in 4:
			var z: float = -0.45 + i * 0.28
			for side: float in [-1.0, 1.0]:
				_part(_box(), Vector3(side * 0.37, 0.78, z), Vector3(0.04, 0.34, 0.07), color.darkened(0.6), Vector3(0.25, 0, 0))
			_part(_box(), Vector3(0, 1.15 - (z + 0.45) * 0.14, z), Vector3(0.4, 0.04, 0.07), color.darkened(0.6))
	else:
		_part(_cylinder(0.06, 0.15, 0.55), Vector3(0, 0.66, 0.92), Vector3.ONE, back, Vector3(2.1, 0, 0))
	_eyes(head + Vector3(0, 0.07, -0.19), 0.2)


## Eber: gedrungener, hoher Rumpf mit Rückenborsten, großer Kopf mit Rüssel und Hauern, kurze Läufe.
func _boar() -> void:
	var back: Color = color.darkened(0.2)
	_part(_sphere(0.5), Vector3(0, 0.72, 0.1), Vector3(0.95, 0.9, 1.35), color)
	for i: int in 5:
		_part(_cylinder(0.0, 0.07, 0.22), Vector3(0, 1.18 - absf(i - 2) * 0.04, -0.35 + i * 0.2), Vector3.ONE, back, Vector3(0.3, 0, 0))
	var head := Vector3(0, 0.7, -0.75)
	_part(_box(), head, Vector3(0.5, 0.48, 0.5), color.lightened(0.05))
	_part(_cylinder(0.13, 0.15, 0.22), head + Vector3(0, -0.06, -0.34), Vector3.ONE, color.lightened(0.15), Vector3(-PI * 0.5, 0, 0))
	for side: float in [-1.0, 1.0]:
		_part(_cylinder(0.0, 0.04, 0.26), head + Vector3(side * 0.14, -0.1, -0.4), Vector3.ONE, Color(0.95, 0.92, 0.85), Vector3(-0.6, 0, side * 0.5))
		_part(_cylinder(0.0, 0.08, 0.16), head + Vector3(side * 0.18, 0.3, 0.05), Vector3.ONE, back, Vector3(0, 0, side * -0.4))
		for z: float in [-0.35, 0.45]:
			_part(_cylinder(0.08, 0.1, 0.42), Vector3(side * 0.26, 0.2, z), Vector3.ONE, back.darkened(0.1))
	_part(_cylinder(0.02, 0.04, 0.3), Vector3(0, 0.8, 0.78), Vector3.ONE, back, Vector3(0.9, 0, 0))
	_eyes(head + Vector3(0, 0.1, -0.26), 0.24)


## Schlange: Körper aus fünf Kugeln in einer Welle, erhobener Kopf.
func _snake() -> void:
	for i: int in 6:
		var z: float = -0.5 + i * 0.32
		_part(_sphere(0.22), Vector3(sin(i * 1.3) * 0.25, 0.2, z), Vector3(1.0, 0.8, 1.2), color if i % 2 == 0 else color.darkened(0.15))
	_part(_sphere(0.26), Vector3(0, 0.45, -0.8), Vector3(1.1, 0.8, 1.3), color.lightened(0.1))
	_eyes(Vector3(0, 0.55, -1.0), 0.18)


## Bär: massiger Körper, großer Kopf, dicke Beine.
func _bear() -> void:
	_part(_box(), Vector3(0, 0.75, 0.05), Vector3(0.95, 0.8, 1.35), color)
	_part(_sphere(0.36), Vector3(0, 1.0, -0.8), Vector3.ONE, color.lightened(0.06))
	_part(_sphere(0.14), Vector3(0, 0.93, -1.1), Vector3.ONE, color.darkened(0.3))
	for x: float in [-0.32, 0.32]:
		for z: float in [-0.45, 0.5]:
			_part(_box(), Vector3(x, 0.25, z), Vector3(0.26, 0.5, 0.26), color.darkened(0.25))
	_eyes(Vector3(0, 1.08, -1.08), 0.24)


## Krokodil: lang und flach, langer Kiefer, Schwanz.
func _croc() -> void:
	_part(_box(), Vector3(0, 0.3, 0.1), Vector3(0.75, 0.35, 1.7), color)
	_part(_box(), Vector3(0, 0.3, -1.05), Vector3(0.45, 0.22, 0.7), color.lightened(0.05))
	_part(_box(), Vector3(0, 0.25, 1.35), Vector3(0.3, 0.2, 1.0), color.darkened(0.1))
	for x: float in [-0.42, 0.42]:
		for z: float in [-0.5, 0.6]:
			_part(_box(), Vector3(x, 0.1, z), Vector3(0.18, 0.22, 0.18), color.darkened(0.25))
	_eyes(Vector3(0, 0.48, -0.75), 0.3)


func _spider() -> void:
	_part(_sphere(0.6), Vector3(0, 0.55, 0.2), Vector3.ONE, color)
	_part(_sphere(0.35), Vector3(0, 0.5, -0.35), Vector3.ONE, color.lightened(0.1))
	for i: int in 4:
		var z: float = -0.3 + i * 0.22
		for side: float in [-1.0, 1.0]:
			_part(_box(), Vector3(side * 0.6, 0.35, z), Vector3(0.8, 0.07, 0.07), color.darkened(0.3), Vector3(0, 0, side * -0.5))
	_eyes(Vector3(0, 0.6, -0.62), 0.14)


func _humanoid() -> void:
	_part(_cylinder(0.22, 0.28, 0.9), Vector3(0, 1.0, 0), Vector3.ONE, color)
	_part(_sphere(0.26), Vector3(0, 1.62, 0), Vector3.ONE, color.lightened(0.1))
	_part(_box(), Vector3(-0.15, 0.3, 0), Vector3(0.12, 0.6, 0.12), color.darkened(0.2))
	_part(_box(), Vector3(0.15, 0.3, 0), Vector3(0.12, 0.6, 0.12), color.darkened(0.2))
	_part(_box(), Vector3(-0.35, 1.05, 0), Vector3(0.1, 0.6, 0.1), color.darkened(0.1))
	_part(_box(), Vector3(0.35, 1.05, 0), Vector3(0.1, 0.6, 0.1), color.darkened(0.1))
	_eyes(Vector3(0, 1.66, -0.24), 0.16)


func _golem() -> void:
	_part(_box(), Vector3(0, 1.0, 0), Vector3(1.1, 1.0, 0.8), color)
	_part(_box(), Vector3(0, 1.7, -0.1), Vector3(0.6, 0.45, 0.55), color.lightened(0.08))
	_part(_box(), Vector3(-0.8, 0.9, 0), Vector3(0.35, 1.0, 0.35), color.darkened(0.15))
	_part(_box(), Vector3(0.8, 0.9, 0), Vector3(0.35, 1.0, 0.35), color.darkened(0.15))
	_part(_box(), Vector3(-0.3, 0.25, 0), Vector3(0.35, 0.5, 0.35), color.darkened(0.25))
	_part(_box(), Vector3(0.3, 0.25, 0), Vector3(0.35, 0.5, 0.35), color.darkened(0.25))
	_eyes(Vector3(0, 1.75, -0.39), 0.2)


func _eyes(center: Vector3, spacing: float) -> void:
	for side: float in [-1.0, 1.0]:
		_eye_builder.add(_sphere(0.07), MeshBuilder.at(center + Vector3(side * spacing * 0.5, 0, 0)), EYE_COLOR)


func _part(mesh: PrimitiveMesh, offset: Vector3, part_scale: Vector3, part_color: Color, part_rotation: Vector3 = Vector3.ZERO) -> void:
	_body.add(mesh, MeshBuilder.at(offset, part_scale, part_rotation), part_color)


static var _box_mesh: BoxMesh = null
static var _sphere_meshes: Dictionary = {}


static func _box() -> BoxMesh:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
	return _box_mesh


static func _sphere(radius: float) -> SphereMesh:
	if not _sphere_meshes.has(radius):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 10
		mesh.rings = 5
		_sphere_meshes[radius] = mesh
	return _sphere_meshes[radius]


static func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh
