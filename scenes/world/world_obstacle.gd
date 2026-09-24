class_name WorldObstacle
extends Combatant
## Wiederverwendbares Welt-Hindernis (GU_SYSTEM.md, Abschnitt 8): reagiert auf Tags, Zustände und Pfade der Gu.
## Brennbare Hecke (Feuer), Wasserfläche (Eis), Felsbrocken (Wucht), Ruinenschalter (Blitz), Lichtsiegel (Licht), Blutsiegel (Blut-Pfad).

signal opened

const KIND_HEDGE: StringName = &"hecke"
const KIND_WATER: StringName = &"wasser"
const KIND_BOULDER: StringName = &"fels"
const KIND_SWITCH: StringName = &"schalter"
const KIND_LIGHT: StringName = &"lichtsiegel"
const KIND_BLOOD: StringName = &"blutsiegel"
const HINT_COOLDOWN: float = 4.0
const OPEN_TIME: float = 0.8
const LIGHT_REVEAL_RADIUS: float = 4.0

## Was das Hindernis auslöst: Tag des Treffers, Zustand oder Pfad.
const TRIGGERS: Dictionary[StringName, Dictionary] = {
	KIND_HEDGE: {"tags": [&"feuer"], "status": &"brand", "hint": "Die Dornenhecke ist trocken – Feuer könnte sie verbrennen."},
	KIND_WATER: {"tags": [&"eis"], "status": &"frost", "hint": "Tiefes Wasser. Wäre es gefroren, könnte man darüber gehen."},
	KIND_BOULDER: {"tags": [&"wucht"], "hint": "Ein schwerer Felsbrocken. Nur rohe Wucht bewegt ihn."},
	KIND_SWITCH: {"tags": [&"blitz"], "status": &"ladung", "hint": "Ein alter Ruinenschalter. Er wartet auf eine Ladung."},
	KIND_LIGHT: {"tags": [&"licht"], "hint": "Ein Lichtsiegel. Es schläft im Dunkeln."},
	KIND_BLOOD: {"path": &"blut", "hint": "Ein Blutsiegel des alten Klans. Nur Blut öffnet es."},
}

var id: StringName = &""
var kind: StringName = KIND_BOULDER
## Kollisionsformen und Modelle, die beim Öffnen verschwinden.
var blockers: Array[CollisionShape3D] = []
var closed_visuals: Array[Node3D] = []
## Modelle, die erst nach dem Öffnen erscheinen (z. B. Eis).
var open_visuals: Array[Node3D] = []
var is_open: bool = false
## Trefferradius (flach), damit Geschosse und Flächen das Hindernis erreichen.
var hit_radius: float = 1.2
var _hint_time: float = 0.0


func setup(obstacle_id: StringName, obstacle_kind: StringName, radius: float) -> void:
	id = obstacle_id
	kind = obstacle_kind
	hit_radius = radius


func _ready() -> void:
	display_name = String(kind)
	body_height = 2.0
	_init_combatant(TEAM_WORLD, 1000000.0)
	body_radius = hit_radius
	add_to_group(&"obstacles")
	for node: Node3D in open_visuals:
		node.visible = false
	if id in GameState.opened_obstacles:
		_set_open(false)


func _physics_process(delta: float) -> void:
	_hint_time = maxf(0.0, _hint_time - delta)
	if kind == KIND_LIGHT and not is_open and PassiveGu.flag("reveal"):
		var player: Node3D = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Node3D
		if player != null and player.global_position.distance_to(global_position) < LIGHT_REVEAL_RADIUS:
			open()


## Treffer lösen das Hindernis aus oder geben einen Hinweis; Schaden nimmt es nie.
func receive_hit(hit: HitInfo) -> void:
	if is_open or hit.is_dot:
		return
	if triggered_by(hit):
		open()
	elif _hint_time <= 0.0 and hit.team == TEAM_PLAYER:
		_hint_time = HINT_COOLDOWN
		EventBus.message.emit(tr(String(TRIGGERS[kind].get("hint", ""))), Color(0.85, 0.85, 0.7))


func triggered_by(hit: HitInfo) -> bool:
	var rule: Dictionary = TRIGGERS[kind]
	for tag: Variant in rule.get("tags", []):
		if tag in hit.tags:
			return true
	if rule.has("status") and hit.status == rule["status"]:
		return true
	return rule.has("path") and hit.path == rule["path"]


func open() -> void:
	if is_open:
		return
	GameState.opened_obstacles.append(id)
	_set_open(true)
	EventBus.message.emit(tr("Der Weg ist frei."), Color(1.0, 0.85, 0.3))
	opened.emit()


func _set_open(animated: bool) -> void:
	is_open = true
	for shape: CollisionShape3D in blockers:
		shape.set_deferred(&"disabled", true)
	for node: Node3D in open_visuals:
		node.visible = true
	for node: Node3D in closed_visuals:
		if animated:
			var tween: Tween = node.create_tween()
			tween.tween_property(node, "scale", Vector3(1.0, 0.05, 1.0), OPEN_TIME)
			tween.tween_callback(node.hide)
		else:
			node.hide()
	if animated:
		Fx.sphere(get_tree(), global_position + Vector3.UP, 2.5, Color(1.0, 0.9, 0.6, 0.4), 0.5)
