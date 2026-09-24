class_name Npc
extends Node3D
## Ein Dorfbewohner: Figur in der Farbe seiner NPC-Art, Name über dem Kopf, Gespräch mit Aufgabe oder Tausch.

var type: NpcTypeData = null
var title: String = ""
## Aufgabe, die dieser NPC vergibt (leer = keine).
var quest_id: StringName = &""
var offers_trade: bool = false
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
	_model.animate(delta, 0.0)
	var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
	if player != null and player.global_position.distance_to(global_position) < 6.0:
		var to_player: Vector3 = player.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-to_player.x, -to_player.z), clampf(delta * 4.0, 0.0, 1.0))
	_label.text = display_title() + _quest_mark()


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
