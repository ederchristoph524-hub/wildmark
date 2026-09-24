class_name HealthComponent
extends Node
## Lebenspunkte einer Figur: Schaden, Heilung, Tod.

signal damaged(amount: float)
signal healed(amount: float)
signal died
## Leben ist auf floor_hp gefallen (Duelle: niemand stirbt, der Kampf endet).
signal floored

## Untergrenze für Schaden (0 = keine); z. B. Duell bis 15 % Leben.
var floor_hp: float = 0.0
var max_hp: float = 100.0
var hp: float = 100.0


func setup(maximum: float, current: float = -1.0) -> void:
	max_hp = maximum
	hp = maximum if current < 0.0 else minf(current, maximum)


func is_dead() -> bool:
	return hp <= 0.0


## Zieht Schaden ab und liefert den tatsächlich abgezogenen Wert.
func apply_damage(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var dealt: float = minf(amount, maxf(0.0, hp - floor_hp))
	hp -= dealt
	if dealt > 0.0:
		damaged.emit(dealt)
	if floor_hp > 0.0 and hp <= floor_hp + 0.001:
		floored.emit()
		return dealt
	if hp <= 0.0:
		hp = 0.0
		died.emit()
	return dealt


func heal(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var gained: float = minf(amount, max_hp - hp)
	hp += gained
	if gained > 0.0:
		healed.emit(gained)
	return gained


func ratio() -> float:
	return hp / max_hp if max_hp > 0.0 else 0.0
