class_name Telegraph
extends MeshInstance3D
## Roter Bodenindikator vor starken Angriffen (KAMPFSYSTEM: keine Treffer ohne Vorwarnung). Rot ist nur für Gefahr reserviert.

const DANGER_COLOR: Color = Color(1.0, 0.15, 0.1, 0.45)
const HEIGHT_OFFSET: float = 0.08

static var _disc: CylinderMesh = null

var duration: float = 0.5
var _elapsed: float = 0.0


## Scheibe (radius) oder Rechteck (length > 0) am Boden, wächst während duration.
static func show_disc(tree: SceneTree, center: Vector3, radius: float, time: float) -> Telegraph:
	if _disc == null:
		_disc = CylinderMesh.new()
		_disc.top_radius = 1.0
		_disc.bottom_radius = 1.0
		_disc.height = 0.04
		_disc.radial_segments = 20
		_disc.rings = 1
	var telegraph := Telegraph.new()
	telegraph.mesh = _disc
	telegraph.duration = time
	telegraph.material_override = Fx.material(DANGER_COLOR)
	telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Combat.fx_parent(tree).add_child(telegraph)
	telegraph.global_position = center + Vector3.UP * HEIGHT_OFFSET
	telegraph.scale = Vector3(radius * 0.2, 1.0, radius * 0.2)
	telegraph.set_meta(&"radius", radius)
	return telegraph


static func show_line(tree: SceneTree, from: Vector3, to: Vector3, width: float, time: float) -> Telegraph:
	var telegraph := Telegraph.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.04, maxf(from.distance_to(to), 0.1))
	telegraph.mesh = box
	telegraph.duration = time
	telegraph.material_override = Fx.material(DANGER_COLOR)
	telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Combat.fx_parent(tree).add_child(telegraph)
	telegraph.global_position = (from + to) * 0.5 + Vector3.UP * HEIGHT_OFFSET
	var flat: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	if flat.length() > 0.01:
		telegraph.look_at(telegraph.global_position + flat, Vector3.UP)
	return telegraph


func _process(delta: float) -> void:
	_elapsed += delta
	if has_meta(&"radius"):
		var radius: float = float(get_meta(&"radius"))
		var grow: float = clampf(_elapsed / maxf(duration, 0.01), 0.2, 1.0)
		scale = Vector3(radius * grow, 1.0, radius * grow)
	if _elapsed >= duration + 0.05:
		queue_free()
