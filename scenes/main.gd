class_name Main
extends Node3D
## Hauptszene: Startmenü, Spielsitzung (Welt, Spieler, HUD), Menüs mit Pause, automatisches Speichern und Tod.

## Startausstattung: etwas Urstein und Futter für drei Fütterungen des ersten Gu.
const START_STONES: int = 2
const START_FEEDINGS: int = 3
## Am Handy wird die Oberfläche größer skaliert, damit Schrift mindestens etwa 14 px hat (GDD, UI).
const TOUCH_UI_SCALE: float = 1.3

var world: World = null
var player: Player = null
var hud: Hud = null
var _menu_layer: CanvasLayer = null
var _start_menu: StartMenu = null
var _overlay: Control = null
var _autosave: float = 0.0


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		get_tree().root.content_scale_factor = TOUCH_UI_SCALE
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_layer)
	EventBus.new_game_requested.connect(_on_new_game)
	EventBus.continue_requested.connect(_on_continue)
	EventBus.return_to_menu_requested.connect(show_start_menu)
	EventBus.player_died.connect(_on_player_died)
	EventBus.reaction_triggered.connect(_on_reaction)
	show_start_menu()


func show_start_menu() -> void:
	_end_session()
	_start_menu = StartMenu.new()
	_menu_layer.add_child(_start_menu)


func _on_new_game(options: Dictionary) -> void:
	GameState.reset(options)
	_start_session()
	var family: GuFamilyData = DataRegistry.family(GameState.first_family)
	GameState.add_gu(GuInstance.create(family.member_for_rank(1).id))
	GameState.essence = player.aperture.capacity()
	GameState.add_item(&"kristall", START_STONES)
	GameState.add_item(family.feed_item, family.feed_amount * START_FEEDINGS)
	var progression: ProgressionData = DataRegistry.progression()
	EventBus.message.emit(tr("Deine Apertur ist erwacht: Talent %s (%d %%).") % [GameState.talent_grade, roundi(GameState.apt)], progression.talent_colors.get(GameState.talent_grade, UiTheme.ACCENT))
	EventBus.message.emit(tr("Dein erster Gu: %s. Wilde Gu leuchten irgendwo im Dschungel.") % tr(family.member_for_rank(1).display_name), UiTheme.ACCENT)
	SaveSystem.save_game()


func _on_continue() -> void:
	if not SaveSystem.load_game():
		EventBus.message.emit(tr("Spielstand konnte nicht geladen werden"), UiTheme.DANGER)
		return
	_start_session()
	EventBus.message.emit(tr("Willkommen zurück, Tag %d.") % GameState.day, UiTheme.ACCENT)


func _start_session() -> void:
	_end_session()
	world = World.new()
	add_child(world)
	if GameState.position == Vector3.ZERO:
		GameState.position = world.spawn_point()
		GameState.rest_point = GameState.position
	player = Player.new()
	world.entities.add_child(player)
	player.global_position = GameState.position + Vector3.UP * 0.3
	hud = Hud.new()
	hud.player = player
	add_child(hud)
	GameState.active = true
	_autosave = Balance.values.autosave_interval
	get_tree().paused = false


func _end_session() -> void:
	GameState.active = false
	get_tree().paused = false
	for node: Node in [world, hud, _start_menu, _overlay]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	for child: Node in _menu_layer.get_children():
		child.queue_free()
	world = null
	player = null
	hud = null
	_start_menu = null
	_overlay = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if not GameState.active or get_tree().paused:
		return
	_autosave -= delta
	if _autosave <= 0.0:
		_autosave = Balance.values.autosave_interval
		if player != null and not player.is_dead() and SaveSystem.save_game():
			EventBus.message.emit(tr("Automatisch gespeichert"), UiTheme.MUTED)


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.active or player == null or player.is_dead():
		return
	if event.is_action_pressed(&"gu_menu"):
		_open_menu(GuMenu.new())
	elif event.is_action_pressed(&"pause_menu"):
		_open_menu(PauseMenu.new())


## Öffnet ein Menü und pausiert das Spiel, bis es geschlossen wird.
func _open_menu(menu: Control) -> void:
	get_viewport().set_input_as_handled()
	if menu is GuMenu:
		(menu as GuMenu).player = player
	hud.touch.release_all()
	hud.touch.visible = false
	hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_menu_layer.add_child(menu)
	menu.connect(&"closed", _on_menu_closed)


func _on_menu_closed() -> void:
	get_tree().paused = false
	if hud != null:
		hud.visible = true
		hud.touch.visible = DisplayServer.is_touchscreen_available()


func _on_reaction(reaction_id: StringName, _where: Vector3) -> void:
	if reaction_id in GameState.seen_reactions:
		return
	GameState.seen_reactions.append(reaction_id)
	var reaction: ReactionData = DataRegistry.reaction(reaction_id)
	EventBus.message.emit(tr("Neue Reaktion entdeckt: %s – im Kombinationsbuch vermerkt.") % tr(reaction.display_name), Color(1.0, 0.85, 0.3))


func _on_player_died() -> void:
	var alive: bool = DeathRules.apply(player.global_position)
	_overlay = DeathScreen.create(DeathRules.description(GameState.death_mode), not alive)
	_menu_layer.add_child(_overlay)
	if alive:
		get_tree().create_timer(Balance.values.respawn_delay).timeout.connect(_respawn)


func _respawn() -> void:
	if player == null or not is_instance_valid(player):
		return
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	player.respawn(GameState.rest_point)
	if not GameState.loot_sack.is_empty():
		Pickup.spawn(get_tree(), GameState.loot_sack["position"], GameState.loot_sack["items"], true)
	SaveSystem.save_game()
