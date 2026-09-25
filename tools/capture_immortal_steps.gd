class_name CaptureImmortalSteps
extends RefCounted
## Schritte für capture_immortal.gd: freier Start im Startmenü, Unsterblicher Rang 7 mit HUD und Touch, Gu-Menü-Seiten
## Unsterblich, Unsterbliche Gu und Schatzhimmel, eigene Apertur mit Landgeist und eine Kalamität.

const OUT_DIR: String = "res://build/immortal/"

var tree: SceneTree = null
var main: Main = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	SaveSystem.save_path = "user://capture_immortal.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(20)
	main._start_menu._choose_mode(true)
	main._start_menu._free_section._choose_rank(7)
	await _frames(5)
	await _shot("01_start_frei")
	var scroll: ScrollContainer = main._start_menu.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	scroll.scroll_vertical = 900
	await _frames(5)
	await _shot("01b_start_frei_unten")
	EventBus.new_game_requested.emit({"first_family": &"flamme", "talent_grade": &"A", "apt": 92.0, "death_mode": &"standard", "area": &"qing_mao",
		"free": {"rank": 7, "stage": 1, "grade": 2, "inspiration": &"dao", "immortal_gu": 6, "settlement": &""}})
	await _frames(120)
	main.hud.touch.visible = true
	GameState.time_of_day = 0.3
	await _frames(10)
	await _shot("02_hud_unsterblich")
	main.hud.touch.visible = false
	for tab: String in ["Unsterblich", "Unsterbliche Gu", "Schatzhimmel"]:
		main._open_menu(GuMenu.new())
		await _frames(5)
		_open_tab(tab)
		await _frames(10)
		await _shot("03_" + tab.to_lower().replace(" ", "_"))
		for child: Node in main._menu_layer.get_children():
			if child is GuMenu:
				(child as GuMenu).close()
		await _frames(5)
	ImmortalAperture.enter()
	for i: int in 300:
		await _frames(1)
		if main.world != null and main.world.area.id == ImmortalAperture.AREA_ID:
			break
	await _frames(90)
	main.player.camera_rig.pitch = -0.25
	await _frames(20)
	await _shot("04_apertur")
	GameState.immortal.next_calamity_day = GameState.day
	ImmortalProgress.on_new_day(GameState.day)
	ImmortalProgress.on_night(true)
	await _frames(400)
	await _shot("05_kalamitaet")
	tree.quit(0)


func _open_tab(title: String) -> void:
	for child: Node in main._menu_layer.get_children():
		var tabs: Array[Node] = child.find_children("*", "TabContainer", true, false)
		if tabs.is_empty():
			continue
		var container: TabContainer = tabs[0] as TabContainer
		for i: int in container.get_tab_count():
			if container.get_tab_title(i) == tr(title):
				container.current_tab = i


func _frames(count: int) -> void:
	for i: int in count:
		await tree.process_frame


func _shot(name_part: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = tree.root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + name_part + ".png"))
	print("Bild gespeichert: %s · Draw Calls %d" % [name_part, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
