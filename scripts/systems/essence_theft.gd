class_name EssenceTheft
extends RefCounted
## Uressenz rauben und Abklingzeiten verkürzen – für Spieler und Gu-Meister gleich (Diebstahl- und Weisheits-Pfad).
## Geraubte Essenz = Schaden × Faktor × (Essenzvorrat / Höchstleben des Räubers), damit der Raub mit dem Rang
## mitwächst; Gu-Meister verlieren dieselbe Menge aus ihrer Apertur.


static func steal(attacker: Combatant, victim: Combatant, dealt: float, factor: float) -> void:
	var amount: float = dealt * factor * _ratio(attacker)
	if amount <= 0.0:
		return
	_drain(victim, amount)
	if attacker is Player:
		(attacker as Player).aperture.gain(amount)
	elif attacker is GuMaster:
		var master: GuMaster = attacker as GuMaster
		master.essence = minf(master.essence_capacity(), master.essence + amount)


static func _ratio(combatant: Combatant) -> float:
	if combatant.health.max_hp <= 0.0:
		return 0.0
	if combatant is Player:
		return (combatant as Player).aperture.capacity() / combatant.health.max_hp
	if combatant is GuMaster:
		return (combatant as GuMaster).essence_capacity() / combatant.health.max_hp
	return 0.0


static func _drain(victim: Combatant, amount: float) -> void:
	if victim is Player:
		GameState.essence = maxf(0.0, GameState.essence - amount)
	elif victim is GuMaster:
		var master: GuMaster = victim as GuMaster
		master.essence = maxf(0.0, master.essence - amount)


## Weisheit: alle Abklingzeiten sofort um refund Sekunden kürzer, danach duration Sekunden lang × cd_mult.
static func hasten(caster: Combatant, refund: float, cd_mult: float, duration: float) -> void:
	if caster is Player:
		(caster as Player).holder.hasten(refund, cd_mult, duration)
	elif caster is GuMaster:
		for instance: GuInstance in (caster as GuMaster).gu_list:
			instance.cooldown_left = maxf(0.0, instance.cooldown_left - refund)
