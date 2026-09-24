class_name CaptureSteps
extends RefCounted
## Schritte für capture_screenshots.gd: Startmenü, Lager, Kampf, Nacht, Gu-Menü.

const OUT_DIR: String = "res://build/screenshots/"

var tree: SceneTree = null
var main: Main = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# build/ darf Godot nicht importieren (sonst landen Bilder und Web-Build im Projekt).
	FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(20)
	await _shot("01_startmenue")
	EventBus.new_game_requested.emit({"first_family": &"flamme", "talent_grade": &"B", "apt": 72.0, "death_mode": &"standard"})
	await _frames(90)
	await _shot("02_lager")
	main.hud.touch.visible = true
	await _frames(5)
	await _shot("02b_touch")
	main.hud.touch.visible = false
	var player: Player = main.player
	player.camera_rig.pitch = -0.2
	player.camera_rig.yaw = -0.4
	await _frames(20)
	await _shot("02c_dorf")
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is Npc and (node as Npc).quest_id == &"bau":
			var dialog := DialogMenu.new()
			dialog.npc = node
			main._open_menu(dialog)
			await _frames(10)
			await _shot("02d_gespraech")
			dialog.close()
			break
	await _frames(5)
	await _shoot_duel(player)
	player.camera_rig.pitch = -0.35
	player.camera_rig.yaw = PI * 0.75
	await _frames(30)
	await _shot("03_dschungel")
	player.global_position = Vector3(38.0, main.world.terrain.height_at(38.0, 10.0) + 0.5, 10.0)
	player.camera_rig.yaw = 0.0
	await _frames(20)
	for i: int in 3:
		var at: Vector3 = player.global_position + Vector3(-2.0 + i * 2.0, 0.0, -6.0 - i)
		main.world.spawner.spawn(DataRegistry.enemy([&"wolf", &"slime", &"spinne"][i]), Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))
	await _frames(20)
	GameState.essence = player.aperture.capacity()
	player.use_slot(0)
	await _frames(12)
	await _shot("04_kampf")
	await _frames(40)
	await _shot("05_kampf_danach")
	GameState.time_of_day = 0.9
	await _frames(30)
	await _shot("06_nacht")
	GameState.time_of_day = 0.3
	await _shoot_sites(player)
	main._open_menu(GuMenu.new())
	await _frames(10)
	await _shot("07_gu_menue")
	await _shoot_childhood()
	tree.quit()


## Spielbare Kindheit: Dorf mit Hinweis, danach Talenttest und Gu-Wahl.
func _shoot_childhood() -> void:
	for child: Node in main._menu_layer.get_children():
		child.queue_free()
	EventBus.new_game_requested.emit({"childhood": true, "first_family": &"", "death_mode": &"standard"})
	await _frames(90)
	main.player.camera_rig.yaw = -0.4
	main.player.camera_rig.pitch = -0.2
	await _frames(20)
	await _shot("08_kindheit")
	GameState.childhood_step = Childhood.STEPS.size() - 1
	EventBus.awakening_requested.emit()
	await _frames(10)
	await _shot("09_erwachen")


## Duell mit dem Klanlehrer: Spieler vor dem Gu-Meister, kurz nach dem Countdown.
func _shoot_duel(player: Player) -> void:
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is GuMaster:
			var master: GuMaster = node
			var start: Vector3 = player.global_position
			player.global_position = master.global_position + Vector3(0.0, 0.3, 6.0)
			player.camera_rig.yaw = 0.0
			player.camera_rig.pitch = -0.25
			master.start_duel(player)
			await _frames(roundi(Balance.values.duel_countdown * 60.0) + 50)
			await _shot("02e_duell")
			player.health.apply_damage(9999.0)
			await _frames(5)
			player.global_position = start
			await _frames(10)
			return


## Ein Bild je Hindernis-Ort, aus Richtung des Lagers gesehen.
func _shoot_sites(player: Player) -> void:
	var centers: Array[Vector3] = ObstacleSites.plan(main.world)
	for index: int in centers.size():
		var center: Vector3 = centers[index]
		var toward_camp: Vector3 = (-center).normalized() * 10.0
		var at: Vector3 = center + toward_camp
		player.global_position = Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.5, at.z)
		player.camera_rig.yaw = atan2(toward_camp.x, toward_camp.z)
		await _frames(15)
		await _shot("site_%d_%s" % [index, String(ObstacleSites.SITES[index][1])])


func _frames(count: int) -> void:
	for i: int in count:
		await tree.process_frame


func _shot(name_part: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = tree.root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + name_part + ".png"))
	print("Bild gespeichert: %s · Draw Calls %d · Objekte %d · Dreiecke %d · FPS %d" % [name_part,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		Engine.get_frames_per_second()])
