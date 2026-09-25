class_name Dao
extends RefCounted
## Dao-Markierungen und Pfad-Beherrschung (FORMELN.md, Pfade): Jeder Gu-Einsatz prägt Markierungen in seinen Pfad.
## Höhere Beherrschung (gu.json → ATTAIN) senkt Essenzkosten und Abklingzeit dieses Pfads; Markierungen in
## gegensätzlichen Pfaden (PATH_CONFLICT) verteuern ihn. Zustand in GameState.dao.


static func marks(path: StringName) -> float:
	return GameState.dao.get(path, 0.0)


## Fügt Markierungen hinzu und meldet eine neue Beherrschungsstufe.
static func add(path: StringName, amount: float) -> void:
	if path == &"" or amount <= 0.0:
		return
	var before: int = attain(path)
	GameState.dao[path] = marks(path) + amount
	var after: int = attain(path)
	if after > before:
		var system: GuSystemData = DataRegistry.gu_system()
		EventBus.message.emit(Loc.t("Dao-Beherrschung %s: %s") % [Loc.t(system.path_name(path)), Loc.t(system.attain_names[after])], system.attain_colors[after])


## Beherrschungsstufe (0 = Gewöhnlich).
static func attain(path: StringName) -> int:
	var needs: Array[float] = DataRegistry.gu_system().attain_needs
	var value: float = marks(path)
	var level: int = 0
	for i: int in needs.size():
		if value >= needs[i]:
			level = i
	return level


## Anteil der Markierungen gegensätzlicher Pfade (0 … dao_conflict_max).
static func conflict(path: StringName) -> float:
	var b: BalanceData = Balance.values
	var foes: float = 0.0
	for foe: Variant in DataRegistry.gu_system().path_conflicts.get(path, []):
		foes += marks(StringName(str(foe)))
	if foes <= 0.0:
		return 0.0
	return minf(b.dao_conflict_max, foes / (marks(path) + 1.0 + foes) * b.dao_conflict_scale)


static func cost_mult(path: StringName) -> float:
	var b: BalanceData = Balance.values
	return maxf(b.dao_cost_min, 1.0 - attain(path) * b.dao_cost_per_attain + conflict(path) * b.dao_conflict_cost)


static func cooldown_mult(path: StringName) -> float:
	var b: BalanceData = Balance.values
	return maxf(b.dao_cd_min, 1.0 - attain(path) * b.dao_cd_per_attain)


## Nächste Schwelle oder -1 auf der höchsten Stufe.
static func next_need(path: StringName) -> float:
	var needs: Array[float] = DataRegistry.gu_system().attain_needs
	var level: int = attain(path)
	return needs[level + 1] if level + 1 < needs.size() else -1.0
