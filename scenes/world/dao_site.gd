class_name DaoSite
extends Node3D
## Dao-Ort (gebiete.json → orte, typ dao_ort): ein Steinkreis mit Stelen um einen Mittelstein, dessen Runen in der
## Farbe des Pfads leuchten; darüber schweben Teilchen in der Handschrift des Pfads (GuVfx). Wer hier kultiviert,
## prägt Dao-Markierungen in diesen Pfad (Balance.dao_site_rate je Sekunde) – der Weg zur Pfad-Beherrschung ohne
## tausend Gu-Einsätze.

const GROUP: StringName = &"dao_sites"
const STONE: Color = Color(0.4, 0.4, 0.42)
const MOSS: Color = Color(0.3, 0.38, 0.26)
const STELAE: int = 7
const CHECK_INTERVAL: float = 0.5
const BEAM_RADIUS: float = 0.7
const BEAM_HEIGHT: float = 40.0
const BEAM_VIEW: float = 320.0

var path: StringName = &""
var radius: float = 10.0
var site_name: String = ""
var _check_left: float = 0.0
var _inside: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	var color: Color = DataRegistry.gu_system().path_color(path)
	var b := MeshBuilder.new()
	var glow := MeshBuilder.new()
	var ring: float = radius * 0.62
	for i: int in STELAE:
		var angle: float = TAU * float(i) / STELAE
		var at := Vector3(cos(angle) * ring, 0.0, sin(angle) * ring)
		var height: float = 3.2 + 0.7 * sin(float(i) * 2.3)
		b.add(MeshBuilder.box(Vector3(0.9, height, 0.4)), MeshBuilder.at(at + Vector3.UP * height * 0.5, Vector3.ONE, Vector3(0, -angle + PI * 0.5, 0)), STONE.darkened(0.06 * (i % 3)))
		b.add(MeshBuilder.box(Vector3(1.15, 0.25, 0.6)), MeshBuilder.at(at + Vector3.UP * height, Vector3.ONE, Vector3(0, -angle + PI * 0.5, 0)), STONE.darkened(0.15))
		# Rune auf der Innenseite jeder Stele.
		var inward: Vector3 = -at.normalized() * 0.21
		glow.add(MeshBuilder.box(Vector3(0.14, 1.2, 0.04)), MeshBuilder.at(at + inward + Vector3.UP * height * 0.55, Vector3.ONE, Vector3(0, -angle + PI * 0.5, 0)), color)
	# Mittelstein auf einem gestuften Sockel, darauf ein leuchtender Kern.
	b.add(MeshBuilder.cylinder(2.0, 2.3, 0.35, 8), MeshBuilder.at(Vector3.UP * 0.17), STONE.darkened(0.1))
	b.add(MeshBuilder.cylinder(1.4, 1.6, 0.35, 8), MeshBuilder.at(Vector3.UP * 0.5), STONE)
	b.add(MeshBuilder.cylinder(0.4, 0.8, 3.6, 6), MeshBuilder.at(Vector3.UP * 2.45), STONE.lightened(0.05))
	b.add(MeshBuilder.sphere(1.1, 7, 3), MeshBuilder.at(Vector3(0.9, 0.3, -0.6), Vector3(1.0, 0.3, 0.8)), MOSS)
	glow.add(MeshBuilder.sphere(0.55, 8, 5), MeshBuilder.at(Vector3.UP * 4.75), color)
	glow.add(MeshBuilder.box(Vector3(0.1, 2.0, 0.82)), MeshBuilder.at(Vector3(0.0, 2.3, 0.0)), color)
	_add_mesh(b, WorldMaterials.vertex_colored())
	_add_mesh(glow, WorldMaterials.glowing(color))
	_add_beam(color)
	GuVfx.zone(self, GuVfx.style_of(path), radius * 0.45)


## Lichtsäule über dem Mittelstein: von weitem zu sehen, damit man den Ort findet.
func _add_beam(color: Color) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = BEAM_RADIUS * 0.4
	cylinder.bottom_radius = BEAM_RADIUS
	cylinder.height = BEAM_HEIGHT
	cylinder.radial_segments = 8
	cylinder.rings = 1
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	var beam := MeshInstance3D.new()
	beam.mesh = cylinder
	beam.material_override = Fx.material(Color(color, 0.16))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position.y = 4.75 + BEAM_HEIGHT * 0.5
	beam.visibility_range_end = BEAM_VIEW
	add_child(beam)


func _add_mesh(b: MeshBuilder, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = material
	node.visibility_range_end = PlaceDecor.VIEW
	add_child(node)


## Hinweis beim Betreten.
func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_INTERVAL
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
	var inside: bool = player != null and player.global_position.distance_to(global_position) < radius
	if inside and not _inside:
		var system: GuSystemData = DataRegistry.gu_system()
		EventBus.message.emit(Loc.t("%s: Kultiviere hier, um Dao-Markierungen im %s-Pfad zu sammeln.") % [Loc.t(site_name), Loc.t(system.path_name(path))], system.path_color(path))
	_inside = inside


## Pfad des Dao-Orts an dieser Stelle; leer, wenn keiner.
static func path_at(tree: SceneTree, point: Vector3) -> StringName:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var site: DaoSite = node as DaoSite
		if site != null and site.global_position.distance_to(point) < site.radius:
			return site.path
	return &""
