class_name WaterSurface
extends RefCounted
## Wasserflächen: runde Seen und Quellen mit dem Wasser-Shader (optional leuchtend).

const WATER_SHADER: Shader = preload("res://assets/shaders/water.gdshader")
const SEGMENTS: int = 28
## So tief watet man höchstens im Meer.
const WADE_DEPTH: float = 0.9

## Alle Wasser-Materialien der aktuellen Welt (DayNight setzt die Himmelsfarbe für die Spiegelung).
static var materials: Array[ShaderMaterial] = []
static var _sky: Color = Color(0.6, 0.75, 0.85)


## Beim Weltaufbau leeren (die alten Flächen sind weg).
static func reset() -> void:
	materials.clear()


static func set_sky(color: Color) -> void:
	_sky = color
	for mat: ShaderMaterial in materials:
		mat.set_shader_parameter(&"sky_color", color)


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


## Meer bis zum Horizont (Östliches Meer) samt Watboden: tiefer als WADE_DEPTH sinkt niemand ein.
static func sea(world: World, level: float, color: Color) -> void:
	var mesh := PlaneMesh.new()
	var extent: float = world.area.size + TerrainBackdrop.REACH * 2.0
	mesh.size = Vector2(extent, extent)
	mesh.subdivide_width = 0
	mesh.subdivide_depth = 0
	var node := MeshInstance3D.new()
	node.name = "Sea"
	node.mesh = mesh
	node.material_override = material(color, 0.0)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)
	node.position = Vector3(0.0, level, 0.0)
	var floor_body := StaticBody3D.new()
	floor_body.name = "SeaFloor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(world.area.size, 1.0, world.area.size)
	shape.shape = box
	floor_body.add_child(shape)
	world.add_child(floor_body)
	floor_body.position = Vector3(0.0, level - WADE_DEPTH - 0.5, 0.0)


static func material(color: Color, glow: float, flow: float = 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter(&"waves_nm", ProceduralTextures.get_texture(&"waves_normal"))
	mat.set_shader_parameter(&"sky_color", _sky)
	materials.append(mat)
	mat.set_shader_parameter(&"shallow_color", color)
	mat.set_shader_parameter(&"deep_color", color.darkened(0.65))
	mat.set_shader_parameter(&"glow", glow)
	mat.set_shader_parameter(&"flow", flow)
	return mat
