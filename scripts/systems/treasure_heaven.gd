class_name TreasureHeaven
extends RefCounted
## Schatzhimmel (Treasure Yellow Heaven, docs/UNSTERBLICH.md, 8): Marktplatz der Unsterblichen. Sterbliche Gu bis Rang 5
## kosten nur eine Handvoll Unsterblichen-Essenzsteine, dazu Materialien, Verkauf und Umtausch von Ursteinen und die
## tägliche Auktion unsterblicher Gu und Killer-Move-Eingebungen. Werte aus unsterblich.json → schatzhimmel.

const PRIMEVAL_ITEM: StringName = &"kristall"
const COLOR: Color = Color(1.0, 0.84, 0.3)


static func data() -> Dictionary:
	return DataRegistry.immortal().treasure if DataRegistry.immortal() != null else {}


static func can_enter() -> bool:
	return GameState.rank >= int(data().get("zutritt_rang", Immortal.FIRST_RANK))


static func stones() -> int:
	return GameState.item_count(ImmortalAperture.STONE_ITEM)


static func _pay(price: int) -> bool:
	if not can_enter():
		EventBus.message.emit(Loc.t("Der Schatzhimmel öffnet sich nur Unsterblichen."), UiTheme.DANGER)
		return false
	if not GameState.take_item(ImmortalAperture.STONE_ITEM, price):
		EventBus.message.emit(Loc.t("Nicht genug Unsterblichen-Essenzsteine (%d nötig).") % price, UiTheme.DANGER)
		return false
	return true


# --- Sterbliche Gu ---

## Preis eines sterblichen Gu (0 = nicht im Angebot).
static func mortal_price(rank: int) -> int:
	return int(data().get("sterbliche_gu", {}).get(str(rank), 0))


## Sterbliche Gu im Angebot, nach Rang absteigend und Name.
static func mortal_offers(rank: int) -> Array[GuData]:
	var result: Array[GuData] = []
	if mortal_price(rank) <= 0:
		return result
	for gu: GuData in DataRegistry.all_gu():
		if gu.rank == rank:
			result.append(gu)
	result.sort_custom(func(a: GuData, b: GuData) -> bool: return Loc.t(a.display_name) < Loc.t(b.display_name))
	return result


static func buy_mortal(gu: GuData) -> bool:
	if not _pay(mortal_price(gu.rank)):
		return false
	GameState.add_gu(GuInstance.create(gu.id, GuRefining.roll_trait()))
	EventBus.message.emit(Loc.t("Schatzhimmel: %s (Rang %d) gekauft.") % [Loc.t(gu.display_name), gu.rank], COLOR)
	ImmortalGu.check_insight()
	return true


# --- Materialien ---

static func materials() -> Dictionary:
	return data().get("materialien", {})


static func buy_material(id: StringName) -> bool:
	var price: int = int(materials().get(String(id), 0))
	if price <= 0 or not _pay(price):
		return false
	GameState.add_item(id, 1)
	return true


static func sales() -> Dictionary:
	return data().get("verkauf", {})


static func sell(id: StringName) -> bool:
	var price: int = int(sales().get(String(id), 0))
	if price <= 0 or not GameState.take_item(id, 1):
		return false
	GameState.add_item(ImmortalAperture.STONE_ITEM, price)
	return true


## Ursteine je Unsterblichen-Essenzstein beim Umtausch.
static func primeval_rate() -> int:
	return int(data().get("kristall_je_stein", 150))


## Tauscht so viele Ursteine wie möglich (höchstens max_stones Essenzsteine). Liefert die Anzahl.
static func exchange_primeval(max_stones: int = 999999) -> int:
	if not can_enter():
		return 0
	var count: int = mini(max_stones, floori(float(GameState.item_count(PRIMEVAL_ITEM)) / primeval_rate()))
	if count <= 0:
		return 0
	GameState.take_item(PRIMEVAL_ITEM, count * primeval_rate())
	GameState.add_item(ImmortalAperture.STONE_ITEM, count)
	return count


# --- Auktion ---

static func auction_price(rank: int) -> int:
	return int(data().get("auktion", {}).get("preise", {}).get(str(rank), 999999))


## Heutige Auktion: bis zu „anzahl“ unsterbliche Gu bis zu deinem Rang, die noch niemand besitzt (fest je Tag).
static func auction_gu(day: int = -1) -> Array[ImmortalGuData]:
	var pool: Array[ImmortalGuData] = ImmortalGu.unowned(maxi(GameState.rank, Immortal.FIRST_RANK))
	var result: Array[ImmortalGuData] = []
	result.assign(_pick(pool, int(data().get("auktion", {}).get("anzahl", 5)), GameState.day if day < 0 else day))
	return result


## Heutige Killer-Move-Eingebungen: unbekannte Unsterblichen-Killer-Moves, deren Kern du besitzt.
static func auction_killers(day: int = -1) -> Array[ImmortalKillerData]:
	var pool: Array[ImmortalKillerData] = []
	for resource: Resource in DataRegistry.all(&"immortal_killers"):
		var move: ImmortalKillerData = resource as ImmortalKillerData
		if move.id not in GameState.immortal.known_killers and ImmortalGu.owns(move.core):
			pool.append(move)
	var picked: Array = _pick(pool, int(data().get("auktion", {}).get("killer_moves", 2)), (GameState.day if day < 0 else day) + 7)
	var result: Array[ImmortalKillerData] = []
	result.assign(picked)
	return result


static func _pick(pool: Array, count: int, seed_day: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_day * 7919 + 13)
	var copy: Array = pool.duplicate()
	var result: Array = []
	while not copy.is_empty() and result.size() < count:
		result.append(copy.pop_at(rng.randi_range(0, copy.size() - 1)))
	return result


static func buy_immortal(gu: ImmortalGuData) -> bool:
	if ImmortalGu.owns(gu.id) or not _pay(auction_price(gu.rank)):
		return false
	return ImmortalGu.grant(gu.id)


static func killer_price() -> int:
	return int(data().get("auktion", {}).get("killer_preis", 120))


## Eine Eingebung kaufen: der Killer Move wird bekannt (wirken lässt er sich erst mit allen sterblichen Gliedern).
static func buy_killer(move: ImmortalKillerData) -> bool:
	if move.id in GameState.immortal.known_killers or not _pay(killer_price()):
		return false
	ImmortalGu.learn(move.id)
	return true
