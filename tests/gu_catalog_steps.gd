class_name GuCatalogSteps
extends RefCounted
## Schritte für test_gu_catalog.gd: Übungsziele aufstellen, jeden Gu, Killer Move und jede Bestien-Fähigkeit auslösen
## und prüfen, dass etwas passiert (eigene Datei, weil Autoloads erst nach dem Start bekannt sind).

const SPOT: Vector3 = Vector3(0.0, 0.0, 106.0)
const WAIT_FRAMES: int = 100
const DUMMY_HP: float = 100000.0
## Wirkformen ohne Schaden: geprüft wird ein Zustand am Spieler oder in der Welt.
const UTILITY_FORMS: Array[StringName] = [&"selbstschild", &"selbst_heilung", &"bewegung", &"zaehmen", &"tarnung", &"staerkung", &"beschwoerung",
	&"eingebung", &"glueck", &"verwandlung"]

var tree: SceneTree = null
var main: Main = null
var player: Player = null
var _failures: PackedStringArray = []
var _dummies: Array[Enemy] = []


func run(scene_tree: SceneTree) -> void:
	tree = scene_tree
	await tree.physics_frame
	SaveSystem.save_path = "user://test_catalog.json"
	SaveSystem.delete_save()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	tree.root.add_child(main)
	await _frames(3)
	EventBus.new_game_requested.emit({"first_family": &"mondlicht", "talent_grade": &"A", "apt": 90.0, "death_mode": &"standard"})
	await _frames(20)
	player = main.player
	main.world.spawner.set_physics_process(false)
	# Wandernde Gu-Meister würden die Messung stören.
	main.world.wanderers.set_process(false)
	for node: Node in tree.get_nodes_in_group(Wanderer.GROUP):
		node.queue_free()
	var tested: int = 0
	for resource: Resource in DataRegistry.all(&"families"):
		var family: GuFamilyData = resource as GuFamilyData
		for member: GuData in family.members:
			await _test_gu(family, member)
			tested += 1
	print("Gu geprüft: %d" % tested)
	var moves: int = 0
	for resource: Resource in DataRegistry.all(&"killer_moves"):
		await _test_killer(resource as KillerMoveData)
		moves += 1
	print("Killer Moves geprüft: %d" % moves)
	await _test_abilities()
	_test_relics()
	for failure: String in _failures:
		printerr("FEHLGESCHLAGEN: ", failure)
	print("test_gu_catalog: %s" % ("OK" if _failures.is_empty() else "%d Fehler" % _failures.size()))
	tree.quit(0 if _failures.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _check(condition: bool, text: String) -> void:
	if not condition:
		_failures.append(text)


## Spieler zurück auf den freien Platz, volle Werte, alles andere weg; drei Übungsziele vor ihm.
func _reset() -> void:
	for node: Node in tree.get_nodes_in_group(Combat.GROUP_COMBATANTS):
		if node is Enemy:
			node.queue_free()
	for node: Node in Combat.fx_parent(tree).get_children():
		if node is EffectZone or node is OrbitBlades or node is GuTrap or node is Projectile:
			node.queue_free()
	await _frames(2)
	player.global_position = Vector3(SPOT.x, main.world.terrain.height_at(SPOT.x, SPOT.z) + 0.5, SPOT.z)
	player.velocity = Vector3.ZERO
	player.health.hp = player.health.max_hp
	player.reductions.clear()
	player.buffs.clear()
	player.stealth_time = 0.0
	player.invulnerable_time = 0.0
	_dummies.clear()
	for offset: Vector3 in [Vector3(0, 0, -3.0), Vector3(0, 0, -6.0), Vector3(1.5, 0, -4.5)]:
		_dummies.append(_spawn_dummy(&"golem", offset))
	await _frames(3)


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


func _damage_dealt() -> float:
	var total: float = 0.0
	for dummy: Enemy in _dummies:
		if is_instance_valid(dummy):
			total += DUMMY_HP - dummy.health.hp
	return total


func _test_gu(family: GuFamilyData, gu: GuData) -> void:
	await _reset()
	var tame_target: Enemy = null
	if family.form == &"zaehmen":
		tame_target = _spawn_dummy(&"ratte", Vector3(0, 0, -2.5))
		tame_target.health.max_hp = 8.0
		tame_target.health.hp = 1.0
	if family.form == &"selbst_heilung":
		player.health.hp = player.health.max_hp * 0.4
	var start_hp: float = player.health.hp
	var start_pos: Vector3 = player.global_position
	var caster := GuCaster.new(player, family, gu)
	caster.power = Formulas.gu_power(Balance.values, gu.rank, gu.rank)
	caster.aim_direction = Vector3.FORWARD
	caster.target = _dummies[0] if tame_target == null else tame_target
	var cast_ok: bool = caster.cast()
	var stealthed: bool = player.stealth_time > 0.0
	var buffed: bool = not player.buffs.is_empty()
	var shielded: bool = not player.reductions.is_empty()
	var hasted: bool = player.holder.haste_time > 0.0
	var lucky: bool = player.luck_time > 0.0
	await _frames(25)
	var grown: bool = player.model.scale.x > 1.05
	player.luck_time = 0.0
	var swapped: bool = player.global_position.distance_to(start_pos) > 1.0
	player.holder.haste_time = 0.0
	await _frames(WAIT_FRAMES)
	var label: String = "%s (%s, Rang %d, %s)" % [gu.id, family.id, gu.rank, family.form]
	_check(cast_ok, label + ": cast() liefert false")
	match family.form:
		&"selbstschild":
			_check(shielded, label + ": kein Schutz")
		&"selbst_heilung":
			_check(player.health.hp > start_hp, label + ": keine Heilung")
		&"bewegung":
			_check(player.global_position.distance_to(start_pos) > 0.3, label + ": keine Bewegung")
		&"zaehmen":
			_check(not tree.get_nodes_in_group(Enemy.GROUP_COMPANIONS).is_empty(), label + ": nichts gezähmt")
		&"tarnung":
			_check(stealthed, label + ": keine Tarnung")
		&"staerkung":
			_check(buffed, label + ": keine Stärkung")
		&"beschwoerung":
			_check(not tree.get_nodes_in_group(Enemy.GROUP_COMPANIONS).is_empty(), label + ": nichts beschworen")
		&"eingebung":
			_check(hasted, label + ": Abklingzeiten nicht verkürzt")
		&"glueck":
			_check(lucky, label + ": kein Glück")
		&"verwandlung":
			_check(buffed and grown, label + ": keine Verwandlung")
		&"tausch":
			_check(swapped and _damage_dealt() > 0.0, label + ": kein Platztausch mit Schaden")
		_:
			if family.form == &"falle":
				await _trigger_traps()
			_check(_damage_dealt() > 0.0, label + ": kein Schaden an den Übungszielen")


## Fallen lösen erst aus, wenn ein Gegner darauf tritt: Übungsziele auf die Fallen stellen.
func _trigger_traps() -> void:
	var index: int = 0
	for node: Node in Combat.fx_parent(tree).get_children():
		if node is GuTrap and index < _dummies.size():
			_dummies[index].global_position = (node as Node3D).global_position + Vector3.UP * 0.3
			index += 1
	await _frames(40)


func _test_killer(move: KillerMoveData) -> void:
	await _reset()
	var summons_before: int = tree.get_nodes_in_group(Enemy.GROUP_COMPANIONS).size()
	player.health.hp = player.health.max_hp * 0.5
	var start_hp: float = player.health.hp
	KillerMoveEffects.execute(move, player, 60.0, Vector3.FORWARD, _dummies[0], 1.0)
	var changed_self: bool = not player.reductions.is_empty() or not player.buffs.is_empty() or player.stealth_time > 0.0
	await _frames(WAIT_FRAMES)
	await _trigger_traps()
	var summoned: bool = tree.get_nodes_in_group(Enemy.GROUP_COMPANIONS).size() > summons_before
	var healed: bool = player.health.hp > start_hp
	_check(_damage_dealt() > 0.0 or changed_self or summoned or healed, "Killer Move %s: keine Wirkung" % move.id)


## Jede Bestie mit Fähigkeit setzt sie einmal gegen den Spieler ein (keine Fehler, Spieler wird getroffen oder Diener erscheinen).
func _test_abilities() -> void:
	for resource: Resource in DataRegistry.all(&"enemies"):
		var data: EnemyData = resource as EnemyData
		if data.ability.is_empty():
			continue
		await _reset()
		var distance: float = minf(4.0, data.ability_range * 0.6)
		var at: Vector3 = player.global_position + Vector3(0, 0, -distance)
		var beast: Enemy = main.world.spawner.spawn(data, Vector3(at.x, main.world.terrain.height_at(at.x, at.z) + 0.3, at.z))
		await _frames(2)
		beast.target = player
		player.health.max_hp = 100000.0
		player.health.hp = 100000.0
		var before: int = tree.get_nodes_in_group(Enemy.GROUP_ENEMIES).size()
		EnemyAbilities.use(beast, distance)
		await _frames(WAIT_FRAMES)
		var hurt: bool = player.health.hp < 100000.0
		var spawned: bool = tree.get_nodes_in_group(Enemy.GROUP_ENEMIES).size() > before
		_check(hurt or spawned, "Fähigkeit von %s wirkt nicht" % data.id)
		player.health.max_hp = player.max_hp_now()
		player.health.hp = player.health.max_hp
		print("Fähigkeit geprüft: %s" % data.id)


## Relikt-Gu verfeinern die Wand um eine Stufe, aber nur auf ihrem Rang.
func _test_relics() -> void:
	GameState.rank = 1
	GameState.stage = 0
	GameState.add_item(&"reliquie_gruenkupfer", 1)
	GameState.add_item(&"reliquie_rotstahl", 1)
	_check(Relics.blocked_reason(&"reliquie_rotstahl") != "", "Rotstahl-Relikt wirkt nicht auf Rang 1")
	_check(Relics.use(&"reliquie_gruenkupfer", player.aperture) and GameState.stage == 1, "Grünkupfer-Relikt hebt die Stufe")
