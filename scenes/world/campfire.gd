class_name Campfire
extends Node3D
## Lagerfeuer als Ruheort: Rasten heilt, setzt den Wiederbelebungspunkt und speichert. Bestien meiden das Lager.

const FIRE_COLOR: Color = Color(1.0, 0.55, 0.15)
const EMBER_COLOR: Color = Color(1.0, 0.85, 0.3)
const LOG_COLOR: Color = Color(0.35, 0.24, 0.15)
const TENT_COLOR: Color = Color(0.6, 0.5, 0.35)
const STONE_COLOR: Color = Color(0.45, 0.45, 0.43)

## Das Dorffeuer hat ein Zelt daneben, ein selbst gebautes Lagerfeuer nicht.
var build_tent: bool = true
var _flames: Node3D = null
var _time: float = 0.0


func _ready() -> void:
	add_to_group(Player.GROUP_INTERACTABLES)
	var ground := MeshBuilder.new()
	for i: int in 8:
		var angle: float = i * TAU / 8.0
		ground.add(MeshBuilder.sphere(0.22, 5, 3), MeshBuilder.at(Vector3(cos(angle) * 0.8, 0.1, sin(angle) * 0.8)), STONE_COLOR)
	ground.add(MeshBuilder.cylinder(0.12, 0.12, 1.3, 5), MeshBuilder.at(Vector3(0, 0.15, 0), Vector3.ONE, Vector3(0, 0.4, PI * 0.5)), LOG_COLOR)
	ground.add(MeshBuilder.cylinder(0.12, 0.12, 1.3, 5), MeshBuilder.at(Vector3(0, 0.2, 0), Vector3.ONE, Vector3(0, -0.8, PI * 0.5)), LOG_COLOR)
	_add_mesh(ground.build(), WorldMaterials.props())
	_flames = Node3D.new()
	add_child(_flames)
	var flame := MeshInstance3D.new()
	flame.mesh = MeshBuilder.cylinder(0.0, 0.45, 1.1, 6)
	flame.position.y = 0.65
	flame.material_override = Fx.material(FIRE_COLOR)
	_flames.add_child(flame)
	var core := MeshInstance3D.new()
	core.mesh = MeshBuilder.cylinder(0.0, 0.25, 0.7, 5)
	core.position.y = 0.45
	core.material_override = Fx.material(EMBER_COLOR)
	_flames.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = FIRE_COLOR
	light.omni_range = 9.0
	light.light_energy = 1.6
	light.position.y = 1.2
	add_child(light)
	if build_tent:
		_build_tent()


func _build_tent() -> void:
	var tent := MeshBuilder.new()
	tent.add(MeshBuilder.cylinder(0.0, 1.6, 2.0, 4), MeshBuilder.at(Vector3(4.0, 1.0, -2.5), Vector3(1.0, 1.0, 1.3), Vector3(0, PI * 0.25, 0)), TENT_COLOR)
	tent.add(MeshBuilder.box(Vector3(0.8, 0.6, 0.6)), MeshBuilder.at(Vector3(-3.0, 0.3, -2.0)), Color(0.5, 0.36, 0.2))
	tent.add(MeshBuilder.box(Vector3(0.6, 0.5, 0.6)), MeshBuilder.at(Vector3(-3.1, 0.85, -2.0), Vector3.ONE, Vector3(0, 0.4, 0)), Color(0.45, 0.32, 0.18))
	_add_mesh(tent.build(), WorldMaterials.props())
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 2.4)
	shape.shape = box
	shape.position = Vector3(4.0, 1.0, -2.5)
	body.add_child(shape)
	add_child(body)


func _add_mesh(mesh: Mesh, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	add_child(node)


func _process(delta: float) -> void:
	_time += delta
	_flames.scale = Vector3(1.0 + sin(_time * 9.0) * 0.08, 1.0 + sin(_time * 7.0) * 0.15, 1.0 + cos(_time * 8.0) * 0.08)


func interact_label() -> String:
	return tr("Rasten (Heilen, Speichern)")


func interact(player: Player) -> void:
	player.heal(player.health.max_hp)
	player.status.clear_negative()
	GameState.rest_point = global_position + Vector3(2.0, 0.5, 2.0)
	if SaveSystem.save_game():
		EventBus.message.emit(tr("Du rastest am Feuer. Spiel gespeichert – hier wachst du nach dem Tod auf."), EMBER_COLOR)
