class_name SpiritSpring
extends Node3D
## Geisterquelle: leuchtendes Becken mit aufsteigendem Nebel. Wer an ihr kultiviert, verfeinert die Aperturwand
## doppelt so schnell und sammelt mehr Uressenz (Balance.spirit_spring_mult).

const GROUP: StringName = &"spirit_springs"
const SPRING_COLOR: Color = Color(0.45, 0.95, 0.85)
const STONE: Color = Color(0.5, 0.52, 0.5)

var radius: float = 8.0
var _mist: CPUParticles3D = null


func _ready() -> void:
	add_to_group(GROUP)
	var b := MeshBuilder.new()
	for i: int in 16:
		var angle: float = i * TAU / 16.0
		b.add(MeshBuilder.sphere(0.55, 6, 3), MeshBuilder.at(Vector3(cos(angle) * 3.3, 0.15, sin(angle) * 3.3), Vector3(1.3, 0.7, 1.0), Vector3(0, -angle, 0)), STONE.darkened(0.05 * (i % 3)))
	var stones := MeshInstance3D.new()
	stones.mesh = b.build()
	stones.material_override = WorldMaterials.vertex_colored()
	add_child(stones)
	var pool := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 3.1
	disc.bottom_radius = 3.1
	disc.height = 0.05
	disc.radial_segments = 20
	pool.mesh = disc
	pool.position.y = 0.2
	pool.material_override = WaterSurface.material(SPRING_COLOR.darkened(0.3), 0.9)
	add_child(pool)
	var light := OmniLight3D.new()
	light.light_color = SPRING_COLOR
	light.omni_range = 9.0
	light.light_energy = 1.2
	light.position.y = 1.2
	add_child(light)
	_mist = CPUParticles3D.new()
	_mist.amount = 24
	_mist.lifetime = 3.0
	_mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_mist.emission_sphere_radius = 2.4
	_mist.direction = Vector3.UP
	_mist.initial_velocity_min = 0.3
	_mist.initial_velocity_max = 0.7
	_mist.gravity = Vector3.ZERO
	var mote := SphereMesh.new()
	mote.radius = 0.08
	mote.height = 0.16
	mote.radial_segments = 4
	mote.rings = 2
	_mist.mesh = mote
	var mote_material := StandardMaterial3D.new()
	mote_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_material.albedo_color = SPRING_COLOR.lightened(0.4)
	_mist.material_override = mote_material
	_mist.position.y = 0.4
	add_child(_mist)


## Faktor für Kultivieren an dieser Stelle (1 = keine Quelle in der Nähe).
static func bonus_at(tree: SceneTree, point: Vector3) -> float:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var spring: SpiritSpring = node as SpiritSpring
		if spring != null and spring.global_position.distance_to(point) < spring.radius:
			return Balance.values.spirit_spring_mult
	return 1.0
