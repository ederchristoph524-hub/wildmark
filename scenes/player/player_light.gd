class_name PlayerLight
extends RefCounted
## Lichtkreis des Kleines-Licht-Gu bei Nacht.

const LIGHT_NAME: StringName = &"GuLight"
const COLOR: Color = Color(1.0, 0.95, 0.75)
const RANGE: float = 12.0


static func update(player: Node3D, active: bool) -> void:
	var light: OmniLight3D = player.get_node_or_null(NodePath(LIGHT_NAME)) as OmniLight3D
	if light == null:
		if not active:
			return
		light = OmniLight3D.new()
		light.name = LIGHT_NAME
		light.light_color = COLOR
		light.omni_range = RANGE
		light.light_energy = 1.4
		light.position.y = 2.2
		player.add_child(light)
	light.visible = active
