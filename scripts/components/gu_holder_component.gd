class_name GuHolderComponent
extends Node
## Gu im Besitz des Spielers: Slots, Cooldowns, Hunger, Fütterung, Merkmale und Einsatz (KAMPFSYSTEM.md, Abschnitt 2–3).

signal gu_used(slot: int, family_id: StringName)

const COST_KEY: StringName = &"ess"
const HP_COST_KEY: StringName = &"hp_kosten"
const COOLDOWN_KEY: StringName = &"cd"

var host: Combatant = null
var aperture: ApertureComponent = null


func _init(owner_combatant: Combatant, owner_aperture: ApertureComponent) -> void:
	host = owner_combatant
	aperture = owner_aperture
	name = "GuHolder"


func _physics_process(delta: float) -> void:
	if host.is_dead():
		return
	for instance: GuInstance in GameState.gu:
		instance.cooldown_left = maxf(0.0, instance.cooldown_left - delta)
	_update_hunger(delta)


# --- Daten zu einem Gu ---

func gu_data(instance: GuInstance) -> GuData:
	return DataRegistry.gu(instance.gu_id) if instance != null else null


func family_of(instance: GuInstance) -> GuFamilyData:
	var data: GuData = gu_data(instance)
	return DataRegistry.family(data.family) if data != null else null


func trait_rule(instance: GuInstance, key: String, fallback: Variant) -> Variant:
	if instance == null or instance.trait_id == &"":
		return fallback
	return (Balance.values.trait_rules.get(instance.trait_id, {}) as Dictionary).get(key, fallback)


func is_starved(instance: GuInstance) -> bool:
	return instance.satiety <= 0.0


func is_hungry(instance: GuInstance) -> bool:
	return instance.satiety <= Balance.values.satiety_hungry


## Wirkungsfaktor: Rangstärke × Rang-Passung × Hunger × Merkmal.
func power_of(instance: GuInstance) -> float:
	var data: GuData = gu_data(instance)
	var b: BalanceData = Balance.values
	var hunger: float = 0.0 if is_starved(instance) else (b.hungry_effect if is_hungry(instance) else 1.0)
	return Formulas.gu_power(b, data.rank, GameState.rank) * hunger * float(trait_rule(instance, "effect", 1.0)) * PhysiqueEffects.path_power(data.family)


func essence_cost(instance: GuInstance) -> float:
	var family: GuFamilyData = family_of(instance)
	var data: GuData = gu_data(instance)
	var base_cost: float = float(family.base_r1.get(COST_KEY, 0.0))
	return Formulas.gu_essence_cost(Balance.values, base_cost, data.rank, GameState.rank) * float(trait_rule(instance, "cost", 1.0)) * PassiveGu.mult("essence_cost_mult") * Dao.cost_mult(family.path)


## Lebenskosten (Blutpfad): hp_kosten ist ein Prozentsatz des Höchstlebens, damit der Preis mit dem Rang mitwächst.
func hp_cost(instance: GuInstance) -> float:
	return Formulas.gu_hp_cost(float(family_of(instance).base_r1.get(HP_COST_KEY, 0.0)), host.health.max_hp)


func cooldown_of(instance: GuInstance) -> float:
	var gift_mult: float = GuGifts.number(gu_data(instance), "cd_mult")
	var family: GuFamilyData = family_of(instance)
	return float(family.base_r1.get(COOLDOWN_KEY, 1.0)) * (gift_mult if gift_mult > 0.0 else 1.0) * float(trait_rule(instance, "cooldown", 1.0)) * PassiveGu.mult("cooldown_mult") * Dao.cooldown_mult(family.path)


## Leer = einsatzbereit, sonst Grund für die Anzeige.
func blocked_reason(instance: GuInstance) -> String:
	if instance == null:
		return tr("Leerer Slot")
	if is_starved(instance):
		return tr("%s ist ausgehungert – füttern!") % tr(gu_data(instance).display_name)
	if instance.cooldown_left > 0.0:
		return tr("Noch nicht bereit")
	if not aperture.has_essence(essence_cost(instance)):
		return tr("Zu wenig Uressenz")
	if hp_cost(instance) > 0.0 and host.health.hp <= hp_cost(instance):
		return tr("Zu wenig Leben")
	return ""


func is_ready(slot: int) -> bool:
	return blocked_reason(GameState.slot_instance(slot)) == ""


## Setzt den Gu im Slot ein. aim = Blickrichtung, target = weiches Ziel (darf null sein).
func use_slot(slot: int, aim: Vector3, target: Combatant) -> bool:
	var instance: GuInstance = GameState.slot_instance(slot)
	var reason: String = blocked_reason(instance)
	if reason != "":
		EventBus.message.emit(reason, Color(1.0, 0.6, 0.4))
		return false
	var family: GuFamilyData = family_of(instance)
	if randf() < float(trait_rule(instance, "fail", 0.0)):
		instance.cooldown_left = cooldown_of(instance)
		EventBus.message.emit(tr("%s versagt!") % tr(gu_data(instance).display_name), Color(1.0, 0.6, 0.4))
		return false
	var caster := GuCaster.new(host, family, gu_data(instance))
	caster.power = power_of(instance)
	caster.extra_stacks = int(trait_rule(instance, "stacks", 0))
	caster.aim_direction = aim
	caster.target = target
	if not caster.cast():
		return false
	aperture.spend(essence_cost(instance))
	if hp_cost(instance) > 0.0:
		host.health.apply_damage(hp_cost(instance))
	instance.cooldown_left = cooldown_of(instance)
	Dao.add(family.path, Balance.values.dao_per_use * float(trait_rule(instance, "dao", 1.0)))
	gu_used.emit(slot, family.id)
	return true


## Liegt ein einsatzfähiger Gu mit dieser Ranggabe in einem Slot (z. B. „glide")?
func slotted_gift(key: String) -> bool:
	for slot: int in GameState.SLOT_COUNT:
		var instance: GuInstance = GameState.slot_instance(slot)
		if instance != null and not is_starved(instance) and GuGifts.has(gu_data(instance), key):
			return true
	return false


# --- Hunger und Fütterung ---

func feed_item(instance: GuInstance) -> StringName:
	return family_of(instance).feed_item


func feed_cost(instance: GuInstance) -> int:
	return Formulas.feed_amount(Balance.values, family_of(instance).feed_amount, gu_data(instance).rank)


func feed(index: int) -> bool:
	var instance: GuInstance = GameState.gu[index]
	var item: StringName = feed_item(instance)
	if instance.satiety >= Balance.values.satiety_max - 0.5:
		EventBus.message.emit(tr("%s ist satt.") % tr(gu_data(instance).display_name), Color(0.8, 0.9, 0.8))
		return false
	if not GameState.take_item(item, feed_cost(instance)):
		var item_data: ItemData = DataRegistry.item(item)
		EventBus.message.emit(tr("Zu wenig %s") % tr(item_data.display_name if item_data != null else String(item)), Color(1.0, 0.36, 0.45))
		return false
	instance.satiety = Balance.values.satiety_max
	instance.starved_time = 0.0
	EventBus.message.emit(tr("%s gefüttert") % tr(gu_data(instance).display_name), Color(0.5, 0.85, 0.35))
	return true


func _update_hunger(delta: float) -> void:
	for index: int in range(GameState.gu.size() - 1, -1, -1):
		var data: GuData = gu_data(GameState.gu[index])
		if data != null and _starve_tick(GameState.gu[index], data.rank, data.display_name, delta):
			GameState.remove_gu(index)
	for index: int in range(GameState.support.size() - 1, -1, -1):
		var support: SupportGuData = DataRegistry.support_gu(GameState.support[index].gu_id)
		if support != null and _starve_tick(GameState.support[index], support.rank, support.display_name, delta):
			GameState.support.remove_at(index)


## Senkt die Sättigung; liefert true, wenn der Gu verhungert ist.
func _starve_tick(instance: GuInstance, rank: int, title: String, delta: float) -> bool:
	var b: BalanceData = Balance.values
	var loss: float = Formulas.hunger_per_second(b, rank) * float(trait_rule(instance, "hunger", 1.0)) * PassiveGu.mult("hunger_mult") * delta
	instance.satiety = maxf(0.0, instance.satiety - loss)
	if instance.satiety > 0.0:
		return false
	instance.starved_time += delta
	if instance.starved_time < b.starve_days * b.day_length or trait_rule(instance, "no_starve", false):
		return false
	EventBus.message.emit(tr("%s ist verhungert.") % tr(title), Color(1.0, 0.3, 0.3))
	EventBus.gu_died.emit(instance.gu_id)
	return true


## Füttert einen Hilfs-Gu (Futter aus den Daten, Menge nach Rang).
func feed_support(index: int) -> bool:
	var instance: GuInstance = GameState.support[index]
	var data: SupportGuData = DataRegistry.support_gu(instance.gu_id)
	if instance.satiety >= Balance.values.satiety_max - 0.5:
		EventBus.message.emit(tr("%s ist satt.") % tr(data.display_name), Color(0.8, 0.9, 0.8))
		return false
	if not GameState.take_item(data.feed_item, support_feed_cost(data)):
		EventBus.message.emit(tr("Zu wenig %s") % tr(DataRegistry.item(data.feed_item).display_name), Color(1.0, 0.36, 0.45))
		return false
	instance.satiety = Balance.values.satiety_max
	instance.starved_time = 0.0
	EventBus.message.emit(tr("%s gefüttert") % tr(data.display_name), Color(0.5, 0.85, 0.35))
	return true


func support_feed_cost(data: SupportGuData) -> int:
	return Formulas.feed_amount(Balance.values, data.feed_amount, data.rank)
