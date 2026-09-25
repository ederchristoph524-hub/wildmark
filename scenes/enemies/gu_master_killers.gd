class_name GuMasterKillers
extends RefCounted
## Killer Moves der NPC-Gu-Meister: Aus je zwei ihrer Gu wird wie beim Spieler die beste passende Stufe gesucht
## (KillerMoveData.min_rank ≤ niedrigerer Gu-Rang). Die KI kündigt ihn mit langer Ausholzeit und großem Warnkreis an.

## Mögliche Killer Moves: [{move, a, b}] (a, b = Indizes in gu_list), stärkste Stufe zuerst.
static func options(master: GuMaster) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a: int in master.gu_list.size():
		for b: int in range(a + 1, master.gu_list.size()):
			var move: KillerMoveData = best_for(master.family_of(a).id, master.family_of(b).id, mini(master.gu_data(a).rank, master.gu_data(b).rank))
			if move != null:
				result.append({"move": move, "a": a, "b": b})
	result.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return (x["move"] as KillerMoveData).min_rank > (y["move"] as KillerMoveData).min_rank)
	return result


## Höchste Stufe des Paars bis max_rank (unabhängig davon, was der Spieler kennt).
static func best_for(first: StringName, second: StringName, max_rank: int) -> KillerMoveData:
	var found: KillerMoveData = null
	for resource: Resource in DataRegistry.all(&"killer_moves"):
		var move: KillerMoveData = resource as KillerMoveData
		if not ((move.family_a == first and move.family_b == second) or (move.family_a == second and move.family_b == first)):
			continue
		if move.min_rank <= max_rank and (found == null or move.min_rank > found.min_rank):
			found = move
	return found


## Essenzkosten wie beim Spieler: (Kosten a + Kosten b) × killer_cost_mult.
static func cost(master: GuMaster, option: Dictionary) -> float:
	return (master.essence_cost(option["a"]) + master.essence_cost(option["b"])) * Balance.values.killer_cost_mult


## Lebenskosten (Blutpfad) ebenso × killer_cost_mult.
static func hp_cost(master: GuMaster, option: Dictionary) -> float:
	return (master.hp_cost(option["a"]) + master.hp_cost(option["b"])) * Balance.values.killer_cost_mult


static func is_ready(master: GuMaster, option: Dictionary) -> bool:
	return master.is_ready(option["a"]) and master.is_ready(option["b"]) and master.essence + 0.001 >= cost(master, option) \
		and master.health.hp > hp_cost(master, option) * 2.0


## Wirkt den Killer Move; beide Gu gehen auf Abklingzeit.
static func execute(master: GuMaster, option: Dictionary, aim: Vector3, foe: Combatant) -> void:
	if not is_ready(master, option):
		return
	var move: KillerMoveData = option["move"]
	Sound.play(&"killer", master.global_position)
	var damage: float = 0.0
	var power: float = INF
	for index: int in [option["a"], option["b"]]:
		damage = maxf(damage, float(master.family_of(index).base_r1.get(KillerMoveController.DAMAGE_KEY, 0.0)))
		power = minf(power, Formulas.gu_power(Balance.values, master.gu_data(index).rank, master.rank))
	master.essence = maxf(0.0, master.essence - cost(master, option))
	master.pay_hp(hp_cost(master, option))
	for index: int in [option["a"], option["b"]]:
		master.put_on_cooldown(index)
	KillerMoveEffects.execute(move, master, damage * power * move.damage_mult, aim, foe, power)
