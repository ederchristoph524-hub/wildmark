class_name PlayerModel
extends Node3D
## Platzhalter-Figur des Spielers aus einfachen Formen: Körper in Erdtönen, Kopf, leuchtende Apertur-Stelle in Rangfarbe.

const BODY_COLOR: Color = Color(0.55, 0.42, 0.3)
const CLOTH_COLOR: Color = Color(0.36, 0.3, 0.22)
const SKIN_COLOR: Color = Color(0.86, 0.7, 0.55)
const HAIR_COLOR: Color = Color(0.12, 0.1, 0.09)

## Kleidungsfarben (NPCs tragen die Farbe ihrer Art).
var cloth_color: Color = CLOTH_COLOR
var body_color: Color = BODY_COLOR
var aperture_glow: MeshInstance3D = null
var _bob: float = 0.0
var _body: Node3D = null
var _builder: MeshBuilder = MeshBuilder.new()


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_builder.add(_capsule(0.32, 1.0), MeshBuilder.at(Vector3(0.0, 0.85, 0.0)), cloth_color)
	_builder.add(_capsule(0.3, 0.7), MeshBuilder.at(Vector3(0.0, 1.15, 0.0)), body_color)
	_builder.add(_sphere(0.24), MeshBuilder.at(Vector3(0.0, 1.62, 0.0)), SKIN_COLOR)
	_builder.add(_sphere(0.25), MeshBuilder.at(Vector3(0.0, 1.7, 0.05), Vector3(1.0, 0.7, 1.0)), HAIR_COLOR)
	_builder.add(_capsule(0.09, 0.62), MeshBuilder.at(Vector3(-0.38, 1.1, 0.0)), body_color)
	_builder.add(_capsule(0.09, 0.62), MeshBuilder.at(Vector3(0.38, 1.1, 0.0)), body_color)
	_builder.add(_sphere(0.07), MeshBuilder.at(Vector3(0.0, 1.62, -0.24), Vector3(2.4, 0.4, 0.4)), HAIR_COLOR)
	var body := MeshInstance3D.new()
	body.mesh = _builder.build()
	body.material_override = WorldMaterials.vertex_colored()
	_body.add_child(body)
	aperture_glow = MeshInstance3D.new()
	aperture_glow.mesh = _sphere(0.1)
	aperture_glow.position = Vector3(0.0, 1.0, -0.3)
	aperture_glow.material_override = Fx.material(Color(0.5, 0.8, 0.4))
	_body.add_child(aperture_glow)


func set_rank_color(color: Color) -> void:
	if aperture_glow != null:
		aperture_glow.material_override = Fx.material(color)


## Leichtes Wippen beim Laufen.
func animate(delta: float, speed: float) -> void:
	if _body == null:
		return
	_bob += delta * speed * 2.2
	_body.position.y = absf(sin(_bob)) * 0.06 * clampf(speed / 5.0, 0.0, 1.0)


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 2
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh
