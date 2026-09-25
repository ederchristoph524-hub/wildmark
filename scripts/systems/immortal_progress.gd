class_name ImmortalProgress
extends RefCounted
## Ränge 6–9 (docs/UNSTERBLICH.md, 4 und 6): Kalamitäten werden am Morgen angekündigt und brechen nachts in deiner
## Apertur los (bist du nicht dort, kämpft das Land allein – mit Verlusten); überstandene Kalamitäten heben die Stufe.
## Auf der Höchststufe öffnet eine Trübsal den nächsten Rang: Rotdattel-, Weißlitschi-, Gelbaprikosen-Essenz; ab Rang 8
## wird das Land zum Grotto-Himmel, auf Rang 9 wirst du Ehrwürdiger und Dao-Herr deines Hauptpfads.

const TRIALS: Dictionary[int, StringName] = {6: &"himm", 7: &"gross", 8: &"hoechst"}
const WARN_COLOR: Color = Color(1.0, 0.75, 0.4)
const UNATTENDED_BASE: float = 0.5
const UNATTENDED_PER_GRADE: float = 0.08
const UNATTENDED_DAO: float = 0.25
const VENERABLE_RANK: int = 9

static var running: bool = false


static func connect_signals() -> void:
	if not EventBus.day_started.is_connected(on_new_day):
		EventBus.day_started.connect(on_new_day)
		EventBus.night_changed.connect(on_night)


static func on_new_day(day: int) -> void:
	if not Immortal.is_immortal():
		return
	ImmortalAperture.produce(day)
	var state: ImmortalState = GameState.immortal
	if state.pending_calamity == &"" and state.next_calamity_day != ImmortalState.NO_CALAMITY and day >= state.next_calamity_day:
		state.pending_calamity = next_calamity()
		state.pending_since = day
		var data: Dictionary = DataRegistry.immortal().calamity(state.pending_calamity)
		EventBus.message.emit(Loc.t(String(data.get("warning", ""))), data.get("color", WARN_COLOR))
		EventBus.message.emit(Loc.t("Heute Nacht bricht sie los – sei dann in deiner Apertur, sonst kämpft dein Land allein."), WARN_COLOR)


## Nächste Kalamität im Zyklus des Rangs.
static func next_calamity() -> StringName:
	var cycle: Array = Immortal.rank_info().get("cycle", [&"erd"])
	return cycle[GameState.immortal.calamities_survived % maxi(cycle.size(), 1)] if not cycle.is_empty() else &"erd"


static func on_night(night: bool) -> void:
	var state: ImmortalState = GameState.immortal
	if not night or not Immortal.is_immortal() or state.pending_calamity == &"" or running or not GameState.active:
		return
	var world: World = ImmortalWorld.world()
	if world != null and ImmortalAperture.is_inside():
		running = true
		var event := CalamityEvent.create(world, state.pending_calamity, GameState.rank)
		event.finished.connect(_on_calamity_done)
		world.add_child(event)
	else:
		_unattended()


static func _on_calamity_done(survived: bool) -> void:
	running = false
	if survived:
		_survive(true)
		return
	_lose_store(Balance.immortal.unattended_loss)
	EventBus.message.emit(Loc.t("Die Kalamität hat dein Land verwüstet – sie kehrt in der nächsten Nacht zurück."), UiTheme.DANGER)


## Ohne dich: das Land hält mit einer Chance nach Grad und Schutz-Gu stand, verliert aber gelagerte Erträge.
static func _unattended() -> void:
	var state: ImmortalState = GameState.immortal
	var chance: float = UNATTENDED_BASE + state.grade * UNATTENDED_PER_GRADE + Immortal.passive(&"kalamitaet_schutz")
	_lose_store(Balance.immortal.unattended_loss * (0.5 if randf() < chance else 1.0))
	if randf() < chance:
		EventBus.message.emit(Loc.t("Dein Land hat die Kalamität ohne dich überstanden – doch Erträge sind verloren."), WARN_COLOR)
		_survive(false)
	else:
		EventBus.message.emit(Loc.t("Dein Land ist der Kalamität ohne dich nicht gewachsen – sie wütet weiter, bis du dich ihr stellst."), UiTheme.DANGER)


static func _survive(present: bool) -> void:
	var state: ImmortalState = GameState.immortal
	var data: Dictionary = DataRegistry.immortal().calamity(state.pending_calamity)
	var dao: float = float(data.get("dao", 0.0)) / Balance.immortal.calamity_dao_divisor * (1.0 if present else UNATTENDED_DAO)
	var path: StringName = Immortal.main_path()
	Dao.add(path if path != &"" else &"himmel", dao)
	state.calamities_survived += 1
	state.pending_calamity = &""
	state.next_calamity_day = GameState.day + int(Immortal.rank_info().get("days", 3))
	var before: int = GameState.stage
	Immortal.sync_stage()
	EventBus.message.emit(Loc.t("%s überstanden! +%d Dao-Markierungen.") % [Loc.t(String(data.get("name", ""))), roundi(dao)], data.get("color", WARN_COLOR))
	if GameState.stage > before:
		var progression: ProgressionData = DataRegistry.progression()
		EventBus.message.emit(Loc.t("Rang %d · %s") % [GameState.rank, Loc.t(progression.stage_name(GameState.stage))], Immortal.essence_color(GameState.rank))
		EventBus.stage_reached.emit(GameState.rank, GameState.stage)


static func _lose_store(fraction: float) -> void:
	var store: Dictionary[StringName, int] = GameState.immortal.land_store
	for id: StringName in store.keys():
		store[id] = floori(store[id] * (1.0 - fraction))
		if store[id] <= 0:
			store.erase(id)


# --- Durchbruch zum nächsten Unsterblichen-Rang ---

## Leer = die Trübsal zum nächsten Rang kann beginnen.
static func breakthrough_reason() -> String:
	if not Immortal.is_immortal():
		return Loc.t("Noch sterblich.")
	if GameState.rank >= VENERABLE_RANK:
		return Loc.t("Rang 9 ist die Grenze dieser Welt.")
	if GameState.stage < Balance.values.max_stage:
		return Loc.t("Überstehe erst die Kalamitäten deines Rangs (Höchststufe).")
	var need: Dictionary = Immortal.rank_info().get("breakthrough", {})
	var path: StringName = Immortal.main_path()
	var dao_need: float = float(need.get("dao", 0.0)) / Balance.immortal.calamity_dao_divisor
	if Dao.marks(path) < dao_need:
		return Loc.t("Dein Hauptpfad braucht %d Dao-Markierungen (%d).") % [roundi(dao_need), roundi(Dao.marks(path))]
	if int(need.get("attain", 0)) > 0 and Dao.attain(path) < int(need["attain"]):
		return Loc.t("Du brauchst Höchste-Großmeister-Beherrschung in deinem Hauptpfad.")
	if GameState.item_count(&"unsterblichen_stein") < int(need.get("stones", 0)):
		return Loc.t("Du brauchst %d Unsterblichen-Essenzsteine für die neue Essenz.") % int(need.get("stones", 0))
	if running or ImmortalAscension.running:
		return Loc.t("Eine Prüfung läuft bereits.")
	return ""


static func start_breakthrough() -> void:
	var reason: String = breakthrough_reason()
	var world: World = ImmortalWorld.world()
	if reason != "" or world == null:
		EventBus.message.emit(reason, UiTheme.DANGER)
		return
	running = true
	var event := CalamityEvent.create(world, TRIALS.get(GameState.rank, &"himm"), GameState.rank + 1)
	event.finished.connect(_on_trial_done)
	world.add_child(event)


static func _on_trial_done(survived: bool) -> void:
	running = false
	if not survived:
		EventBus.message.emit(Loc.t("Die Trübsal hat dich zurückgeworfen – sammle dich und versuche es erneut."), UiTheme.DANGER)
		EventBus.breakthrough_attempted.emit(false, GameState.rank)
		return
	advance()


## Steigt einen Unsterblichen-Rang auf (auch für den freien Start mit quiet).
static func advance(quiet: bool = false) -> void:
	var state: ImmortalState = GameState.immortal
	var need: Dictionary = Immortal.rank_info().get("breakthrough", {})
	if not quiet:
		GameState.take_item(&"unsterblichen_stein", int(need.get("stones", 0)))
	GameState.rank += 1
	state.calamities_survived = 0
	state.pending_calamity = &""
	state.next_calamity_day = GameState.day + int(Immortal.rank_info().get("days", 3))
	state.add_beads(GameState.rank, float(Immortal.land_grade().get("start_beads", 4.0)))
	Immortal.sync_stage()
	if GameState.rank >= VENERABLE_RANK:
		become_venerable()
	ImmortalWorld.refresh_player()
	if quiet:
		return
	var color: Color = Immortal.essence_color(GameState.rank)
	EventBus.message.emit(Loc.t("Durchbruch! Rang %d – %s.") % [GameState.rank, Loc.t(Immortal.essence_name(GameState.rank))], color)
	if GameState.rank == 8:
		EventBus.message.emit(Loc.t("Dein Gesegnetes Land wandelt sich zum Grotto-Himmel: mehr Raum, eigenes Wetter, Himmelskristalle."), color)
	EventBus.breakthrough_attempted.emit(true, GameState.rank)


## Rang 9: Unsterblicher oder Dämonischer Ehrwürdiger (nach Ruf) und Dao-Herr des Hauptpfads.
static func become_venerable() -> void:
	var state: ImmortalState = GameState.immortal
	var path: StringName = Immortal.main_path()
	state.dao_lord_path = path
	var demonic: bool = GameState.infamy > GameState.fame
	var path_name: String = DataRegistry.gu_system().path_name(path) if path != &"" else "Himmel"
	state.venerable_title = Loc.t("%s-%s") % [Loc.t(path_name), Loc.t("Dämonischer Ehrwürdiger" if demonic else "Unsterblicher Ehrwürdiger")]
	EventBus.message.emit(Loc.t("Du bist der zwölfte Ehrwürdige: %s – Dao-Herr des Pfads %s.") % [state.venerable_title, Loc.t(path_name)], Immortal.essence_color(VENERABLE_RANK))
