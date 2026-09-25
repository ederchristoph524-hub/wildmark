class_name GuRefining
extends RefCounted
## Verfeinerung wilder Gu (FORMELN.md, Verfeinerung) und Merkmals-Würfe (GU_SYSTEM.md, Abschnitt 5).

const RARE_TRAIT: StringName = &"glaenzend"
## Körper-Gu prägen Markierungen in den Kraftpfad.
const BODY_PATH: StringName = &"kraft"
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


## gu ist GuData, BodyGuData oder SupportGuData (alle haben id, display_name, rank).
static func rank_of(gu: Resource) -> int:
	return int(gu.get("rank"))


static func essence_cost(gu: Resource) -> float:
	return float(Formulas.refine_cost(Balance.values, rank_of(gu)))


static func chance(gu: Resource) -> float:
	var b: BalanceData = Balance.values
	return minf(Formulas.refine_chance(b, rank_of(gu), GameState.rank, GameState.apt) + PassiveGu.add("refine_bonus"), b.refine_max)


## Körper-Gu werden eingeprägt und belegen keinen Platz.
static func needs_capacity(gu: Resource) -> bool:
	return not gu is BodyGuData


## Leer = möglich, sonst Grund.
static func blocked_reason(gu: Resource, aperture: ApertureComponent) -> String:
	var b: BalanceData = Balance.values
	var rank: int = rank_of(gu)
	if rank - GameState.rank > b.refine_max_rank_gap:
		return Loc.t("Dieser Gu ist dir %d Ränge überlegen – unmöglich zu verfeinern.") % (rank - GameState.rank)
	if gu is BodyGuData and gu.get("id") in GameState.body_gu:
		return Loc.t("Dieser Körper-Gu ist bereits eingeprägt.")
	if needs_capacity(gu) and GameState.held_count() >= PassiveGu.capacity():
		return Loc.t("Deine Apertur fasst keine weiteren Gu.")
	var cost: float = essence_cost(gu)
	if aperture.capacity() < cost:
		return Loc.t("Du brauchst %d Uressenz, deine Apertur fasst nur %d. Meditiere (M), um sie zu stärken.") % [roundi(cost), floori(aperture.capacity())]
	if not aperture.has_essence(cost):
		return Loc.t("Zu wenig Uressenz (%d nötig). Warte oder iss Urstein (R).") % roundi(cost)
	return ""


## Versucht die Verfeinerung. Liefert die neue Instanz oder null (Essenz ist dann trotzdem verbraucht).
## Körper-Gu werden eingeprägt (Instanz ohne Merkmal), Hilfs-Gu kommen zu den Hilfs-Gu.
static func refine(gu: Resource, aperture: ApertureComponent, roll: float = -1.0) -> GuInstance:
	if not aperture.spend(essence_cost(gu)):
		return null
	if (randf() if roll < 0.0 else roll) >= chance(gu):
		EventBus.message.emit(Loc.t("Die Verfeinerung misslingt – der Gu entwindet sich."), Color(1.0, 0.45, 0.4))
		return null
	var id: StringName = gu.get("id")
	var title: String = Loc.t(String(gu.get("display_name")))
	Dao.add(path_of(gu), Balance.values.dao_refine_base + int(gu.get("rank")) * Balance.values.dao_refine_per_rank)
	if gu is BodyGuData:
		GameState.body_gu.append(id)
		EventBus.message.emit(Loc.t("%s ist jetzt dauerhaft in deinen Körper eingeprägt.") % title, Color(1.0, 0.85, 0.3))
		EventBus.gu_obtained.emit(id)
		return GuInstance.create(id)
	var instance: GuInstance = GuInstance.create(id, roll_trait())
	if gu is SupportGuData:
		GameState.support.append(instance)
	else:
		GameState.add_gu(instance)
	var trait_text: String = ""
	if instance.trait_id != &"":
		trait_text = " (" + Loc.t(DataRegistry.trait_data(instance.trait_id).display_name) + ")"
	EventBus.message.emit(Loc.t("Verfeinert: %s%s") % [title, trait_text], Color(1.0, 0.85, 0.3))
	EventBus.gu_obtained.emit(id)
	return instance


## Pfad eines Gu beliebiger Art (Körper-Gu gehören zum Kraftpfad).
static func path_of(gu: Resource) -> StringName:
	if gu is GuData:
		return DataRegistry.family((gu as GuData).family).path
	if gu is SupportGuData:
		return (gu as SupportGuData).path
	return BODY_PATH


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
