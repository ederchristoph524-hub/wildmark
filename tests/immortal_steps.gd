class_name ImmortalSteps
extends RefCounted
## Schritte für test_immortal.gd: freier Start als Unsterblicher, Perlen statt Uressenz, Schaden gegen Rang-5-Meister,
## unsterbliche Gu und Killer Moves, eigene Apertur mit Landgeist und Erträgen, Kalamität, Schatzhimmel, Durchbruch,
## Aufstieg eines Sterblichen und Speichern/Laden.

const MAX_BUILD_FRAMES: int = 600

var tree: SceneTree = null
var main: Main = null
var player: Player = null
var _failures: PackedStringArray = []


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	await tree.physics_frame
	SaveSystem.save_path = "user://test_immortal.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	await _test_start_menu()
	await _test_free_start()
	await _test_mortal_gu_and_ants()
	await _test_immortal_gu()
	await _test_killer()
	await _test_aperture()
	await _test_calamity()
	_test_treasure()
	_test_breakthrough()
	await _test_save_load()
	await _test_ascension()
	await _test_everything()
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_immortal: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	tree.quit(0 if _failures.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _check(condition: bool, text: String) -> void:
	if not condition:
		_failures.append(text)
	print(("  ok  " if condition else "  ✗   ") + text)


func _new_game(free: Dictionary, area: StringName = &"qing_mao") -> void:
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"A", "apt": 90.0, "death_mode": &"standard", "free": free, "area": area})
	var waited: int = 0
	while (main.player == null or main.world == null or main.world.area.id != area) and waited < MAX_BUILD_FRAMES:
		await _frames(1)
		waited += 1
	await _frames(20)
	player = main.player


func _travel(area_id: StringName) -> void:
	EventBus.travel_requested.emit(area_id)
	var waited: int = 0
	while (main.world == null or main.world.area == null or main.world.area.id != area_id) and waited < MAX_BUILD_FRAMES:
		await _frames(1)
		waited += 1
	await _frames(20)
	player = main.player


## Der echte Weg über das Startmenü: Freier Start, Rang 6, Talent 100 % → Extreme Physique.
func _test_start_menu() -> void:
	print("-- Startmenü")
	var menu: StartMenu = main._start_menu
	menu._choose_mode(true)
	menu._free_section._choose_rank(6)
	menu._free_section.set_apt(100)
	_check(menu._talent == PhysiqueEffects.GRADE, "Talent 100 % wählt den Grad der Extremen Physique")
	menu._start()
	var waited: int = 0
	while (main.player == null or GameState.rank != 6) and waited < MAX_BUILD_FRAMES:
		await _frames(1)
		waited += 1
	await _frames(10)
	_check(Immortal.is_immortal() and GameState.physique != &"" and is_equal_approx(GameState.apt, 100.0), "Startmenü: Unsterblicher mit Extremer Physique")
	_check(GameState.childhood_step == -1, "keine Kindheit im freien Start")


func _test_free_start() -> void:
	print("-- freier Start")
	await _new_game({"rank": 6, "stage": 0, "grade": 2, "inspiration": &"leben", "immortal_gu": 3, "settlement": &""})
	var state: ImmortalState = GameState.immortal
	_check(Immortal.is_immortal() and GameState.rank == 6 and state.grade == 2, "freier Start: Rang 6, Gesegnetes Land hohen Grades")
	_check(state.beads_for(6) >= float(Immortal.land_grade().get("start_beads", 1)), "Startperlen Grüntrauben-Essenz (%.1f)" % state.beads_for(6))
	_check(state.gu.size() == 3, "drei unsterbliche Gu (%d)" % state.gu.size())
	_check(GameState.gu.size() > 8 and PassiveGu.capacity() >= Balance.immortal.mortal_gu_capacity, "Dutzende sterbliche Gu möglich (%d, Platz %d)" % [GameState.gu.size(), PassiveGu.capacity()])
	_check(player.health.max_hp > 2000.0, "Leben eines Unsterblichen (%d)" % roundi(player.health.max_hp))
	_check(GameState.item_count(ImmortalAperture.STONE_ITEM) > 0, "Unsterblichen-Essenzsteine zu Beginn")
	_check(Immortal.inspiration_effect().has("max_hp"), "Eingebung „Leben“ wirkt")


## Sterbliche Gu kosten fast nichts; Rang-5-Meister richten kaum Schaden an und fallen schnell.
func _test_mortal_gu_and_ants() -> void:
	print("-- Ameisen")
	var beads: float = GameState.immortal.beads_for(6)
	var ratio: float = player.aperture.ratio()
	_check(ratio >= 1.0 and player.aperture.spend(500.0), "Uressenz unerschöpflich (Anteil %.2f, 500 Essenz bezahlt)" % ratio)
	_check(beads - GameState.immortal.beads_for(6) <= Balance.immortal.mortal_cast_beads * 1.01, "ein sterblicher Gu kostet nur %.3f Perlen" % Balance.immortal.mortal_cast_beads)
	var master := GuMaster.new()
	master.setup(DataRegistry.gu_master(&"zehn_extreme"), "Test", player.global_position + Vector3(0.0, 0.3, -8.0))
	main.world.add_child(master)
	await _frames(2)
	var hp: float = player.health.hp
	player.receive_hit(HitInfo.create(1000.0, master, master.team))
	var taken: float = hp - player.health.hp
	_check(taken < 1000.0 * Balance.immortal.mortal_vs_immortal * 1.5, "Rang-5-Treffer 1000 → nur %d Schaden" % roundi(taken))
	var master_hp: float = master.health.hp
	master.receive_hit(HitInfo.create(100.0, player, player.team))
	var dealt: float = master_hp - master.health.hp
	_check(dealt > 100.0 * Balance.immortal.immortal_vs_mortal * 0.9, "Unsterblicher trifft Rang 5 mit ×%.0f (%d)" % [dealt / 100.0, roundi(dealt)])
	master.queue_free()
	player.health.hp = player.health.max_hp
	await _frames(2)


func _test_immortal_gu() -> void:
	print("-- unsterbliche Gu")
	var state: ImmortalState = GameState.immortal
	GameState.immortal.gu.clear()
	state.slots.fill(&"")
	var active: ImmortalGuData = null
	for resource: Resource in DataRegistry.all(&"immortal_gu"):
		var data: ImmortalGuData = resource as ImmortalGuData
		if data.rank == 6 and data.is_usable() and _damages(data.steps):
			active = data
			break
	_check(active != null and ImmortalGu.grant(active.id, true) and state.slots[0] == active.id, "aktiver unsterblicher Gu auf Taste 5")
	if active == null:
		return
	var enemy: Enemy = main.world.spawner.spawn(DataRegistry.enemy(&"wolf"), player.global_position + player.camera_rig.flat_forward() * 3.0 + Vector3.UP * 0.3)
	await _frames(2)
	player.targeting.soft_target = enemy
	var beads: float = state.beads_for(6)
	player.immortal.use_slot(0)
	await _frames(40)
	_check(state.beads_for(6) < beads - 0.01, "%s kostet Perlen (%.2f)" % [active.display_name, beads - state.beads_for(6)])
	_check(player.immortal.controller.cooldown_left(active.id) > 0.0, "Abklingzeit läuft")
	_check(not is_instance_valid(enemy) or enemy.is_dead() or enemy.health.hp < enemy.health.max_hp, "unsterblicher Gu trifft (%s, %s)" % [active.id, str(enemy.health.hp) + "/" + str(enemy.health.max_hp) if is_instance_valid(enemy) else "weg"])
	if is_instance_valid(enemy):
		enemy.queue_free()
	var passive_before: float = Immortal.passive(&"reduction")
	for resource: Resource in DataRegistry.all(&"immortal_gu"):
		var data: ImmortalGuData = resource as ImmortalGuData
		if data.passive.has("reduction") and not ImmortalGu.owns(data.id):
			ImmortalGu.grant(data.id, true)
			break
	_check(Immortal.passive(&"reduction") > passive_before, "passiver unsterblicher Gu wirkt dauerhaft")
	await _frames(2)


## Kern + alle sterblichen Familien → Eingebung → Kanalisieren → Wirkung.
func _test_killer() -> void:
	print("-- Unsterblichen-Killer-Move")
	var move: ImmortalKillerData = null
	for resource: Resource in DataRegistry.all(&"immortal_killers"):
		var candidate: ImmortalKillerData = resource as ImmortalKillerData
		if DataRegistry.immortal_gu(candidate.core).rank <= GameState.rank and candidate.mortal_families.size() >= 3:
			move = candidate
			break
	_check(move != null, "Killer Move mit Rang-6-Kern und mehreren sterblichen Gliedern gefunden")
	if move == null:
		return
	ImmortalGu.grant(move.core, true)
	for family_id: StringName in move.mortal_families:
		GameState.add_gu(GuInstance.create(DataRegistry.family(family_id).member_for_rank(5).id))
	ImmortalGu.check_insight(true)
	_check(move.id in GameState.immortal.known_killers, "Eingebung: %s erkannt (%d Glieder)" % [move.display_name, move.mortal_families.size()])
	GameState.immortal.cooldowns.clear()
	var moves: Array[ImmortalKillerData] = player.immortal.controller.available()
	GameState.immortal.active_killer = moves.find(move)
	var enemy: Enemy = main.world.spawner.spawn(DataRegistry.enemy(&"wolf"), player.global_position + player.camera_rig.flat_forward() * 5.0 + Vector3.UP * 0.3)
	await _frames(2)
	player.targeting.soft_target = enemy
	var beads: float = GameState.immortal.beads_for(6)
	player.immortal.start_killer()
	_check(player.immortal.controller.is_channeling(), "Kanalisieren beginnt")
	await _frames(roundi(move.channel * 60.0) + 40)
	_check(not player.immortal.controller.is_channeling() and GameState.immortal.cooldowns.has(move.id), "Killer Move ausgeführt")
	_check(GameState.immortal.beads_for(6) < beads, "Killer Move kostet Perlen")
	if is_instance_valid(enemy):
		enemy.queue_free()
	await _frames(2)


## Hat ein Schritt Schaden (mult)?
static func _damages(steps: Array) -> bool:
	for step: Variant in steps:
		if step is Dictionary and float((step as Dictionary).get("mult", 0.0)) > 0.0 and String((step as Dictionary).get("t", "")) != "buff":
			return true
	return false


func _test_aperture() -> void:
	print("-- Apertur")
	await _frames(roundi(Balance.values.combat_linger * 60.0) + 10)
	var from: StringName = GameState.area
	ImmortalAperture.enter()
	await _travel(ImmortalAperture.AREA_ID)
	_check(GameState.area == ImmortalAperture.AREA_ID and main.world.area.id == ImmortalAperture.AREA_ID, "eigene Apertur betreten")
	var spirits: int = main.world.find_children("*", "LandSpirit", true, false).size()
	_check(spirits == 1, "Landgeist in der Apertur")
	ImmortalAperture.produce(GameState.day + 2)
	var stored: int = int(GameState.immortal.land_store.get(ImmortalAperture.STONE_ITEM, 0))
	_check(stored > 0, "Land erzeugt Essenzsteine (%d)" % stored)
	var stones: int = GameState.item_count(ImmortalAperture.STONE_ITEM)
	ImmortalAperture.collect()
	_check(GameState.item_count(ImmortalAperture.STONE_ITEM) == stones + stored, "Erträge eingesammelt")
	var beads: float = GameState.immortal.beads_for(6)
	var made: int = ImmortalAperture.condense(3)
	_check(made == 3 and GameState.immortal.beads_for(6) >= beads + 2.99, "Essenzsteine zu Perlen verdichtet")
	_check(not main.world.area.immortal.is_empty(), "Apertur hat Unsterblichen-Regeln")
	ImmortalAperture.leave()
	await _travel(from)
	_check(GameState.area == from, "Apertur verlassen – zurück in %s" % from)
	ImmortalAperture.enter()
	await _travel(ImmortalAperture.AREA_ID)


func _test_calamity() -> void:
	print("-- Kalamität")
	var state: ImmortalState = GameState.immortal
	state.next_calamity_day = GameState.day
	ImmortalProgress.on_new_day(GameState.day)
	_check(state.pending_calamity != &"", "Kalamität angekündigt (%s)" % state.pending_calamity)
	var survived: int = state.calamities_survived
	ImmortalProgress.on_night(true)
	await _frames(5)
	var events: Array[Node] = main.world.find_children("*", "CalamityEvent", true, false)
	_check(events.size() == 1 and CalamityEvent.status_text != "", "Kalamität bricht in der Apertur los")
	await _frames(120)
	if not events.is_empty():
		(events[0] as CalamityEvent).call(&"_finish", true)
	await _frames(3)
	_check(state.calamities_survived == survived + 1 and state.pending_calamity == &"", "Kalamität überstanden")
	player.health.hp = player.health.max_hp


func _test_treasure() -> void:
	print("-- Schatzhimmel")
	GameState.add_item(ImmortalAperture.STONE_ITEM, 5000)
	var offers: Array[GuData] = TreasureHeaven.mortal_offers(5)
	var count: int = GameState.gu.size()
	_check(not offers.is_empty() and TreasureHeaven.buy_mortal(offers[0]) and GameState.gu.size() == count + 1, "Rang-5-Gu für %d Steine gekauft" % TreasureHeaven.mortal_price(5))
	var auction: Array[ImmortalGuData] = TreasureHeaven.auction_gu()
	_check(not auction.is_empty() and auction == TreasureHeaven.auction_gu(), "Auktion des Tages steht fest (%d Angebote)" % auction.size())
	if not auction.is_empty():
		_check(TreasureHeaven.buy_immortal(auction[0]) and ImmortalGu.owns(auction[0].id), "unsterblichen Gu ersteigert")
	GameState.add_item(TreasureHeaven.PRIMEVAL_ITEM, TreasureHeaven.primeval_rate() * 2)
	_check(TreasureHeaven.exchange_primeval(2) == 2, "Ursteine in Essenzsteine getauscht")


func _test_breakthrough() -> void:
	print("-- Durchbruch")
	_check(ImmortalProgress.breakthrough_reason() != "", "Durchbruch gesperrt ohne Höchststufe")
	GameState.immortal.calamities_survived = Balance.values.max_stage * int(Immortal.rank_info().get("per_stage", 3))
	Immortal.sync_stage()
	GameState.dao[Immortal.main_path()] = 1.0e6
	_check(GameState.stage == Balance.values.max_stage and ImmortalProgress.breakthrough_reason() == "", "Höchststufe, Dao und Steine: Trübsal möglich")
	ImmortalProgress.advance()
	_check(GameState.rank == 7 and GameState.immortal.beads_for(7) > 0.0, "Rang 7 – Rotdattel-Essenz")
	while GameState.rank < 9:
		ImmortalProgress.advance(true)
	_check(GameState.immortal.venerable_title != "" and GameState.immortal.dao_lord_path != &"", "Rang 9: %s" % GameState.immortal.venerable_title)


func _test_save_load() -> void:
	print("-- Speichern")
	var state: ImmortalState = GameState.immortal
	var gu: Array[StringName] = state.gu.duplicate()
	var beads: float = state.bead_total()
	var killers: int = state.known_killers.size()
	ImmortalAperture.leave()
	await _travel(state.return_area)
	SaveSystem.save_game()
	GameState.immortal.reset()
	_check(SaveSystem.load_game(), "Spielstand geladen")
	_check(GameState.immortal.gu == gu and absf(GameState.immortal.bead_total() - beads) < 0.01 and GameState.immortal.known_killers.size() == killers and GameState.rank == 9, "Unsterblichen-Zustand bleibt erhalten")


## Ein Sterblicher auf dem Gipfel von Rang 5: Qi sammeln, Grad vorhersagen, aufsteigen.
func _test_ascension() -> void:
	print("-- Aufstieg")
	await _new_game({"rank": 5, "stage": Balance.values.max_stage, "settlement": &""})
	_check(GameState.rank == 5 and not Immortal.is_immortal() and ImmortalAscension.is_gathering(), "Rang 5 Höchststufe, sammelt Qi")
	_check(ImmortalAscension.predicted_grade() < 0, "ohne Qi: Himmel und Erde würden dich verwerfen")
	GameState.kills = 600
	GameState.immortal.heaven_qi = 600.0
	GameState.immortal.earth_qi = 600.0
	var grade: int = ImmortalAscension.predicted_grade()
	_check(grade >= 1, "viel und ausgewogenes Qi: %s" % ImmortalAscension.grade_name(grade))
	GameState.immortal.heaven_qi = 900.0
	GameState.immortal.earth_qi = 20.0
	_check(ImmortalAscension.predicted_grade() < grade, "einseitiges Qi senkt den Grad")
	GameState.essence = player.aperture.capacity()
	_check(ImmortalAscension.blocked_reason(player) == "", "Aufstieg möglich")
	ImmortalAscension.ascend(grade, true)
	_check(Immortal.is_immortal() and GameState.immortal.beads_for(6) > 0.0, "aufgestiegen – Gesegnetes Land und Perlen")


## Freier Start mit allem: Ort samt Siedlung, Talent, gezielte Gu aller Arten, Sekte, Ruf, Dao, Vermögen, Tageszeit.
func _test_everything() -> void:
	print("-- alles einstellen")
	var immortal_ids: Array[StringName] = [&"wellenschwert_gu", &"herbstlicht_gu"]
	var free: Dictionary = {
		"rank": 8, "stage": 2, "grade": 3, "inspiration": &"kosten", "settlement": &"", "apt": 100,
		"first_family": &"schwert", "mortal": [&"wind", &"zeit", &"stern"] as Array[StringName], "mortal_random": 0,
		"body": [&"eisenblut"] as Array[StringName], "support": [&"blitzauge"] as Array[StringName],
		"immortal_ids": immortal_ids, "immortal_gu": 0,
		"sect": &"gu_yue", "sect_rank": 3, "fame": 2000, "infamy": 0, "dao_path": &"zeit", "dao_level": 5,
		"stones": 100000, "immortal_stones": 1000, "beads": 100, "time": 0.75,
	}
	EventBus.new_game_requested.emit({"first_family": &"schwert", "talent_grade": &"Durchbrochen", "apt": 100.0, "physique": &"ice",
		"death_mode": &"standard", "free": free, "area": &"qing_mao"})
	var waited: int = 0
	while (main.player == null or GameState.rank != 8) and waited < MAX_BUILD_FRAMES:
		await _frames(1)
		waited += 1
	await _frames(20)
	player = main.player
	var state: ImmortalState = GameState.immortal
	_check(GameState.rank == 8 and GameState.stage == 2 and state.grade == 3 and state.inspiration == &"kosten", "Rang 8 Oberstufe, Super-Land, Eingebung gewählt")
	_check(GameState.physique == &"ice" and is_equal_approx(GameState.apt, 100.0), "Extreme Physique und Talent 100 %")
	_check(ImmortalGu.owns(&"wellenschwert_gu") and ImmortalGu.owns(&"herbstlicht_gu") and state.gu.size() == 2, "gezielt gewählte unsterbliche Gu (%d)" % state.gu.size())
	var families: Dictionary = ImmortalGu.held_families()
	_check(families.has(&"schwert") and families.has(&"wind") and families.has(&"zeit") and families.has(&"stern"), "erster Gu und gewählte sterbliche Gu")
	_check(DataRegistry.gu(GameState.gu[0].gu_id).rank == 5, "erster Gu auf Rang 5")
	_check(&"eisenblut" in GameState.body_gu and GameState.support.size() == 1, "Körper- und Hilfs-Gu")
	_check(GameState.sect == &"gu_yue" and GameState.sect_rank == 3, "Sekte Gu Yue, Rang 3")
	_check(GameState.fame == 2000 and Immortal.main_path() == &"zeit" and Dao.attain(&"zeit") == 5, "Ansehen, Hauptpfad Zeit, Höchster Großmeister")
	_check(GameState.item_count(&"kristall") == 100000 and GameState.item_count(ImmortalAperture.STONE_ITEM) == 1000, "Vermögen fest eingestellt")
	_check(state.beads_for(8) >= 100.0, "zusätzliche Perlen (%.0f)" % state.beads_for(8))
	_check(absf(GameState.time_of_day - 0.75) < 0.05, "Geburt in der Nacht")
