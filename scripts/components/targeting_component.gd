class_name TargetingComponent
extends Node
## Zielerfassung: weiches Ziel in Blickrichtung, harte Fixierung (Tab) mit Zielwechsel und Markierung über dem Ziel.

const MARKER_COLOR: Color = Color(1.0, 0.85, 0.3)
const LOCK_COLOR: Color = Color(1.0, 0.35, 0.25)
const MARKER_HEIGHT: float = 0.7
## Hindernisse werden nur anvisiert, wenn keine Bestie näher liegt.
const OBSTACLE_PENALTY: float = 12.0

var host: Combatant = null
## Weiches Ziel; freigegebene oder tote Ziele werden beim Lesen verworfen (Web-Export stürzt sonst ab).
var soft_target: Combatant = null:
	get:
		if soft_target != null and _invalid(soft_target):
			soft_target = null
		return soft_target
var locked_target: Combatant = null:
	get:
		if locked_target != null and _invalid(locked_target):
			locked_target = null
		return locked_target
## Blickrichtung, in der gesucht wird (setzt der Besitzer).
var view_forward: Vector3 = Vector3.FORWARD
var _marker: MeshInstance3D = null


func _init(owner_combatant: Combatant) -> void:
	host = owner_combatant
	name = "Targeting"


func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	mesh.radial_segments = 6
	mesh.rings = 3
	_marker = MeshInstance3D.new()
	_marker.mesh = mesh
	_marker.top_level = true
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.visible = false
	add_child(_marker)


func _physics_process(_delta: float) -> void:
	if locked_target != null and _too_far(locked_target):
		locked_target = null
	soft_target = locked_target if locked_target != null else find_soft_target()
	_update_marker()


## Nächster Gegner im Blickkegel, sonst der nächste in Reichweite.
func find_soft_target() -> Combatant:
	var b: BalanceData = Balance.values
	var best: Combatant = null
	var best_score: float = INF
	for candidate: Combatant in Combat.hostiles(host.get_tree(), host.team):
		var offset: Vector3 = candidate.global_position - host.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance > b.target_range:
			continue
		var angle: float = rad_to_deg(view_forward.angle_to(offset.normalized())) if distance > 0.1 else 0.0
		if angle > b.target_angle and distance > b.fist_range * 1.5:
			continue
		var score: float = distance + angle * 0.08 + (OBSTACLE_PENALTY if candidate.team == Combatant.TEAM_WORLD else 0.0)
		if score < best_score:
			best_score = score
			best = candidate
	return best


func toggle_lock() -> void:
	locked_target = null if locked_target != null else find_soft_target()


## Wechselt zum nächsten Gegner im Umkreis (nach Entfernung).
func switch_target() -> void:
	var candidates: Array[Combatant] = Combat.in_radius(Combat.hostiles(host.get_tree(), host.team), host.global_position, Balance.values.target_range)
	if candidates.is_empty():
		locked_target = null
		return
	candidates.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.global_position.distance_squared_to(host.global_position) < b.global_position.distance_squared_to(host.global_position))
	var index: int = candidates.find(locked_target if locked_target != null else soft_target)
	locked_target = candidates[(index + 1) % candidates.size()]


## Freigegeben, tot oder inzwischen verbündet (z. B. Gu-Meister nach dem Duell).
func _invalid(target: Combatant) -> bool:
	return not is_instance_valid(target) or target.is_dead() or target.team == host.team


func _too_far(target: Combatant) -> bool:
	return target.global_position.distance_to(host.global_position) > Balance.values.target_range * 1.5


func _update_marker() -> void:
	_marker.visible = soft_target != null
	if soft_target != null:
		_marker.global_position = soft_target.global_position + Vector3.UP * (soft_target.body_height + MARKER_HEIGHT)
		_marker.material_override = Fx.material(LOCK_COLOR if locked_target != null else MARKER_COLOR)
