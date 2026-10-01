class_name FreeStartExtras
extends RefCounted
## Freier Start, Kapitel Leben und Gu-Zusätze (StartFreeLife, StartFreeGu): Körper- und Hilfs-Gu, Sekte samt Rang und
## Signatur-Gu, Ruf, Dao-Beherrschung, Vermögen und Tageszeit. Wird von FreeStart.apply nach Rang und Gu aufgerufen.

const NOT_SET: int = -1
## Futter für so viele Fütterungen je Hilfs-Gu.
const SUPPORT_FEEDINGS: int = 5


static func apply(free: Dictionary) -> void:
	_give_body(free.get("body", []))
	_give_support(free.get("support", []))
	_join_sect(StringName(free.get("sect", &"")), int(free.get("sect_rank", 0)))
	GameState.fame = maxi(GameState.fame, int(free.get("fame", 0)))
	GameState.infamy = maxi(GameState.infamy, int(free.get("infamy", 0)))
	_set_wealth(int(free.get("stones", NOT_SET)), int(free.get("immortal_stones", NOT_SET)), int(free.get("beads", 0)))
	if free.has("time"):
		GameState.time_of_day = clampf(float(free["time"]), 0.0, 0.999)


## Beherrschung im Hauptpfad: Markierungen bis zur gewählten Stufe; der Pfad wird zum Hauptpfad (meiste Markierungen).
static func give_dao_level(path: StringName, level: int) -> void:
	var needs: Array[float] = DataRegistry.gu_system().attain_needs
	var marks: float = needs[clampi(level, 0, needs.size() - 1)] if not needs.is_empty() else 0.0
	var highest: float = 0.0
	for other: StringName in GameState.dao:
		if other != path:
			highest = maxf(highest, GameState.dao[other])
	GameState.dao[path] = maxf(maxf(float(GameState.dao.get(path, 0.0)), marks), highest + 1.0)


static func _give_body(ids: Array) -> void:
	for id: Variant in ids:
		var key := StringName(id)
		if DataRegistry.has(&"body", key) and key not in GameState.body_gu:
			GameState.body_gu.append(key)


static func _give_support(ids: Array) -> void:
	for id: Variant in ids:
		var key := StringName(id)
		if not DataRegistry.has(&"support", key):
			continue
		var data: SupportGuData = DataRegistry.support_gu(key)
		GameState.support.append(GuInstance.create(key))
		if data.feed_item != &"":
			GameState.add_item(data.feed_item, maxi(data.feed_amount, 1) * SUPPORT_FEEDINGS)


## Mitglied ab Start: Beitrittsgeschenk, Verdienst des Rangs, Rang-Geschenke und ab Kernschüler der Signatur-Gu.
static func _join_sect(id: StringName, rank: int) -> void:
	if id == &"" or not DataRegistry.has(&"sects", id):
		return
	var sect: SectData = DataRegistry.sect(id)
	var ranks: Array[SectRankData] = DataRegistry.progression().sect_ranks
	rank = clampi(rank, 0, maxi(ranks.size() - 1, 0))
	GameState.sect = id
	GameState.sect_rank = rank
	GameState.sect_merit = ranks[rank].merit_needed if not ranks.is_empty() else 0
	GameState.sect_stipend_day = GameState.day
	for item: StringName in sect.join_gift:
		GameState.add_item(item, sect.join_gift[item])
	for i: int in range(1, rank + 1):
		for item: StringName in ranks[i].reward:
			GameState.add_item(item, ranks[i].reward[item])
	if rank >= SectLife.SIGNATURE_RANK:
		SectLife.grant_signature_gu(sect)


## Feste Mengen statt der Standardausstattung (NOT_SET = Standard behalten).
static func _set_wealth(stones: int, immortal_stones: int, beads: int) -> void:
	if stones >= 0:
		GameState.take_item(TreasureHeaven.PRIMEVAL_ITEM, GameState.item_count(TreasureHeaven.PRIMEVAL_ITEM))
		GameState.add_item(TreasureHeaven.PRIMEVAL_ITEM, stones)
	if immortal_stones >= 0:
		GameState.take_item(ImmortalAperture.STONE_ITEM, GameState.item_count(ImmortalAperture.STONE_ITEM))
		GameState.add_item(ImmortalAperture.STONE_ITEM, immortal_stones)
	if beads > 0 and Immortal.is_immortal():
		GameState.immortal.add_beads(GameState.rank, float(beads))
