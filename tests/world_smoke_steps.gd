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
	steps._check(inheritance.state == Inheritance.State.CLAIMED and &"blumenwein" in GameState.inheritances and wild == 1, "Erbe geöffnet: Schnaps-Wurm wartet (%d)" % wild)
