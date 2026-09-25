class_name SectTasks
extends RefCounted
## Sektenaufträge: Das Oberhaupt der eigenen Sekte vergibt einen Auftrag pro Tag – Bestien jagen, Material
## liefern oder ein Duell gewinnen. Lohn: Verdienst (SectLife) und Urstein nach Sektenrang. Zustand in
## GameState.sect_task ({"type", "item", "count", "start", "day", "done"}).

const HUNT: String = "jagd"
const DELIVER: String = "liefern"
const DUEL: String = "duell"
const TYPES: Array[String] = [HUNT, HUNT, DELIVER, DELIVER, DUEL]


## Auftrag von heute (vergibt einen neuen, wenn keiner läuft oder der alte von gestern ist).
static func today() -> Dictionary:
	var task: Dictionary = GameState.sect_task
	if task.is_empty() or int(task.get("day", 0)) != GameState.day:
		task = _roll()
		GameState.sect_task = task
	return task


static func _roll() -> Dictionary:
	var b: BalanceData = Balance.values
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.sect, GameState.day])
	var type: String = TYPES[rng.randi() % TYPES.size()]
	var task: Dictionary = {"type": type, "day": GameState.day, "done": false, "item": &""}
	match type:
		HUNT:
			task["count"] = b.sect_task_hunt + GameState.rank * 2
			task["start"] = GameState.kills
		DELIVER:
			task["item"] = _material(rng)
			task["count"] = b.sect_task_deliver + GameState.rank
			task["start"] = 0
		_:
			task["count"] = 1
			task["start"] = GameState.duels_won
	return task


## Ein Material, das es im aktuellen Gebiet gibt (Ressourcen des Gebiets), sonst Fell.
static func _material(rng: RandomNumberGenerator) -> StringName:
	var area: AreaData = DataRegistry.area(GameState.area)
	var pool: Array = area.resources.keys() if area != null else []
	return pool[rng.randi() % pool.size()] if not pool.is_empty() else &"fell"


static func progress(task: Dictionary) -> int:
	match String(task["type"]):
		HUNT:
			return GameState.kills - int(task["start"])
		DELIVER:
			return GameState.item_count(task["item"])
	return GameState.duels_won - int(task["start"])


static func is_complete(task: Dictionary) -> bool:
	return not task["done"] and progress(task) >= int(task["count"])


static func text(task: Dictionary) -> String:
	var count: int = int(task["count"])
	match String(task["type"]):
		HUNT:
			return Loc.t("Erlege %d Bestien") % count
		DELIVER:
			return Loc.t("Bringe %d %s") % [count, Loc.t(DataRegistry.item(task["item"]).display_name)]
	return Loc.t("Gewinne ein Duell gegen einen Gu-Meister")


static func reward_stones() -> int:
	var b: BalanceData = Balance.values
	return b.sect_task_stones + GameState.sect_rank * b.sect_task_stones_per_rank


## Abgeben: Material wird eingezogen, Lohn ausgezahlt.
static func turn_in() -> bool:
	var task: Dictionary = today()
	if not SectLife.is_member() or not is_complete(task):
		return false
	if String(task["type"]) == DELIVER:
		GameState.take_item(task["item"], int(task["count"]))
	task["done"] = true
	var stones: int = reward_stones()
	GameState.add_item(SectLife.STONE, stones)
	EventBus.message.emit(Loc.t("Sektenauftrag erfüllt: +%d Urstein") % stones, SectLife.COLOR)
	SectLife.add_merit(Balance.values.sect_task_merit)
	return true
