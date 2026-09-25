class_name PlayerModel
extends Node3D
## Figur eines Menschen (Spieler, Dorfbewohner, Gu-Meister): Robe in Klanfarben, schwingende Glieder beim Laufen,
## Schneidersitz beim Kultivieren und eine leuchtende Apertur in Rangfarbe.

const CHARACTER_SHADER: Shader = preload("res://assets/shaders/character.gdshader")
const BODY_COLOR: Color = Color(0.55, 0.42, 0.3)
const CLOTH_COLOR: Color = Color(0.36, 0.3, 0.22)
const SKIN_COLOR: Color = Color(0.86, 0.7, 0.55)
const HAIR_COLOR: Color = Color(0.12, 0.1, 0.09)
const SASH_COLOR: Color = Color(0.62, 0.45, 0.18)
## Haut- und Haarfarben für abwechslungsreiche Dorfbewohner.
const SKIN_TONES: Array[Color] = [Color(0.86, 0.7, 0.55), Color(0.8, 0.62, 0.46), Color(0.9, 0.76, 0.62), Color(0.72, 0.55, 0.4)]
const HAIR_TONES: Array[Color] = [Color(0.1, 0.08, 0.07), Color(0.16, 0.12, 0.1), Color(0.05, 0.05, 0.06), Color(0.55, 0.55, 0.55)]
const SASH_TONES: Array[Color] = [Color(0.62, 0.45, 0.18), Color(0.3, 0.3, 0.55), Color(0.55, 0.2, 0.18), Color(0.2, 0.42, 0.3)]
## Schrittweite und Schwung der Glieder.
const STEP_RATE: float = 2.1
const MAX_SWING: float = 0.62

## Kleidungsfarben (NPCs tragen die Farbe ihrer Art).
var cloth_color: Color = CLOTH_COLOR
var body_color: Color = BODY_COLOR
var skin_color: Color = SKIN_COLOR
var hair_color: Color = HAIR_COLOR
var sash_color: Color = SASH_COLOR
## Kopfbedeckung (CharacterMesh._hat); leer = Haarknoten.
var hat: StringName = &""
## Nur Gu-Meister zeigen die leuchtende Apertur.
var show_aperture: bool = true
var aperture_glow: MeshInstance3D = null
var sitting: bool = false
## Sichtweite der Figur (0 = unbegrenzt), für Dorfbewohner in großen Siedlungen.
var view_distance: float = 0.0
var _phase: float = 0.0
var _amount: float = 0.0
var _body: MeshInstance3D = null
var _material: ShaderMaterial = null


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = CHARACTER_SHADER
	_material.set_shader_parameter(&"fabric_tex", ProceduralTextures.get_texture(&"fabric"))
	_material.set_shader_parameter(&"fabric_nm", ProceduralTextures.get_texture(&"fabric_normal"))
	_material.set_shader_parameter(&"skin_color", skin_color)
	_material.set_shader_parameter(&"hair_color", hair_color)
	_body = MeshInstance3D.new()
	_body.material_override = _material
	add_child(_body)
	_body.mesh = CharacterMesh.build(_colors(), false)
	_body.visibility_range_end = view_distance
	if show_aperture:
		aperture_glow = MeshInstance3D.new()
		aperture_glow.mesh = MeshBuilder.sphere(0.07, 6, 4)
		aperture_glow.position = Vector3(0.0, 1.02, -0.13)
		aperture_glow.material_override = Fx.material(Color(0.5, 0.8, 0.4))
		aperture_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(aperture_glow)


## Wählt Haut, Haar und Schärpe anhand eines Namens (gleicher Name, gleiches Aussehen).
static func vary_looks(model: PlayerModel, seed_text: String) -> void:
	var h: int = absi(seed_text.hash())
	model.skin_color = SKIN_TONES[h % SKIN_TONES.size()]
	model.hair_color = HAIR_TONES[floori(h / 7.0) % HAIR_TONES.size()]
	model.sash_color = SASH_TONES[floori(h / 31.0) % SASH_TONES.size()]


func _colors() -> Dictionary:
	return {"robe": body_color, "sleeve": body_color.darkened(0.08), "trousers": cloth_color, "sash": sash_color, "skin": skin_color, "hair": hair_color, "hat": hat}


func set_rank_color(color: Color) -> void:
	if aperture_glow != null:
		aperture_glow.material_override = Fx.material(color)


## Schneidersitz (Kultivieren) oder Stehen.
func set_sitting(active: bool) -> void:
	if active == sitting or _body == null:
		return
	sitting = active
	_body.mesh = CharacterMesh.build(_colors(), active)
	if aperture_glow != null:
		aperture_glow.position.y = 1.02 - (CharacterMesh.HIP - CharacterMesh.SIT_HIP if active else 0.0)


## Leuchten der ganzen Figur (Aura beim Kultivieren), a = Stärke.
func set_glow(color: Color) -> void:
	if _material != null:
		_material.set_shader_parameter(&"glow_color", color)


## Glieder schwingen mit der Laufgeschwindigkeit; im Stand leichtes Atmen.
func animate(delta: float, speed: float) -> void:
	if _material == null:
		return
	var target: float = 0.0 if sitting else clampf(speed / 5.0, 0.0, 1.0) * MAX_SWING
	_amount = move_toward(_amount, target, delta * 3.0)
	_phase += delta * (speed * STEP_RATE if speed > 0.2 else 0.0)
	_material.set_shader_parameter(&"walk_phase", _phase)
	_material.set_shader_parameter(&"walk_amount", _amount)
	_body.position.y = absf(sin(_phase)) * 0.05 * (_amount / MAX_SWING) if not sitting else 0.0
