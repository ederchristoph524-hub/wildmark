class_name ClanFeud
extends Node
## Klanfehde (gebiete.json → fehde): Alle paar Tage rücken Gu-Meister eines verfeindeten Klans bei Einbruch der
## Nacht gegen eine Siedlung vor – am Qing-Mao-Berg der Bai-Klan gegen das Gu-Yue-Dorf. Späher warnen am Morgen.
## Gehörst du zum angegriffenen Klan, greifen die Angreifer dich an, auch mitten im Dorf. Sind alle besiegt oder
## geflohen, gibt es Lohn, Verdienst und Ansehen; Besiegte darfst du ohne Folgen für deinen Ruf richten. Am Morgen
## ziehen übrig gebliebene Angreifer ab. Nicht gespeichert (wie die Bestienflut).

const WARN_COLOR: Color = Color(1.0, 0.55, 0.3)
const WIN_COLOR: Color = Color(1.0, 0.85, 0.3)
## Abstand vom Dorfrand, an dem die Angreifer auftauchen, und Streuung.
const SPAWN_GAP: float = 40.0
const SPREAD: float = 7.0
## Verdienst und Ansehen für die Verteidiger.
const MERIT: int = 30
const FAME: int = 6

## Kurztext für das HUD (leer, wenn keine Fehde läuft).
static var status_text: String = ""

var world: World = null
var feud: Dictionary = {}
var active: bool = false
var raiders: Array[Wanderer] = []
var _pending: bool = false
var _center: Vector3 = Vector3.ZERO
var _radius: float = 40.0
var _from: Vector3 = Vector3.ZERO
## Fraktion der angegriffenen Siedlung.
var _defender: StringName = &""


func _init(owner_world: World) -> void:
	world = owner_world
	feud = world.area.feud
	name = "ClanFeud"


func _ready() -> void:
	status_text = ""
	for settlement: Dictionary in world.area.settlements:
		var at: Vector2 = settlement["position"]
		if settlement["id"] == feud["target"]:
			_center = world.ground_point(at.x, at.y)
			_radius = settlement["radius"]
			_defender = settlement["faction"]
		elif settlement["faction"] == feud["attacker"]:
			_from = world.ground_point(at.x, at.y)
	EventBus.day_started.connect(_on_day)
	EventBus.night_changed.connect(_on_night)


func _exit_tree() -> void:
	status_text = ""


func _on_day(day: int) -> void:
	if active or day % int(feud["every"]) != int(feud["offset"]):
		return
	# Nicht in derselben Nacht wie eine Bestienflut.
	if world.tide != null and (world.tide.active or day % int(world.tide.tide["every"]) == 0):
		return
	_pending = true
	EventBus.message.emit(tr("Späher melden: %s rückt heute Nacht gegen %s vor!") % [_attacker_name(), _target_name()], WARN_COLOR)


func _on_night(is_night: bool) -> void:
	if is_night and _pending:
		start()
	elif not is_night and active:
		_retreat()


## Startet den Überfall sofort (auch für Tests).
func start() -> void:
	_pending = false
	active = true
	raiders.clear()
	var masters: Array = feud["masters"]
	var count: int = int(feud["count"])
	var heading: Vector3 = (_from - _center) if _from != Vector3.ZERO else Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	heading.y = 0.0
	heading = heading.normalized() if heading.length() > 0.1 else Vector3.FORWARD
	for i: int in count:
		var leader: bool = i == count - 1
		var source: GuMasterData = DataRegistry.gu_master(masters[mini(i, masters.size() - 1)] if leader else masters[randi() % masters.size()])
		if source != null:
			_spawn(source, heading, leader)
	EventBus.message.emit(tr("Überfall! %s greift %s an!") % [_attacker_name(), _target_name()], WARN_COLOR)
	Sound.play(&"drum")


func _spawn(source: GuMasterData, heading: Vector3, leader: bool) -> void:
	var data: GuMasterData = source.duplicate() as GuMasterData
	data.rank = clampi(GameState.rank + (1 if leader and GameState.rank < 5 else 0), 1, 5)
	data.stage = clampi(GameState.stage - (0 if leader else 1), 0, Balance.values.max_stage)
	var side := Vector3(-heading.z, 0.0, heading.x) * randf_range(-SPREAD, SPREAD)
	var at: Vector3 = _center + heading * (_radius + SPAWN_GAP) + side
	if not world.terrain.is_inside(at.x, at.z, 4.0) or world.terrain.in_water(at.x, at.z):
		at = _center + heading * (_radius + 6.0) + side
	var raider := Wanderer.new()
	var title: String = tr("Anführer") + " – " + tr(source.display_name) if leader else tr(source.display_name)
	raider.setup(data, title, world.ground_point(at.x, at.z) + Vector3.UP * 0.3)
	# Ohne Route läuft ein Gu-Meister nach Hause – für Angreifer ist das die Dorfmitte.
	raider.home = _center + Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
	raider.raid_target = _defender
	raider.raid_cry = tr("%s: „Im Namen von %s – heute Nacht fällt euer Dorf!“") % [raider.display_title(), _attacker_name()]
	world.entities.add_child(raider)
	raiders.append(raider)


func _process(_delta: float) -> void:
	if not active:
		return
	var standing: Array[Wanderer] = []
	for raider: Wanderer in raiders:
		if is_instance_valid(raider) and not raider.surrendered and not raider.fleeing:
			standing.append(raider)
	raiders = standing
	status_text = tr("%s: noch %d Angreifer") % [tr(String(feud["name"])), raiders.size()]
	if raiders.is_empty():
		_win()


func _win() -> void:
	active = false
	status_text = ""
	GameState.feuds_repelled += 1
	var parts: PackedStringArray = []
	var reward: Dictionary = feud["reward"]
	for item: StringName in reward:
		GameState.add_item(item, int(reward[item]))
		parts.append("%d %s" % [int(reward[item]), tr(DataRegistry.item(item).display_name)])
	if SectLife.is_member(_defender):
		SectLife.add_merit(MERIT)
	EventBus.message.emit(tr("Der Überfall ist abgewehrt! Lohn: %s") % ", ".join(parts), WIN_COLOR)
	Sound.play(&"gong")
	Renown.add_fame(FAME, tr("%s verteidigt") % _target_name())


## Morgengrauen: Die übrigen Angreifer ziehen ab.
func _retreat() -> void:
	active = false
	status_text = ""
	for raider: Wanderer in raiders:
		if is_instance_valid(raider) and raider.duel_state == GuMaster.DuelState.IDLE:
			raider.queue_free()
	raiders.clear()
	EventBus.message.emit(tr("Im Morgengrauen ziehen die Angreifer von %s mit ihrer Beute ab.") % _attacker_name(), UiTheme.MUTED)


func _attacker_name() -> String:
	var sect: SectData = DataRegistry.sect(feud["attacker"])
	return tr(sect.display_name) if sect != null else String(feud["attacker"])


func _target_name() -> String:
	var sect: SectData = DataRegistry.sect(_defender)
	return tr(sect.display_name) if sect != null else String(feud["target"])
