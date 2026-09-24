class_name ChildhoodSteps
extends RefCounted
## Schritte des Kindheits-Tests (eigene Datei, weil Autoloads erst nach dem Start des Test-Skripts bekannt sind).

var _failures: PackedStringArray = []
var tree: SceneTree = null
var main: Main = null
var player: Player = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	await tree.physics_frame
	SaveSystem.save_path = "user://test_childhood.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	# Talent im Startmenü auf „Extrem“ gestellt, Physique zufällig: Der Talenttest beim Erwachen würfelt sie.
	EventBus.new_game_requested.emit({"childhood": true, "first_family": &"", "death_mode": &"standard", "talent_grade": PhysiqueEffects.GRADE, "apt": 100.0, "physique": &""})
	await _frames(20)
	player = main.player
	_check(Childhood.is_child() and GameState.gu.is_empty() and Childhood.tracker_text() != "", "Kindheit beginnt ohne Gu, mit Hinweis")
	await _test_safe_village()
	await _test_talk()
	await _test_gather()
	await _test_awakening()
	SaveSystem.delete_save()
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_childhood: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	tree.quit(0 if _failures.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _test_safe_village() -> void:
	main.world.spawner._timer = 0.0
	await _frames(30)
	_check(tree.get_nodes_in_group(Enemy.GROUP_ENEMIES).is_empty(), "als Kind kommen keine Bestien")
	_check(not PlayerActions.can_meditate(player) and not PlayerActions.can_eat_stone(player), "ohne Apertur kein Meditieren und kein Urstein")
	var awakenings: Array[int] = [0]
	EventBus.awakening_requested.connect(func() -> void: awakenings[0] += 1)
	_master().interact(player)
	_check(awakenings[0] == 0, "Klanlehrer weckt erst am Ende der Kindheit")


func _test_talk() -> void:
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is Npc and (node as Npc).quest_id == Childhood.STEPS[0]["npc_quest"]:
			node.call("interact", player)
	await _frames(2)
	_check(GameState.childhood_step == 1, "Gespräch mit dem Dorfältesten erledigt")
	_close_menus()
	await _frames(2)
	_check(SaveSystem.save_game() and SaveSystem.load_game() and GameState.childhood_step == 1, "Kindheit wird gespeichert und geladen")


func _test_gather() -> void:
	var bushes: Array[ResourceNode] = []
	for node: Node in tree.get_nodes_in_group(Player.GROUP_HARVESTABLE):
		var bush: ResourceNode = node as ResourceNode
		if bush != null and bush.item == &"beeren" and Vector2(bush.global_position.x, bush.global_position.z).length() < Village.FENCE_RADIUS:
			bushes.append(bush)
	_check(bushes.size() >= 2, "Beerenbüsche im Dorf (%d)" % bushes.size())
	for bush: ResourceNode in bushes:
		player.global_position = bush.global_position + Vector3(1.0, 0.5, 0.0)
		await _frames(2)
		for hit: int in ResourceNode.HITS_NEEDED:
			bush.harvest_hit(player)
		await _frames(90)
	_check(GameState.item_count(&"beeren") >= int(Childhood.STEPS[1]["count"]) and Childhood.is_awakening_step(), "Beeren gesammelt, Erwachen steht an")


func _test_awakening() -> void:
	var chosen: StringName = DataRegistry.gu_system().start_families[1]
	_master().interact(player)
	await _frames(2)
	var menu: AwakeningMenu = null
	for child: Node in main._menu_layer.get_children():
		if child is AwakeningMenu:
			menu = child
	_check(menu != null and tree.paused, "Erwachen öffnet Talenttest und Gu-Wahl")
	if menu == null:
		return
	menu.choose(chosen)
	menu.confirm()
	await _frames(3)
	_check(not Childhood.is_child() and GameState.first_family == chosen and GameState.gu.size() == 1, "erster Gu gewählt, Kindheit vorbei")
	_check(GameState.talent_grade == PhysiqueEffects.GRADE and GameState.apt == 100.0 and PhysiqueEffects.current() != null, "Extremes Talent mit Physique erwacht (%s)" % GameState.physique)
	_check(GameState.item_count(&"kristall") >= Main.START_STONES and not tree.paused, "Startausstattung erhalten, Spiel läuft")
	var duplicate_wild: bool = false
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is WildGu and not node.is_queued_for_deletion() and (node as WildGu).spot_id == StringName("wild_" + String(chosen)):
			duplicate_wild = true
	_check(not duplicate_wild, "wilder Gu der gewählten Familie verschwindet")
	_check(_master().interact_label().begins_with(tr("Duell")), "danach fordert man den Klanlehrer zum Duell")


func _master() -> GuMaster:
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is GuMaster:
			return node
	return null


func _close_menus() -> void:
	for child: Node in main._menu_layer.get_children():
		if child.has_method("close"):
			child.call("close")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		_failures.append(message)
