class_name WorldMaterials
extends RefCounted
## Geteilte, flach schattierte Materialien für Welt und Figuren (ein Material pro Farbe, spart Draw-Call-Wechsel).

static var _solid: Dictionary = {}
static var _vertex: StandardMaterial3D = null
static var _settlement: ShaderMaterial = null
static var _props: ShaderMaterial = null
static var _creatures: Dictionary[StringName, ShaderMaterial] = {}
const CREATURE_SHADER: String = "res://assets/shaders/creature.gdshader"
static var _vegetation: Dictionary[StringName, ShaderMaterial] = {}
const VEGETATION_SHADER: String = "res://assets/shaders/vegetation.gdshader"
const SETTLEMENT_SHADER: String = "res://assets/shaders/settlement.gdshader"


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


## Requisiten (Bauten, Felsen, Gräber, Brücken, Bestien): der Siedlungs-Shader ohne Nachtlicht – Holz, Stein und
## Putz nach Farbe, mit Relief.
static func props() -> ShaderMaterial:
	if _props == null:
		_props = ShaderMaterial.new()
		_props.shader = settlement().shader
		for id: StringName in [&"plaster", &"wood", &"tiles", &"stone"]:
			_props.set_shader_parameter(String(id) + "_tex", ProceduralTextures.get_texture(id))
			_props.set_shader_parameter(String(id) + "_nm", ProceduralTextures.get_texture(id + "_normal"))
		_props.set_shader_parameter(&"tiles_on_slopes", 0.0)
	return _props


## Bestien (Shader creature.gdshader): "fur" Fell, "smooth" glatte feuchte Haut (Schleime, Geister), "rock" Gestein
## (Golems), "scales" Schuppen und Panzer. Je Art ein geteiltes Material.
static func creature(kind: StringName) -> ShaderMaterial:
	if _creatures.has(kind):
		return _creatures[kind]
	var mat := ShaderMaterial.new()
	mat.shader = load(CREATURE_SHADER) as Shader
	var texture: StringName = {&"fur": &"fur", &"smooth": &"fur", &"rock": &"rock", &"scales": &"scales"}.get(kind, &"fur")
	mat.set_shader_parameter(&"skin_tex", ProceduralTextures.get_texture(texture))
	mat.set_shader_parameter(&"skin_nm", ProceduralTextures.get_texture(texture + "_normal"))
	mat.set_shader_parameter(&"kind", float({&"fur": 0, &"smooth": 1, &"rock": 2, &"scales": 3}.get(kind, 0)))
	mat.set_shader_parameter(&"skin_scale", 0.9 if kind == &"rock" else 1.4)
	_creatures[kind] = mat
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


## Pflanzen und Felsen (Shader vegetation.gdshader): "leafy" = Kronen mit Blattausschnitt und Blattkarten, "grass" =
## Grasbüschel-Karten, "small" = Farne, Bambus, Blumen ohne Ausschnitt, "rock" = Gestein. Je Art ein geteiltes Material.
static func vegetation(kind: StringName) -> ShaderMaterial:
	if _vegetation.has(kind):
		return _vegetation[kind]
	var mat := ShaderMaterial.new()
	mat.shader = load(VEGETATION_SHADER) as Shader
	for id: StringName in [&"bark", &"rock"]:
		mat.set_shader_parameter(String(id) + "_tex", ProceduralTextures.get_texture(id))
		mat.set_shader_parameter(String(id) + "_nm", ProceduralTextures.get_texture(id + "_normal"))
	mat.set_shader_parameter(&"leaves_tex", ProceduralTextures.get_texture(&"leaf_cover"))
	mat.set_shader_parameter(&"leaves_nm", ProceduralTextures.get_texture(&"leaves_normal"))
	mat.set_shader_parameter(&"card_tex", ProceduralTextures.get_texture(&"tuft" if kind == &"grass" else &"leaves"))
	match kind:
		&"leafy":
			mat.set_shader_parameter(&"cutout", 1.0)
			mat.set_shader_parameter(&"sway", 0.12)
			mat.set_shader_parameter(&"sway_height", 7.0)
		&"grass":
			mat.set_shader_parameter(&"sway", 0.05)
			mat.set_shader_parameter(&"sway_height", 0.6)
		&"rock":
			mat.set_shader_parameter(&"kind", 1.0)
			mat.set_shader_parameter(&"sway", 0.0)
		_:
			mat.set_shader_parameter(&"sway", 0.06)
			mat.set_shader_parameter(&"sway_height", 1.0)
	_vegetation[kind] = mat
	return mat


## Siedlungen: wie vertex_colored, dazu leuchten nachts markierte Fenster und Laternen (UV2, set_night_glow).
static func settlement() -> ShaderMaterial:
	if _settlement == null:
		_settlement = ShaderMaterial.new()
		_settlement.shader = load(SETTLEMENT_SHADER) as Shader
		for id: StringName in [&"plaster", &"wood", &"tiles", &"stone"]:
			_settlement.set_shader_parameter(String(id) + "_tex", ProceduralTextures.get_texture(id))
			_settlement.set_shader_parameter(String(id) + "_nm", ProceduralTextures.get_texture(id + "_normal"))
	return _settlement


## 0 am Tag, 1 in tiefer Nacht (DayNight).
static func set_night_glow(amount: float) -> void:
	settlement().set_shader_parameter(&"night_glow", clampf(amount, 0.0, 1.0))


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
