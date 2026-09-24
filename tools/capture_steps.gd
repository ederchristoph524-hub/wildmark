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
	tree.quit()


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
