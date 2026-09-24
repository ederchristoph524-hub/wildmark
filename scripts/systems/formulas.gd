class_name Formulas
extends RefCounted
## Reine Rechenfunktionen aus docs/FORMELN.md; alle Konstanten kommen aus BalanceData.


static func essence_cap(b: BalanceData, rank: int, stage: int, apt: float) -> float:
	return b.essence_base * pow(b.essence_rank_growth, rank - 1) * (1.0 + stage * b.essence_stage_bonus) * (apt / 100.0)


## Uressenz pro Sekunde.
static func essence_regen(b: BalanceData, cap: float, apt: float) -> float:
	return cap / (b.regen_divisor - apt * b.regen_apt_factor)


static func wall_need(b: BalanceData, cap: float, stage: int) -> float:
	return cap * (b.wall_base + stage * b.wall_per_stage)


static func gu_rank_pow(b: BalanceData, gu_rank: int) -> float:
	return pow(b.gu_rank_growth, gu_rank - 1)


## Wirkungsfaktor nach Rang-Passung (Gu-Rang gegen Spieler-Rang).
static func gu_fit(b: BalanceData, gu_rank: int, rank: int) -> float:
	var d: int = gu_rank - rank
	if d == 0:
		return 1.0
	if d < 0:
		return maxf(b.gu_fit_min, 1.0 + d * b.gu_fit_below)
	return 1.0 + d * b.gu_fit_above


## Kostenfaktor: Gu über deinem Rang kosten quadratisch mehr.
static func gu_fit_cost(b: BalanceData, gu_rank: int, rank: int) -> float:
	var d: int = gu_rank - rank
	return 1.0 + d * d * b.gu_fit_cost_above if d > 0 else 1.0


## Sättigungsverlust pro Sekunde Echtzeit.
static func hunger_per_second(b: BalanceData, gu_rank: int) -> float:
	return b.hunger_per_day / pow(b.hunger_rank_divisor, gu_rank - 1) / b.day_length


static func feed_amount(b: BalanceData, base_amount: int, gu_rank: int) -> int:
	return maxi(1, roundi(base_amount * pow(b.feed_growth, gu_rank - 1) / 2.0))


static func gu_capacity(b: BalanceData, rank: int, apt: float) -> int:
	return b.capacity_base + rank * b.capacity_per_rank + floori(apt / b.capacity_apt_divisor)


static func refine_chance(b: BalanceData, gu_rank: int, rank: int, apt: float) -> float:
	var d: int = gu_rank - rank
	var index: int = clampi(d, 0, b.refine_chances.size() - 1)
	var chance: float = b.refine_chances[index] * (b.refine_apt_base + apt / b.refine_apt_divisor)
	return clampf(chance, b.refine_min, b.refine_max)


static func refine_cost(b: BalanceData, gu_rank: int) -> int:
	return roundi(b.refine_cost_base * pow(b.refine_cost_growth, gu_rank - 1))


## Wie viel Uressenz ein aktiver Gu kostet (Basis × Rang-Passung).
static func gu_essence_cost(b: BalanceData, base_cost: float, gu_rank: int, rank: int) -> float:
	return base_cost * gu_fit_cost(b, gu_rank, rank)


## Wirkung eines Gu = Basiswert × Rangstärke × Rang-Passung.
static func gu_power(b: BalanceData, gu_rank: int, rank: int) -> float:
	return gu_rank_pow(b, gu_rank) * gu_fit(b, gu_rank, rank)


## Tageszeit 0–1 → ist es Nacht? Die Nacht liegt am Ende des Tages.
static func is_night(b: BalanceData, time_of_day: float) -> bool:
	return time_of_day >= 1.0 - b.night_length / b.day_length


## Würfelt einen Talentgrad wie im Prototyp; roll in [0, 100), pct_roll in [0, 1).
static func roll_talent(b: BalanceData, roll: float, pct_roll: float) -> Dictionary:
	for i: int in b.talent_grades.size():
		if roll < b.talent_roll_thresholds[i]:
			return talent_for_grade(b, StringName(b.talent_grades[i]), pct_roll)
	return talent_for_grade(b, StringName(b.talent_grades[b.talent_grades.size() - 1]), pct_roll)


## Talentwert innerhalb der Spanne eines Grades.
static func talent_for_grade(b: BalanceData, grade: StringName, pct_roll: float) -> Dictionary:
	var index: int = b.talent_grades.find(String(grade))
	if index < 0:
		index = b.talent_grades.size() - 1
	var low: int = b.talent_pct_min[index]
	var high: int = b.talent_pct_max[index]
	return {"grade": StringName(b.talent_grades[index]), "apt": float(low + floori(pct_roll * (high - low + 1)))}
