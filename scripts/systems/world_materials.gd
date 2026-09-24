class_name WorldMaterials
extends RefCounted
## Geteilte, flach schattierte Materialien für Welt und Figuren (ein Material pro Farbe, spart Draw-Call-Wechsel).

static var _solid: Dictionary = {}
static var _vertex: StandardMaterial3D = null


static func solid(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html(true)
	if _solid.has(key):
		return _solid[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	_solid[key] = mat
	return mat


## Material, das Vertex-Farben nutzt (Gelände, Bäume).
static func vertex_colored() -> StandardMaterial3D:
	if _vertex == null:
		_vertex = StandardMaterial3D.new()
		_vertex.vertex_color_use_as_albedo = true
		# Farben sind im sRGB-Raum angegeben (wie albedo_color), sonst wirkt alles ausgewaschen.
		_vertex.vertex_color_is_srgb = true
		_vertex.roughness = 1.0
		_vertex.metallic_specular = 0.1
	return _vertex


static func glowing(color: Color) -> StandardMaterial3D:
	var key: String = "glow_" + color.to_html(true)
	if _solid.has(key):
		return _solid[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	_solid[key] = mat
	return mat
