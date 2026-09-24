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
	return Formulas.gu_power(b, data.rank, GameState.rank) * hunger * float(trait_rule(instance, "effect", 1.0))


func essence_cost(instance: GuInstance) -> float:
	var family: GuFamilyData = family_of(instance)
	var data: GuData = gu_data(instance)
	var base_cost: float = float(family.base_r1.get(COST_KEY, 0.0))
	return Formulas.gu_essence_cost(Balance.values, base_cost, data.rank, GameState.rank) * float(trait_rule(instance, "cost", 1.0))


func hp_cost(instance: GuInstance) -> float:
	return float(family_of(instance).base_r1.get(HP_COST_KEY, 0.0))


func cooldown_of(instance: GuInstance) -> float:
	return float(family_of(instance).base_r1.get(COOLDOWN_KEY, 1.0)) * float(trait_rule(instance, "cooldown", 1.0))


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
	var b: BalanceData = Balance.values
	for index: int in range(GameState.gu.size() - 1, -1, -1):
		var instance: GuInstance = GameState.gu[index]
		var data: GuData = gu_data(instance)
		if data == null:
			continue
		var loss: float = Formulas.hunger_per_second(b, data.rank) * float(trait_rule(instance, "hunger", 1.0)) * delta
		instance.satiety = maxf(0.0, instance.satiety - loss)
		if instance.satiety > 0.0:
			continue
		instance.starved_time += delta
		if instance.starved_time >= b.starve_days * b.day_length and not trait_rule(instance, "no_starve", false):
			EventBus.message.emit(tr("%s ist verhungert.") % tr(data.display_name), Color(1.0, 0.3, 0.3))
			EventBus.gu_died.emit(instance.gu_id)
			GameState.remove_gu(index)
