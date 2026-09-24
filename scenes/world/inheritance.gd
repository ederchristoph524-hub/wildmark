class_name Inheritance
extends Node3D
## Erbe eines verstorbenen Gu-Meisters (gebiete.json → orte, typ „erbe“): Felsspalte mit Siegelstein.
## Opfergabe → Wächter erwachen → sind alle besiegt, gibt das Erbe seine Gu (als wilde Gu zum Verfeinern) und Schätze frei.

const ROCK: Color = Color(0.42, 0.4, 0.37)
const ROCK_DARK: Color = Color(0.3, 0.29, 0.27)
const SEAL: Color = Color(0.85, 0.7, 0.35)
const CAVE: Color = Color(0.05, 0.04, 0.04)
const GUARD_DISTANCE: float = 7.0

enum State { SEALED, GUARDED, CLAIMED }

## Ortsdaten aus AreaData.places.
var data: Dictionary = {}
var state: State = State.SEALED
var _guards: Array[Enemy] = []
var _seal: MeshInstance3D = null
var _label: Label3D = null


func _ready() -> void:
	add_to_group(Player.GROUP_INTERACTABLES)
	if data["id"] in GameState.inheritances:
		state = State.CLAIMED
	_build_rocks()
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 48
	_label.pixel_size = 0.008
	_label.outline_size = 10
	_label.position = Vector3(0, 4.6, 1.5)
	_label.visibility_range_end = 40.0
	add_child(_label)
	_refresh()


## Felshügel mit dunkler Spalte und leuchtendem Siegelstein davor.
func _build_rocks() -> void:
	var b := MeshBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = String(data["id"]).hash()
	for i: int in 9:
		var angle: float = PI + (i - 4) * 0.33
		var offset := Vector3(cos(angle) * 3.2, 0.0, sin(angle) * 2.4 - 1.2)
		b.add(MeshBuilder.sphere(rng.randf_range(1.6, 2.4), 7, 4), MeshBuilder.at(offset + Vector3(0, 1.2, 0), Vector3(1.0, rng.randf_range(1.2, 1.8), 1.0)), ROCK if i % 2 == 0 else ROCK_DARK)
	b.add(MeshBuilder.sphere(3.0, 8, 4), MeshBuilder.at(Vector3(0, 2.6, -2.6), Vector3(1.4, 1.2, 1.0)), ROCK)
	b.add(MeshBuilder.box(Vector3(1.6, 2.6, 0.4)), MeshBuilder.at(Vector3(0, 1.3, 0.4)), CAVE)
	var rocks := MeshInstance3D.new()
	rocks.mesh = b.build()
	rocks.material_override = WorldMaterials.vertex_colored()
	add_child(rocks)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.0, 4.0, 4.0)
	shape.shape = box
	shape.position = Vector3(0, 2.0, -1.8)
	body.add_child(shape)
	add_child(body)
	_seal = MeshInstance3D.new()
	_seal.mesh = MeshBuilder.cylinder(0.6, 0.7, 1.4, 8)
	_seal.position = Vector3(0, 0.7, 1.6)
	_seal.material_override = WorldMaterials.glowing(SEAL)
	add_child(_seal)


func interact_label() -> String:
	match state:
		State.SEALED:
			return tr("Siegel berühren (Opfer: %s)") % _offering_text()
		State.GUARDED:
			return tr("Die Wächter sind erwacht!")
	return tr("Das Erbe ist leer")


func interact(_player: Player) -> void:
	if state != State.SEALED:
		return
	var offering: Dictionary = data["offering"]
	for item: StringName in offering:
		if GameState.item_count(item) < int(offering[item]):
			EventBus.message.emit(tr("Das Siegel verlangt: %s") % _offering_text(), Color(1.0, 0.6, 0.4))
			return
	for item: StringName in offering:
		GameState.take_item(item, int(offering[item]))
	EventBus.message.emit(tr(String(data["text"])), SEAL)
	_awaken_guards()


func _awaken_guards() -> void:
	var world: World = get_parent() as World
	var guards: Array = data["guards"]
	for i: int in guards.size():
		var angle: float = TAU * i / maxf(guards.size(), 1.0)
		var at: Vector3 = world.ground_point(global_position.x + cos(angle) * GUARD_DISTANCE, global_position.z + 2.0 + sin(angle) * GUARD_DISTANCE)
		var guard: Enemy = world.spawner.spawn(DataRegistry.enemy(guards[i]), at + Vector3.UP * 0.3)
		guard.home = global_position
		guard.persistent = true
		_guards.append(guard)
	state = State.GUARDED
	EventBus.message.emit(tr("Die Wächter des Erbes erwachen!"), Color(1.0, 0.36, 0.45))
	_refresh()
	if _guards.is_empty():
		_claim()


func _process(_delta: float) -> void:
	if state != State.GUARDED:
		return
	for guard: Enemy in _guards:
		if is_instance_valid(guard) and not guard.is_dead():
			return
	_claim()


## Belohnung: Gu des Erbes als wilde Gu vor der Spalte, Gegenstände direkt ins Gepäck.
func _claim() -> void:
	state = State.CLAIMED
	GameState.inheritances.append(data["id"])
	var reward: Dictionary = data["reward"]
	var world: World = get_parent() as World
	var spots: Array[Resource] = []
	for id: StringName in reward["support"]:
		spots.append(DataRegistry.support_gu(id))
	for id: StringName in reward["body"]:
		spots.append(DataRegistry.body_gu(id))
	for id: StringName in reward["gu"]:
		spots.append(DataRegistry.gu(id))
	for i: int in spots.size():
		var wild := WildGu.new()
		wild.setup(StringName("erbe_%s_%d" % [data["id"], i]), spots[i])
		world.add_child(wild)
		wild.global_position = global_position + Vector3(-1.5 + i * 1.5, 0.3, 3.2)
	var items: Dictionary = reward["items"]
	for item: StringName in items:
		GameState.add_item(item, int(items[item]))
	EventBus.message.emit(tr("Das Erbe öffnet sich: %s") % tr(String(data["name"])), SEAL)
	_refresh()


func _refresh() -> void:
	_seal.visible = state != State.CLAIMED
	_label.text = tr(String(data["name"])) + ("" if state != State.CLAIMED else "\n" + tr("(geöffnet)"))


func _offering_text() -> String:
	var parts: PackedStringArray = []
	var offering: Dictionary = data["offering"]
	for item: StringName in offering:
		parts.append("%d %s" % [int(offering[item]), tr(DataRegistry.item(item).display_name)])
	return ", ".join(parts) if not parts.is_empty() else tr("nichts")
