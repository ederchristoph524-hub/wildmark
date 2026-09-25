class_name ImmortalAperture
extends RefCounted
## Deine Unsterblichen-Apertur als eigenes Gebiet (docs/UNSTERBLICH.md, 5): Größe nach Grad (+ Annexionen, Grotto-Himmel
## ab Rang 8 × grotto_size_mult), Landschaft nach Hauptpfad, Landgeist in der Mitte, Essenzstein-Ader, Dao-Ort des
## Hauptpfads und Geisterquelle. Das Land erzeugt täglich Essenzsteine und Pfad-Materialien, die der Landgeist verwahrt.

const AREA_ID: StringName = &"apertur"
const REGION: int = 7
const SEED: int = 60606
const STONE_ITEM: StringName = &"unsterblichen_stein"
const CRYSTAL_ITEM: StringName = &"himmelskristall"
const SPIRIT_AT: Vector2 = Vector2(0.0, -20.0)
## Pfad → Material, das das Land zusätzlich erzeugt (sonst Grünkraut).
const PATH_MATERIALS: Dictionary[StringName, StringName] = {
	&"feuer": &"glutasche", &"wasser": &"mondtau", &"eis": &"frostsplitter", &"erde": &"erdkern", &"holz": &"zeitharz",
	&"kraft": &"heldenherz", &"wind": &"windfeder", &"blut": &"blutkoralle", &"seele": &"seelenglas", &"licht": &"sternsand",
	&"stern": &"sternsand", &"zeit": &"zeitharz", &"raum": &"geisterseide", &"blitz": &"donnerholz", &"metall": &"klingenstahl",
	&"schwert": &"klingenstahl", &"gift": &"giftdrüse", &"glueck": &"wuestenrose", &"traum": &"traumsplitter", &"verwandlung": &"geisterseide",
}

static var _cached: AreaData = null
static var _cache_key: String = ""


## Meldet die Apertur als Laufzeit-Gebiet bei der DataRegistry an (vor jedem Gebietsaufbau und beim Start).
static func register() -> void:
	DataRegistry.runtime_areas[AREA_ID] = area_data


static func is_inside() -> bool:
	return GameState.area == AREA_ID


static func size() -> float:
	var land: Dictionary = Immortal.land_grade()
	var base: float = float(land.get("size", 300.0))
	if GameState.rank >= 8:
		base *= Balance.immortal.grotto_size_mult
	return base + GameState.immortal.land_growth


static func is_grotto() -> bool:
	return GameState.rank >= 8


static func title() -> String:
	if is_grotto():
		return Loc.t("Dein Grotto-Himmel")
	return Loc.t(String(Immortal.land_grade().get("name", "Dein Gesegnetes Land")))


## AreaData der eigenen Apertur (zwischengespeichert, neu gebaut, wenn sich Grad, Rang, Pfad oder Größe ändern).
static func area_data() -> AreaData:
	var key: String = "%d_%d_%s_%d" % [GameState.immortal.grade, GameState.rank, Immortal.main_path(), roundi(GameState.immortal.land_growth)]
	if _cached == null or key != _cache_key:
		_cached = _build()
		_cache_key = key
	return _cached


static func _build() -> AreaData:
	var area := AreaData.new()
	var system: ImmortalSystemData = DataRegistry.immortal()
	var path: StringName = Immortal.main_path()
	area.id = AREA_ID
	area.display_name = title()
	area.region = REGION
	area.open = GameState.immortal.grade >= 0
	area.rank_min = Immortal.FIRST_RANK
	area.rank_max = 9
	area.description = Loc.t("Die Welt in deiner Apertur. Ihre Landschaft folgt deinem Hauptpfad.")
	area.size = size()
	area.terrain_seed = SEED
	area.biome = StringName(str(system.path_biomes.get(String(path), system.path_biomes.get("_standard", "dschungel_berg"))))
	area.relief = {&"hoehe": 9.0, &"frequenz": 0.006, &"detail": 0.8, &"berge": 12.0, &"rand": 40.0, &"randhoehe": 38.0, &"horizont": 150.0}
	area.arrival = Vector2(0.0, area.size * 0.22)
	area.wild_gu_rank = 0
	var reach: float = area.size * 0.25
	area.places = [
		{"type": &"dao_ort", "name": "Herz deines Dao", "position": Vector2(0.0, -reach), "radius": 10.0, "path": path if path != &"" else &"himmel", "text": ""},
		{"type": &"geisterquelle", "name": "Quelle deines Landes", "position": Vector2(reach, 0.0), "radius": 9.0},
		{"type": &"ursteinader", "name": "Essenzstein-Ader", "position": Vector2(-reach, reach * 0.3), "radius": 14.0, "count": 4, "amount": 1, "owner": &"", "item": STONE_ITEM},
	]
	area.resources = {PATH_MATERIALS.get(path, &"gruenkraut"): Vector2i(8, 1), &"holz": Vector2i(12, 2), &"stein": Vector2i(12, 2)}
	area.immortal = {"entry_rank": Immortal.FIRST_RANK, "kind": &"grotto_himmel" if is_grotto() else &"gesegnetes_land", "rules": [&"zeitfluss"],
		"time_flow": float(Immortal.land_grade().get("time_flow", 5.0)), "entrance": ""}
	return area


# --- Betreten und Verlassen ---

static func enter() -> void:
	if not Immortal.is_immortal() or is_inside():
		return
	GameState.immortal.return_area = GameState.area
	GameState.immortal.return_position = GameState.position
	EventBus.travel_requested.emit(AREA_ID)


static func leave() -> void:
	if not is_inside():
		return
	var target: StringName = GameState.immortal.return_area if GameState.immortal.return_area != &"" else &"qing_mao"
	EventBus.travel_requested.emit(target)


# --- Erträge ---

## Tägliche Erzeugung (alle vergangenen Tage seit der letzten Erzeugung): Essenzsteine, Pfad-Material, Himmelskristalle
## (Grotto-Himmel), Perlen aus Gu-Häusern direkt in die Apertur.
static func produce(day: int) -> void:
	var state: ImmortalState = GameState.immortal
	var days: int = day - state.last_yield_day
	if days <= 0 or state.grade < 0:
		return
	state.last_yield_day = day
	var b: ImmortalBalanceData = Balance.immortal
	var land: Dictionary = Immortal.land_grade()
	var growth: float = float(land.get("yield", 1.0)) * (1.0 + Immortal.passive(&"ertrag_mult"))
	var stones: int = roundi((float(land.get("stones_per_day", 3.0)) * growth + state.annexed.size() * b.annex_stones_per_day) * days)
	_store(STONE_ITEM, stones)
	_store(PATH_MATERIALS.get(Immortal.main_path(), &"gruenkraut"), roundi(b.land_materials_per_day * growth * days))
	if is_grotto():
		_store(CRYSTAL_ITEM, roundi(b.grotto_crystals_per_day * days))
	var beads: float = Immortal.passive(&"perlen_ertrag") * days
	if beads > 0.0:
		state.add_beads(GameState.rank, beads)
	EventBus.message.emit(Loc.t("Dein Landgeist: +%d Essenzsteine liegen für dich bereit.") % stones, Immortal.essence_color(GameState.rank))


static func _store(id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	var store: Dictionary[StringName, int] = GameState.immortal.land_store
	store[id] = int(store.get(id, 0)) + amount


## Holt alles, was der Landgeist verwahrt, ins Gepäck.
static func collect() -> String:
	var store: Dictionary[StringName, int] = GameState.immortal.land_store
	if store.is_empty():
		return Loc.t("Der Landgeist verwahrt nichts für dich.")
	var parts: PackedStringArray = []
	for id: StringName in store:
		GameState.add_item(id, store[id])
		var item: ItemData = DataRegistry.item(id)
		parts.append("%d %s" % [store[id], Loc.t(item.display_name) if item != null else String(id)])
	store.clear()
	return Loc.t("Eingesammelt: %s") % ", ".join(parts)


## Essenzsteine je Perle des aktuellen Rangs (Rang 6: 1, jeder Rang darüber × stones_per_bead_growth).
static func stones_per_bead() -> int:
	return roundi(pow(Balance.immortal.stones_per_bead_growth, maxi(GameState.rank - Immortal.FIRST_RANK, 0)))


## Verdichtet Essenzsteine aus dem Gepäck zu Perlen des aktuellen Rangs.
static func condense(max_beads: int = 999999) -> int:
	var per_bead: int = stones_per_bead()
	var count: int = mini(floori(float(GameState.item_count(STONE_ITEM)) / per_bead), max_beads)
	if count <= 0:
		return 0
	GameState.take_item(STONE_ITEM, count * per_bead)
	GameState.immortal.add_beads(GameState.rank, count)
	return count


## Gliedert ein Gesegnetes Land der Geschichte in deine Apertur ein (nach seiner Erbschaft).
static func annex(area: AreaData) -> bool:
	var info: Dictionary = area.immortal.get("annex", {})
	var state: ImmortalState = GameState.immortal
	if info.is_empty() or area.id in state.annexed or not Immortal.is_immortal():
		return false
	state.annexed.append(area.id)
	state.land_growth += float(info.get("growth", 60.0))
	for item: StringName in info.get("gift", {}):
		GameState.add_item(item, int(info["gift"][item]))
	Dao.add(StringName(info.get("path", &"")), 50.0)
	EventBus.message.emit(Loc.t("%s ist jetzt Teil deiner Apertur – dein Land wächst.") % Loc.t(area.display_name), Immortal.essence_color(GameState.rank))
	return true
