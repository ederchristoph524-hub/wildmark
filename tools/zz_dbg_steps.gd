extends RefCounted
func run(t: SceneTree) -> void:
	var probe: RefCounted = (load("res://tools/balance_probe_steps.gd") as GDScript).new()
	probe.tree = t
	await t.physics_frame
	SaveSystem.save_path = "user://probe.json"
	SaveSystem.delete_save()
	probe.main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	t.root.add_child(probe.main)
	for i in 3: await t.physics_frame
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"A", "apt": 80.0, "death_mode": &"standard"})
	for i in 20: await t.physics_frame
	probe.player = probe.main.player
	probe.main.world.spawner.set_physics_process(false)
	var rank: int = int(OS.get_environment("RANK"))
	probe._setup(rank)
	var p: Player = probe.player
	var at: Vector3 = p.global_position + Vector3(0, 0, -8.0)
	var beast: Enemy = probe.main.world.spawner.spawn(DataRegistry.enemy(StringName(OS.get_environment("BEAST"))), Vector3(at.x, probe.main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))
	for i in 2: await t.physics_frame
	beast.health.max_hp = 100000
	beast.health.hp = 100000
	for frame in 600:
		p.targeting.soft_target = beast
		for slot in 4:
			if p.holder.is_ready(slot):
				p.use_slot(slot)
				printerr("f%d cast %d" % [frame, slot])
				break
		if frame % 20 == 0:
			printerr("f%d st%d d%.1f stun%.2f frz%.2f fear%s slow%.2f lost%.0f php%.0f" % [frame, beast.state, beast.global_position.distance_to(p.global_position), beast.status.stun_time, beast.status.frozen_time, beast.status.is_feared(), beast.status.speed_multiplier(), 100000 - beast.health.hp, p.health.hp])
		await t.physics_frame
	t.quit()
