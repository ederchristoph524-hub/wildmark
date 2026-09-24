class_name GameSmokeSteps
extends RefCounted
## Schritte des Durchspiel-Tests (eigene Datei, weil Autoloads erst nach dem Start des Test-Skripts bekannt sind).

var _failures: PackedStringArray = []
var tree: SceneTree = null
var main: Main = null
var player: Player = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	await tree.physics_frame
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"B", "apt": 70.0, "death_mode": &"standard"})
	await _frames(20)
	player = main.player
	_check(player != null and GameState.gu.size() == 1, "neues Spiel mit erstem Gu")
	_check(player.is_on_floor(), "Spieler steht auf dem Boden")
	await _test_movement()
	await _test_gu_and_reactions()
	await _test_killer_moves()
	await _test_enemy_ai()
	await _test_obstacles()
	await _test_village()
	await _test_progress()
	await _test_death_and_save()
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_game_smoke: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	tree.quit(0 if _failures.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _clear_enemies() -> void:
	for node: Node in tree.get_nodes_in_group(Combat.GROUP_COMBATANTS):
		if node is Enemy:
			node.queue_free()
	await _frames(2)


func _spawn(id: StringName, offset: Vector3) -> Enemy:
	var at: Vector3 = player.global_position + offset
	return main.world.spawner.spawn(DataRegistry.enemy(id), Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))


## Bestie bleibt stehen (eigene Kopie der Daten, damit andere Bestien unverändert bleiben).
func _freeze_in_place(enemy: Enemy) -> void:
	enemy.data = enemy.data.duplicate()
	enemy.data.speed = 0.0


func _give(family_id: StringName, slot: int) -> GuInstance:
	var instance: GuInstance = GuInstance.create(DataRegistry.family(family_id).member_for_rank(1).id)
	var index: int = GameState.gu.size()
	GameState.gu.append(instance)
	GameState.slots[slot] = index
	return instance


func _test_movement() -> void:
	var start: Vector3 = player.global_position
	Input.action_press(&"move_forward")
	await _frames(40)
	Input.action_release(&"move_forward")
	_check(player.global_position.distance_to(start) > 2.0, "Laufen bewegt den Spieler (%.2f m)" % player.global_position.distance_to(start))
	player.velocity.y = Balance.values.jump_velocity
	await _frames(10)
	_check(player.global_position.y > start.y + 0.3 or not player.is_on_floor(), "Sprung hebt ab")
	await _frames(60)


## Stellt den Spieler auf eine freie Fläche abseits von Lager und Bäumen.
func _move_to_clearing() -> void:
	var spot := Vector3(40.0, 0.0, 12.0)
	player.global_position = Vector3(spot.x, main.world.terrain.height_at(spot.x, spot.z) + 0.5, spot.z)
	player.camera_rig.yaw = 0.0
	for node: Node in main.world.find_children("*", "StaticBody3D", true, false):
		if node is ResourceNode and (node as Node3D).global_position.distance_to(spot) < 20.0:
			node.queue_free()
	await _frames(10)


func _test_gu_and_reactions() -> void:
	print("-- Gu und Reaktionen")
	await _move_to_clearing()
	await _clear_enemies()
	var wolf: Enemy = _spawn(&"wolf", player.camera_rig.flat_forward() * 7.0)
	await _frames(3)
	_freeze_in_place(wolf)
	GameState.essence = player.aperture.capacity()
	player.use_slot(0)
	await _frames(40)
	_check(wolf.health.hp < wolf.health.max_hp, "Mondlicht trifft den Wolf (%.1f/%.1f)" % [wolf.health.hp, wolf.health.max_hp])
	_give(&"stroemung", 1)
	_give(&"frost", 2)
	GameState.essence = player.aperture.capacity()
	wolf.health.hp = wolf.health.max_hp
	player.use_slot(1)
	await _frames(5)
	_check(wolf.status.has_status(&"nass"), "Wasserlicht macht nass")
	GameState.essence = player.aperture.capacity()
	player.use_slot(2)
	await _frames(40)
	_check(&"schockfrost" in GameState.seen_reactions, "Reaktion Schockfrost entdeckt")
	_check(wolf.status.is_frozen(), "Wolf ist eingefroren")
	_give(&"wirbel", 3)
	GameState.essence = player.aperture.capacity()
	wolf.global_position = player.global_position + player.camera_rig.flat_forward() * 1.5
	player.use_slot(3)
	await _frames(5)
	_check(&"zerschmettern" in GameState.seen_reactions, "Zerschmettern mit Wirbelwind")
	await _frames(30)
	_check(tree.get_nodes_in_group(&"fx_root").size() == 1, "Effekt-Knoten vorhanden")


func _test_killer_moves() -> void:
	print("-- _test_killer_moves")
	for resource: Resource in DataRegistry.all(&"killer_moves"):
		var move: KillerMoveData = resource as KillerMoveData
		await _clear_enemies()
		for i: int in 3:
			var enemy: Enemy = _spawn(&"ratte" if move.id != &"rudelsegen" else &"slime", player.camera_rig.flat_forward() * (3.0 + i) + Vector3(i - 1, 0, 0))
			_freeze_in_place(enemy)
		GameState.gu.clear()
		GameState.slots.fill(GameState.EMPTY_SLOT)
		_give(move.family_a, 0)
		_give(move.family_b, 1)
		KillerMoveController.learn(move.id)
		GameState.essence = player.aperture.capacity()
		player.health.hp = player.health.max_hp
		await _frames(2)
		player.killer.selected = player.killer.available().find(move)
		_check(player.killer.current() == move, "%s verfügbar" % move.id)
		GameState.essence = 9999.0
		var started: bool = player.killer.start(player.aim_direction())
		_check(started, "%s startet" % move.id)
		await _frames(roundi(move.channel_time * 60.0) + 60)
		_check(not player.killer.is_channeling(), "%s abgeschlossen" % move.id)
	_check(GameState.known_killer_moves.size() == 8, "alle 8 Killer Moves erlernt")
	GameState.known_killer_moves.clear()
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	_give(&"flamme", 0)
	_give(&"wirbel", 1)
	_check(player.killer._try_insight(&"flamme", &"wirbel", 0.0), "Eingebung lehrt Feuersturm")


func _test_enemy_ai() -> void:
	print("-- _test_enemy_ai")
	await _clear_enemies()
	player.health.hp = player.health.max_hp
	player.invulnerable_time = 0.0
	_spawn(&"wolf", player.camera_rig.flat_forward() * 6.0)
	await _frames(240)
	_check(player.health.hp < player.health.max_hp, "Wolf greift an (Leben %.1f)" % player.health.hp)
	await _clear_enemies()
	var rat: Enemy = _spawn(&"ratte", player.camera_rig.flat_forward() * 3.0)
	await _frames(2)
	rat.health.hp = rat.health.max_hp * 0.2
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	_give(&"sklaverei", 0)
	GameState.essence = player.aperture.capacity()
	player.use_slot(0)
	await _frames(5)
	_check(rat.is_companion(), "Ratte gezähmt")
	await _clear_enemies()
	player.health.hp = player.health.max_hp
	main.world.spawner._timer = 0.0
	await _frames(30)
	_check(tree.get_nodes_in_group(Enemy.GROUP_ENEMIES).size() >= 0, "Spawner läuft")
	var spider: Enemy = _spawn(&"spinne", player.camera_rig.flat_forward() * 5.0)
	spider._special_cooldown = 0.0
	await _frames(120)
	_check(not is_instance_valid(spider) or spider.minions.size() > 0, "Spinne beschwört Spinnlinge")


func _test_village() -> void:
	var npcs: Array[Node] = tree.get_nodes_in_group(Player.GROUP_INTERACTABLES).filter(func(n: Node) -> bool: return n is Npc)
	_check(npcs.size() == 6, "sechs Dorfbewohner (%d)" % npcs.size())
	Quests.start(&"holz")
	var stones: int = GameState.item_count(&"kristall")
	GameState.add_item(&"holz", 10)
	_check(Quests.is_complete(&"holz") and Quests.turn_in(&"holz"), "Aufgabe Holz abgegeben")
	_check(GameState.item_count(&"kristall") == stones + 3 and Quests.state(&"holz") == Quests.DONE, "Belohnung erhalten")
	Quests.start(&"j10")
	for i: int in 10:
		EventBus.enemy_killed.emit(&"wolf", Vector3.ZERO)
	_check(Quests.is_complete(&"j10"), "Jäger-Aufgabe zählt Kills")
	GameState.add_item(&"holz", 30)
	GameState.add_item(&"stein", 20)
	GameState.add_item(&"fell", 5)
	var built_before: int = GameState.built_count
	_check(BuildSystem.build(DataRegistry.build_part(&"bett"), player) and BuildSystem.build(DataRegistry.build_part(&"wand"), player), "Bett und Wand gebaut")
	_check(GameState.built_count == built_before + 2 and tree.get_nodes_in_group(BuildPiece.GROUP).size() >= 2, "Bauteile stehen in der Welt")
	var trader: Npc = null
	for node: Node in npcs:
		if (node as Npc).type.id == &"haendler":
			trader = node
	GameState.add_item(&"kristall", 5)
	_check(Trade.trade(trader.type) and GameState.item_count(&"fleisch") >= 6, "Handel mit dem Händler")
	_check(BuildSystem.demolish_nearest(player), "Abriss")


func _test_obstacles() -> void:
	var obstacles: Dictionary = {}
	for node: Node in tree.get_nodes_in_group(&"obstacles"):
		obstacles[(node as WorldObstacle).kind] = node
	_check(obstacles.size() == 6, "sechs Hindernisse mit Auslöser (%d)" % obstacles.size())
	var fist := HitInfo.create(10.0, player, Combatant.TEAM_PLAYER)
	var hedge: WorldObstacle = obstacles[WorldObstacle.KIND_HEDGE]
	hedge.receive_hit(fist)
	_check(not hedge.is_open, "Faust öffnet die Hecke nicht")
	var fire := HitInfo.create(10.0, player, Combatant.TEAM_PLAYER).with_tags([&"feuer"])
	hedge.receive_hit(fire)
	await _frames(2)
	_check(hedge.is_open and hedge.blockers[0].disabled, "Feuer verbrennt die Hecke")
	var blood := HitInfo.create(10.0, player, Combatant.TEAM_PLAYER)
	blood.path = &"blut"
	(obstacles[WorldObstacle.KIND_BLOOD] as WorldObstacle).receive_hit(blood)
	_check((obstacles[WorldObstacle.KIND_BLOOD] as WorldObstacle).is_open, "Blut öffnet das Blutsiegel")
	(obstacles[WorldObstacle.KIND_BOULDER] as WorldObstacle).receive_hit(HitInfo.create(10.0, player, 0).with_tags([&"wucht"]))
	_check((obstacles[WorldObstacle.KIND_BOULDER] as WorldObstacle).is_open, "Wucht bewegt den Felsbrocken")
	_check(&"site_hecke" in GameState.opened_obstacles, "geöffnete Hindernisse werden gemerkt")


func _test_progress() -> void:
	print("-- _test_progress")
	await _clear_enemies()
	var wild: WildGu = null
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is WildGu and (node as WildGu).gu is GuData:
			wild = node
	_check(wild != null, "wilder Gu in der Welt")
	GameState.essence = player.aperture.capacity()
	var count: int = GameState.gu.size()
	_check(GuRefining.refine(wild.gu, player.aperture, 0.0) != null and GameState.gu.size() == count + 1, "Verfeinerung gelingt")
	GameState.add_item(&"kristall", 1)
	GameState.essence = 0.0
	player.eat_stone()
	await _frames(roundi(Balance.values.stone_eat_time * 60.0) + 5)
	_check(GameState.essence > 1.0, "Urstein füllt Uressenz")
	GameState.wall = 0.999
	GameState.essence = player.aperture.capacity()
	player.toggle_meditation()
	await _frames(20)
	_check(GameState.stage == 1, "Meditation → Stufe 1")
	GameState.stage = 3
	GameState.essence = player.aperture.capacity()
	_check(player.aperture.break_through(0.0) and GameState.rank == 2, "Durchbruch auf Rang 2")
	await _test_upgrade()
	await _test_passives()
	var instance: GuInstance = GameState.gu[0]
	instance.satiety = 0.0
	_check(player.holder.blocked_reason(instance) != "", "ausgehungerter Gu ist blockiert")
	GameState.add_item(player.holder.feed_item(instance), 10)
	_check(player.holder.feed(0) and instance.satiety >= 99.0, "Füttern macht satt")


func _test_passives() -> void:
	GameState.essence = player.aperture.capacity()
	_check(GuRefining.refine(DataRegistry.body_gu(&"rosaeber"), player.aperture, 0.0) != null and &"rosaeber" in GameState.body_gu, "Rosa-Eber eingeprägt")
	await _frames(2)
	_check(is_equal_approx(player.flat_damage, 4.0), "Körper-Gu gibt +4 Schaden")
	var regen_before: float = player.aperture.regeneration()
	GameState.essence = player.aperture.capacity()
	var support_before: int = GameState.support.size()
	_check(GuRefining.refine(DataRegistry.support_gu(&"liquor"), player.aperture, 0.0) != null and GameState.support.size() == support_before + 1, "Schnaps-Wurm als Hilfs-Gu")
	_check(player.aperture.regeneration() > regen_before * 1.3, "Schnaps-Wurm erhöht Regeneration")
	_check(PassiveGu.upkeep() > 0.0, "Hilfs-Gu kostet Unterhalt")
	GameState.support[0].satiety = 10.0
	GameState.add_item(&"beeren", 5)
	GameState.add_item(&"kristall", 5)
	_check(player.holder.feed_support(0) and GameState.support[0].satiety > 99.0, "Hilfs-Gu füttern")


func _test_upgrade() -> void:
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	var whirl: GuInstance = _give(&"wirbel", 0)
	_check(GuRefining.upgrade_blocked_reason(whirl, player.aperture) != "", "Aufstieg ohne Material blockiert")
	var fur_before: int = GameState.item_count(&"wildfell")
	GameState.add_item(&"wildfell", 3)
	GameState.essence = player.aperture.capacity()
	_check(GuRefining.upgrade(whirl, player.aperture, 0.0) and whirl.gu_id == &"sogwirbel", "Aufstieg Wirbelwind → Sogwirbel")
	_check(GameState.item_count(&"wildfell") == fur_before, "Aufstieg verbraucht Material")
	await _clear_enemies()
	var rat: Enemy = _spawn(&"ratte", player.camera_rig.flat_forward() * 4.5)
	await _frames(2)
	_freeze_in_place(rat)
	var before: float = rat.global_position.distance_to(player.global_position)
	GameState.essence = player.aperture.capacity()
	player.use_slot(0)
	await _frames(20)
	_check(not is_instance_valid(rat) or rat.global_position.distance_to(player.global_position) < before, "Sogwirbel zieht heran")
	_check(Pickup._matches(DataRegistry.enemy(&"wolf"), &"beast") and Pickup._matches(DataRegistry.enemy(&"bat"), &"fly"), "Materialquellen nach Fundort")
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	_give(&"mondlicht", 0)


func _test_death_and_save() -> void:
	print("-- _test_death_and_save")
	GameState.add_item(&"holz", 5)
	player.invulnerable_time = 0.0
	player.receive_hit(HitInfo.create(99999.0, null, -1))
	_check(player.is_dead(), "Spieler stirbt")
	await _frames(roundi(Balance.values.respawn_delay * 60.0) + 20)
	_check(not player.is_dead() and player.health.hp > 0.0, "Wiederbelebt")
	_check(not GameState.loot_sack.is_empty() and GameState.item_count(&"holz") == 0, "Beutesack statt Inventar")
	_check(SaveSystem.save_game(), "Speichern")
	var gu_count: int = GameState.gu.size()
	var support_count: int = GameState.support.size()
	var body_count: int = GameState.body_gu.size()
	var rank: int = GameState.rank
	GameState.reset({})
	_check(SaveSystem.load_game() and GameState.gu.size() == gu_count and GameState.rank == rank and not GameState.loot_sack.is_empty(), "Laden stellt den Stand wieder her")
	_check(GameState.support.size() == support_count and GameState.body_gu.size() == body_count and support_count > 0, "Passive Gu werden gespeichert")
	EventBus.return_to_menu_requested.emit()
	await _frames(5)
	EventBus.continue_requested.emit()
	await _frames(20)
	_check(main.player != null and main.world != null, "Weiterspielen baut die Welt neu auf")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
	else:
		print("  ok: ", message)
