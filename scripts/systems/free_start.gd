class_name FreeStart
extends RefCounted
## Freier Start (Startmenü „Freier Start“, docs/UNSTERBLICH.md, 12): Geburtsort (Gebiet und Siedlung), Rang 1–9 mit Stufe,
## Talent samt Extremer Physique, Grad des Gesegneten Landes, Eingebung und unsterbliche Gu – der Spieler beginnt so, als
## hätte er den Weg dorthin schon hinter sich: Rang- und Stufengaben, Dao-Markierungen, Perlen, Gu und Ursteine.
## Optionen (Dictionary unter options["free"]): rank, stage, grade, inspiration, immortal_gu, settlement.

const GIFT_COLOR: Color = Color(1.0, 0.85, 0.45)
const DAO_MARGIN: float = 1.1


## Nach _give_start_kit aufgerufen (Welt und Spieler stehen schon).
static func apply(player: Player, world: World, free: Dictionary) -> void:
	var b: BalanceData = Balance.values
	var target: int = clampi(int(free.get("rank", 1)), 1, ImmortalProgress.VENERABLE_RANK)
	var stage: int = clampi(int(free.get("stage", 0)), 0, b.max_stage)
	var path: StringName = _main_path()
	_raise_mortal(mini(target, Immortal.MORTAL_PEAK), stage if target <= Immortal.MORTAL_PEAK else b.max_stage)
	if target >= Immortal.FIRST_RANK:
		_give_dao(path, target)
		ImmortalAscension.ascend(clampi(int(free.get("grade", 1)), 0, DataRegistry.immortal().land_grades.size() - 1), true)
		GameState.immortal.inspiration = _inspiration(StringName(free.get("inspiration", &"")))
		for _rank: int in range(Immortal.FIRST_RANK + 1, target + 1):
			ImmortalProgress.advance(true)
		GameState.immortal.calamities_survived = stage * int(Immortal.rank_info().get("per_stage", 3))
		Immortal.sync_stage()
		GameState.immortal.next_calamity_day = GameState.day + int(Immortal.rank_info().get("days", 3))
		_give_immortal_gu(clampi(int(free.get("immortal_gu", 0)), 0, 12), path)
	_give_mortal_gu(target)
	_give_items(target)
	ImmortalGu.check_insight(true)
	ImmortalWorld.refresh_player()
	GameState.essence = player.aperture.capacity()
	_place(player, world, StringName(free.get("settlement", &"")))
	_announce(target)


## Rang- und Stufengaben wie bei echten Durchbrüchen (ApertureComponent._stage_up und break_through).
static func _raise_mortal(rank: int, stage: int) -> void:
	var b: BalanceData = Balance.values
	for r: int in range(1, rank + 1):
		var stages: int = b.max_stage if r < rank else stage
		GameState.bonus_hp += b.stage_max_hp * stages
		GameState.bonus_damage += b.stage_damage * stages
		if r >= 2:
			GameState.bonus_hp += b.breakthrough_hp_per_rank * r
			GameState.bonus_damage += b.breakthrough_damage
	GameState.rank = rank
	GameState.stage = stage
	GameState.wall = 0.0


## Hauptpfad: der Pfad des ersten Gu (bestimmt Landschaft der Apertur und Ehrwürdigen-Titel).
static func _main_path() -> StringName:
	var family: GuFamilyData = DataRegistry.family(GameState.first_family)
	return family.path if family != null else &"kraft"


## Dao-Markierungen, die ein Unsterblicher dieses Rangs auf seinem Weg gesammelt hätte (Durchbruch-Bedingungen erfüllt).
static func _give_dao(path: StringName, target: int) -> void:
	var total: float = 0.0
	for rank: int in range(Immortal.FIRST_RANK, target):
		total += float(Immortal.rank_info(rank).get("breakthrough", {}).get("dao", 0.0)) / Balance.immortal.calamity_dao_divisor
	var needs: Array[float] = DataRegistry.gu_system().attain_needs
	if target >= ImmortalProgress.VENERABLE_RANK and not needs.is_empty():
		total = maxf(total, needs[needs.size() - 1])
	GameState.dao[path] = maxf(float(GameState.dao.get(path, 0.0)), total * DAO_MARGIN)


static func _inspiration(chosen: StringName) -> StringName:
	var entries: Array[Dictionary] = DataRegistry.immortal().inspirations
	for entry: Dictionary in entries:
		if entry["id"] == chosen:
			return chosen
	return entries[randi() % entries.size()]["id"] if not entries.is_empty() else &""


## Unsterbliche Gu bis zum eigenen Rang, bevorzugt im Hauptpfad; dazu alle sterblichen Glieder ihrer Killer Moves.
static func _give_immortal_gu(count: int, path: StringName) -> void:
	var pool: Array[ImmortalGuData] = ImmortalGu.unowned(GameState.rank)
	pool.shuffle()
	pool.sort_custom(func(a: ImmortalGuData, b: ImmortalGuData) -> bool: return a.path == path and b.path != path)
	var given: int = 0
	for data: ImmortalGuData in pool:
		if given >= count:
			break
		if ImmortalGu.grant(data.id, true):
			given += 1
			_give_killer_parts(data.id)


static func _give_killer_parts(core: StringName) -> void:
	var held: Dictionary = ImmortalGu.held_families()
	for resource: Resource in DataRegistry.all(&"immortal_killers"):
		var move: ImmortalKillerData = resource as ImmortalKillerData
		if move.core != core:
			continue
		for family_id: StringName in move.mortal_families:
			var family: GuFamilyData = DataRegistry.family(family_id)
			if family == null or held.has(family_id):
				continue
			GameState.add_gu(GuInstance.create(family.member_for_rank(Immortal.MORTAL_PEAK).id, GuRefining.roll_trait()))
			held[family_id] = true


## Sterbliche Gu: der erste Gu wächst auf den Rang mit, dazu weitere Familien – soweit die Apertur sie trägt.
static func _give_mortal_gu(target: int) -> void:
	var rank: int = mini(target, Immortal.MORTAL_PEAK)
	var first: GuFamilyData = DataRegistry.family(GameState.first_family)
	if first != null and not GameState.gu.is_empty():
		GameState.gu[0].gu_id = first.member_for_rank(rank).id
	var families: Array[Resource] = DataRegistry.all(&"families").duplicate()
	families.shuffle()
	var held: Dictionary = ImmortalGu.held_families()
	var wanted: int = Balance.immortal.free_start_gu + (rank - 1)
	for resource: Resource in families:
		if wanted <= 0 or GameState.held_count() >= PassiveGu.capacity():
			break
		var family: GuFamilyData = resource as GuFamilyData
		if held.has(family.id):
			continue
		GameState.add_gu(GuInstance.create(family.member_for_rank(rank).id, GuRefining.roll_trait()))
		held[family.id] = true
		wanted -= 1
	for instance: GuInstance in GameState.gu:
		var family: GuFamilyData = DataRegistry.family_of(instance.gu_id)
		if family != null:
			GameState.add_item(family.feed_item, family.feed_amount * 3)


static func _give_items(target: int) -> void:
	var b: ImmortalBalanceData = Balance.immortal
	GameState.add_item(TreasureHeaven.PRIMEVAL_ITEM, b.free_start_stones * target * target)
	if target >= Immortal.FIRST_RANK:
		GameState.add_item(ImmortalAperture.STONE_ITEM, b.free_start_immortal_stones * (target - Immortal.MORTAL_PEAK))


## Geburt in einer bestimmten Siedlung des Gebiets (sonst am Ankunftspunkt).
static func _place(player: Player, world: World, settlement_id: StringName) -> void:
	var settlement: Dictionary = world.area.settlement(settlement_id) if settlement_id != &"" else {}
	if settlement.is_empty():
		return
	var at: Vector2 = settlement["position"]
	at += Vector2(0.0, float(settlement.get("radius", 40.0)) * 0.35)
	var spot: Vector3 = world.ground_point(at.x, at.y) + Vector3.UP * 0.5
	player.global_position = spot
	GameState.position = spot
	GameState.rest_point = spot


static func _announce(target: int) -> void:
	var progression: ProgressionData = DataRegistry.progression()
	var color: Color = Immortal.essence_color(target) if target >= Immortal.FIRST_RANK else progression.rank_color(target)
	EventBus.message.emit(Loc.t("Freier Start: %s · %s.") % [Loc.t(progression.rank_name(GameState.rank)), Loc.t(progression.stage_name(GameState.stage))], color)
	if target >= Immortal.FIRST_RANK:
		EventBus.message.emit(Loc.t("%s – %d unsterbliche Gu, %d sterbliche Gu. Rang-5-Meister sind für dich Ameisen.") % [ImmortalAperture.title(), GameState.immortal.gu.size(), GameState.gu.size()], GIFT_COLOR)
