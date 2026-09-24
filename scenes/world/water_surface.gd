class_name WaterSurface
extends RefCounted
## Wasserflächen: runde Seen und Quellen mit dem Wasser-Shader (optional leuchtend).

const WATER_SHADER: Shader = preload("res://assets/shaders/water.gdshader")
const SEGMENTS: int = 28


## Scheibe auf Wasserhöhe über einem See (lake = x, z, Radius, Wasserhöhe). glow > 0 lässt sie leuchten.
static func lake(world: World, lake_data: Vector4, color: Color, glow: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = lake_data.z + 0.8
	mesh.bottom_radius = lake_data.z + 0.8
	mesh.height = 0.02
	mesh.radial_segments = SEGMENTS
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color, glow)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)
	node.position = Vector3(lake_data.x, lake_data.w, lake_data.y)
	return node


static func material(color: Color, glow: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter(&"shallow_color", color.lightened(0.25))
	mat.set_shader_parameter(&"deep_color", color.darkened(0.45))
	mat.set_shader_parameter(&"glow", glow)
	return mat
