class_name Pickup
extends Node3D
## Aufsammelbare Beute (auch der Beutesack nach dem Tod): wird angezogen, sobald der Spieler nahe ist.

const MAGNET_RADIUS: float = 3.5
const MAGNET_SPEED: float = 9.0
const LIFETIME: float = 150.0
const SACK_COLOR: Color = Color(0.85, 0.7, 0.35)
## Nur für die Darstellung: Farbe je Gegenstand (Daten kennen noch keine Icons).
const ITEM_COLORS: Dictionary[StringName, Color] = {
	&"kristall": Color(0.45, 0.95, 1.0), &"beeren": Color(0.55, 0.3, 0.9), &"fleisch": Color(0.85, 0.35, 0.3),
	&"fell": Color(0.55, 0.4, 0.25), &"stein": Color(0.6, 0.6, 0.62), &"holz": Color(0.6, 0.42, 0.22),
}

var items: Dictionary = {}
var is_sack: bool = false
var _age: float = 0.0
var _mesh: MeshInstance3D = null


static func spawn(tree: SceneTree, at: Vector3, contents: Dictionary, sack: bool = false) -> Pickup:
	var pickup := Pickup.new()
	pickup.items = contents
	pickup.is_sack = sack
	Combat.fx_parent(tree).add_child(pickup)
	pickup.global_position = at
	return pickup


## Beute nach den Drop-Würfen aus gegner.json (Bosse lassen alles fallen).
static func drop_loot(tree: SceneTree, data: EnemyData, at: Vector3) -> void:
	for drop: DropEntry in data.drops:
		if data.boss or randf() < drop.chance:
			spawn(tree, at + Vector3(randf_range(-0.6, 0.6), 0.6, randf_range(-0.6, 0.6)), {drop.item: 1})


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var first: StringName = StringName(str(items.keys()[0])) if not items.is_empty() else &""
	var color: Color = SACK_COLOR if is_sack else ITEM_COLORS.get(first, Color(0.9, 0.9, 0.7))
	if is_sack:
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.5, 0.5)
		_mesh.mesh = box
		_mesh.material_override = WorldMaterials.glowing(color)
	else:
		_mesh.mesh = Fx.sphere_mesh()
		_mesh.scale = Vector3.ONE * 0.35
		_mesh.material_override = Fx.material(color)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_settle()


## Legt die Beute auf den Boden.
func _settle() -> void:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.0, global_position + Vector3.DOWN * 20.0, 1)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		global_position = (result["position"] as Vector3) + Vector3.UP * 0.4


func _physics_process(delta: float) -> void:
	_age += delta
	_mesh.position.y = sin(_age * 3.0) * 0.1
	_mesh.rotation.y += delta * 1.5
	if not is_sack and _age > LIFETIME:
		queue_free()
		return
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Player
	if player == null or player.is_dead():
		return
	var offset: Vector3 = player.aim_point() - global_position
	if offset.length() <= Balance.values.pickup_radius:
		_collect()
	elif offset.length() <= MAGNET_RADIUS and not is_sack:
		global_position += offset.normalized() * MAGNET_SPEED * delta


func _collect() -> void:
	var parts: PackedStringArray = []
	for id: Variant in items:
		var item_id: StringName = StringName(str(id))
		GameState.add_item(item_id, int(items[id]))
		var data: ItemData = DataRegistry.item(item_id)
		parts.append("+%d %s" % [int(items[id]), tr(data.display_name) if data != null else String(item_id)])
	if is_sack:
		GameState.loot_sack = {}
		EventBus.message.emit(tr("Beutesack zurückgeholt"), SACK_COLOR)
	EventBus.floating_text.emit(", ".join(parts), global_position + Vector3.UP, Color(0.9, 1.0, 0.8))
	queue_free()
