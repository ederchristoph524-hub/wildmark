class_name Npc
extends Node3D
## Ein Dorfbewohner: Figur in der Farbe seiner NPC-Art, Name über dem Kopf, Gespräch mit Aufgabe oder Tausch.

const WALK_SPEED: float = 1.2
const WANDER_JITTER: float = 2.0
const WAIT_MIN: float = 2.0
const WAIT_MAX: float = 7.0
## Dorfbewohner weiter weg sieht man nicht (spart Draw Calls in großen Siedlungen).
const VIEW: float = 70.0

var type: NpcTypeData = null
var title: String = ""
## Aufgabe, die dieser NPC vergibt (leer = keine).
var quest_id: StringName = &""
var offers_trade: bool = false
## Sekte der Siedlung und ob dieser Bewohner sie vertritt (Beitritt und Rang im Gespräch, siehe SectLife).
var sect_id: StringName = &""
var leader: bool = false
## Spaziergänger: geht zwischen Ankerpunkten der Siedlung (wander_points) hin und her.
var wander_points: Array[Vector3] = []
var _walk_target: Vector3 = Vector3.INF
var _wait: float = 0.0
## Robenfarbe (Klanfarbe); ohne Angabe die Farbe der NPC-Art.
var robe_color: Color = Color(0, 0, 0, 0)
var _model: PlayerModel = null
var _label: Label3D = null
var _time: float = 0.0


func setup(npc_type: NpcTypeData, npc_title: String, quest: StringName, trade: bool) -> void:
	type = npc_type
	title = npc_title
	quest_id = quest
	offers_trade = trade


func _ready() -> void:
	add_to_group(Player.GROUP_INTERACTABLES)
	_model = PlayerModel.new()
	var robe: Color = robe_color if robe_color.a > 0.0 else type.color
	_model.cloth_color = robe.darkened(0.45)
	_model.body_color = robe
	_model.show_aperture = false
	PlayerModel.vary_looks(_model, display_title())
	_model.view_distance = VIEW
	add_child(_model)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.pixel_size = 0.006
	_label.outline_size = 10
	_label.position.y = 2.25
	_label.visibility_range_end = 30.0
	add_child(_label)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	body.add_child(shape)
	add_child(body)


func _process(delta: float) -> void:
	_time += delta
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
	var near_player: bool = player != null and player.global_position.distance_to(global_position) < 6.0
	var speed: float = 0.0 if near_player or wander_points.is_empty() else _walk(delta)
	_model.animate(delta, speed)
	if near_player:
		var to_player: Vector3 = player.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-to_player.x, -to_player.z), clampf(delta * 4.0, 0.0, 1.0))
	_label.text = display_title() + _quest_mark()


## Geht zum nächsten Ziel (mit kurzen Pausen); liefert die Geschwindigkeit für die Laufanimation.
func _walk(delta: float) -> float:
	if _wait > 0.0:
		_wait -= delta
		return 0.0
	if _walk_target == Vector3.INF:
		var point: Vector3 = wander_points[randi() % wander_points.size()]
		_walk_target = point + Vector3(randf_range(-WANDER_JITTER, WANDER_JITTER), 0.0, randf_range(-WANDER_JITTER, WANDER_JITTER))
	var offset: Vector3 = _walk_target - global_position
	offset.y = 0.0
	if offset.length() < 0.4:
		_walk_target = Vector3.INF
		_wait = randf_range(WAIT_MIN, WAIT_MAX)
		return 0.0
	var step: Vector3 = offset.normalized() * minf(WALK_SPEED * delta, offset.length())
	var world: World = get_parent() as World
	var next: Vector3 = global_position + step
	global_position = world.ground_point(next.x, next.z) if world != null else next
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-offset.x, -offset.z), clampf(delta * 5.0, 0.0, 1.0))
	return WALK_SPEED


func display_title() -> String:
	return tr(title) if title != "" else tr(type.display_name)


## „!" = neue Aufgabe, „?" = Aufgabe abgebbar.
func _quest_mark() -> String:
	if quest_id == &"":
		return ""
	if Quests.state(quest_id) == "":
		return "  !"
	return "  ?" if Quests.is_complete(quest_id) else ""


func interact_label() -> String:
	return tr("Sprechen mit %s") % display_title()


func interact(_player: Player) -> void:
	EventBus.dialog_requested.emit(self)
