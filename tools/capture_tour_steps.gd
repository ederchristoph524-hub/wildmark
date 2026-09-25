class_name CaptureTourSteps
extends RefCounted
## Schritte für capture_tour.gd: freie Kamera an festen Aussichtspunkten (relativ zu Siedlungen und Orten des Gebiets).

const OUT_DIR: String = "res://build/tour/"

var tree: SceneTree = null
var main: Main = null
var _camera: Camera3D = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	SaveSystem.save_path = "user://tour_save.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(10)
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"B", "apt": 70.0, "death_mode": &"standard", "area": _area_arg()})
	await _frames(90)
	main.hud.visible = false
	GameState.time_of_day = _time_arg()
	# --weather=0.9 erzwingt das Wetter des Bioms (Regen, Schnee, Sand) mit dieser Stärke.
	var weather_arg: float = _float_arg("--weather=", -1.0)
	if weather_arg >= 0.0:
		for child: Node in main.world.get_children():
			if child is Weather and (child as Weather).is_processing():
				(child as Weather).force(weather_arg)
	_camera = Camera3D.new()
	_camera.near = PlayerCamera.VIEW_NEAR
	_camera.far = PlayerCamera.VIEW_FAR
	main.world.add_child(_camera)
	_camera.current = true
	var world: World = main.world
	var views: Array[Array] = _views(world)
	var only: PackedStringArray = _only_arg()
	for view: Array in views:
		if only.is_empty() or String(view[0]) in only:
			await _view(view[0], view[1], view[2])
	tree.quit()


func _area_arg() -> StringName:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--area="):
			return StringName(arg.trim_prefix("--area="))
	return &"qing_mao"


## --time=0.9 setzt die Tageszeit (0–1, Standard Vormittag); z. B. für Nachtbilder.
func _time_arg() -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--time="):
			return float(arg.trim_prefix("--time="))
	return 0.28


## --wait=300 wartet so viele Bilder vor dem Foto (Partikel, Tageswechsel); Standard 12.
func _float_arg(prefix: String, fallback: float) -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return float(arg.trim_prefix(prefix))
	return fallback


func _string_arg(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


func _vector(text: String) -> Vector3:
	var parts: PackedStringArray = text.split(",")
	if parts.size() < 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _wait_arg() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--wait="):
			return int(arg.trim_prefix("--wait="))
	return 12


## --only=name1,name2 beschränkt den Rundgang auf diese Aussichtspunkte.
func _only_arg() -> PackedStringArray:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			return arg.trim_prefix("--only=").split(",")
	return PackedStringArray()


## Aussichtspunkte: [Name, Kameraposition, Blickziel].
func _views(world: World) -> Array[Array]:
	var result: Array[Array] = []
	var size: float = world.area.size
	# --at=x,y,z --look=x,y,z: freie Ansicht „frei" (Weltkoordinaten) für gezielte Prüfungen.
	var free_at: String = _string_arg("--at=")
	if free_at != "":
		result.append(["frei", _vector(free_at), _vector(_string_arg("--look="))])
	result.append(["uebersicht", Vector3(size * 0.1, size * 0.45, size * 0.55), Vector3(0, 0, 0)])
	for settlement: Dictionary in world.area.settlements:
		var at: Vector2 = settlement["position"]
		var r: float = settlement["radius"]
		var center: Vector3 = world.ground_point(at.x, at.y)
		result.append([String(settlement["id"]) + "_luft", center + Vector3(r * 0.9, r * 0.8, r * 1.6), center])
		result.append([String(settlement["id"]) + "_tor", world.ground_point(at.x + 3.0, at.y + r + 14.0) + Vector3.UP * 2.0, center + Vector3(0, 4.0, 0)])
		result.append([String(settlement["id"]) + "_strasse", world.ground_point(at.x + 2.0, at.y + r * 0.6) + Vector3.UP * 1.7, center + Vector3(0, 3.0, -r * 0.4)])
	for place: Dictionary in world.area.places:
		var p: Vector2 = place["position"]
		var target: Vector3 = world.ground_point(p.x, p.y)
		var distance: float = float(place["radius"]) * 1.6 + 8.0
		result.append([String(place["id"]), target + Vector3(distance * 0.7, distance * 0.45, distance), target])
	for i: int in world.area.rivers.size():
		var points: Array = world.area.rivers[i]["points"]
		var middle: int = floori(points.size() * 0.5)
		var mid: Vector2 = points[middle]
		var along: Vector2 = ((points[mini(middle + 1, points.size() - 1)] as Vector2) - mid).normalized()
		var target: Vector3 = world.ground_point(mid.x, mid.y)
		var eye: Vector3 = world.ground_point(mid.x - along.x * 30.0 + along.y * 18.0, mid.y - along.y * 30.0 - along.x * 18.0)
		eye.y = maxf(eye.y + 6.0, target.y + 22.0)
		result.append(["fluss_%d" % i, eye, target + Vector3(along.x * 20.0, 0.0, along.y * 20.0)])
	result.append(["horizont", world.spawn_point() + Vector3.UP * 1.2, world.spawn_point() + Vector3(0.0, 8.0, 200.0)])
	result.append(["wildnis", world.ground_point(-60.0, 120.0) + Vector3.UP * 1.8, world.ground_point(-110.0, 60.0) + Vector3.UP * 4.0])
	return result


func _view(title: String, from: Vector3, to: Vector3) -> void:
	_camera.global_position = from
	_camera.look_at(to, Vector3.UP)
	await _frames(_wait_arg())
	await RenderingServer.frame_post_draw
	var image: Image = tree.root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + GameState.area + "_" + title + ".png"))
	print("Tour: %s · Draw Calls %d · Dreiecke %d" % [title,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	if OS.get_cmdline_user_args().has("--census"):
		_census()


## Grobe Zählung der sichtbaren Meshes je Elternknoten-Art (vor der Kamera, innerhalb der Sichtweite).
func _census() -> void:
	var counts: Dictionary[String, int] = {}
	var forward: Vector3 = -_camera.global_basis.z
	for node: Node in main.world.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = node as GeometryInstance3D
		if not geometry.is_visible_in_tree() or geometry is Label3D:
			continue
		var offset: Vector3 = geometry.global_position - _camera.global_position
		if geometry.visibility_range_end > 0.0 and offset.length() > geometry.visibility_range_end:
			continue
		if offset.length() > 30.0 and offset.normalized().dot(forward) < 0.3:
			continue
		var parent: Node = geometry.get_parent()
		while parent.get_script() == null and parent.get_parent() != main.world and parent != main.world:
			parent = parent.get_parent()
		var key: String = parent.get_script().get_global_name() if parent.get_script() != null else String(parent.name)
		counts[key] = counts.get(key, 0) + 1
	var keys: Array = counts.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return counts[a] > counts[b])
	for key: String in keys.slice(0, 10):
		print("    %s: %d" % [key, counts[key]])


func _frames(count: int) -> void:
	for i: int in count:
		await tree.process_frame
