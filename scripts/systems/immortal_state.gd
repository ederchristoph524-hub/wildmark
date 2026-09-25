class_name ImmortalState
extends RefCounted
## Gespeicherter Zustand des Unsterblichen-Reichs (Teil von GameState): gesammelte Qi vor dem Aufstieg, Grad und
## Größe des Gesegneten Landes, Perlen je Essenzrang, Eingebung, Kalamitäten, unsterbliche Gu samt Tasten und
## Abklingzeiten, bekannte Unsterblichen-Killer-Moves, Lager des Landgeists, Seelenfundament und Rückweg aus der Apertur.

const NO_CALAMITY: int = -1

# --- Aufstieg ---
var heaven_qi: float = 0.0
var earth_qi: float = 0.0

# --- Apertur ---
## Grad des Gesegneten Landes (Index in ImmortalSystemData.land_grades), -1 = noch sterblich.
var grade: int = -1
## Annektierte Länder (Gebiets-IDs) und der Flächenzuwachs daraus (m Kantenlänge).
var annexed: Array[StringName] = []
var land_growth: float = 0.0
## Erträge, die der Landgeist verwahrt (Item-ID → Anzahl), und der Tag der letzten Erzeugung.
var land_store: Dictionary[StringName, int] = {}
var last_yield_day: int = 0
## Rückweg aus der eigenen Apertur: Gebiet und Position beim Betreten.
var return_area: StringName = &""
var return_position: Vector3 = Vector3.ZERO

# --- Essenz ---
## Essenzrang (6–9) → Perlen.
var beads: Dictionary[int, float] = {}
var inspiration: StringName = &""

# --- Kalamitäten ---
## Überstandene Kalamitäten auf dem aktuellen Rang (bestimmen die Stufe).
var calamities_survived: int = 0
## Tag, an dem die nächste Kalamität angekündigt wird; angekündigte Kalamität und Tag der Ankündigung.
var next_calamity_day: int = NO_CALAMITY
var pending_calamity: StringName = &""
var pending_since: int = 0
## Ehrwürdiger (Rang 9): Titel und Pfad, in dem er Dao-Herr ist.
var venerable_title: String = ""
var dao_lord_path: StringName = &""

# --- Gu ---
var gu: Array[StringName] = []
var slots: Array[StringName] = []
var cooldowns: Dictionary[StringName, float] = {}
var known_killers: Array[StringName] = []
var active_killer: int = 0

# --- Dimensionen ---
var soul_foundation: float = 0.0


func reset() -> void:
	heaven_qi = 0.0
	earth_qi = 0.0
	grade = -1
	annexed = []
	land_growth = 0.0
	land_store = {}
	last_yield_day = 0
	return_area = &""
	return_position = Vector3.ZERO
	beads = {}
	inspiration = &""
	calamities_survived = 0
	next_calamity_day = NO_CALAMITY
	pending_calamity = &""
	pending_since = 0
	venerable_title = ""
	dao_lord_path = &""
	gu = []
	slots = []
	slots.resize(Balance.immortal.slot_count)
	slots.fill(&"")
	cooldowns = {}
	known_killers = []
	active_killer = 0
	soul_foundation = 0.0


func bead_total() -> float:
	var total: float = 0.0
	for rank: int in beads:
		total += beads[rank]
	return total


## Perlen, die einen Gu dieses Rangs nähren können (Essenz des Rangs oder höher).
func beads_for(rank: int) -> float:
	var total: float = 0.0
	for essence_rank: int in beads:
		if essence_rank >= rank:
			total += beads[essence_rank]
	return total


func add_beads(rank: int, amount: float) -> void:
	beads[rank] = maxf(0.0, float(beads.get(rank, 0.0)) + amount)


## Verbraucht Perlen ab dem Rang des Gu, die niedrigste passende Essenz zuerst.
func spend_beads(rank: int, amount: float) -> bool:
	if beads_for(rank) + 0.0001 < amount:
		return false
	var ranks: Array = beads.keys()
	ranks.sort()
	var left: float = amount
	for essence_rank: int in ranks:
		if essence_rank < rank or left <= 0.0:
			continue
		var used: float = minf(beads[essence_rank], left)
		beads[essence_rank] -= used
		left -= used
	return true


func to_dict() -> Dictionary:
	var bead_list: Dictionary = {}
	for rank: int in beads:
		bead_list[str(rank)] = beads[rank]
	return {
		"qi": [heaven_qi, earth_qi], "grade": grade, "annexed": annexed, "land_growth": land_growth,
		"land_store": _names_to_strings(land_store), "last_yield_day": last_yield_day,
		"return": {"area": String(return_area), "position": [return_position.x, return_position.y, return_position.z]},
		"beads": bead_list, "inspiration": String(inspiration),
		"calamities": {"survived": calamities_survived, "next": next_calamity_day, "pending": String(pending_calamity), "since": pending_since},
		"venerable": {"title": venerable_title, "path": String(dao_lord_path)},
		"gu": gu, "slots": slots, "cooldowns": _names_to_strings(cooldowns), "killers": known_killers, "active_killer": active_killer,
		"soul_foundation": soul_foundation,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	var qi: Array = d.get("qi", [0.0, 0.0])
	heaven_qi = float(qi[0]) if qi.size() > 0 else 0.0
	earth_qi = float(qi[1]) if qi.size() > 1 else 0.0
	grade = int(d.get("grade", -1))
	annexed = _names(d.get("annexed", []))
	land_growth = float(d.get("land_growth", 0.0))
	var store: Dictionary = d.get("land_store", {})
	for key: Variant in store:
		land_store[StringName(str(key))] = int(store[key])
	last_yield_day = int(d.get("last_yield_day", 0))
	var back: Dictionary = d.get("return", {})
	return_area = StringName(str(back.get("area", "")))
	var at: Array = back.get("position", [0.0, 0.0, 0.0])
	if at.size() == 3:
		return_position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	var saved_beads: Dictionary = d.get("beads", {})
	for key: Variant in saved_beads:
		beads[int(str(key))] = float(saved_beads[key])
	inspiration = StringName(str(d.get("inspiration", "")))
	var calamity: Dictionary = d.get("calamities", {})
	calamities_survived = int(calamity.get("survived", 0))
	next_calamity_day = int(calamity.get("next", NO_CALAMITY))
	pending_calamity = StringName(str(calamity.get("pending", "")))
	pending_since = int(calamity.get("since", 0))
	var venerable: Dictionary = d.get("venerable", {})
	venerable_title = str(venerable.get("title", ""))
	dao_lord_path = StringName(str(venerable.get("path", "")))
	gu = _names(d.get("gu", []))
	var saved_slots: Array = d.get("slots", [])
	for i: int in mini(saved_slots.size(), slots.size()):
		slots[i] = StringName(str(saved_slots[i]))
	var saved_cd: Dictionary = d.get("cooldowns", {})
	for key: Variant in saved_cd:
		cooldowns[StringName(str(key))] = float(saved_cd[key])
	known_killers = _names(d.get("killers", []))
	active_killer = int(d.get("active_killer", 0))
	soul_foundation = float(d.get("soul_foundation", 0.0))


static func _names(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for entry: Variant in value:
			result.append(StringName(str(entry)))
	return result


static func _names_to_strings(d: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in d:
		result[str(key)] = d[key]
	return result
