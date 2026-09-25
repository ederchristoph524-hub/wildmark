class_name CaptureGuGallerySteps
extends RefCounted
## Schritte für capture_gu_gallery.gd: Übungsplatz, je Familie ein Gu des gewählten Rangs, zwei Momente je Feld.

const OUT_DIR: String = "res://build/gallery/"
const SPOT: Vector3 = Vector3(0.0, 0.0, 106.0)
const THUMB: Vector2i = Vector2i(320, 180)
const COLUMNS: int = 1
const ROWS: int = 5
const MOMENTS: Array[int] = [4, 14, 36]
## Ausschnitt um Spieler und Übungsziele (Fensterpixel bei 1280×720), damit die Wirkung groß genug ist.
const CROP: Rect2i = Rect2i(240, 110, 800, 450)
const DUMMY_HP: float = 100000.0

var tree: SceneTree = null
var main: Main = null
var player: Player = null
var _sheet: Image = null
var _sheet_index: int = 0
var _cell: int = 0
var _legend: PackedStringArray = []


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	SaveSystem.save_path = "user://test_gallery.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"A", "apt": 90.0, "death_mode": &"standard"})
	await _frames(30)
	player = main.player
	main.world.spawner.set_physics_process(false)
	main.world.wanderers.set_process(false)
	for node: Node in tree.get_nodes_in_group(Wanderer.GROUP):
		node.queue_free()
	GameState.time_of_day = 0.35
	main.hud.visible = false
	var rank: int = _int_arg("--rank=", 3)
	var only: PackedStringArray = _list_arg("--only=")
	for resource: Resource in DataRegistry.all(&"families"):
		var family: GuFamilyData = resource as GuFamilyData
		if not only.is_empty() and String(family.id) not in only:
			continue
		for member: GuData in family.members:
			if member.rank == rank:
				await _capture(family, member)
	_flush()
	var legend := FileAccess.open(OUT_DIR + "legende.txt", FileAccess.WRITE)
	legend.store_string("\n".join(_legend))
	print("Galerie: %d Felder" % _legend.size())
	tree.quit(0)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _capture(family: GuFamilyData, gu: GuData) -> void:
	await _reset()
	var target: Enemy = _spawn_dummy(&"golem", Vector3(0, 0, -5.0))
	_spawn_dummy(&"golem", Vector3(-1.8, 0, -7.0))
	_spawn_dummy(&"golem", Vector3(1.8, 0, -7.5))
	if family.form == &"zaehmen":
		target = _spawn_dummy(&"ratte", Vector3(0, 0, -3.0))
		target.health.max_hp = 8.0
		target.health.hp = 1.0
	await _frames(4)
	var caster := GuCaster.new(player, family, gu)
	caster.power = Formulas.gu_power(Balance.values, gu.rank, gu.rank)
	caster.aim_direction = Vector3.FORWARD
	caster.target = target
	caster.cast()
	var shots: Array[Image] = []
	var waited: int = 0
	for moment: int in MOMENTS:
		await _frames(moment - waited)
		waited = moment
		await RenderingServer.frame_post_draw
		var image: Image = tree.root.get_texture().get_image().get_region(CROP)
		image.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_BILINEAR)
		shots.append(image)
	_place(shots, "%s · %s (%s, %s)" % [family.id, gu.id, family.form, family.path])


func _reset() -> void:
	for node: Node in tree.get_nodes_in_group(Combat.GROUP_COMBATANTS):
		if node is Enemy:
			node.queue_free()
	for node: Node in Combat.fx_parent(tree).get_children():
		if node is EffectZone or node is OrbitBlades or node is GuTrap or node is Projectile or node is CPUParticles3D:
			node.queue_free()
	for node: Node in tree.get_nodes_in_group(Enemy.GROUP_COMPANIONS):
		node.queue_free()
	await _frames(20)
	player.global_position = Vector3(SPOT.x, main.world.terrain.height_at(SPOT.x, SPOT.z) + 0.5, SPOT.z)
	player.velocity = Vector3.ZERO
	player.health.hp = player.health.max_hp
	player.buffs.clear()
	player.reductions.clear()
	player.stealth_time = 0.0
	player.camera_rig.yaw = 0.55
	player.camera_rig.pitch = -0.3
	await _frames(10)


func _spawn_dummy(id: StringName, offset: Vector3) -> Enemy:
	var at: Vector3 = player.global_position + offset
	var enemy: Enemy = main.world.spawner.spawn(DataRegistry.enemy(id), Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))
	enemy.data = enemy.data.duplicate()
	enemy.data.speed = 0.0
	enemy.data.damage = 0
	enemy.data.ability = []
	enemy.data.behavior = &""
	enemy.health.max_hp = DUMMY_HP
	enemy.health.hp = DUMMY_HP
	return enemy


func _place(shots: Array[Image], label: String) -> void:
	if _sheet == null:
		_sheet = Image.create(THUMB.x * MOMENTS.size() * COLUMNS + (COLUMNS - 1) * 8, THUMB.y * ROWS + (ROWS - 1) * 4, false, Image.FORMAT_RGB8)
		_sheet.fill(Color(0.1, 0.1, 0.1))
	var column: int = _cell % COLUMNS
	var row: int = floori(float(_cell) / COLUMNS)
	for i: int in shots.size():
		var shot: Image = shots[i]
		shot.convert(Image.FORMAT_RGB8)
		var at := Vector2i(column * (THUMB.x * MOMENTS.size() + 8) + i * THUMB.x, row * (THUMB.y + 4))
		_sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, THUMB), at)
	_legend.append("Bogen %d, Zeile %d, Spalte %d: %s" % [_sheet_index + 1, row + 1, column + 1, label])
	_cell += 1
	if _cell >= COLUMNS * ROWS:
		_flush()


func _flush() -> void:
	if _sheet == null:
		return
	_sheet.save_png(OUT_DIR + "bogen_%d.png" % (_sheet_index + 1))
	_sheet = null
	_sheet_index += 1
	_cell = 0


func _int_arg(prefix: String, fallback: int) -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return int(arg.trim_prefix(prefix))
	return fallback


func _list_arg(prefix: String) -> PackedStringArray:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix).split(",")
	return PackedStringArray()
