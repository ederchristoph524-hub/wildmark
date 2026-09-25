class_name GuRecipes
extends RefCounted
## Gu verschmelzen (gu_system.json → rezepte), wie Weißjade aus Weißem Eber und Jadehaut: Die Zutat-Gu und das
## Material werden verbraucht; misslingt es, ist nur das Material verloren. Gilt für Körper-, Hilfs- und aktive Gu.


static func all() -> Array[Dictionary]:
	return DataRegistry.gu_system().recipes


## Besitzt der Spieler diesen Gu (eingeprägt, als Hilfs- oder als aktiver Gu)?
static func owns(id: StringName) -> bool:
	return _find(id) != ""


## Wo der Gu liegt: "body", "support:<index>", "gu:<index>" oder leer.
static func _find(id: StringName) -> String:
	if id in GameState.body_gu:
		return "body"
	for i: int in GameState.support.size():
		if GameState.support[i].gu_id == id:
			return "support:%d" % i
	for i: int in GameState.gu.size():
		if GameState.gu[i].gu_id == id:
			return "gu:%d" % i
	return ""


## Leer = verschmelzbar, sonst der Grund.
static func blocked_reason(recipe: Dictionary) -> String:
	if owns(recipe["result"]):
		return Loc.t("Schon vorhanden")
	for input: StringName in recipe["inputs"]:
		if not owns(input):
			return Loc.t("Es fehlt: %s") % Loc.t(title(input))
	var materials: Dictionary = recipe["materials"]
	for item: StringName in materials:
		if GameState.item_count(item) < int(materials[item]):
			return Loc.t("Zu wenig %s") % Loc.t(DataRegistry.item(item).display_name)
	return ""


## Verschmilzt; roll < 0 würfelt selbst. Liefert true bei Erfolg.
static func fuse(recipe: Dictionary, roll: float = -1.0) -> bool:
	if blocked_reason(recipe) != "":
		return false
	var materials: Dictionary = recipe["materials"]
	for item: StringName in materials:
		GameState.take_item(item, int(materials[item]))
	if (randf() if roll < 0.0 else roll) >= float(recipe["chance"]):
		EventBus.message.emit(Loc.t("Die Verschmelzung misslingt – das Material ist verloren, die Gu bleiben."), Color(1.0, 0.45, 0.4))
		return false
	for input: StringName in recipe["inputs"]:
		_remove(input)
	var result: Resource = _resource(recipe["result"])
	_grant(result)
	Dao.add(GuRefining.path_of(result), Balance.values.dao_refine_base + int(result.get("rank")) * Balance.values.dao_refine_per_rank)
	EventBus.message.emit(Loc.t("Verschmolzen: %s") % Loc.t(String(result.get("display_name"))), Color(1.0, 0.85, 0.3))
	EventBus.gu_obtained.emit(recipe["result"])
	return true


static func title(id: StringName) -> String:
	var resource: Resource = _resource(id)
	return String(resource.get("display_name")) if resource != null else String(id)


static func _resource(id: StringName) -> Resource:
	if DataRegistry.has(&"body", id):
		return DataRegistry.body_gu(id)
	if DataRegistry.has(&"support", id):
		return DataRegistry.support_gu(id)
	return DataRegistry.gu(id) if DataRegistry.has_gu(id) else null


static func _remove(id: StringName) -> void:
	var where: String = _find(id)
	if where == "body":
		GameState.body_gu.erase(id)
	elif where.begins_with("support:"):
		GameState.support.remove_at(int(where.get_slice(":", 1)))
	elif where.begins_with("gu:"):
		GameState.remove_gu(int(where.get_slice(":", 1)))


static func _grant(result: Resource) -> void:
	var id: StringName = result.get("id")
	if result is BodyGuData:
		GameState.body_gu.append(id)
	elif result is SupportGuData:
		GameState.support.append(GuInstance.create(id))
	else:
		GameState.add_gu(GuInstance.create(id))
