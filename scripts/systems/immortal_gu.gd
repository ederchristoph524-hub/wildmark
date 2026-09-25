class_name ImmortalGu
extends RefCounted
## Besitz unsterblicher Gu: erhalten (jeder ist einzigartig), Tasten belegen, Teile eines Unsterblichen-Killer-Moves
## prüfen und neue Killer Moves durch Eingebung erkennen, sobald Kern und alle sterblichen Familien beisammen sind.

const GAIN_COLOR: Color = Color(1.0, 0.85, 0.45)


static func owns(id: StringName) -> bool:
	return id in GameState.immortal.gu


## Nimmt einen unsterblichen Gu in die Apertur auf; aktive Gu kommen in eine freie Taste.
static func grant(id: StringName, quiet: bool = false) -> bool:
	if owns(id) or not DataRegistry.has_immortal_gu(id):
		return false
	var data: ImmortalGuData = DataRegistry.immortal_gu(id)
	GameState.immortal.gu.append(id)
	if data.is_usable():
		var free: int = GameState.immortal.slots.find(&"")
		if free >= 0:
			GameState.immortal.slots[free] = id
	if not quiet:
		EventBus.message.emit(Loc.t("Unsterblicher Gu erhalten: %s (Rang %d)") % [Loc.t(data.display_name), data.rank], GAIN_COLOR)
	check_insight(quiet)
	return true


static func remove(id: StringName) -> void:
	GameState.immortal.gu.erase(id)
	for i: int in GameState.immortal.slots.size():
		if GameState.immortal.slots[i] == id:
			GameState.immortal.slots[i] = &""


## Legt einen aktiven unsterblichen Gu auf Taste slot (vorher belegte Taste mit demselben Gu wird frei).
static func assign(slot: int, id: StringName) -> void:
	var slots: Array[StringName] = GameState.immortal.slots
	if slot < 0 or slot >= slots.size():
		return
	for i: int in slots.size():
		if slots[i] == id:
			slots[i] = &""
	slots[slot] = id


## Familien aller sterblichen Gu in der Apertur (gleich welchen Rangs).
static func held_families() -> Dictionary:
	var result: Dictionary = {}
	for instance: GuInstance in GameState.gu:
		var family: GuFamilyData = DataRegistry.family_of(instance.gu_id)
		if family != null:
			result[family.id] = true
	return result


## Liegen Kern und alle sterblichen Familien des Killer Moves in deiner Apertur?
static func has_parts(move: ImmortalKillerData, families: Dictionary = {}) -> bool:
	if not owns(move.core):
		return false
	var held: Dictionary = families if not families.is_empty() else held_families()
	for family_id: StringName in move.mortal_families:
		if not held.has(family_id):
			return false
	return true


## Fehlende sterbliche Familien eines Killer Moves (für die Anzeige).
static func missing_families(move: ImmortalKillerData) -> Array[StringName]:
	var held: Dictionary = held_families()
	var result: Array[StringName] = []
	for family_id: StringName in move.mortal_families:
		if not held.has(family_id):
			result.append(family_id)
	return result


## Eingebung: Jeder Unsterblichen-Killer-Move, dessen Teile du vollständig besitzt, wird erkannt.
static func check_insight(quiet: bool = false) -> void:
	var held: Dictionary = held_families()
	for resource: Resource in DataRegistry.all(&"immortal_killers"):
		var move: ImmortalKillerData = resource as ImmortalKillerData
		if move.id in GameState.immortal.known_killers or not has_parts(move, held):
			continue
		learn(move.id, quiet)


static func learn(id: StringName, quiet: bool = false) -> void:
	if id in GameState.immortal.known_killers or DataRegistry.immortal_killer(id) == null:
		return
	GameState.immortal.known_killers.append(id)
	if not quiet:
		EventBus.message.emit(Loc.t("Eingebung! Unsterblichen-Killer-Move erkannt: %s") % Loc.t(DataRegistry.immortal_killer(id).display_name), GAIN_COLOR)
	EventBus.killer_move_learned.emit(id)


## Unsterbliche Gu, die noch niemand besitzt (für Schatzhimmel und Beute), optional bis zu einem Rang.
static func unowned(max_rank: int = 9) -> Array[ImmortalGuData]:
	var result: Array[ImmortalGuData] = []
	for resource: Resource in DataRegistry.all(&"immortal_gu"):
		var data: ImmortalGuData = resource as ImmortalGuData
		if data.rank <= max_rank and data.kind != ImmortalGuData.KIND_CONCEPT and not owns(data.id):
			result.append(data)
	return result
