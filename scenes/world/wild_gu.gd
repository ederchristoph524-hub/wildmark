class_name WildGu
extends Node3D
## Ein wilder Gu in der Welt: leuchtet in seiner Pfadfarbe, lässt sich mit Uressenz verfeinern (einfangen).

var spot_id: StringName = &""
var gu: GuData = null
var _time: float = 0.0
var _body: Node3D = null
var _label: Label3D = null


func setup(id: StringName, gu_data: GuData) -> void:
	spot_id = id
	gu = gu_data


func _ready() -> void:
	add_to_group(Player.GROUP_INTERACTABLES)
	var family: GuFamilyData = DataRegistry.family(gu.family)
	var color: Color = DataRegistry.gu_system().path_color(family.path)
	_body = Node3D.new()
	add_child(_body)
	var worm := MeshInstance3D.new()
	worm.mesh = MeshBuilder.new().add(MeshBuilder.sphere(0.18, 6, 3), MeshBuilder.at(Vector3(0, 0, -0.2)), Color.WHITE).add(MeshBuilder.sphere(0.15, 6, 3), MeshBuilder.at(Vector3(0, 0, 0.05)), Color.WHITE).add(MeshBuilder.sphere(0.12, 6, 3), MeshBuilder.at(Vector3(0, 0, 0.27)), Color.WHITE).build()
	worm.material_override = WorldMaterials.glowing(color)
	_body.add_child(worm)
	var halo := MeshInstance3D.new()
	halo.mesh = Fx.sphere_mesh()
	halo.scale = Vector3.ONE * 1.1
	halo.material_override = Fx.material(Color(color, 0.18))
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(halo)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	_label.pixel_size = 0.006
	_label.outline_size = 8
	_label.modulate = color.lightened(0.3)
	_label.position.y = 1.4
	_label.text = tr("Wilder %s") % tr(gu.display_name)
	add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	_body.position = Vector3(sin(_time * 0.9) * 0.4, 0.8 + sin(_time * 2.3) * 0.2, cos(_time * 0.7) * 0.4)
	_body.rotation.y = _time * 1.3


func interact_label() -> String:
	return tr("Verfeinern: %s (%d Uressenz, %d %%)") % [tr(gu.display_name), roundi(GuRefining.essence_cost(gu)), roundi(GuRefining.chance(gu) * 100.0)]


func interact(player: Player) -> void:
	var reason: String = GuRefining.blocked_reason(gu, player.aperture)
	if reason != "":
		EventBus.message.emit(reason, Color(1.0, 0.6, 0.4))
		return
	Fx.sphere(get_tree(), global_position + Vector3.UP, 1.5, Color(1.0, 1.0, 1.0, 0.5), 0.4)
	if GuRefining.refine(gu, player.aperture) != null:
		GameState.collected_wild_gu.append(spot_id)
		queue_free()
