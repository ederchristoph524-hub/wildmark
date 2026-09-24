class_name ObstacleBuilder
extends RefCounted
## Geometrie der Hindernis-Orte: Mauerringe mit Lücke, Tore, Siegel, Wasser, Hecken, Felsen, Vorsprung.

const STONE: Color = Color(0.5, 0.5, 0.47)
const RUIN: Color = Color(0.58, 0.55, 0.48)
const HEDGE: Color = Color(0.2, 0.33, 0.14)
const THORN: Color = Color(0.45, 0.35, 0.2)
const WATER: Color = Color(0.2, 0.45, 0.75, 0.75)
const ICE: Color = Color(0.8, 0.95, 1.0)
const BOULDER: Color = Color(0.45, 0.43, 0.4)
const MOSS: Color = Color(0.3, 0.4, 0.18)
const LIGHT_SEAL: Color = Color(1.0, 0.95, 0.6)
const BLOOD_SEAL: Color = Color(0.8, 0.1, 0.12)
const WALL_HEIGHT: float = 3.0
const SEGMENTS: int = 12


## Statischer Mauerring aus Blöcken; gap_angle < 0 = geschlossen. Liefert den Winkel der Lücke.
static func wall_ring(parent: Node3D, world: World, center: Vector3, radius: float, gap_angle: float, color: Color) -> void:
	var body := StaticBody3D.new()
	parent.add_child(body)
	var b := MeshBuilder.new()
	for i: int in SEGMENTS:
		var angle: float = i * TAU / SEGMENTS
		if gap_angle >= 0.0 and absf(angle_difference(angle, gap_angle)) < TAU / SEGMENTS * 0.6:
			continue
		var point: Vector3 = _ring_point(world, center, radius, angle)
		var size := Vector3(radius * TAU / SEGMENTS * 1.1, WALL_HEIGHT, 0.8)
		var transform := Transform3D(Basis(Vector3.UP, -angle + PI * 0.5), point + Vector3.UP * WALL_HEIGHT * 0.45)
		b.add(MeshBuilder.box(size), transform, color.darkened(randf() * 0.1))
		_ruin_details(b, transform, size, color)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		shape.transform = transform
		body.add_child(shape)
	_mesh(body, b.build(), WorldMaterials.vertex_colored())


## Verwitterte Mauer: Steinfugen, Deckstein, teils eingestürzte Zinnen und Moos obenauf.
static func _ruin_details(b: MeshBuilder, transform: Transform3D, size: Vector3, color: Color) -> void:
	var top: float = size.y * 0.5
	for level: float in [-size.y * 0.17, size.y * 0.17]:
		b.add(MeshBuilder.box(Vector3(size.x, 0.07, size.z + 0.04)), transform * MeshBuilder.at(Vector3(0, level, 0)), color.darkened(0.28))
	b.add(MeshBuilder.box(Vector3(size.x + 0.15, 0.22, size.z + 0.2)), transform * MeshBuilder.at(Vector3(0, top + 0.1, 0)), color.darkened(0.15))
	for merlon: float in [-0.3, 0.3]:
		if randf() < 0.6:
			var height: float = randf_range(0.3, 0.7)
			b.add(MeshBuilder.box(Vector3(0.9, height, size.z)), transform * MeshBuilder.at(Vector3(merlon * size.x, top + 0.2 + height * 0.5, 0)), color.darkened(0.05))
	if randf() < 0.5:
		b.add(MeshBuilder.box(Vector3(size.x * 0.45, 0.1, size.z + 0.24)), transform * MeshBuilder.at(Vector3(randf_range(-0.25, 0.25) * size.x, top + 0.24, 0)), MOSS)


## Ring aus Blocker-Formen als Kinder des Hindernisses (verschwinden beim Öffnen); visible = Mesh erzeugen.
static func blocker_ring(obstacle: WorldObstacle, world: World, center: Vector3, radius: float, height: float, color: Color, visible: bool) -> void:
	var b := MeshBuilder.new()
	for i: int in SEGMENTS:
		var angle: float = i * TAU / SEGMENTS
		var point: Vector3 = _ring_point(world, center, radius, angle) - obstacle.position
		var size := Vector3(radius * TAU / SEGMENTS * 1.15, height, 1.0)
		var transform := Transform3D(Basis(Vector3.UP, -angle + PI * 0.5), point + Vector3.UP * height * 0.45)
		b.add(MeshBuilder.box(size), transform, color.darkened(randf() * 0.15))
		if visible:
			b.add(MeshBuilder.cylinder(0.0, 0.12, 0.6, 3), Transform3D(Basis.IDENTITY, point + Vector3(0, height, 0)), THORN)
		obstacle.blockers.append(_shape(obstacle, BoxShape3D.new(), size, transform))
	if visible:
		obstacle.closed_visuals.append(_mesh(obstacle, b.build(), WorldMaterials.vertex_colored()))


## Tor in einer Maueröffnung (Blocker), optional mit leuchtendem Siegel.
static func gate(obstacle: WorldObstacle, local_position: Vector3, facing: float, seal_color: Color) -> void:
	var size := Vector3(3.0, WALL_HEIGHT, 0.5)
	var transform := Transform3D(Basis(Vector3.UP, facing), local_position + Vector3.UP * WALL_HEIGHT * 0.5)
	obstacle.blockers.append(_shape(obstacle, BoxShape3D.new(), size, transform))
	var door: MeshInstance3D = _mesh(obstacle, MeshBuilder.new().add(MeshBuilder.box(size), transform, RUIN.darkened(0.2)).build(), WorldMaterials.vertex_colored())
	obstacle.closed_visuals.append(door)
	if seal_color.a > 0.0:
		var seal_transform := transform.translated_local(Vector3(0, 0.2, -0.3))
		var seal: MeshInstance3D = _mesh(obstacle, MeshBuilder.new().add(MeshBuilder.cylinder(0.7, 0.7, 0.1, 12), seal_transform * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), Color.WHITE).build(), WorldMaterials.glowing(seal_color))
		obstacle.closed_visuals.append(seal)


static func boulder(obstacle: WorldObstacle) -> void:
	var transform := Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.9, 1.0)), Vector3.UP * 1.2)
	obstacle.blockers.append(_shape(obstacle, SphereShape3D.new(), Vector3.ONE * 1.5, transform))
	obstacle.closed_visuals.append(_mesh(obstacle, MeshBuilder.new().add(MeshBuilder.sphere(1.5, 7, 4), transform, BOULDER).build(), WorldMaterials.vertex_colored()))


static func switch_pillar(obstacle: WorldObstacle) -> void:
	_shape(obstacle, CylinderShape3D.new(), Vector3(0.5, 1.8, 0.5), Transform3D(Basis.IDENTITY, Vector3.UP * 0.9))
	var b := MeshBuilder.new().add(MeshBuilder.cylinder(0.35, 0.5, 1.8, 6), MeshBuilder.at(Vector3.UP * 0.9), RUIN)
	_mesh(obstacle, b.build(), WorldMaterials.vertex_colored())
	_mesh(obstacle, MeshBuilder.new().add(MeshBuilder.sphere(0.3, 6, 3), MeshBuilder.at(Vector3.UP * 2.0), Color.WHITE).build(), WorldMaterials.glowing(Color(0.5, 0.7, 1.0)))


## Wasserfläche (vor dem Gefrieren) und Eis (danach).
static func pond(obstacle: WorldObstacle, radius: float) -> void:
	var water := MeshBuilder.new().add(MeshBuilder.cylinder(radius, radius, 0.08, 20), MeshBuilder.at(Vector3.UP * 0.12), Color.WHITE).build()
	obstacle.closed_visuals.append(_mesh(obstacle, water, Fx.material(WATER)))
	obstacle.open_visuals.append(_mesh(obstacle, water, WorldMaterials.glowing(ICE)))
	var island := MeshBuilder.new().add(MeshBuilder.cylinder(1.8, 2.2, 0.5, 10), MeshBuilder.at(Vector3.UP * 0.2), Color(0.35, 0.5, 0.25)).build()
	_mesh(obstacle, island, WorldMaterials.vertex_colored())


## Hoher Vorsprung: nur mit Doppelsprung (Schritt-Familie) erreichbar.
static func ledge(parent: Node3D, top_height: float) -> void:
	var body := StaticBody3D.new()
	parent.add_child(body)
	var transform := Transform3D(Basis.IDENTITY, Vector3.UP * top_height * 0.5)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.6
	cylinder.height = top_height
	shape.shape = cylinder
	shape.transform = transform
	body.add_child(shape)
	_mesh(body, MeshBuilder.new().add(MeshBuilder.cylinder(1.6, 1.9, top_height, 7), transform, STONE).build(), WorldMaterials.vertex_colored())


static func _ring_point(world: World, center: Vector3, radius: float, angle: float) -> Vector3:
	return world.ground_point(center.x + cos(angle) * radius, center.z + sin(angle) * radius)


static func _shape(parent: Node3D, shape: Shape3D, size: Vector3, transform: Transform3D) -> CollisionShape3D:
	if shape is BoxShape3D:
		(shape as BoxShape3D).size = size
	elif shape is SphereShape3D:
		(shape as SphereShape3D).radius = size.x
	elif shape is CylinderShape3D:
		(shape as CylinderShape3D).radius = size.x
		(shape as CylinderShape3D).height = size.y
	var node := CollisionShape3D.new()
	node.shape = shape
	node.transform = transform
	parent.add_child(node)
	return node


static func _mesh(parent: Node3D, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node
