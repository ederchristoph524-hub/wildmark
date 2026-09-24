class_name WildGu
extends Node3D
## Ein wilder Gu in der Welt: leuchtet in seiner Pfadfarbe, lässt sich mit Uressenz verfeinern (einfangen).

## Sichtweite von Körper und Leuchthülle (weiter weg ist ein 40-cm-Gu ohnehin nicht zu erkennen; spart Draw Calls).
const BODY_VIEW: float = 70.0
const HALO_VIEW: float = 45.0

var spot_id: StringName = &""
## GuData, BodyGuData oder SupportGuData.
var gu: Resource = null
## Versteckte wilde Gu sind nur mit Kleines-Licht-Gu sichtbar (und nur dann verfeinerbar).
var hidden: bool = false
var _time: float = 0.0
var _body: Node3D = null
var _label: Label3D = null


func setup(id: StringName, gu_data: Resource, is_hidden: bool = false) -> void:
	spot_id = id
	gu = gu_data
	hidden = is_hidden


func _ready() -> void:
	add_to_group(Player.GROUP_INTERACTABLES)
	var color: Color = path_color()
	_body = Node3D.new()
	add_child(_body)
	var worm := MeshInstance3D.new()
	worm.mesh = MeshBuilder.new().add(MeshBuilder.sphere(0.18, 6, 3), MeshBuilder.at(Vector3(0, 0, -0.2)), Color.WHITE).add(MeshBuilder.sphere(0.15, 6, 3), MeshBuilder.at(Vector3(0, 0, 0.05)), Color.WHITE).add(MeshBuilder.sphere(0.12, 6, 3), MeshBuilder.at(Vector3(0, 0, 0.27)), Color.WHITE).build()
	worm.material_override = WorldMaterials.glowing(color)
	worm.visibility_range_end = BODY_VIEW
	_body.add_child(worm)
	var halo := MeshInstance3D.new()
	halo.mesh = Fx.sphere_mesh()
	halo.scale = Vector3.ONE * 1.1
	halo.material_override = Fx.material(Color(color, 0.18))
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.visibility_range_end = HALO_VIEW
	_body.add_child(halo)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 36
	_label.pixel_size = 0.006
	_label.outline_size = 8
	_label.modulate = color.lightened(0.3)
	_label.position.y = 1.4
	_label.text = tr("Wilder %s") % tr(String(gu.get("display_name")))
	add_child(_label)


## Farbe nach Pfad (Familie bzw. Hilfs-Gu); Körper-Gu leuchten in Kraft-Farbe.
func path_color() -> Color:
	var system: GuSystemData = DataRegistry.gu_system()
	if gu is GuData:
		return system.path_color(DataRegistry.family((gu as GuData).family).path)
	if gu is SupportGuData:
		return system.path_color((gu as SupportGuData).path)
	return system.path_color(&"kraft")


func _process(delta: float) -> void:
	_time += delta
	_body.position = Vector3(sin(_time * 0.9) * 0.4, 0.8 + sin(_time * 2.3) * 0.2, cos(_time * 0.7) * 0.4)
	_body.rotation.y = _time * 1.3
	var seen: bool = not hidden or PassiveGu.flag("reveal")
	_body.visible = seen
	_label.visible = seen
	_label.visibility_range_end = PassiveGu.detection_range() * 1.5
	if seen != is_in_group(Player.GROUP_INTERACTABLES):
		if seen:
			add_to_group(Player.GROUP_INTERACTABLES)
		else:
			remove_from_group(Player.GROUP_INTERACTABLES)


func interact_label() -> String:
	return tr("Verfeinern: %s (%d Uressenz, %d %%)") % [tr(String(gu.get("display_name"))), roundi(GuRefining.essence_cost(gu)), roundi(GuRefining.chance(gu) * 100.0)]


func interact(player: Player) -> void:
	var reason: String = GuRefining.blocked_reason(gu, player.aperture)
	if reason != "":
		EventBus.message.emit(reason, Color(1.0, 0.6, 0.4))
		return
	Fx.sphere(get_tree(), global_position + Vector3.UP, 1.5, Color(1.0, 1.0, 1.0, 0.5), 0.4)
	if GuRefining.refine(gu, player.aperture) != null:
		GameState.collected_wild_gu.append(spot_id)
		queue_free()
