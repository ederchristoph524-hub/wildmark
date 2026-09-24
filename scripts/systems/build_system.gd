class_name BuildSystem
extends RefCounted
## Lager bauen (materialien.json → BUILD): Kosten prüfen, vor dem Spieler aufstellen, speichern, abreißen.

const PLACE_DISTANCE: float = 2.6
const DEMOLISH_ID: StringName = &"abriss"
const DEMOLISH_RANGE: float = 4.0
## Bauteile, die im Startgebiet noch keinen Sinn ergeben (Werkbank ohne Ausrüstung, Unsterblichen-Felder).
const HIDDEN: Array[StringName] = [&"werkbank", &"feld", &"segen"]


static func available_parts() -> Array[BuildData]:
	var result: Array[BuildData] = []
	for resource: Resource in DataRegistry.all(&"builds"):
		var part: BuildData = resource as BuildData
		if part.id not in HIDDEN:
			result.append(part)
	return result


static func blocked_reason(part: BuildData) -> String:
	if part.min_rank > GameState.rank:
		return Loc.t("Erst ab Rang %d") % part.min_rank
	for item: StringName in part.cost:
		if GameState.item_count(item) < part.cost[item]:
			return Loc.t("Es fehlt: %s (%d/%d)") % [Loc.t(DataRegistry.item(item).display_name), GameState.item_count(item), part.cost[item]]
	return ""


## Baut vor dem Spieler (oder reißt beim Abriss das nächste Teil ab).
static func build(part: BuildData, player: Player) -> bool:
	if part.id == DEMOLISH_ID:
		return demolish_nearest(player)
	if blocked_reason(part) != "":
		return false
	for item: StringName in part.cost:
		GameState.take_item(item, part.cost[item])
	var forward: Vector3 = player.camera_rig.flat_forward()
	var at: Vector3 = player.global_position + forward * PLACE_DISTANCE
	var world: World = player.get_tree().get_first_node_in_group(World.GROUP_WORLD) as World
	at.y = world.terrain.height_at(at.x, at.z)
	var entry: Dictionary = {"id": part.id, "position": at, "yaw": atan2(-forward.x, -forward.z), "area": GameState.area}
	GameState.buildings.append(entry)
	GameState.built_count += 1
	spawn(world, entry)
	EventBus.message.emit(Loc.t("Gebaut: %s") % Loc.t(part.display_name), Color(0.85, 0.75, 0.5))
	return true


static func spawn(world: World, entry: Dictionary) -> BuildPiece:
	var piece := BuildPiece.new()
	piece.setup(DataRegistry.build_part(entry["id"]), entry)
	world.add_child(piece)
	piece.global_position = entry["position"]
	piece.rotation.y = float(entry["yaw"])
	return piece


static func restore(world: World) -> void:
	for entry: Dictionary in GameState.buildings:
		if DataRegistry.has(&"builds", entry["id"]) and entry.get("area", GameState.area) == GameState.area:
			spawn(world, entry)


## Abriss: nächstes eigenes Bauteil entfernen, die Hälfte der Kosten zurück.
static func demolish_nearest(player: Player) -> bool:
	var nearest: BuildPiece = null
	var best: float = DEMOLISH_RANGE
	for node: Node in player.get_tree().get_nodes_in_group(BuildPiece.GROUP):
		var piece: BuildPiece = node as BuildPiece
		var distance: float = piece.global_position.distance_to(player.global_position)
		if distance < best:
			best = distance
			nearest = piece
	if nearest == null:
		EventBus.message.emit(Loc.t("Kein eigenes Bauteil in der Nähe"), Color(1.0, 0.6, 0.4))
		return false
	for item: StringName in nearest.part.cost:
		GameState.add_item(item, floori(nearest.part.cost[item] / 2.0))
	GameState.buildings.erase(nearest.entry)
	nearest.queue_free()
	EventBus.message.emit(Loc.t("Abgerissen: %s") % Loc.t(nearest.part.display_name), Color(0.85, 0.75, 0.5))
	return true
