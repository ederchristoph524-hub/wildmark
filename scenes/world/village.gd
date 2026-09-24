class_name Village
extends RefCounted
## Das Klan-Dorf rund um das Dorffeuer: Hütten, Palisade, Dorfbewohner mit Aufgaben und Händler.

const HUT_RADIUS: float = 13.0
const FENCE_RADIUS: float = 20.0
const FENCE_SEGMENTS: int = 28
const FENCE_GAPS: Array[float] = [0.0, PI]
const HUT_ANGLES: Array[float] = [0.6, 1.5, 2.6, 3.9, 5.2]
const WALL: Color = Color(0.55, 0.42, 0.28)
const ROOF: Color = Color(0.42, 0.3, 0.18)
const POST: Color = Color(0.45, 0.33, 0.2)
## NPC-Art, Titel (leer = Name aus den Daten), Aufgabe, Tausch, Winkel, Abstand vom Feuer.
const PEOPLE: Array[Array] = [
	[&"klan", "Dorfältester", &"bau", false, 1.1, 7.0],
	[&"klan", "Klanwächter", &"j10", false, 0.15, 18.0],
	[&"klan", "Holzfäller", &"holz", false, 3.4, 10.0],
	[&"klan", "Späherin", &"ero", false, 4.6, 9.0],
	[&"haendler", "", &"", true, 5.7, 9.5],
	[&"daemon", "", &"", true, 0.7, 27.0],
]
## Gu-Meister des Klans (Daten-ID, Titel, Winkel, Abstand): fordert man ihn heraus, gibt es ein Duell auf dem Dorfplatz.
const MASTER: Array = [&"gu_yue", "Klanlehrer", 2.1, 6.5]
## Beerenbüsche innerhalb der Palisade (Winkel, Abstand) – für die Kindheit und als kleine Vorratsquelle.
const BUSHES: Array[Vector2] = [Vector2(3.15, 16.5), Vector2(3.4, 16.0), Vector2(4.25, 16.5)]
const BUSH_YIELD: int = 3


static func build(world: World, center: Vector3) -> void:
	for angle: float in HUT_ANGLES:
		_hut(world, world.ground_point(center.x + cos(angle) * HUT_RADIUS, center.z + sin(angle) * HUT_RADIUS), angle)
	_fence(world, center)
	for entry: Array in PEOPLE:
		var npc := Npc.new()
		npc.setup(DataRegistry.npc_type(entry[0]), String(entry[1]), entry[2], bool(entry[3]))
		world.add_child(npc)
		var angle: float = float(entry[4])
		npc.position = world.ground_point(center.x + cos(angle) * float(entry[5]), center.z + sin(angle) * float(entry[5]))
	for bush: Vector2 in BUSHES:
		var node := ResourceNode.new(&"beeren", BUSH_YIELD)
		world.add_child(node)
		node.position = world.ground_point(center.x + cos(bush.x) * bush.y, center.z + sin(bush.x) * bush.y)
		node.rotation.y = bush.x * 3.0
	var master := GuMaster.new()
	var master_angle: float = float(MASTER[2])
	master.setup(DataRegistry.gu_master(MASTER[0]), String(MASTER[1]), world.ground_point(center.x + cos(master_angle) * float(MASTER[3]), center.z + sin(master_angle) * float(MASTER[3])))
	world.add_child(master)


static func _hut(world: World, at: Vector3, angle: float) -> void:
	var b := MeshBuilder.new()
	var facing := Basis(Vector3.UP, -angle - PI * 0.5)
	b.add(MeshBuilder.box(Vector3(3.6, 2.4, 3.0)), Transform3D(facing, at + Vector3.UP * 1.2), WALL)
	b.add(MeshBuilder.cylinder(0.0, 2.9, 1.6, 4), Transform3D(facing * Basis(Vector3.UP, PI * 0.25), at + Vector3.UP * 3.2), ROOF)
	b.add(MeshBuilder.box(Vector3(0.9, 1.6, 0.1)), Transform3D(facing, at + facing * Vector3(0, 0.8, 1.52)), Color(0.2, 0.15, 0.1))
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = WorldMaterials.vertex_colored()
	world.add_child(node)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.6, 3.0, 3.0)
	shape.shape = box
	shape.transform = Transform3D(facing, at + Vector3.UP * 1.5)
	body.add_child(shape)
	world.add_child(body)


## Palisade mit zwei Toren (zu den Hindernis-Orten hin offen).
static func _fence(world: World, center: Vector3) -> void:
	var b := MeshBuilder.new()
	var body := StaticBody3D.new()
	world.add_child(body)
	for i: int in FENCE_SEGMENTS:
		var angle: float = i * TAU / FENCE_SEGMENTS
		var in_gap: bool = false
		for gap: float in FENCE_GAPS:
			if absf(angle_difference(angle, gap)) < TAU / FENCE_SEGMENTS * 1.1:
				in_gap = true
		if in_gap:
			continue
		var point: Vector3 = world.ground_point(center.x + cos(angle) * FENCE_RADIUS, center.z + sin(angle) * FENCE_RADIUS)
		var length: float = FENCE_RADIUS * TAU / FENCE_SEGMENTS
		var basis := Basis(Vector3.UP, -angle + PI * 0.5)
		for p: int in 5:
			var offset: Vector3 = basis * Vector3((p - 2) * length / 5.0, 0, 0)
			b.add(MeshBuilder.cylinder(0.14, 0.16, 2.2 + (p % 2) * 0.3, 5), MeshBuilder.at(point + offset + Vector3.UP * 1.1), POST)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(length, 2.4, 0.4)
		shape.shape = box
		shape.transform = Transform3D(basis, point + Vector3.UP * 1.2)
		body.add_child(shape)
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = WorldMaterials.vertex_colored()
	world.add_child(node)
