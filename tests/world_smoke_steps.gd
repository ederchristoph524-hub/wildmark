class_name WorldSmokeSteps
extends RefCounted
## Durchspiel-Schritte zu Kultivieren, Aura, Karten und Gebieten (eigene Datei, damit die anderen unter 400 Zeilen bleiben).

var steps: GameSmokeSteps = null


func _init(owner_steps: GameSmokeSteps) -> void:
	steps = owner_steps


func run() -> void:
	print("-- world_smoke")
	await _test_cultivation()
	await _test_maps()
	_test_area()
	await _test_inheritance()
	_test_sect_life()
	_test_origin()
	await _test_beast_tide()
	_test_dao()


func _test_cultivation() -> void:
	await steps._clear_enemies()
	var player: Player = steps.player
	var stage: int = GameState.stage
	GameState.stage = 0
	player.toggle_meditation()
	await steps._frames(40)
	steps._check(player.aperture.meditating and player.model.sitting and player.cultivation.aura.strength() > 0.5, "Kultivieren: Schneidersitz und Aura")
	player.toggle_meditation()
	await steps._frames(60)
	steps._check(not player.aperture.meditating and not player.model.sitting and player.cultivation.aura.strength() < 0.1, "Kultivieren beendet, Aura erlischt")
	# Durchbruch über den Kultivieren-Knopf (Talent „Durchbrochen“ = sicherer Erfolg).
	var grade: StringName = GameState.talent_grade
	var rank: int = GameState.rank
	GameState.talent_grade = PhysiqueEffects.GRADE
	GameState.stage = Balance.values.max_stage
	GameState.essence = player.aperture.capacity()
	player.toggle_meditation()
	await steps._frames(10)
	steps._check(player.aperture.ritual_left > 0.0, "Durchbruch-Ritual beginnt")
	await steps._frames(roundi(Balance.values.breakthrough_ritual_time * 60.0) + 10)
	steps._check(GameState.rank == rank + 1 and player.aperture.ritual_left <= 0.0, "Durchbruch gelingt nach dem Ritual (Rang %d)" % GameState.rank)
	GameState.rank = rank
	GameState.talent_grade = grade
	GameState.stage = stage


func _test_maps() -> void:
	var world: World = steps.main.world
	steps._check(MapData.texture(world) != null and MapData.texture(world).get_width() == MapData.TEXTURE_SIZE, "Kartenbild des Gebiets")
	var village: bool = false
	for marker: Dictionary in MapData.markers(world, true):
		village = village or marker["kind"] == MapData.KIND_VILLAGE
	steps._check(village and steps.main.hud.minimap != null, "Minikarte mit Dorf")
	EventBus.menu_toggled.emit(&"map")
	await steps._frames(3)
	var menu: MapMenu = null
	for child: Node in steps.main._menu_layer.get_children():
		if child is MapMenu:
			menu = child
	steps._check(menu != null and steps.tree.paused, "Karte öffnet sich")
	if menu != null:
		menu.close()
	await steps._frames(3)
	steps._check(not steps.tree.paused and DataRegistry.area(GameState.area) != null, "Karte geschlossen, aktuelles Gebiet bekannt")


func _test_area() -> void:
	var world: World = steps.main.world
	var villages: int = 0
	for poi: Dictionary in world.pois:
		villages += 1 if poi["kind"] == MapData.KIND_VILLAGE else 0
	steps._check(world.area.id == &"qing_mao" and villages == 3, "Qing-Mao-Berg mit drei Klan-Dörfern (%d)" % villages)
	var spring: SpiritSpring = steps.tree.get_first_node_in_group(SpiritSpring.GROUP) as SpiritSpring
	steps._check(spring != null and is_equal_approx(SpiritSpring.bonus_at(steps.tree, spring.global_position), Balance.values.spirit_spring_mult), "Geisterquelle beschleunigt Kultivieren")
	steps._check(not world.terrain.lakes.is_empty() and world.terrain.in_water(world.terrain.lakes[0].x, world.terrain.lakes[0].y), "Jadesee im Gelände")
	var center: Vector3 = world.ground_point(0.0, 0.0)
	steps._check(world.in_settlement(center.x, center.z) and not world.in_settlement(0.0, 150.0), "Siedlungen sind Schutzzonen")


func _test_inheritance() -> void:
	await steps._clear_enemies()
	var inheritance: Inheritance = null
	for node: Node in steps.tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is Inheritance:
			inheritance = node
	steps._check(inheritance != null and inheritance.state == Inheritance.State.SEALED, "Erbe des Blumenwein-Mönchs versiegelt")
	if inheritance == null:
		return
	steps.player.global_position = inheritance.global_position + Vector3(0, 0.5, 6.0)
	GameState.add_item(&"kristall", 5)
	var stones: int = GameState.item_count(&"kristall")
	inheritance.interact(steps.player)
	await steps._frames(2)
	steps._check(inheritance.state == Inheritance.State.GUARDED and GameState.item_count(&"kristall") == stones - 3, "Opfergabe erweckt die Wächter")
	for node: Node in steps.tree.get_nodes_in_group(Enemy.GROUP_ENEMIES):
		(node as Enemy).receive_hit(HitInfo.create(9999.0, steps.player, steps.player.team))
	await steps._frames(10)
	var wild: int = 0
	for node: Node in steps.tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is WildGu and String((node as WildGu).spot_id).begins_with("erbe_"):
			wild += 1
	var reward: Dictionary = inheritance.data["reward"]
	var expected: int = (reward["support"] as Array).size() + (reward["gu"] as Array).size() + (reward["body"] as Array).size()
	steps._check(inheritance.state == Inheritance.State.CLAIMED and &"blumenwein" in GameState.inheritances and wild == expected, "Erbe geöffnet: Schnaps-Wurm und Eisenzahn warten (%d/%d)" % [wild, expected])


## Sektenleben: Beitritt beim Oberhaupt, Aufstieg mit Geschenken, Signatur-Gu, Zuteilung, Speichern.
func _test_sect_life() -> void:
	var leaders: Array[Node] = steps.tree.get_nodes_in_group(Player.GROUP_INTERACTABLES).filter(func(n: Node) -> bool: return n is Npc and (n as Npc).leader and (n as Npc).sect_id == &"gu_yue")
	steps._check(not leaders.is_empty(), "das Dorfoberhaupt vertritt den Gu-Yue-Klan")
	var sect: SectData = DataRegistry.sect(&"gu_yue")
	var stones: int = GameState.item_count(&"kristall")
	steps._check(SectLife.join(sect) and SectLife.is_member(&"gu_yue") and GameState.item_count(&"kristall") >= stones, "Beitritt mit Geschenk")
	var gu_count: int = GameState.gu.size()
	SectLife.add_merit(DataRegistry.progression().sect_ranks[2].merit_needed)
	steps._check(GameState.sect_rank == 2 and GameState.gu.size() == gu_count + 1, "Aufstieg über zwei Ränge, Kernschüler erhält das Signatur-Gu")
	var before: int = GameState.item_count(&"kristall")
	SectLife.on_new_day(GameState.day + 1)
	SectLife.on_new_day(GameState.day + 1)
	steps._check(GameState.item_count(&"kristall") == before + SectLife.stipend(), "tägliche Zuteilung genau einmal")
	var saved: Dictionary = GameState.to_dict()
	GameState.from_dict(saved)
	steps._check(GameState.sect == &"gu_yue" and GameState.sect_rank == 2, "Sekte und Rang werden gespeichert")
	var task: Dictionary = SectTasks.today()
	steps._check(task["day"] == GameState.day and int(task["count"]) > 0 and SectTasks.text(task) != "", "Sektenauftrag des Tages")
	match String(task["type"]):
		SectTasks.HUNT:
			GameState.kills += int(task["count"])
		SectTasks.DELIVER:
			GameState.add_item(task["item"], int(task["count"]))
		_:
			GameState.duels_won += 1
	var merit: int = GameState.sect_merit
	steps._check(SectTasks.turn_in() and GameState.sect_merit > merit and not SectTasks.turn_in(), "Auftrag abgeben (einmal pro Tag)")
	SectLife.leave()
	steps._check(not SectLife.is_member(), "Austritt")


## Bestienflut: Wellen stürmen auf das Gu-Yue-Dorf zu; sind alle erlegt, gibt es den Lohn.
func _test_beast_tide() -> void:
	await steps._clear_enemies()
	var tide: BeastTide = steps.main.world.tide
	steps._check(tide != null, "Qing-Mao-Berg hat eine Wolfsflut")
	if tide == null:
		return
	var stones: int = GameState.item_count(&"kristall")
	tide.start()
	await steps._frames(roundi(BeastTide.WAVE_INTERVAL * 60.0 * BeastTide.WAVES) + 30)
	var beasts: Array[Node] = steps.tree.get_nodes_in_group(Enemy.GROUP_ENEMIES)
	steps._check(beasts.size() >= int(tide.tide["count"]) and BeastTide.status_text != "", "alle Wellen sind erschienen (%d Bestien)" % beasts.size())
	for node: Node in beasts:
		(node as Enemy).health.apply_damage(99999.0)
	await steps._frames(10)
	steps._check(not tide.active and GameState.item_count(&"kristall") > stones and BeastTide.status_text == "", "Flut abgewehrt, Lohn erhalten")


## Dao: Markierungen heben die Beherrschung, senken Kosten und Abklingzeit; Gegenpfade verteuern.
func _test_dao() -> void:
	var saved: Dictionary = GameState.dao.duplicate()
	GameState.dao.clear()
	var base_cost: float = Dao.cost_mult(&"feuer")
	Dao.add(&"feuer", DataRegistry.gu_system().attain_needs[2])
	steps._check(Dao.attain(&"feuer") == 2 and Dao.cost_mult(&"feuer") < base_cost and Dao.cooldown_mult(&"feuer") < 1.0, "Meister im Feuerpfad: billiger und schneller")
	steps._check(Dao.conflict(&"wasser") > 0.0 and Dao.cost_mult(&"wasser") > 1.0, "Feuer-Markierungen verteuern den Wasserpfad")
	var round_trip: Dictionary = GameState.to_dict()
	GameState.from_dict(round_trip)
	steps._check(is_equal_approx(Dao.marks(&"feuer"), DataRegistry.gu_system().attain_needs[2]), "Markierungen werden gespeichert")
	GameState.dao = saved


## Herkunft Hauptlinie: Geschenk, Talentbonus und Mitgliedschaft im Gu-Yue-Klan mit Verdienst.
func _test_origin() -> void:
	var standing: StandingData = DataRegistry.standing(&"haupt")
	var stones: int = GameState.item_count(&"kristall")
	var apt: float = GameState.apt
	GameState.standing = &"haupt"
	Origins.apply()
	steps._check(GameState.item_count(&"kristall") >= stones + standing.gift.get(&"kristall", 0) and GameState.apt >= minf(apt + standing.apt_bonus, 100.0) - 0.01, "Hauptlinie: Geschenk und Talentbonus")
	steps._check(SectLife.is_member(Origins.HOME_SECT) and GameState.sect_merit >= standing.home_merit and GameState.sect_rank >= 1, "Hauptlinie ist Innerer Schüler im Gu-Yue-Klan")
	SectLife.leave()
	GameState.standing = &""
	GameState.apt = apt
