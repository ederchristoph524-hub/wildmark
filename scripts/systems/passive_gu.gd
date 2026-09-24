class_name PassiveGu
extends RefCounted
## Wirkungen der passiven Gu: Körper-Gu (dauerhaft eingeprägt) und Hilfs-Gu (satt, Rang passend, Apertur nicht leer),
## dazu die Extreme Physique des Spielers (BalanceData.physique_rules) mit denselben Schlüsseln.


## Wirkt dieser Hilfs-Gu gerade?
static func is_active(instance: GuInstance) -> bool:
	var data: SupportGuData = DataRegistry.support_gu(instance.gu_id)
	if data == null or instance.satiety <= 0.0 or data.rank > GameState.rank + 1:
		return false
	return not GameState.passives_suspended or data.id in Balance.values.upkeep_free


## Produkt eines Multiplikators über alle aktiven Hilfs-Gu (z. B. regen_mult).
static func mult(key: String) -> float:
	var result: float = float(PhysiqueEffects.rule().get(key, 1.0))
	for instance: GuInstance in GameState.support:
		if is_active(instance):
			result *= float(_rule(instance).get(key, 1.0))
	return result


## Summe eines Zuschlags über alle aktiven Hilfs-Gu (z. B. capacity_add).
static func add(key: String) -> float:
	var result: float = float(PhysiqueEffects.rule().get(key, 0.0))
	for instance: GuInstance in GameState.support:
		if is_active(instance):
			result += float(_rule(instance).get(key, 0.0))
	return result


static func flag(key: String) -> bool:
	for instance: GuInstance in GameState.support:
		if is_active(instance) and bool(_rule(instance).get(key, false)):
			return true
	return false


## Unterhalt pro Sekunde aller Hilfs-Gu (dauerhafte ausgenommen).
static func upkeep() -> float:
	var total: float = 0.0
	var b: BalanceData = Balance.values
	for instance: GuInstance in GameState.support:
		var data: SupportGuData = DataRegistry.support_gu(instance.gu_id)
		if data != null and data.id not in b.upkeep_free and is_active(instance):
			total += data.rank * b.support_upkeep_per_rank
	return total


## Summe einer Körper-Gu-Wirkung (grundschaden, max_hp, schaden_erlitten).
static func body(key: StringName) -> float:
	var total: float = float(PhysiqueEffects.rule().get(String(key), 0.0))
	for id: StringName in GameState.body_gu:
		var data: BodyGuData = DataRegistry.body_gu(id)
		if data != null:
			total += data.effects.get(key, 0.0)
	return total


static func capacity() -> int:
	return Formulas.gu_capacity(Balance.values, GameState.rank, GameState.apt) + roundi(add("capacity_add"))


static func detection_range() -> float:
	return Balance.values.detection_range * mult("detection_mult")


static func _rule(instance: GuInstance) -> Dictionary:
	var data: SupportGuData = DataRegistry.support_gu(instance.gu_id)
	return data.rules if data != null else {}
