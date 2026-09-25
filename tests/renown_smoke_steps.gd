class_name RenownSmokeSteps
extends RefCounted
## Durchspiel-Schritte zu wandernden Gu-Meistern, Überfällen, Urteil und Ruf (Wanderer, Wanderers, Renown).

var steps: GameSmokeSteps = null


func _init(owner_steps: GameSmokeSteps) -> void:
	steps = owner_steps


func run() -> void:
	print("-- renown_smoke")
	GameState.fame = 0
	GameState.infamy = 0
	_test_spawn()
	await _test_demonic_ambush()
	await _test_righteous_robbery()
	_test_renown_effects()
	_test_bounty_hunter()
	_test_disguise_and_compass()
	GameState.fame = 0
	GameState.infamy = 0


func _test_spawn() -> void:
	var world: World = steps.main.world
	steps._check(world.wanderers != null and world.wanderers.count_alive(false) == world.area.wanderer_count,
		"Wanderer unterwegs (%d)" % world.area.wanderer_count)
	var on_land: bool = true
	for node: Node in steps.main.get_tree().get_nodes_in_group(Wanderer.GROUP):
		var wanderer: Wanderer = node as Wanderer
		on_land = on_land and not world.terrain.in_water(wanderer.global_position.x, wanderer.global_position.z)
	steps._check(on_land, "Wanderer stehen an Land")


func _test_demonic_ambush() -> void:
	await steps._clear_enemies()
	var player: Player = steps.player
	var rogue: Wanderer = _spawn(&"streuner", player.global_position + Vector3(6.0, 0.0, 0.0))
	await steps._frames(3)
	steps._check(rogue.is_hostile() and rogue.is_demonic(), "Dämonischer Wanderer ist feindselig")
	rogue.ambush(player)
	steps._check(rogue.duel_state == GuMaster.DuelState.COUNTDOWN and player.health.floor_hp == 0.0, "Überfall ohne Duell-Untergrenze")
	await _defeat(rogue)
	steps._check(rogue.surrendered and rogue.is_in_group(Player.GROUP_INTERACTABLES) and not rogue.is_hostile(), "Besiegter Dämon ergibt sich")
	rogue.offer_choices()
	await steps._frames(2)
	var menu: ChoiceMenu = _choice_menu()
	steps._check(menu != null and menu.options.size() == 3, "Urteil: töten, ausrauben, verschonen")
	if menu != null:
		menu.close()
	await steps._frames(2)
	var stones: int = GameState.item_count(DuelRewards.STONE_ITEM)
	var purse: int = rogue.purse
	var wild_before: int = _wild_count()
	rogue.kill()
	await steps._frames(3)
	steps._check(not is_instance_valid(rogue) and GameState.item_count(DuelRewards.STONE_ITEM) == stones + purse and purse > 0,
		"Töten bringt den Geldbeutel (%d Urstein)" % purse)
	steps._check(_wild_count() > wild_before, "Seine Gu bleiben wild zurück")
	steps._check(GameState.fame == Balance.values.renown_kill_demonic and GameState.infamy == 0, "Dämon erschlagen: Ansehen")


func _test_righteous_robbery() -> void:
	var player: Player = steps.player
	var b: BalanceData = Balance.values
	var patrol: Wanderer = _spawn(&"gu_yue", player.global_position + Vector3(0.0, 0.0, 6.0))
	await steps._frames(3)
	steps._check(not patrol.is_hostile(), "Rechtschaffene Patrouille lässt Unbescholtene ziehen")
	patrol.interact(player)
	steps._check(GameState.infamy == b.renown_attack and patrol.duel_state == GuMaster.DuelState.COUNTDOWN, "Überfall kostet Ruf")
	await _defeat(patrol)
	var stones: int = GameState.item_count(DuelRewards.STONE_ITEM)
	var purse: int = patrol.purse
	patrol.rob()
	steps._check(GameState.item_count(DuelRewards.STONE_ITEM) == stones + purse and GameState.infamy == b.renown_attack + b.renown_rob and patrol.fleeing,
		"Ausrauben: Urstein, Berüchtigtheit, Flucht")
	await steps._frames(roundi(Wanderer.FLEE_TIME * 60.0) + 20)
	steps._check(not is_instance_valid(patrol), "Beraubter verschwindet")


func _test_renown_effects() -> void:
	var b: BalanceData = Balance.values
	GameState.infamy = b.renown_wanted
	var rogue: Wanderer = _spawn(&"streuner", steps.player.global_position + Vector3(40.0, 0.0, 0.0))
	var patrol: Wanderer = _spawn(&"gu_yue", steps.player.global_position + Vector3(-40.0, 0.0, 0.0))
	steps._check(Renown.is_wanted() and patrol.is_hostile() and not rogue.is_hostile(), "Gesucht: Rechtschaffene jagen dich, Dämonen lassen dich ziehen")
	steps._check(is_equal_approx(Renown.trade_markup(&"gu_yue"), b.renown_wanted_markup) and Renown.trade_markup(&"schattensekte") == 1.0, "Aufschlag nur bei Rechtschaffenen")
	steps._check(Renown.join_blocked(DataRegistry.sect(&"bai_clan")) != "" and Renown.join_blocked(DataRegistry.sect(&"blutfluegel")) == "", "Gesuchte: Klans lehnen ab, Dämonensekten nehmen auf")
	GameState.infamy = b.renown_demon
	steps._check(Renown.trade_refused(&"gu_yue") != "" and Renown.trade_refused(&"karawanenbund") == "", "Dämon: kein Handel bei Rechtschaffenen")
	Renown.on_new_day(GameState.day + 1)
	steps._check(GameState.infamy == b.renown_demon - b.renown_decay, "Berüchtigtheit verblasst täglich")
	steps._check(int((GameState.to_dict()["player"]["renown"] as Dictionary)["infamy"]) == GameState.infamy, "Ruf wird gespeichert")
	GameState.infamy = 0
	steps._check(Renown.join_blocked(DataRegistry.sect(&"blutfluegel")) != "", "Unbescholtene: Dämonensekten misstrauen")
	rogue.queue_free()
	patrol.queue_free()


func _test_bounty_hunter() -> void:
	GameState.infamy = Balance.values.renown_wanted
	var hunter: Wanderer = steps.main.world.wanderers.spawn_hunter(steps.player.global_position)
	steps._check(hunter != null and hunter.bounty_hunter and hunter.is_hostile() and hunter.rank == clampi(GameState.rank, 1, 5),
		"Kopfgeldjäger auf deinem Rang")
	if hunter != null:
		hunter.queue_free()


## Menschenhaut-Gu verbirgt Gesuchte, Kaktuszeiger-Gu zeigt wilde Gu auf der Karte.
func _test_disguise_and_compass() -> void:
	var rank: int = GameState.rank
	GameState.rank = maxi(rank, 3)
	GameState.infamy = Balance.values.renown_wanted
	var patrol: Wanderer = _spawn(&"gu_yue", steps.player.global_position + Vector3(-40.0, 0.0, 0.0))
	var skin: GuInstance = GuInstance.create(&"menschenhaut")
	GameState.support.append(skin)
	steps._check(Renown.disguised() and not patrol.is_hostile() and Renown.trade_markup(&"gu_yue") == 1.0, "Menschenhaut: Rechtschaffene erkennen dich nicht")
	GameState.support.erase(skin)
	var compass: GuInstance = GuInstance.create(&"kaktuszeiger")
	GameState.support.append(compass)
	var wild: bool = false
	for marker: Dictionary in MapData.markers(steps.main.world, false):
		wild = wild or marker["kind"] == MapData.KIND_WILD
	steps._check(wild, "Kaktuszeiger: wilde Gu auf der Karte")
	GameState.support.erase(compass)
	GameState.rank = rank
	patrol.queue_free()


func _spawn(id: StringName, at: Vector3) -> Wanderer:
	var wanderer := Wanderer.new()
	var world: World = steps.main.world
	wanderer.setup(DataRegistry.gu_master(id), "", world.ground_point(at.x, at.z) + Vector3.UP * 0.3)
	world.entities.add_child(wanderer)
	return wanderer


## Wartet die Vorwarnung ab und bringt ihn unter die Aufgabegrenze.
func _defeat(wanderer: Wanderer) -> void:
	await steps._frames(roundi(Balance.values.wanderer_warning * 60.0) + 20)
	wanderer.health.hp = wanderer.health.max_hp * Balance.values.duel_surrender_ratio * 0.5
	wanderer._after_hit(null, 0.0)
	await steps._frames(2)


func _choice_menu() -> ChoiceMenu:
	for node: Node in steps.main.get_tree().root.find_children("*", "", true, false):
		if node is ChoiceMenu:
			return node as ChoiceMenu
	return null


func _wild_count() -> int:
	var total: int = 0
	for node: Node in steps.main.world.entities.get_children():
		if node is WildGu:
			total += 1
	return total
