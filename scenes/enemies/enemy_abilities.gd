class_name EnemyAbilities
extends RefCounted
## Sonderfähigkeiten der Bestien nach Feld beh: Diener beschwören, Verbündete heilen, hinter das Ziel teleportieren.

const MAX_MINIONS: int = 3
const HEAL_RADIUS: float = 6.0
const HEAL_INTERVAL: float = 3.0
const TELEPORT_INTERVAL: float = 5.0
const TELEPORT_MIN_DISTANCE: float = 3.0


## Führt die Fähigkeit aus und liefert die Abklingzeit bis zum nächsten Einsatz.
static func use(enemy: Enemy, distance: float) -> float:
	var b: BalanceData = Balance.values
	match enemy.data.behavior:
		Enemy.BEH_SPAWN, Enemy.BEH_BOSS:
			if enemy.data.minion != &"":
				_spawn_minion(enemy)
			return b.spawn_minion_interval
		Enemy.BEH_HEAL:
			_heal_allies(enemy)
			return HEAL_INTERVAL
		Enemy.BEH_TELEPORT:
			if distance > TELEPORT_MIN_DISTANCE and enemy.target != null:
				_teleport_behind(enemy, enemy.target)
			return TELEPORT_INTERVAL
	return b.spawn_minion_interval


static func _spawn_minion(enemy: Enemy) -> void:
	enemy.minions = enemy.minions.filter(func(m: Enemy) -> bool: return is_instance_valid(m) and not m.is_dead())
	if enemy.minions.size() >= MAX_MINIONS:
		return
	var spawner: Node = enemy.get_tree().get_first_node_in_group(&"enemy_spawner")
	if spawner == null:
		return
	var offset := Vector3(randf_range(-1.5, 1.5), 0.5, randf_range(-1.5, 1.5))
	var minion: Enemy = spawner.call("spawn_minion", enemy.data.minion, enemy.global_position + offset, enemy.team)
	if minion != null:
		enemy.minions.append(minion)


static func _heal_allies(enemy: Enemy) -> void:
	for ally: Combatant in Combat.in_radius(Combat.members(enemy.get_tree(), enemy.team), enemy.global_position, HEAL_RADIUS):
		if ally.health.ratio() < 1.0:
			ally.heal(Balance.values.heal_amount)
			Fx.ring(enemy.get_tree(), ally.global_position, 1.0, Color(0.5, 1.0, 0.5), 0.4)


static func _teleport_behind(enemy: Enemy, target: Combatant) -> void:
	var behind: Vector3 = target.global_position - (target.global_position - enemy.global_position).normalized() * 2.0
	Fx.sphere(enemy.get_tree(), enemy.aim_point(), 1.0, Color(0.3, 0.1, 0.5, 0.6), 0.3)
	enemy.global_position = Vector3(behind.x, target.global_position.y + 0.5, behind.z)
