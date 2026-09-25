class_name PacingProbeSteps
extends RefCounted
## Rechnung für pacing_probe.gd: reines Meditieren, durch die Regeneration begrenzt (die Wand brennt Essenz schneller,
## als sie nachkommt). Je Rang: vier Stufen, Auffüllen auf die Durchbruch-Schwelle (mit Höchststufen-Bonus) und die
## erwarteten Fehlversuche des Talentgrads. Nach einem Durchbruch ist die Apertur leer, zu Beginn (Rang 1) voll.

## Talentgrad → mittlerer Talentwert.
const GRADES: Array[Array] = [["D", 30.0], ["C", 50.0], ["B", 70.0], ["A", 90.0]]
const MAX_RANK: int = 5


func run(tree: SceneTree) -> void:
	var b: BalanceData = Balance.values
	var progression: ProgressionData = DataRegistry.progression()
	print("Tempo (Minuten reines Meditieren; wall_rank_growth %.2f, Tag %d s):" % [b.wall_rank_growth, roundi(b.day_length)])
	for entry: Array in GRADES:
		var grade := StringName(entry[0])
		var apt: float = entry[1]
		var cap_rank: int = progression.rank_cap.get(grade, MAX_RANK)
		var total: float = 0.0
		var parts: PackedStringArray = []
		for rank: int in range(1, MAX_RANK + 1):
			var seconds: float = _rank_seconds(b, rank, apt, rank == 1)
			if rank < cap_rank:
				seconds += _retry_seconds(b, rank, apt, progression.breakthrough_chance.get(grade, 1.0))
			total += seconds
			parts.append("R%d %d" % [rank, roundi(seconds / 60.0)])
			if rank == cap_rank:
				break
		print("  %s (Talent %d, Obergrenze Rang %d): %s · bis zur Obergrenze %d min" % [grade, roundi(apt), cap_rank, " · ".join(parts), roundi(total / 60.0)])
	tree.quit()


## Sekunden von leerer (bzw. voller) Apertur bis zur Durchbruch-Schwelle auf der Höchststufe.
func _rank_seconds(b: BalanceData, rank: int, apt: float, start_full: bool) -> float:
	var seconds: float = 0.0
	var pool: float = Formulas.essence_cap(b, rank, 0, apt) if start_full else 0.0
	for stage: int in b.max_stage:
		var cap: float = Formulas.essence_cap(b, rank, stage, apt)
		var need: float = Formulas.wall_need(b, cap, stage, rank)
		var from_pool: float = minf(pool, need)
		seconds += from_pool / (cap * b.meditation_burn)
		pool -= from_pool
		seconds += (need - from_pool) / Formulas.essence_regen(b, cap, apt)
	var peak_cap: float = Formulas.essence_cap(b, rank, b.max_stage, apt)
	seconds += b.breakthrough_min_essence * peak_cap / (Formulas.essence_regen(b, peak_cap, apt) * b.meditation_peak_regen_mult)
	return seconds


## Erwartete Wartezeit durch Fehlversuche: jeder kostet den Verlust (1 − fail_keep) der Essenz, der neu gesammelt wird.
func _retry_seconds(b: BalanceData, rank: int, apt: float, chance: float) -> float:
	var peak_cap: float = Formulas.essence_cap(b, rank, b.max_stage, apt)
	var lost: float = b.breakthrough_min_essence * (1.0 - b.breakthrough_fail_keep) * peak_cap
	var refill: float = lost / (Formulas.essence_regen(b, peak_cap, apt) * b.meditation_peak_regen_mult)
	return (1.0 / maxf(chance, 0.05) - 1.0) * refill
