class_name KillerMoveEffects
extends RefCounted
## Wirkungen der acht Killer Moves (GU_SYSTEM.md, Abschnitt 7). Zusatzwerte in Balance.killer_rules.

const COLOR_FIRE: Color = Color(1.0, 0.45, 0.15)
const COLOR_MOON: Color = Color(0.85, 0.9, 1.0)
const COLOR_WATER: Color = Color(0.3, 0.6, 1.0)
const COLOR_ICE: Color = Color(0.7, 0.95, 1.0)
const COLOR_POISON: Color = Color(0.55, 0.9, 0.2)
const COLOR_BONE: Color = Color(0.95, 0.9, 0.8)
const COLOR_THUNDER: Color = Color(0.6, 0.75, 1.0)
const COLOR_LEAF: Color = Color(0.5, 1.0, 0.5)


## caster ist der Spieler (Player); damage = Grundschaden × Stärke × mult.
static func execute(move: KillerMoveData, caster: Combatant, damage: float, aim: Vector3) -> void:
	var rule: Dictionary = Balance.values.killer_rules.get(move.id, {})
	var tree: SceneTree = caster.get_tree()
	match move.id:
		&"feuersturm":
			_fire_storm(caster, tree, damage, rule)
		&"mondschritt":
			_moon_step(caster, tree, damage, rule, aim)
		&"gewitterflut":
			_thunder_flood(caster, tree, damage, rule, aim)
		&"gletscherbruch":
			_glacier_break(caster, tree, damage, rule)
		&"pestfeuer":
			_plague_fire(caster, tree, damage, rule)
		&"knochenfestung":
			caster.call("start_reactive_armor", &"thorns", float(rule.get("time", 6.0)), float(rule.get("reduction", 0.3)), damage * float(rule.get("thorn_mult", 0.6)))
			Fx.sphere(tree, caster.aim_point(), 1.6, Color(COLOR_BONE, 0.4), float(rule.get("time", 6.0)))
		&"donnerpanzer":
			caster.call("start_reactive_armor", &"thunder", float(rule.get("time", 6.0)), float(rule.get("reduction", 0.3)), float(rule.get("charge_stacks", 3)))
			Fx.sphere(tree, caster.aim_point(), 1.6, Color(COLOR_THUNDER, 0.4), float(rule.get("time", 6.0)))
		&"rudelsegen":
			_pack_blessing(caster, tree, rule)
		_:
			push_warning("KillerMoveEffects: keine Wirkung für '%s'" % move.id)
	EventBus.floating_text.emit(Loc.t(move.display_name) + "!", caster.aim_point() + Vector3.UP, Color(1.0, 0.8, 0.3))
	EventBus.killer_move_used.emit(move.id)


static func _hit(caster: Combatant, damage: float, tags: Array[StringName], status: StringName = &"", stacks: int = 1) -> HitInfo:
	var hit := HitInfo.create(damage, caster, caster.team).with_tags(tags)
	if status != &"":
		hit.with_status(status, stacks)
	return hit


static func _fire_storm(caster: Combatant, tree: SceneTree, damage: float, rule: Dictionary) -> void:
	var radius: float = float(rule.get("radius", 5.0))
	var hostiles: Array[Combatant] = Combat.hostiles(tree, caster.team)
	for target: Combatant in Combat.in_radius(hostiles, caster.global_position, radius):
		target.receive_hit(_hit(caster, damage, [&"feuer", &"wind"], rule.get("status", &"brand"), int(rule.get("stacks", 1))))
		for neighbour: Combatant in Combat.in_radius(hostiles, target.global_position, float(rule.get("spread_radius", 4.0))):
			neighbour.status.apply_status(&"brand", 1)
	Fx.ring(tree, caster.global_position, radius, COLOR_FIRE, 0.6)
	Fx.sphere(tree, caster.aim_point(), radius, Color(COLOR_FIRE, 0.45), 0.5)


static func _moon_step(caster: Combatant, tree: SceneTree, damage: float, rule: Dictionary, aim: Vector3) -> void:
	var flat: Vector3 = Vector3(aim.x, 0.0, aim.z).normalized()
	var start: Vector3 = caster.aim_point()
	var end: Vector3 = start + flat * float(rule.get("distance", 10.0))
	for target: Combatant in Combat.on_line(Combat.hostiles(tree, caster.team), start, end, float(rule.get("width", 2.2))):
		target.receive_hit(_hit(caster, damage, [&"schnitt", &"licht"]))
	Fx.beam(tree, start, end, COLOR_MOON, 0.6, 0.8)
	caster.call("dash_to", end - Vector3.UP * (start.y - caster.global_position.y))


static func _thunder_flood(caster: Combatant, tree: SceneTree, damage: float, rule: Dictionary, aim: Vector3) -> void:
	var flat: Vector3 = Vector3(aim.x, 0.0, aim.z).normalized()
	var start: Vector3 = caster.aim_point()
	var end: Vector3 = start + flat * float(rule.get("length", 13.0))
	var targets: Array[Combatant] = Combat.on_line(Combat.hostiles(tree, caster.team), start, end, float(rule.get("width", 4.0)))
	for target: Combatant in targets:
		target.status.apply_status(&"nass", 1)
	Fx.beam(tree, start, end, Color(COLOR_WATER, 0.7), 0.5, float(rule.get("width", 4.0)))
	var strike: Callable = func() -> void:
		if not is_instance_valid(caster):
			return
		for target: Combatant in targets:
			if is_instance_valid(target) and not target.is_dead():
				target.receive_hit(_hit(caster, damage, [&"blitz"], &"ladung", 1))
				Fx.beam(tree, target.aim_point() + Vector3.UP * 8.0, target.aim_point(), COLOR_THUNDER, 0.3, 0.4)
	tree.create_timer(float(rule.get("delay", 0.35))).timeout.connect(strike)


static func _glacier_break(caster: Combatant, tree: SceneTree, damage: float, rule: Dictionary) -> void:
	var radius: float = float(rule.get("radius", 5.0))
	var targets: Array[Combatant] = Combat.in_radius(Combat.hostiles(tree, caster.team), caster.global_position, radius)
	for target: Combatant in targets:
		target.status.freeze(Balance.values.freeze_time)
	Fx.ring(tree, caster.global_position, radius, COLOR_ICE, 0.5)
	var shatter: Callable = func() -> void:
		if not is_instance_valid(caster):
			return
		for target: Combatant in targets:
			if is_instance_valid(target) and not target.is_dead():
				target.receive_hit(_hit(caster, damage, [&"wucht", &"eis"]))
		Fx.sphere(tree, caster.aim_point(), radius, Color(COLOR_ICE, 0.5), 0.4)
	tree.create_timer(float(rule.get("delay", 0.5))).timeout.connect(shatter)


static func _plague_fire(caster: Combatant, tree: SceneTree, damage: float, rule: Dictionary) -> void:
	var radius: float = float(rule.get("radius", 5.0))
	var targets: Array[Combatant] = Combat.in_radius(Combat.hostiles(tree, caster.team), caster.global_position, radius)
	for target: Combatant in targets:
		target.status.set_stacks(&"gift", int(rule.get("gift_stacks", 5)))
	Fx.sphere(tree, caster.aim_point(), radius, Color(COLOR_POISON, 0.4), 0.5)
	var ignite: Callable = func() -> void:
		if not is_instance_valid(caster):
			return
		for target: Combatant in targets:
			if is_instance_valid(target) and not target.is_dead():
				target.receive_hit(_hit(caster, damage, [&"feuer"], &"brand", 1))
		Fx.ring(tree, caster.global_position, radius, COLOR_FIRE, 0.6)
	tree.create_timer(0.4).timeout.connect(ignite)


static func _pack_blessing(caster: Combatant, tree: SceneTree, rule: Dictionary) -> void:
	for ally: Combatant in Combat.members(tree, caster.team):
		if ally != caster:
			ally.heal(ally.health.max_hp * float(rule.get("heal", 0.5)))
			Fx.ring(tree, ally.global_position, 1.5, COLOR_LEAF, 0.6)
	var spawner: Node = tree.get_first_node_in_group(&"enemy_spawner")
	if spawner != null:
		spawner.call("spawn_companion", rule.get("summon", &"wolf"), caster.global_position + Vector3(2.0, 0.0, 2.0), float(rule.get("summon_time", 20.0)), caster)
	Fx.sphere(tree, caster.aim_point(), 4.0, Color(COLOR_LEAF, 0.35), 0.6)
