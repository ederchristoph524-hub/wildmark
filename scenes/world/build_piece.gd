class_name BuildPiece
extends StaticBody3D
## Ein gebautes Lagerteil: Wände blockieren, Fackeln und Feuer leuchten, das Lagerfeuer ist ein Ruheort,
## das Bett setzt den Wiederbelebungspunkt und lässt bis zum Morgen schlafen, die Falle trifft die erste Bestie.

const GROUP: StringName = &"build_pieces"
const WOOD: Color = Color(0.5, 0.36, 0.22)
const STONE_COLOR: Color = Color(0.52, 0.52, 0.5)
const TRAP_DAMAGE: float = 30.0
const TRAP_RADIUS: float = 0.9
const FIRE_HEAL_PER_SECOND: float = 3.0

var part: BuildData = null
var entry: Dictionary = {}


func setup(build_part: BuildData, saved_entry: Dictionary) -> void:
	part = build_part
	entry = saved_entry
	collision_layer = 1
	collision_mask = 0


func _ready() -> void:
	add_to_group(GROUP)
	var b := MeshBuilder.new()
	match part.id:
		&"wand":
			_box_body(b, Vector3(2.6, 2.0, 0.3), WOOD)
		&"steinwand":
			_box_body(b, Vector3(2.6, 2.2, 0.5), STONE_COLOR)
		&"fackel":
			b.add(MeshBuilder.cylinder(0.06, 0.08, 1.6, 5), MeshBuilder.at(Vector3.UP * 0.8), WOOD)
			_flame(Vector3.UP * 1.75, 0.18)
		&"feuer":
			var fire := Campfire.new()
			fire.build_tent = false
			add_child(fire)
		&"bett":
			_box_body(b, Vector3(1.0, 0.4, 2.0), WOOD)
			b.add(MeshBuilder.box(Vector3(0.9, 0.15, 1.8)), MeshBuilder.at(Vector3.UP * 0.45), Color(0.75, 0.7, 0.6))
			add_to_group(Player.GROUP_INTERACTABLES)
		&"falle":
			b.add(MeshBuilder.cylinder(0.6, 0.6, 0.08, 8), MeshBuilder.at(Vector3.UP * 0.04), Color(0.4, 0.38, 0.35))
			for i: int in 6:
				b.add(MeshBuilder.cylinder(0.0, 0.05, 0.3, 3), MeshBuilder.at(Vector3(cos(i * 1.05) * 0.4, 0.15, sin(i * 1.05) * 0.4)), Color(0.7, 0.7, 0.7))
		_:
			b.add(MeshBuilder.box(Vector3(1.6, 0.08, 1.6)), MeshBuilder.at(Vector3.UP * 0.04), WOOD)
	var mesh := MeshInstance3D.new()
	mesh.mesh = b.build()
	mesh.material_override = WorldMaterials.vertex_colored()
	add_child(mesh)
	if part.light > 0.0 and part.id != &"feuer":
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.7, 0.4)
		light.omni_range = part.light * 2.0
		light.position.y = 1.8
		add_child(light)


func _box_body(b: MeshBuilder, size: Vector3, color: Color) -> void:
	b.add(MeshBuilder.box(size), MeshBuilder.at(Vector3.UP * size.y * 0.5), color)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y * 0.5
	add_child(shape)


func _flame(at: Vector3, radius: float) -> void:
	var flame := MeshInstance3D.new()
	flame.mesh = MeshBuilder.cylinder(0.0, radius, radius * 3.0, 5)
	flame.position = at
	flame.material_override = Fx.material(Campfire.FIRE_COLOR)
	add_child(flame)


func _physics_process(_delta: float) -> void:
	if part.id != &"falle":
		return
	for enemy: Combatant in Combat.in_radius(Combat.hostiles(get_tree(), Combatant.TEAM_PLAYER), global_position, TRAP_RADIUS):
		if enemy is Enemy:
			enemy.receive_hit(HitInfo.create(TRAP_DAMAGE, null, Combatant.TEAM_PLAYER))
			Fx.sphere(get_tree(), global_position + Vector3.UP * 0.4, 1.0, Color(0.8, 0.8, 0.8, 0.6), 0.25)
			GameState.buildings.erase(entry)
			queue_free()
			return


func interact_label() -> String:
	return tr("Schlafen (Wiederbelebungspunkt, speichern)")


## Bett: Wiederbelebungspunkt, volle Heilung, nachts bis zum Morgen schlafen, speichern.
func interact(player: Player) -> void:
	player.heal(player.health.max_hp * Balance.values.bed_heal)
	GameState.rest_point = global_position + Vector3.UP * 0.5
	if Formulas.is_night(Balance.values, GameState.time_of_day):
		GameState.time_of_day = 0.0
		GameState.day += 1
		EventBus.message.emit(tr("Du schläfst bis zum Morgen."), Color(0.8, 0.85, 1.0))
	if SaveSystem.save_game():
		EventBus.message.emit(tr("Hier wachst du nach dem Tod auf. Spiel gespeichert."), Color(0.85, 0.75, 0.5))
