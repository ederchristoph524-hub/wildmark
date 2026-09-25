class_name Immortal
extends RefCounted
## Regeln des Unsterblichen-Reichs für Spieler und Figuren (docs/UNSTERBLICH.md): Unsterblichen-Kraft, Schaden
## zwischen Unsterblichen und Sterblichen, Leben, Stufe aus überstandenen Kalamitäten, Perlen und Dauerwirkungen der
## unsterblichen Gu und der Eingebung.

const FIRST_RANK: int = 6
const MORTAL_PEAK: int = 5


static func is_immortal() -> bool:
	return GameState.rank >= FIRST_RANK


static func system() -> ImmortalSystemData:
	return DataRegistry.immortal()


## Rang für sterbliche Formeln (Kapazität, Rang-Passung): Unsterbliche zählen dort als Rang 5 – ihre sterblichen Gu
## werden von Unsterblichen-Essenz genährt und wirken voll.
static func mortal_rank(rank: int) -> int:
	return mini(rank, MORTAL_PEAK)


## Unsterblichen-Kraft eines unsterblichen Gu oder Killer Moves dieses Rangs.
static func power(rank: int) -> float:
	var b: ImmortalBalanceData = Balance.immortal
	return b.power_base * pow(b.power_growth, maxi(rank, FIRST_RANK) - FIRST_RANK)


## Schadensfaktor zwischen zwei Kultivierungsrängen: Unsterbliche zerquetschen Sterbliche, Sterbliche kratzen
## Unsterbliche kaum; unter Unsterblichen zählt jeder Rang Unterschied.
static func damage_mult(attacker_rank: int, defender_rank: int) -> float:
	var b: ImmortalBalanceData = Balance.immortal
	if attacker_rank >= FIRST_RANK and defender_rank < FIRST_RANK:
		return b.immortal_vs_mortal * pow(b.rank_factor, attacker_rank - FIRST_RANK)
	if attacker_rank < FIRST_RANK and defender_rank >= FIRST_RANK:
		return b.mortal_vs_immortal / pow(b.rank_factor, defender_rank - FIRST_RANK)
	if attacker_rank >= FIRST_RANK and defender_rank >= FIRST_RANK:
		return pow(b.rank_factor, attacker_rank - defender_rank)
	return 1.0


## Zusätzliches Leben eines Unsterblichen dieses Rangs (Figuren ohne Gu-Boni).
static func base_hp(rank: int) -> float:
	if rank < FIRST_RANK:
		return 0.0
	var b: ImmortalBalanceData = Balance.immortal
	return b.hp_base * pow(b.hp_growth, rank - FIRST_RANK)


## Zusätzliches Leben des Spielers: Unsterblichen-Leben mit Gu- und Eingebungs-Bonus, dazu das Seelenfundament.
static func player_hp_bonus(mortal_hp: float) -> float:
	var b: ImmortalBalanceData = Balance.immortal
	var soul: float = minf(GameState.immortal.soul_foundation, b.soul_foundation_max) * b.soul_foundation_hp
	var immortal_part: float = base_hp(GameState.rank) * (1.0 + passive(&"max_hp"))
	return immortal_part + (mortal_hp + immortal_part) * soul


## Fester Schadenszuschlag eines Unsterblichen (Faust, sterbliche Gu).
static func flat_damage(rank: int) -> float:
	if rank < FIRST_RANK:
		return 0.0
	var b: ImmortalBalanceData = Balance.immortal
	return b.flat_damage_base * pow(b.power_growth, rank - FIRST_RANK)


## Rang-Info (Essenz, Farbe, Kalamitäten-Zyklus, Durchbruch) des aktuellen Rangs.
static func rank_info(rank: int = -1) -> Dictionary:
	return system().rank_info(GameState.rank if rank < 0 else rank) if system() != null else {}


## Stufe (0–3) aus den überstandenen Kalamitäten des aktuellen Rangs.
static func stage_for(survived: int, rank: int = -1) -> int:
	var per_stage: int = int(rank_info(rank).get("per_stage", 3))
	return clampi(floori(float(survived) / per_stage), 0, Balance.values.max_stage)


## Fortschritt zur nächsten Stufe (0–1), wie die Aperturwand der Sterblichen.
static func stage_progress() -> float:
	var per_stage: int = int(rank_info().get("per_stage", 3))
	if GameState.stage >= Balance.values.max_stage:
		return 1.0
	return float(GameState.immortal.calamities_survived % per_stage) / per_stage


## Aktualisiert GameState.stage nach einer überstandenen Kalamität.
static func sync_stage() -> void:
	GameState.stage = stage_for(GameState.immortal.calamities_survived)
	GameState.wall = stage_progress()


## Summe einer Dauerwirkung aller unsterblichen Gu in der Apertur (passiv und Gu-Häuser) und der Eingebung.
static func passive(key: StringName) -> float:
	var total: float = 0.0
	for id: StringName in GameState.immortal.gu:
		if DataRegistry.has_immortal_gu(id):
			var data: ImmortalGuData = DataRegistry.immortal_gu(id)
			if data.passive.has(key) and not (data.passive[key] is bool):
				total += float(data.passive[key])
	total += float(inspiration_effect().get(String(key), 0.0))
	return total


## Hat irgendein unsterblicher Gu die Wirkung (sicht, stealth, reflect, unstoppable)?
static func has_passive_flag(key: StringName) -> bool:
	for id: StringName in GameState.immortal.gu:
		if DataRegistry.has_immortal_gu(id) and bool(DataRegistry.immortal_gu(id).passive.get(key, false)):
			return true
	return false


## Weltwirkung (reise, zeitruecksprung, wiedergeburt, sicht) eines besessenen unsterblichen Gu.
static func has_world_effect(effect: StringName) -> bool:
	for id: StringName in GameState.immortal.gu:
		if DataRegistry.has_immortal_gu(id) and DataRegistry.immortal_gu(id).world == effect:
			return true
	return false


static func inspiration_effect() -> Dictionary:
	if GameState.immortal.inspiration == &"" or system() == null:
		return {}
	for entry: Dictionary in system().inspirations:
		if entry["id"] == GameState.immortal.inspiration:
			return entry["effect"]
	return {}


## Grad des Gesegneten Landes (leer, solange sterblich).
static func land_grade() -> Dictionary:
	if GameState.immortal.grade < 0 or system() == null:
		return {}
	return system().grade(GameState.immortal.grade)


## Hauptpfad: der Pfad mit den meisten Dao-Markierungen (bestimmt Landschaft und Ehrwürdigen-Titel).
static func main_path() -> StringName:
	var best: StringName = &""
	var best_marks: float = -1.0
	for path: StringName in GameState.dao:
		if GameState.dao[path] > best_marks:
			best = path
			best_marks = GameState.dao[path]
	return best


## Sterbliche Gu eines Unsterblichen: solange eine Perle da ist, unerschöpflich.
static func has_mortal_essence() -> bool:
	return GameState.immortal.beads_for(FIRST_RANK) > Balance.immortal.mortal_cast_beads * 0.5


static func spend_mortal_cast() -> void:
	GameState.immortal.spend_beads(FIRST_RANK, minf(Balance.immortal.mortal_cast_beads, GameState.immortal.beads_for(FIRST_RANK)))


## Perlenkosten mit Eingebung „Preis der Macht“.
static func bead_cost(base: float) -> float:
	return base * maxf(0.1, 1.0 + float(inspiration_effect().get("perlen_kosten", 0.0)))


static func essence_name(rank: int) -> String:
	return system().essence_name(rank) if system() != null else "Unsterblichen-Essenz"


static func essence_color(rank: int) -> Color:
	return system().essence_color(rank) if system() != null else Color.WHITE
