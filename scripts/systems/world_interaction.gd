class_name WorldInteraction
extends RefCounted
## Suche nach Sammelstellen und interaktiven Objekten in der Nähe einer Figur.


## Nächster Knoten einer Gruppe innerhalb von max_distance, sonst null.
static func nearest(from: Node3D, group: StringName, max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_distance: float = max_distance
	for node: Node in from.get_tree().get_nodes_in_group(group):
		var candidate: Node3D = node as Node3D
		var distance: float = candidate.global_position.distance_to(from.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


## Faustschlag ins Leere trifft die nächste Sammelstelle vor der Figur.
static func harvest(from: Node3D, forward: Vector3, angle_deg: float) -> void:
	var best: Node3D = null
	var best_distance: float = Balance.values.fist_range + 1.0
	for node: Node in from.get_tree().get_nodes_in_group(Player.GROUP_HARVESTABLE):
		var target: Node3D = node as Node3D
		var offset: Vector3 = target.global_position - from.global_position
		offset.y = 0.0
		if offset.length() < best_distance and (offset.length() < 1.0 or forward.angle_to(offset) < deg_to_rad(angle_deg)):
			best = target
			best_distance = offset.length()
	if best != null:
		best.call("harvest_hit", from)
