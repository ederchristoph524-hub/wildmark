class_name ResourceNode
extends StaticBody3D
## Sammelstelle (Beerenbusch, Stein, Urstein-Kristall, Totholz): mit Faustschlägen abbauen, wächst nach einer Weile nach.

const HITS_NEEDED: int = 3
const REGROW_TIME: float = 240.0
const KIND_BERRIES: StringName = &"beeren"
const KIND_STONE: StringName = &"stein"
const KIND_CRYSTAL: StringName = &"kristall"
const KIND_WOOD: StringName = &"holz"
## Sammelstellen werden erst aus der Nähe gezeichnet (spart Draw Calls am Handy).
const VIEW_DISTANCE: float = 55.0

var item: StringName = KIND_BERRIES
var amount: int = 2
var _hits: int = 0
var _regrow: float = 0.0
var _visual: Node3D = null
var _fruit: Node3D = null
var _shape: CollisionShape3D = null


func _init(item_id: StringName, yield_amount: int) -> void:
	item = item_id
	amount = yield_amount
	collision_layer = 1
	collision_mask = 0


func _ready() -> void:
	add_to_group(Player.GROUP_HARVESTABLE)
	_visual = Node3D.new()
	add_child(_visual)
	_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	_shape.shape = sphere
	_shape.position.y = 0.5
	add_child(_shape)
	_build_visual()


func _build_visual() -> void:
	var b := MeshBuilder.new()
	match item:
		KIND_BERRIES:
			b.add(MeshBuilder.sphere(0.75, 6, 3), MeshBuilder.at(Vector3(0, 0.55, 0), Vector3(1.1, 0.8, 1.0)), Color(0.2, 0.45, 0.2))
			_fruit = _mesh_node(MeshBuilder.new().add(MeshBuilder.sphere(0.12, 5, 3), MeshBuilder.at(Vector3(0.4, 0.8, -0.4)), Color(0.55, 0.25, 0.85)).add(MeshBuilder.sphere(0.12, 5, 3), MeshBuilder.at(Vector3(-0.35, 0.9, -0.3)), Color(0.55, 0.25, 0.85)).add(MeshBuilder.sphere(0.12, 5, 3), MeshBuilder.at(Vector3(0.1, 1.05, 0.4)), Color(0.55, 0.25, 0.85)).build())
		KIND_STONE:
			b.add(MeshBuilder.sphere(0.8, 6, 3), MeshBuilder.at(Vector3(0, 0.45, 0), Vector3(1.2, 0.8, 1.0)), Color(0.55, 0.55, 0.52))
			b.add(MeshBuilder.sphere(0.5, 5, 3), MeshBuilder.at(Vector3(0.6, 0.35, 0.3)), Color(0.48, 0.48, 0.45))
		KIND_CRYSTAL:
			b.add(MeshBuilder.sphere(0.6, 6, 3), MeshBuilder.at(Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 1.0)), Color(0.4, 0.4, 0.42))
			var crystals := MeshBuilder.new()
			for i: int in 3:
				var tilt := Vector3(0.3 * (i - 1), 0.0, 0.25 * (1 - i))
				crystals.add(MeshBuilder.cylinder(0.0, 0.2, 1.1 - i * 0.2, 5), MeshBuilder.at(Vector3(0.25 * (i - 1), 0.8, 0.15 * i), Vector3.ONE, tilt), Color.WHITE)
			_mesh_node(crystals.build()).material_override = WorldMaterials.glowing(Color(0.35, 0.9, 1.0))
		_:
			b.add(MeshBuilder.cylinder(0.32, 0.36, 2.4, 6), MeshBuilder.at(Vector3(0, 0.35, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5)), Color(0.4, 0.28, 0.18))
	_mesh_node(b.build())


func _mesh_node(mesh: ArrayMesh) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = WorldMaterials.vertex_colored()
	node.visibility_range_end = VIEW_DISTANCE
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(node)
	return node


func harvest_hit(_player: Node3D) -> void:
	if _regrow > 0.0:
		return
	_hits += 1
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.12, 0.9, 1.12), 0.06)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.1)
	if _hits < HITS_NEEDED:
		return
	_hits = 0
	Pickup.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), {item: amount})
	_regrow = REGROW_TIME
	remove_from_group(Player.GROUP_HARVESTABLE)
	_set_depleted(true)


func _process(delta: float) -> void:
	if _regrow <= 0.0:
		return
	_regrow -= delta
	if _regrow <= 0.0:
		add_to_group(Player.GROUP_HARVESTABLE)
		_set_depleted(false)


func _set_depleted(depleted: bool) -> void:
	if _fruit != null:
		_fruit.visible = not depleted
	else:
		_visual.visible = not depleted
		_shape.set_deferred(&"disabled", depleted)
