extends Node
## Hält den gesamten speicherbaren Spielzustand (Spieler, Welt, Zeit, bekannte Killer Moves, Startoptionen).

const SLOT_COUNT: int = 4
const DEATH_HARDCORE: StringName = &"hardcore"
const DEATH_STANDARD: StringName = &"standard"
const DEATH_RELAXED: StringName = &"relaxed"
const EMPTY_SLOT: int = -1

## Läuft gerade ein Spiel (nicht im Hauptmenü)?
var active: bool = false

# --- Startoptionen (fest pro Spielstand) ---
var death_mode: StringName = DEATH_STANDARD
var talent_grade: StringName = &"C"
var apt: float = 50.0
var first_family: StringName = &"mondlicht"

# --- Spieler ---
var rank: int = 1
var stage: int = 0
## Fortschritt der Aperturwand 0–1.
var wall: float = 0.0
var essence: float = 0.0
var hp: float = 100.0
## Zuwachs aus Stufen und Durchbrüchen.
var bonus_hp: float = 0.0
var bonus_damage: float = 0.0
var position: Vector3 = Vector3.ZERO
var rest_point: Vector3 = Vector3.ZERO
var inventory: Dictionary[StringName, int] = {}
var gu: Array[GuInstance] = []
## Hilfs-Gu (belegen Kapazität, brauchen Futter und Unterhalt).
var support: Array[GuInstance] = []
## Eingeprägte Körper-Gu (IDs), dauerhaft und ohne Kosten.
var body_gu: Array[StringName] = []
## Apertur leer gelaufen: Hilfs-Gu ruhen, bis wieder genug Essenz da ist (nicht gespeichert).
var passives_suspended: bool = false
## Index in gu je Slot, EMPTY_SLOT = leer.
var slots: Array[int] = []
var known_killer_moves: Array[StringName] = []
var seen_reactions: Array[StringName] = []
## Bereits gefundene wilde Gu (Fundort-IDs).
var collected_wild_gu: Array[StringName] = []
## Geöffnete Welt-Hindernisse (IDs).
var opened_obstacles: Array[StringName] = []
## Quests: ID → {"state": "active"/"done", "start": Wert beim Annehmen}.
var quests: Dictionary[StringName, Dictionary] = {}
var kills: int = 0
## Gewonnene Duelle gegen Gu-Meister und der Spieltag des letzten belohnten Siegs.
var duels_won: int = 0
var last_duel_day: int = 0
## Spielbare Kindheit: aktueller Tutorial-Schritt, -1 = erwacht (siehe Childhood).
var childhood_step: int = -1
## Gebaute Lagerteile: {"id", "position", "yaw"}.
var buildings: Array[Dictionary] = []
var built_count: int = 0
## Besuchte Gebiete (Namen), z. B. für die Quest „Eroberer".
var visited_areas: Array[String] = []
## Beutesack nach dem Tod (Standard-Modus): {"position": Vector3, "items": Dictionary} oder leer.
var loot_sack: Dictionary = {}

# --- Welt ---
var time_of_day: float = 0.0
var day: int = 1
var play_time: float = 0.0


func reset(options: Dictionary) -> void:
	death_mode = options.get("death_mode", DEATH_STANDARD)
	talent_grade = options.get("talent_grade", &"C")
	apt = options.get("apt", 50.0)
	first_family = options.get("first_family", &"mondlicht")
	rank = 1
	stage = 0
	wall = 0.0
	essence = 0.0
	hp = 0.0
	bonus_hp = 0.0
	bonus_damage = 0.0
	position = options.get("spawn", Vector3.ZERO)
	rest_point = position
	inventory = {}
	gu = []
	support = []
	body_gu = []
	passives_suspended = false
	slots = []
	slots.resize(SLOT_COUNT)
	slots.fill(EMPTY_SLOT)
	known_killer_moves = []
	seen_reactions = []
	collected_wild_gu = []
	opened_obstacles = []
	quests = {}
	kills = 0
	duels_won = 0
	last_duel_day = 0
	childhood_step = 0 if options.get("childhood", false) else -1
	buildings = []
	built_count = 0
	visited_areas = []
	loot_sack = {}
	time_of_day = Balance.values.start_time_of_day
	day = 1
	play_time = 0.0


# --- Inventar ---

func item_count(id: StringName) -> int:
	return inventory.get(id, 0)


func add_item(id: StringName, amount: int) -> void:
	inventory[id] = item_count(id) + amount
	if inventory[id] <= 0:
		inventory.erase(id)
	EventBus.item_changed.emit(id, item_count(id))


## Entfernt Gegenstände, falls genug da sind.
func take_item(id: StringName, amount: int) -> bool:
	if item_count(id) < amount:
		return false
	add_item(id, -amount)
	return true


# --- Gu ---

## Fügt einen Gu hinzu und legt ihn in den ersten freien Slot. Liefert den Index.
func add_gu(instance: GuInstance) -> int:
	gu.append(instance)
	var index: int = gu.size() - 1
	var free_slot: int = slots.find(EMPTY_SLOT)
	if free_slot >= 0:
		slots[free_slot] = index
	return index


func remove_gu(index: int) -> void:
	gu.remove_at(index)
	for i: int in slots.size():
		if slots[i] == index:
			slots[i] = EMPTY_SLOT
		elif slots[i] > index:
			slots[i] -= 1


func slot_instance(slot: int) -> GuInstance:
	var index: int = slots[slot] if slot >= 0 and slot < slots.size() else EMPTY_SLOT
	return gu[index] if index >= 0 and index < gu.size() else null


func knows_killer_move(id: StringName) -> bool:
	return id in known_killer_moves


# --- Speichern ---

func to_dict() -> Dictionary:
	var gu_list: Array = []
	for instance: GuInstance in gu:
		gu_list.append(instance.to_dict())
	return {
		"options": {"death_mode": death_mode, "talent_grade": talent_grade, "apt": apt, "first_family": first_family},
		"player": {
			"rank": rank, "stage": stage, "wall": wall, "essence": essence, "hp": hp,
			"bonus_hp": bonus_hp, "bonus_damage": bonus_damage,
			"position": _vec_to_array(position), "rest_point": _vec_to_array(rest_point),
			"inventory": _names_to_strings(inventory), "gu": gu_list, "slots": slots,
			"support": _instances_to_list(support), "body_gu": body_gu,
			"known_killer_moves": known_killer_moves, "seen_reactions": seen_reactions,
			"collected_wild_gu": collected_wild_gu, "opened_obstacles": opened_obstacles, "loot_sack": _sack_to_dict(),
			"quests": _names_to_strings(quests), "kills": kills, "built_count": built_count,
			"duels_won": duels_won, "last_duel_day": last_duel_day, "childhood_step": childhood_step,
			"buildings": _buildings_to_list(), "visited_areas": visited_areas,
		},
		"world": {"time_of_day": time_of_day, "day": day, "play_time": play_time},
	}


func from_dict(d: Dictionary) -> void:
	var options: Dictionary = d.get("options", {})
	reset({
		"death_mode": StringName(str(options.get("death_mode", DEATH_STANDARD))),
		"talent_grade": StringName(str(options.get("talent_grade", "C"))),
		"apt": float(options.get("apt", 50.0)),
		"first_family": StringName(str(options.get("first_family", "mondlicht"))),
	})
	_player_from_dict(d.get("player", {}))
	var world: Dictionary = d.get("world", {})
	time_of_day = float(world.get("time_of_day", time_of_day))
	day = int(world.get("day", 1))
	play_time = float(world.get("play_time", 0.0))


func _player_from_dict(p: Dictionary) -> void:
	rank = int(p.get("rank", 1))
	stage = int(p.get("stage", 0))
	wall = float(p.get("wall", 0.0))
	essence = float(p.get("essence", 0.0))
	hp = float(p.get("hp", 0.0))
	bonus_hp = float(p.get("bonus_hp", 0.0))
	bonus_damage = float(p.get("bonus_damage", 0.0))
	position = _array_to_vec(p.get("position", []))
	rest_point = _array_to_vec(p.get("rest_point", []))
	var items: Dictionary = p.get("inventory", {})
	for key: Variant in items:
		inventory[StringName(str(key))] = int(items[key])
	for entry: Variant in p.get("gu", []):
		if entry is Dictionary:
			gu.append(GuInstance.from_dict(entry))
	for entry: Variant in p.get("support", []):
		if entry is Dictionary:
			support.append(GuInstance.from_dict(entry))
	body_gu = _strings_to_names(p.get("body_gu", []))
	var saved_slots: Array = p.get("slots", [])
	for i: int in mini(saved_slots.size(), SLOT_COUNT):
		var index: int = int(saved_slots[i])
		slots[i] = index if index < gu.size() else EMPTY_SLOT
	known_killer_moves = _strings_to_names(p.get("known_killer_moves", []))
	seen_reactions = _strings_to_names(p.get("seen_reactions", []))
	collected_wild_gu = _strings_to_names(p.get("collected_wild_gu", []))
	opened_obstacles = _strings_to_names(p.get("opened_obstacles", []))
	var saved_quests: Dictionary = p.get("quests", {})
	for key: Variant in saved_quests:
		quests[StringName(str(key))] = saved_quests[key]
	kills = int(p.get("kills", 0))
	duels_won = int(p.get("duels_won", 0))
	last_duel_day = int(p.get("last_duel_day", 0))
	childhood_step = int(p.get("childhood_step", -1))
	built_count = int(p.get("built_count", 0))
	for entry: Variant in p.get("buildings", []):
		if entry is Dictionary:
			buildings.append({"id": StringName(str(entry.get("id", ""))), "position": _array_to_vec(entry.get("position", [])), "yaw": float(entry.get("yaw", 0.0))})
	for area: Variant in p.get("visited_areas", []):
		visited_areas.append(str(area))
	var sack: Dictionary = p.get("loot_sack", {})
	if not sack.is_empty():
		var sack_items: Dictionary = {}
		for key: Variant in sack.get("items", {}):
			sack_items[StringName(str(key))] = int(sack["items"][key])
		loot_sack = {"position": _array_to_vec(sack.get("position", [])), "items": sack_items}


func _sack_to_dict() -> Dictionary:
	if loot_sack.is_empty():
		return {}
	return {"position": _vec_to_array(loot_sack["position"]), "items": _names_to_strings(loot_sack["items"])}


func _buildings_to_list() -> Array:
	var result: Array = []
	for entry: Dictionary in buildings:
		result.append({"id": String(entry["id"]), "position": _vec_to_array(entry["position"]), "yaw": entry["yaw"]})
	return result


static func _instances_to_list(list: Array[GuInstance]) -> Array:
	var result: Array = []
	for instance: GuInstance in list:
		result.append(instance.to_dict())
	return result


## Alle Gu, die Platz in der Apertur belegen (Familien- und Hilfs-Gu).
func held_count() -> int:
	return gu.size() + support.size()


static func _vec_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _array_to_vec(a: Variant) -> Vector3:
	if a is Array and (a as Array).size() == 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


static func _names_to_strings(d: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in d:
		result[str(key)] = d[key]
	return result


static func _strings_to_names(a: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if a is Array:
		for entry: Variant in a:
			result.append(StringName(str(entry)))
	return result
