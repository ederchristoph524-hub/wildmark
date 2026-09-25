class_name AreaSteps
extends RefCounted
## Schritte für test_areas.gd (eigene Datei, weil Autoloads erst nach dem Start bekannt sind).

const MAX_BUILD_FRAMES: int = 600

var tree: SceneTree = null
var main: Main = null
var _failures: PackedStringArray = []


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	await tree.physics_frame
	SaveSystem.save_path = "user://test_areas.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"A", "apt": 90.0, "death_mode": &"standard"})
	await _frames(20)
	for resource: Resource in DataRegistry.all(&"areas"):
		var area: AreaData = resource as AreaData
		if area.open and area.id != GameState.area:
			await _visit(area)
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_areas: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	tree.quit(0 if _failures.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _check(condition: bool, text: String) -> void:
	if not condition:
		_failures.append(text)


func _visit(area: AreaData) -> void:
	var started: int = Time.get_ticks_msec()
	EventBus.travel_requested.emit(area.id)
	var waited: int = 0
	while (main.world == null or main.world.area == null or main.world.area.id != area.id) and waited < MAX_BUILD_FRAMES:
		await _frames(1)
		waited += 1
	await _frames(30)
	var world: World = main.world
	var label: String = String(area.id)
	_check(world != null and world.area.id == area.id, label + ": Reise gelingt")
	if world == null or world.area.id != area.id:
		return
	var player: Player = main.player
	print("%s: Aufbau %d ms" % [label, Time.get_ticks_msec() - started])
	_check(player.is_on_floor(), label + ": Spieler steht am Ankunftspunkt")
	_check(not world.terrain.in_water(player.global_position.x, player.global_position.z), label + ": Ankunft nicht im Wasser")
	var villages: int = 0
	for poi: Dictionary in world.pois:
		villages += 1 if poi["kind"] == MapData.KIND_VILLAGE else 0
	_check(villages == area.settlements.size(), label + ": alle Siedlungen gebaut (%d)" % villages)
	var npcs: int = 0
	var masters: int = 0
	var inheritances: int = 0
	var wild: int = 0
	for node: Node in world.find_children("*", "", true, false):
		if node is Npc:
			npcs += 1
		elif node is GuMaster and not node is Wanderer:
			masters += 1
		elif node is Inheritance:
			inheritances += 1
		elif node is WildGu:
			wild += 1
	_check(npcs >= area.settlements.size(), label + ": Bewohner vorhanden (%d)" % npcs)
	_check(masters >= 1, label + ": mindestens ein Gu-Meister (%d)" % masters)
	var expected_inheritances: int = 0
	for place: Dictionary in area.places:
		expected_inheritances += 1 if place["type"] == &"erbe" else 0
	_check(inheritances == expected_inheritances, label + ": Erbschaften (%d/%d)" % [inheritances, expected_inheritances])
	var gated: int = 0
	for obstacle: Dictionary in area.obstacles:
		gated += 0 if obstacle["kind"] == &"vorsprung" else 1
	_check(tree.get_nodes_in_group(&"obstacles").size() >= gated, label + ": Hindernisse (%d/%d)" % [tree.get_nodes_in_group(&"obstacles").size(), gated])
	_check(wild >= 10, label + ": wilde Gu (%d)" % wild)
	for zone: int in area.enemy_zones.size():
		_check(not world.spawner.candidates(zone, false).is_empty(), label + ": Bestien in Zone %d" % zone)
	for place: Dictionary in area.places:
		var at: Vector2 = place["position"]
		if place["type"] != &"see":
			_check(not world.terrain.in_water(at.x, at.y), label + ": Ort %s liegt nicht im Wasser" % place["name"])
	for obstacle: Node in tree.get_nodes_in_group(&"obstacles"):
		var point: Vector3 = (obstacle as Node3D).global_position
		if (obstacle as WorldObstacle).kind != WorldObstacle.KIND_WATER:
			_check(not world.terrain.in_water(point.x, point.z), label + ": Hindernis %s nicht im Wasser" % (obstacle as WorldObstacle).id)
