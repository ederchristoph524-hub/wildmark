class_name GuRefining
extends RefCounted
## Verfeinerung wilder Gu (FORMELN.md, Verfeinerung) und Merkmals-Würfe (GU_SYSTEM.md, Abschnitt 5).

const RARE_TRAIT: StringName = &"glaenzend"
const ANY_TRAIT_KEY: StringName = &"eines"


## Würfelt ein Merkmal: selten „Glänzend", sonst mit merkmal_chance eines nach Gewicht; leer = keines.
static func roll_trait(roll: float = -1.0, pick: float = -1.0) -> StringName:
	var chances: Dictionary[StringName, float] = DataRegistry.gu_system().trait_chances
	var r: float = randf() if roll < 0.0 else roll
	if r < chances.get(RARE_TRAIT, 0.0):
		return RARE_TRAIT
	if r >= chances.get(ANY_TRAIT_KEY, 0.0):
		return &""
	var pool: Array[TraitData] = []
	var total: int = 0
	for resource: Resource in DataRegistry.all(&"traits"):
		var gu_trait: TraitData = resource as TraitData
		if gu_trait.id != RARE_TRAIT:
			pool.append(gu_trait)
			total += gu_trait.weight
	var target: float = (randf() if pick < 0.0 else pick) * total
	for gu_trait: TraitData in pool:
		target -= gu_trait.weight
		if target < 0.0:
			return gu_trait.id
	return pool.back().id if not pool.is_empty() else &""


static func essence_cost(gu: GuData) -> float:
	return float(Formulas.refine_cost(Balance.values, gu.rank))


static func chance(gu: GuData) -> float:
	return Formulas.refine_chance(Balance.values, gu.rank, GameState.rank, GameState.apt)


## Leer = möglich, sonst Grund.
static func blocked_reason(gu: GuData, aperture: ApertureComponent) -> String:
	var b: BalanceData = Balance.values
	if gu.rank - GameState.rank > b.refine_max_rank_gap:
		return Loc.t("Dieser Gu ist dir %d Ränge überlegen – unmöglich zu verfeinern.") % (gu.rank - GameState.rank)
	if GameState.gu.size() >= Formulas.gu_capacity(b, GameState.rank, GameState.apt):
		return Loc.t("Deine Apertur fasst keine weiteren Gu.")
	var cost: float = essence_cost(gu)
	if aperture.capacity() < cost:
		return Loc.t("Du brauchst %d Uressenz, deine Apertur fasst nur %d. Meditiere (M), um sie zu stärken.") % [roundi(cost), floori(aperture.capacity())]
	if not aperture.has_essence(cost):
		return Loc.t("Zu wenig Uressenz (%d nötig). Warte oder iss Urstein (R).") % roundi(cost)
	return ""


## Versucht die Verfeinerung. Liefert die neue Instanz oder null (Essenz ist dann trotzdem verbraucht).
static func refine(gu: GuData, aperture: ApertureComponent, roll: float = -1.0) -> GuInstance:
	if not aperture.spend(essence_cost(gu)):
		return null
	if (randf() if roll < 0.0 else roll) >= chance(gu):
		EventBus.message.emit(Loc.t("Die Verfeinerung misslingt – der Gu entwindet sich."), Color(1.0, 0.45, 0.4))
		return null
	var instance: GuInstance = GuInstance.create(gu.id, roll_trait())
	GameState.add_gu(instance)
	var trait_text: String = ""
	if instance.trait_id != &"":
		trait_text = " (" + Loc.t(DataRegistry.trait_data(instance.trait_id).display_name) + ")"
	EventBus.message.emit(Loc.t("Verfeinert: %s%s") % [Loc.t(gu.display_name), trait_text], Color(1.0, 0.85, 0.3))
	EventBus.gu_obtained.emit(gu.id)
	return instance


# --- Aufstiegsverfeinerung (GU_SYSTEM.md, Gu-Aufstieg) ---

## Das nächste Mitglied der Familie oder null.
static func upgrade_target(instance: GuInstance) -> GuData:
	var gu: GuData = DataRegistry.gu(instance.gu_id)
	var family: GuFamilyData = DataRegistry.family(gu.family)
	return family.member_for_rank(gu.rank + 1)


static func upgrade_materials(target: GuData) -> Dictionary:
	return DataRegistry.family(target.family).upgrade_materials.get(target.rank, {})


## Chance: Verfeinerungsformel mit dem Zielrang, Merkmal „Scheu" +15 %.
static func upgrade_chance(instance: GuInstance, target: GuData) -> float:
	var bonus: float = 0.0
	if instance.trait_id != &"":
		bonus = float((Balance.values.trait_rules.get(instance.trait_id, {}) as Dictionary).get("upgrade", 0.0))
	return clampf(chance(target) + bonus, Balance.values.refine_min, Balance.values.refine_max)


## Leer = möglich, sonst Grund.
static func upgrade_blocked_reason(instance: GuInstance, aperture: ApertureComponent) -> String:
	var target: GuData = upgrade_target(instance)
	if target == null:
		return Loc.t("Höchster Rang dieser Familie erreicht.")
	if target.rank > GameState.rank + 1:
		return Loc.t("Der Zielrang darf höchstens 1 über deinem Rang liegen.")
	var materials: Dictionary = upgrade_materials(target)
	for item: Variant in materials:
		if GameState.item_count(item) < int(materials[item]):
			var data: ItemData = DataRegistry.item(item)
			return Loc.t("Es fehlt: %s (%d/%d)") % [Loc.t(data.display_name), GameState.item_count(item), int(materials[item])]
	var cost: float = essence_cost(target)
	if aperture.capacity() < cost:
		return Loc.t("Du brauchst %d Uressenz, deine Apertur fasst nur %d. Meditiere, um sie zu stärken.") % [roundi(cost), floori(aperture.capacity())]
	if not aperture.has_essence(cost):
		return Loc.t("Zu wenig Uressenz (%d nötig).") % roundi(cost)
	return ""


## Materialien und Essenz sind in jedem Fall verbraucht; bei Erfolg wird der Gu zum nächsten Mitglied und behält sein Merkmal.
static func upgrade(instance: GuInstance, aperture: ApertureComponent, roll: float = -1.0) -> bool:
	if upgrade_blocked_reason(instance, aperture) != "":
		return false
	var target: GuData = upgrade_target(instance)
	var materials: Dictionary = upgrade_materials(target)
	for item: Variant in materials:
		GameState.take_item(item, int(materials[item]))
	aperture.spend(essence_cost(target))
	if (randf() if roll < 0.0 else roll) >= upgrade_chance(instance, target):
		EventBus.message.emit(Loc.t("Aufstieg misslungen – die Materialien sind verloren."), Color(1.0, 0.45, 0.4))
		return false
	instance.gu_id = target.id
	instance.satiety = Balance.values.satiety_max
	EventBus.message.emit(Loc.t("Aufstieg! Dein Gu ist jetzt %s.") % Loc.t(target.display_name), Color(1.0, 0.85, 0.3))
	EventBus.gu_obtained.emit(target.id)
	return true
