class_name CombatSmokeSteps
extends RefCounted
## Weitere Durchspiel-Schritte (Duell, Ziel antippen, Slot-Wechsel), damit game_smoke_steps.gd unter 400 Zeilen bleibt.

var steps: GameSmokeSteps = null


func _init(owner_steps: GameSmokeSteps) -> void:
	steps = owner_steps


func run() -> void:
	print("-- combat_smoke")
	await _test_tap_target()
	await _test_slot_switch()
	await _test_physiques()
	await _test_duel()


func _test_tap_target() -> void:
	await steps._clear_enemies()
	var forward: Vector3 = steps.player.camera_rig.flat_forward()
	var near: Enemy = steps._spawn(&"wolf", forward * 6.0)
	var far: Enemy = steps._spawn(&"slime", forward * 9.0 + forward.cross(Vector3.UP) * 3.0)
	steps._freeze_in_place(near)
	steps._freeze_in_place(far)
	await steps._frames(3)
	var camera: Camera3D = steps.tree.root.get_camera_3d()
	var targeting: TargetingComponent = steps.player.targeting
	steps._check(targeting.tap_select(camera, camera.unproject_position(far.aim_point()) + Vector2(12.0, 6.0)) == far, "Gegner antippen fixiert ihn")
	await steps._frames(2)
	targeting.tap_select(camera, camera.unproject_position(near.aim_point()))
	steps._check(targeting.locked_target == near, "anderen Gegner antippen wechselt")
	targeting.tap_select(camera, camera.unproject_position(near.aim_point()))
	steps._check(targeting.locked_target == null, "erneut antippen löst die Fixierung")
	# Echter Touch-Weg mit Handy-UI-Skalierung: Tippen über die Touch-Steuerung.
	steps.tree.root.content_scale_factor = Main.TOUCH_UI_SCALE
	steps.main.hud.touch.visible = true
	await steps._frames(2)
	await _tap(camera.unproject_position(far.aim_point()))
	steps._check(targeting.locked_target == far, "Tippen auf dem Bildschirm fixiert den Gegner (UI-Skalierung %.1f)" % Main.TOUCH_UI_SCALE)
	steps.main.hud.touch.visible = false
	steps.tree.root.content_scale_factor = 1.0
	targeting.locked_target = null
	await steps._clear_enemies()


func _test_slot_switch() -> void:
	GameState.gu.clear()
	GameState.slots.fill(GameState.EMPTY_SLOT)
	steps._give(&"mondlicht", 0)
	steps._give(&"wirbel", 1)
	var loadout: LoadoutComponent = steps.player.loadout
	await steps._frames(int(Balance.values.combat_linger * 60.0) + 5)
	steps._check(not loadout.in_combat() and loadout.assign(1, 2) and GameState.slots[2] == 1 and GameState.slots[1] == GameState.EMPTY_SLOT, "außerhalb des Kampfes wechselt der Slot sofort")
	loadout.mark_combat()
	steps._check(not loadout.assign(1, 3) and GameState.slots[2] == 1 and loadout.shown_slots()[3] == 1, "im Kampf wird der Wechsel vorgemerkt")
	loadout.begin_pending()
	await steps._frames(60)
	steps._check(loadout.is_channeling() and GameState.slots[2] == 1, "Wechsel wird kanalisiert")
	await steps._frames(roundi(Balance.values.slot_switch_channel * 60.0))
	steps._check(GameState.slots[3] == 1 and GameState.slots[2] == GameState.EMPTY_SLOT and not loadout.is_channeling(), "nach der Kanalisierung gewechselt")
	loadout.mark_combat()
	loadout.assign(1, 0)
	loadout.begin_pending()
	await steps._frames(30)
	steps.player.invulnerable_time = 0.0
	steps.player.receive_hit(HitInfo.create(5.0, null, Combatant.TEAM_ENEMY))
	steps._check(not loadout.is_channeling() and GameState.slots[3] == 1 and GameState.slots[0] == 0, "Treffer bricht den Wechsel ab")


func _test_physiques() -> void:
	var physiques: Array[PhysiqueData] = DataRegistry.progression().physiques
	var complete: bool = physiques.size() == 10
	for physique: PhysiqueData in physiques:
		complete = complete and Balance.values.physique_rules.has(physique.id) and PhysiqueEffects.effect_lines(physique.id).size() >= 2
	steps._check(complete, "zehn Extreme Physiques mit Regeln und Wirkungstext")
	var player: Player = steps.player
	var instance: GuInstance = GameState.slot_instance(0) if GameState.slot_instance(0) != null else steps._give(&"mondlicht", 0)
	var cost: float = player.holder.essence_cost(instance)
	var cooldown: float = player.holder.cooldown_of(instance)
	var power: float = player.holder.power_of(instance)
	var max_hp: float = player.health.max_hp
	GameState.physique = &"dream"
	steps._check(is_equal_approx(player.holder.essence_cost(instance), cost * 0.6), "Traum: Gu kosten 40 % weniger")
	GameState.physique = &"moon"
	steps._check(is_equal_approx(player.holder.cooldown_of(instance), cooldown * 0.5) and is_equal_approx(player.holder.power_of(instance), power * Balance.values.physique_path_power), "Mond: halbe Abklingzeit, Mondlicht stärker")
	GameState.physique = &"strength"
	await steps._frames(2)
	steps._check(is_equal_approx(player.health.max_hp, max_hp + 50.0) and is_equal_approx(player.flat_damage, 5.0), "Kraft: mehr Leben und Grundschaden")
	GameState.physique = &"ice"
	await steps._frames(2)
	player.status.apply_status(&"gift", 3)
	steps._check(player.status.stacks_of(&"gift") == 0, "Eisseele: immun gegen Gift")
	GameState.physique = &"lightning"
	var hit := HitInfo.create(10.0, player, player.team)
	PhysiqueEffects.decorate_hit(hit, player)
	steps._check(hit.status == &"brand", "Blitzglanz: Treffer entzünden")
	await _test_physique_wall()
	GameState.physique = &"metal"
	var saved: Dictionary = GameState.to_dict()
	GameState.physique = &""
	GameState.from_dict(saved)
	steps._check(GameState.physique == &"metal", "Physique wird gespeichert und geladen")
	GameState.physique = &""
	await steps._frames(2)


## Extreme Physiques verfeinern die Wand ohne Meditation und ohne Essenz.
func _test_physique_wall() -> void:
	var stage: int = GameState.stage
	GameState.stage = 0
	GameState.wall = 0.0
	GameState.physique = &"forest"
	await steps._frames(60)
	steps._check(GameState.wall > 0.0 and not steps.player.aperture.meditating, "Wand verfeinert sich von selbst (%.3f)" % GameState.wall)
	GameState.physique = &""
	var wall: float = GameState.wall
	await steps._frames(30)
	steps._check(is_equal_approx(GameState.wall, wall), "ohne Physique kein Selbstverfeinern")
	GameState.stage = stage


func _tap(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		# Eingaben kommen in Fensterkoordinaten; die Streckung (UI-Skalierung) rechnet Godot selbst heraus.
		touch.position = steps.tree.root.get_final_transform() * at
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await steps._frames(2)


func _test_duel() -> void:
	await steps._clear_enemies()
	var masters: Array[Node] = steps.tree.get_nodes_in_group(Player.GROUP_INTERACTABLES).filter(func(n: Node) -> bool: return n is GuMaster)
	steps._check(masters.size() == 1, "ein Gu-Meister im Dorf")
	if masters.is_empty():
		return
	var master: GuMaster = masters[0]
	steps._check(master.gu_list.size() == 3 and not master in Combat.hostiles(steps.tree, steps.player.team), "drei Gu, außerhalb des Duells kein Ziel")
	steps.player.global_position = master.global_position + Vector3(0.0, 0.3, 6.0)
	master.start_duel(steps.player)
	await steps._frames(roundi(Balance.values.duel_countdown * 60.0) + 10)
	steps._check(master.duel_state == GuMaster.DuelState.FIGHT and master in Combat.hostiles(steps.tree, steps.player.team), "Duell beginnt nach dem Countdown")
	var hp_before: float = steps.player.health.hp
	await steps._frames(240)
	steps._check(master.essence < master.essence_capacity() - 1.0 and steps.player.health.hp < hp_before, "Gu-Meister setzt Gu ein und trifft")
	steps.player.health.apply_damage(9999.0)
	await steps._frames(2)
	steps._check(not steps.player.is_dead() and steps.player.health.ratio() > 0.99 and master.duel_state == GuMaster.DuelState.IDLE, "Niederlage bei 15 %: niemand stirbt, beide geheilt")
	var stones: int = GameState.item_count(&"kristall")
	var drop_chance: float = Balance.values.duel_gu_drop_chance
	Balance.values.duel_gu_drop_chance = 0.0
	master.start_duel(steps.player)
	await steps._frames(roundi(Balance.values.duel_countdown * 60.0) + 10)
	master.receive_hit(HitInfo.create(master.health.max_hp * 0.9, steps.player, steps.player.team))
	await steps._frames(2)
	Balance.values.duel_gu_drop_chance = drop_chance
	steps._check(GameState.duels_won == 1 and GameState.item_count(&"kristall") == stones + Balance.values.duel_first_win_stones, "Sieg: Gu-Meister gibt auf, Lohn erhalten")
	steps._check(master.team == Combatant.TEAM_PLAYER and master.health.ratio() > 0.99 and steps.player.health.floor_hp == 0.0, "nach dem Duell zurückgesetzt")
	var wild: WildGu = DuelRewards.drop_gu(master)
	steps._check(wild != null and wild.gu is GuData, "Gu-Meister kann einen Gu als wilden Gu verlieren")
	wild.queue_free()
