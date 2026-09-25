class_name ImmortalAscension
extends RefCounted
## Unsterblichen-Aufstieg (docs/UNSTERBLICH.md, 2): Himmels- und Erd-Qi sammeln sich beim Kultivieren auf Rang 5
## Höchststufe (je nach Höhe und Ort), Menschen-Qi ergibt sich aus deinem Leben. Menge und Balance bestimmen den Grad
## des Gesegneten Landes. Das Ritual: Frage an Himmel und Erde (Eingebung), Erdkalamität, Himmlische Trübsal.

const HEAVEN_HEIGHT_SCALE: float = 25.0
const EARTH_DEPTH_SCALE: float = 40.0
const SITE_MULT: float = 2.5
const SITE_RADIUS: float = 25.0
const MIN_FACTOR: float = 0.3
const MAX_FACTOR: float = 2.0
const TRIAL_RANK: int = 5
const QI_COLOR: Color = Color(0.85, 0.95, 1.0)

static var running: bool = false


static func config() -> Dictionary:
	return DataRegistry.immortal().ascension


## Rang 5 auf der Höchststufe: jetzt sammelt Kultivieren Qi für den Aufstieg.
static func is_gathering() -> bool:
	return GameState.rank == TRIAL_RANK and GameState.stage >= Balance.values.max_stage


## Beim Kultivieren (ApertureComponent): Himmels-Qi aus Höhe und Himmels-Dao-Orten, Erd-Qi aus Tiefe, Adern und Quellen.
static func gather(host: Node3D, delta: float) -> void:
	var cfg: Dictionary = config()
	var at: Vector3 = host.global_position
	var tree: SceneTree = host.get_tree()
	var site: StringName = DaoSite.path_at(tree, at)
	var heaven: float = clampf(MIN_FACTOR + at.y / HEAVEN_HEIGHT_SCALE, MIN_FACTOR, MAX_FACTOR)
	var earth: float = clampf(MAX_FACTOR - at.y / EARTH_DEPTH_SCALE, MIN_FACTOR, MAX_FACTOR)
	if String(site) in cfg.get("himmels_pfade", []):
		heaven *= SITE_MULT
	if String(site) in cfg.get("erd_pfade", []):
		earth *= SITE_MULT
	if SpiritSpring.bonus_at(tree, at) > 1.0 or _near_vein(tree, at):
		earth *= SITE_MULT
	var cap: float = float(cfg.get("qi_max", 1000.0))
	var state: ImmortalState = GameState.immortal
	state.heaven_qi = minf(state.heaven_qi + float(cfg.get("himmel_rate", 1.0)) * heaven * delta, cap)
	state.earth_qi = minf(state.earth_qi + float(cfg.get("erd_rate", 1.0)) * earth * delta, cap)


static func _near_vein(tree: SceneTree, at: Vector3) -> bool:
	for node: Node in tree.get_nodes_in_group(Player.GROUP_INTERACTABLES):
		var resource: ResourceNode = node as ResourceNode
		if resource != null and resource.item in [&"kristall", &"erdqi", &"erdkern"] and resource.global_position.distance_to(at) < SITE_RADIUS:
			return true
	return false


## Nimmt Himmels- und Erd-Qi-Kristalle aus dem Gepäck auf.
static func absorb_crystals() -> int:
	var amount: float = float(config().get("item_qi", 40.0))
	var cap: float = float(config().get("qi_max", 1000.0))
	var used: int = 0
	while GameState.take_item(&"himmelsqi", 1):
		GameState.immortal.heaven_qi = minf(GameState.immortal.heaven_qi + amount, cap)
		used += 1
	while GameState.take_item(&"erdqi", 1):
		GameState.immortal.earth_qi = minf(GameState.immortal.earth_qi + amount, cap)
		used += 1
	return used


## Menschen-Qi: Summe deines Lebens (Dao, Siege, Duelle, Aufgaben, Erbschaften, Gebiete, Ruf, Gu, Tage).
static func human_qi() -> float:
	var w: Dictionary = config().get("mensch", {})
	var dao_total: float = 0.0
	for path: StringName in GameState.dao:
		dao_total += GameState.dao[path]
	var quests_done: int = 0
	for id: StringName in GameState.quests:
		if String(GameState.quests[id].get("state", "")) == Quests.DONE:
			quests_done += 1
	var total: float = dao_total * float(w.get("dao", 0.05)) + GameState.kills * float(w.get("kills", 1.0)) \
		+ GameState.duels_won * float(w.get("duelle", 12.0)) + quests_done * float(w.get("aufgaben", 20.0)) \
		+ GameState.inheritances.size() * float(w.get("erbschaften", 50.0)) + GameState.visited_areas.size() * float(w.get("gebiete", 15.0)) \
		+ (GameState.fame + GameState.infamy) * float(w.get("ruf", 0.25)) + GameState.held_count() * float(w.get("gu", 8.0)) \
		+ GameState.day * float(w.get("tage", 3.0))
	return minf(total, float(config().get("qi_max", 1000.0)))


## Verhältnis des kleinsten zum größten Qi (1 = vollkommen ausgewogen).
static func balance() -> float:
	var values: Array[float] = [GameState.immortal.heaven_qi, GameState.immortal.earth_qi, human_qi()]
	var high: float = values.max()
	return values.min() / high if high > 0.0 else 0.0


static func score() -> float:
	var total: float = GameState.immortal.heaven_qi + GameState.immortal.earth_qi + human_qi()
	return total / 3.0 * balance()


## Voraussichtlicher Grad (0–3), -1 = Himmel und Erde würden dich verwerfen. Extreme Physiques: immer „super“.
static func predicted_grade() -> int:
	if GameState.physique != &"":
		return 3
	if balance() < float(config().get("min_balance", 0.45)):
		return -1
	var thresholds: Array = config().get("grad_schwellen", [120, 300, 520, 780])
	var grade: int = -1
	for i: int in thresholds.size():
		if score() >= float(thresholds[i]):
			grade = i
	return grade


static func grade_name(index: int) -> String:
	if index < 0:
		return Loc.t("Scheitern")
	return Loc.t(String(DataRegistry.immortal().grade(index).get("name", "")))


## Leer = das Ritual kann beginnen.
static func blocked_reason(player: Player) -> String:
	if GameState.rank != TRIAL_RANK or GameState.stage < Balance.values.max_stage:
		return Loc.t("Erst auf Rang 5, Höchststufe, kannst du den Aufstieg wagen.")
	if player.aperture.ratio() < Balance.values.breakthrough_min_essence:
		return Loc.t("Fülle deine Apertur fast ganz mit Uressenz.")
	if running or ImmortalProgress.running:
		return Loc.t("Eine Prüfung läuft bereits.")
	if player.loadout.in_combat():
		return Loc.t("Nicht mitten im Kampf.")
	return ""


## Beginnt mit der Frage an Himmel und Erde (Auswahl), danach Erdkalamität und Himmlische Trübsal.
static func start(player: Player) -> void:
	var reason: String = blocked_reason(player)
	if reason != "":
		EventBus.message.emit(reason, UiTheme.DANGER)
		return
	var options: Array = []
	for entry: Dictionary in DataRegistry.immortal().inspirations:
		options.append(["%s – %s" % [Loc.t(entry["question"]), Loc.t(entry["text"])], _begin.bind(entry["id"])])
	EventBus.choice_requested.emit(Loc.t("Frage an Himmel und Erde"),
		Loc.t("Du zerbrichst deine sterbliche Apertur. In diesem Augenblick darfst du Himmel und Erde eine Frage stellen – die Antwort begleitet dich für immer."), options)


static func _begin(inspiration: StringName) -> void:
	var world: World = ImmortalWorld.world()
	if world == null:
		return
	GameState.immortal.inspiration = inspiration
	running = true
	EventBus.message.emit(Loc.t("Himmels-, Erd- und Menschen-Qi stürzen in deine zerbrechende Apertur …"), QI_COLOR)
	var first := CalamityEvent.create(world, &"aufstieg_erd", TRIAL_RANK)
	first.finished.connect(_after_earth)
	world.add_child(first)


static func _after_earth(survived: bool) -> void:
	var world: World = ImmortalWorld.world()
	if not survived or world == null:
		_fail()
		return
	var second := CalamityEvent.create(world, &"aufstieg_himm", TRIAL_RANK)
	second.finished.connect(_after_heaven)
	world.add_child(second)


static func _after_heaven(survived: bool) -> void:
	running = false
	if not survived:
		_fail()
		return
	var grade: int = predicted_grade()
	if grade < 0:
		_reject()
		return
	ascend(grade)


## Macht den Spieler zum Unsterblichen (auch für den freien Start): Rang 6, Gesegnetes Land, erste Perlen.
static func ascend(grade: int, quiet: bool = false) -> void:
	var state: ImmortalState = GameState.immortal
	var land: Dictionary = DataRegistry.immortal().grade(grade)
	GameState.rank = Immortal.FIRST_RANK
	GameState.stage = 0
	GameState.wall = 0.0
	state.grade = grade
	state.add_beads(Immortal.FIRST_RANK, float(land.get("start_beads", 4.0)))
	state.heaven_qi = 0.0
	state.earth_qi = 0.0
	state.calamities_survived = 0
	state.next_calamity_day = GameState.day + Balance.immortal.first_calamity_delay
	state.last_yield_day = GameState.day
	ImmortalWorld.refresh_player()
	if quiet:
		return
	EventBus.message.emit(Loc.t("Unsterblichen-Aufstieg! Rang 6 – %s. Deine Apertur ist jetzt eine eigene Welt.") % Loc.t(String(land.get("name", ""))), Immortal.essence_color(Immortal.FIRST_RANK))
	EventBus.message.emit(Loc.t("%.0f Perlen %s – für sterbliche Gu ist jede davon unerschöpflich.") % [state.beads_for(Immortal.FIRST_RANK), Loc.t(Immortal.essence_name(Immortal.FIRST_RANK))], Immortal.essence_color(Immortal.FIRST_RANK))
	EventBus.breakthrough_attempted.emit(true, GameState.rank)


## Unausgewogenes Qi: Himmel und Erde verwerfen dich – du lebst, aber die Apertur ist zerbrochen.
static func _reject() -> void:
	var cfg: Dictionary = config()
	GameState.stage = int(cfg.get("rueckfall_stufe", 1))
	GameState.essence = 0.0
	GameState.immortal.heaven_qi *= 0.5
	GameState.immortal.earth_qi *= 0.5
	EventBus.message.emit(Loc.t(String(cfg.get("text_scheitern", "Himmel und Erde verwerfen dich."))), UiTheme.DANGER)
	EventBus.breakthrough_attempted.emit(false, GameState.rank)


static func _fail() -> void:
	running = false
	GameState.stage = int(config().get("rueckfall_stufe", 1))
	GameState.essence = 0.0
	GameState.immortal.heaven_qi = 0.0
	GameState.immortal.earth_qi = 0.0
	EventBus.message.emit(Loc.t("Der Aufstieg ist gescheitert – deine sterbliche Apertur ist zerbrochen und muss neu wachsen."), UiTheme.DANGER)
	EventBus.breakthrough_attempted.emit(false, GameState.rank)
