class_name MapData
extends RefCounted
## Grundlagen für Minikarte und Gebietskarte: Geländebild aus dem Terrain, Umrechnung Welt → Karte, Kartenpunkte.

const TEXTURE_SIZE: int = 128
const KIND_VILLAGE: StringName = &"village"
const KIND_PLACE: StringName = &"place"
const KIND_SITE: StringName = &"site"
const KIND_CAMP: StringName = &"camp"
const KIND_PERSON: StringName = &"person"
const KIND_MASTER: StringName = &"master"
const KIND_QUEST: StringName = &"quest"
const KIND_ENEMY: StringName = &"enemy"
const KIND_COLORS: Dictionary[StringName, Color] = {
	&"village": Color(0.95, 0.8, 0.45), &"place": Color(0.75, 0.85, 1.0), &"site": Color(0.8, 0.6, 1.0),
	&"camp": Color(1.0, 0.6, 0.25), &"person": Color(0.85, 0.85, 0.8), &"master": Color(0.6, 1.0, 0.6),
	&"quest": Color(1.0, 0.85, 0.2), &"enemy": Color(1.0, 0.3, 0.25),
}

static var _texture: ImageTexture = null
static var _texture_owner: int = 0


## Geländebild des aktuellen Gebiets (einmal pro Welt erzeugt).
static func texture(world: World) -> ImageTexture:
	if _texture != null and _texture_owner == world.get_instance_id():
		return _texture
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	var size: float = world.terrain.map_size()
	for py: int in TEXTURE_SIZE:
		for px: int in TEXTURE_SIZE:
			var x: float = (px + 0.5) / TEXTURE_SIZE * size - size * 0.5
			var z: float = (py + 0.5) / TEXTURE_SIZE * size - size * 0.5
			image.set_pixel(px, py, world.terrain.map_color(x, z))
	_texture = ImageTexture.create_from_image(image)
	_texture_owner = world.get_instance_id()
	return _texture


## Weltposition → Kartenkoordinate 0–1.
static func to_uv(world: World, position: Vector3) -> Vector2:
	var size: float = world.terrain.map_size()
	return Vector2((position.x + size * 0.5) / size, (position.z + size * 0.5) / size)


## Alle festen und beweglichen Kartenpunkte: {uv, kind, label}.
static func markers(world: World, with_enemies: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for poi: Dictionary in world.pois:
		result.append({"uv": to_uv(world, poi["position"]), "kind": poi["kind"], "label": poi["label"]})
	var tree: SceneTree = world.get_tree()
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		if node is Npc:
			var npc: Npc = node
			var quest: bool = npc.quest_id != &"" and Quests.state(npc.quest_id) != Quests.DONE
			result.append({"uv": to_uv(world, npc.global_position), "kind": KIND_QUEST if quest else KIND_PERSON, "label": npc.display_title()})
		elif node is GuMaster:
			result.append({"uv": to_uv(world, (node as GuMaster).global_position), "kind": KIND_MASTER, "label": (node as GuMaster).display_title()})
	if with_enemies:
		for node: Node in tree.get_nodes_in_group(Enemy.GROUP_ENEMIES):
			var enemy: Enemy = node as Enemy
			if enemy != null and not enemy.is_dead() and not enemy.is_companion():
				result.append({"uv": to_uv(world, enemy.global_position), "kind": KIND_ENEMY, "label": ""})
	return result
