class_name BalanceProbeSteps
extends RefCounted
## Schritte für balance_probe.gd.

const SPOT: Vector3 = Vector3(0.0, 0.0, 106.0)
## Messdauer: Schaden in beide Richtungen über diese Zeit, daraus Zeit bis zum Sieg und bis zum eigenen Tod.
const MEASURE_FRAMES: int = 1200
const DUMMY_HP: float = 1000000.0
## Abstand des Übungsziels in der Einzeltabelle (Auren, Klingenkreise und Nahkampf-Kreise erreichen es noch).
const SOLO_DISTANCE: float = 2.0
const LOADOUT: Array[StringName] = [&"mondlicht", &"flamme", &"frost", &"phantom"]
const BEASTS: Dictionary[int, Array] = {
	1: [&"wolf", &"eber", &"steinaffe"],
	2: [&"blitzwolf", &"bergbaer", &"jadeaffe"],
	3: [&"elektrowolf", &"riesenkrokodil", &"riesenskorpion"],
	4: [&"sandwurm", &"feuerfuchs", &"wuestenskorpion"],
	5: [&"weisser_tiger", &"seeschlange", &"donnerkronenwolf"],
}

var tree: SceneTree = null
var main: Main = null
var player: Player = null


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	await tree.physics_frame
	SaveSystem.save_path = "user://probe.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"A", "apt": 80.0, "death_mode": &"standard"})
	await _frames(20)
	player = main.player
	main.world.spawner.set_physics_process(false)
	if OS.get_cmdline_user_args().has("--solo"):
		await _solo_table()
		tree.quit()
		return
	print("Rang | Bestie | Leben | dein Schaden/s | Sieg nach s | Schaden/s an dir | dein Leben | Tod nach s")
	for rank: int in range(1, 6):
		for beast: StringName in BEASTS[rank]:
			await _fight(rank, beast)
	tree.quit()


## Schaden pro Sekunde jedes Gu allein gegen ein stehendes Ziel in SOLO_DISTANCE (10 s), je Rang – nah genug für Nahkampf-Formen.
func _solo_table() -> void:
	print("Familie | R1 | R2 | R3 | R4 | R5")
	for resource: Resource in DataRegistry.all(&"families"):
		var family: GuFamilyData = resource as GuFamilyData
		var cells: PackedStringArray = []
		for rank: int in range(1, 6):
			cells.append("%.0f" % await _solo(family, rank))
		print("%s | %s" % [family.id, " | ".join(cells)])


func _solo(family: GuFamilyData, rank: int) -> float:
	for node: Node in tree.get_nodes_in_group(Combat.GROUP_COMBATANTS):
		if node is Enemy:
			node.queue_free()
	for node: Node in Combat.fx_parent(tree).get_children():
		if node is EffectZone or node is OrbitBlades or node is GuTrap or node is Projectile:
			node.queue_free()
	await _frames(2)
	_setup(rank)
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	GameState.gu.append(GuInstance.create(family.member_for_rank(rank).id))
	GameState.slots[0] = 0
	var at: Vector3 = player.global_position + Vector3(0, 0, -SOLO_DISTANCE)
	var dummy: Enemy = main.world.spawner.spawn(DataRegistry.enemy(&"golem"), Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))
	dummy.data = dummy.data.duplicate()
	dummy.data.speed = 0.0
	dummy.data.damage = 0
	dummy.health.max_hp = DUMMY_HP
	dummy.health.hp = DUMMY_HP
	await _frames(2)
	for frame: int in 600:
		# Rückstoß würde das Ziel aus der Reichweite schieben – gemessen wird der Schaden, nicht die Kontrolle.
		dummy.unstoppable_time = 1.0
		player.targeting.soft_target = dummy
		GameState.essence = player.aperture.capacity()
		if player.holder.is_ready(0):
			player.use_slot(0)
		await tree.physics_frame
	return (DUMMY_HP - dummy.health.hp) / 10.0


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _setup(rank: int) -> void:
	var b: BalanceData = Balance.values
	GameState.rank = rank
	GameState.stage = 2
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	for i: int in LOADOUT.size():
		var instance: GuInstance = GuInstance.create(DataRegistry.family(LOADOUT[i]).member_for_rank(rank).id)
		GameState.gu.append(instance)
		GameState.slots[i] = i
	GameState.bonus_hp = Formulas.cultivated_hp(b, rank, 2) - b.player_base_hp
	player.health.max_hp = player.max_hp_now()
	player.health.hp = player.health.max_hp
	player.health.floor_hp = 1.0
	player.flat_damage = Formulas.cultivated_damage(b, rank, 2)
	GameState.essence = player.aperture.capacity()
	player.global_position = Vector3(SPOT.x, main.world.terrain.height_at(SPOT.x, SPOT.z) + 0.5, SPOT.z)


func _fight(rank: int, beast_id: StringName) -> void:
	for node: Node in tree.get_nodes_in_group(Combat.GROUP_COMBATANTS):
		if node is Enemy:
			node.queue_free()
	await _frames(2)
	_setup(rank)
	var at: Vector3 = player.global_position + Vector3(0, 0, -8.0)
	var beast: Enemy = main.world.spawner.spawn(DataRegistry.enemy(beast_id), Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))
	await _frames(2)
	var real_hp: float = beast.health.max_hp
	beast.health.max_hp = DUMMY_HP
	beast.health.hp = DUMMY_HP
	var start_hp: float = player.health.max_hp
	var taken: float = 0.0
	var last_hp: float = player.health.hp
	for frame: int in MEASURE_FRAMES:
		if not is_instance_valid(beast) or beast.is_dead():
			break
		player.targeting.soft_target = beast
		for slot: int in LOADOUT.size():
			if player.holder.is_ready(slot):
				player.use_slot(slot)
				break
		await tree.physics_frame
		if player.health.hp < last_hp:
			taken += last_hp - player.health.hp
		player.health.hp = player.health.max_hp
		last_hp = player.health.hp
	var seconds: float = MEASURE_FRAMES / 60.0
	var dealt: float = (DUMMY_HP - beast.health.hp) if is_instance_valid(beast) else 0.0
	var dps_out: float = dealt / seconds
	var dps_in: float = taken / seconds
	print("%d | %s | %d | %.1f | %.1f | %.1f | %d | %.1f" % [rank, beast_id, roundi(real_hp), dps_out, real_hp / maxf(dps_out, 0.01), dps_in, roundi(start_hp), start_hp / maxf(dps_in, 0.01)])
