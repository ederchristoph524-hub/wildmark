class_name Combat
extends RefCounted
## Hilfsfunktionen für Kampfabfragen: Ziele im Umkreis, auf Linien und in Kegeln (über Gruppen, ohne Physik).

const GROUP_COMBATANTS: StringName = &"combatants"
const GROUP_FX_ROOT: StringName = &"fx_root"


## Alle lebenden Gegner eines Teams (also Ziele für Angreifer aus attacker_team).
static func hostiles(tree: SceneTree, attacker_team: int) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for node: Node in tree.get_nodes_in_group(GROUP_COMBATANTS):
		var combatant: Combatant = node as Combatant
		if combatant != null and combatant.team != attacker_team and not combatant.is_dead():
			result.append(combatant)
	return result


## Lebende Mitglieder eines Teams.
static func members(tree: SceneTree, team: int) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for node: Node in tree.get_nodes_in_group(GROUP_COMBATANTS):
		var combatant: Combatant = node as Combatant
		if combatant != null and combatant.team == team and not combatant.is_dead():
			result.append(combatant)
	return result


static func in_radius(candidates: Array[Combatant], center: Vector3, radius: float) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for combatant: Combatant in candidates:
		if _flat_distance(combatant.global_position, center) <= radius + combatant.body_radius:
			result.append(combatant)
	return result


## Ziele entlang einer Linie, sortiert nach Entfernung vom Start.
static func on_line(candidates: Array[Combatant], from: Vector3, to: Vector3, width: float) -> Array[Combatant]:
	var hits: Array[Combatant] = []
	for combatant: Combatant in candidates:
		var point: Vector3 = Geometry3D.get_closest_point_to_segment(combatant.aim_point(), from, to)
		if point.distance_to(combatant.aim_point()) <= width * 0.5 + combatant.body_radius:
			hits.append(combatant)
	hits.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	return hits


## Ziele in einem Kegel vor from (Winkel in Grad, gesamt).
static func in_cone(candidates: Array[Combatant], from: Vector3, forward: Vector3, reach: float, angle_deg: float) -> Array[Combatant]:
	var result: Array[Combatant] = []
	var flat_forward: Vector3 = Vector3(forward.x, 0.0, forward.z).normalized()
	for combatant: Combatant in candidates:
		var offset: Vector3 = combatant.global_position - from
		offset.y = 0.0
		if offset.length() > reach + combatant.body_radius:
			continue
		if offset.length() < combatant.body_radius or rad_to_deg(flat_forward.angle_to(offset.normalized())) <= angle_deg * 0.5:
			result.append(combatant)
	return result


static func nearest(candidates: Array[Combatant], point: Vector3) -> Combatant:
	var best: Combatant = null
	var best_distance: float = INF
	for combatant: Combatant in candidates:
		var distance: float = combatant.global_position.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best = combatant
	return best


## Knoten, unter dem Effekte und Geschosse erzeugt werden.
static func fx_parent(tree: SceneTree) -> Node:
	var root: Node = tree.get_first_node_in_group(GROUP_FX_ROOT)
	return root if root != null else tree.current_scene


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
