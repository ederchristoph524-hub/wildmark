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
