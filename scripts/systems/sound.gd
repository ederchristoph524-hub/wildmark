class_name Sound
extends Node
## Klänge des Spiels (SoundSynth erzeugt sie): Gu-Wirken je Pfad, Treffer, Beute, Durchbruch, Knöpfe, dazu
## Ambiente (Wind, nachts Grillen) und das Summen beim Kultivieren. Main hängt einen Sound-Knoten ein; die
## statischen Aufrufe tun nichts, solange keiner da ist (Werkzeuge, Tests ohne Main). Lautstärke in
## user://settings.cfg (Pausenmenü).

const POOL_3D: int = 12
const POOL_2D: int = 6
## Mindestabstand zwischen zwei gleichen Klängen (Zonen treffen in Takten, Schwärme vielfach).
const MIN_GAP: float = 0.06
const MAX_DISTANCE: float = 45.0
const AMBIENT_DB: float = -20.0
const CRICKETS_DB: float = -24.0
const HUM_DB: float = -14.0
const CHECK_INTERVAL: float = 0.25
const SETTINGS_PATH: String = "user://settings.cfg"
const VOLUMES: Array[float] = [1.0, 0.5, 0.0]
const VOLUME_NAMES: Array[String] = ["100 %", "50 %", "aus"]
## Klangfarbe je Tag (erstes passendes Tag der Familie).
const TAG_SOUNDS: Dictionary[StringName, StringName] = {
	&"feuer": &"cast_feuer", &"blitz": &"cast_blitz", &"eis": &"cast_eis", &"licht": &"cast_licht", &"gift": &"cast_gift",
	&"wasser": &"cast_wasser", &"seele": &"cast_seele", &"klang": &"cast_klang", &"stern": &"cast_stern", &"erde": &"cast_erde",
	&"raum": &"cast_raum", &"zeit": &"cast_zeit", &"metall": &"cast_metall", &"holz": &"cast_holz", &"wind": &"cast_luft",
	&"schnitt": &"cast_schnitt", &"durchbohren": &"cast_schnitt", &"blut": &"cast_wucht", &"wucht": &"cast_wucht",
}

## Musik: pentatonische Tonleitern (Halbtöne über dem Grundton) je Region; Grundton in Hz. Tagsüber lebhafter,
## nachts tiefer und seltener.
const SCALES: Dictionary[int, Array] = {
	0: [0, 3, 5, 7, 10, 12, 15], 1: [0, 2, 4, 7, 9, 12, 14], 2: [0, 2, 4, 7, 9, 12, 14], 3: [0, 3, 5, 7, 10, 12, 15], 4: [0, 2, 5, 7, 9, 12, 14],
}
const ROOT_HZ: float = 196.0
const MUSIC_DB: float = -17.0
const MUSIC_GAP: Vector2 = Vector2(1.4, 3.8)

static var instance: Sound = null
static var _volume_index: int = -1

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _last: Dictionary[StringName, float] = {}
var _players_3d: Array[AudioStreamPlayer3D] = []
var _players_2d: Array[AudioStreamPlayer] = []
var _next_3d: int = 0
var _next_2d: int = 0
var _wind: AudioStreamPlayer = null
var _crickets: AudioStreamPlayer = null
var _hum: AudioStreamPlayer = null
var _check_left: float = 0.0
var _music: Array[AudioStreamPlayer] = []
var _next_music: int = 0
var _music_left: float = 3.0
var _note: int = 2


func _ready() -> void:
	name = "Sound"
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in POOL_3D:
		var player := AudioStreamPlayer3D.new()
		player.max_distance = MAX_DISTANCE
		player.unit_size = 6.0
		add_child(player)
		_players_3d.append(player)
	for i: int in POOL_2D:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players_2d.append(player)
	_wind = _loop_player(&"wind")
	_crickets = _loop_player(&"crickets")
	_hum = _loop_player(&"hum")
	for i: int in 3:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = MUSIC_DB
		add_child(voice)
		_music.append(voice)
	apply_volume()
	EventBus.stage_reached.connect(func(_rank: int, _stage: int) -> void: play(&"stage"))
	EventBus.breakthrough_attempted.connect(func(success: bool, _rank: int) -> void: play(&"gong" if success else &"fail"))
	EventBus.killer_move_used.connect(func(_id: StringName) -> void: play(&"killer"))
	EventBus.duel_started.connect(func(_master: Node3D) -> void: play(&"drum"))


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _loop_player(id: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream(id)
	player.volume_db = -80.0
	add_child(player)
	return player


func stream(id: StringName) -> AudioStreamWAV:
	if not _streams.has(id):
		_streams[id] = SoundSynth.build(id)
	return _streams[id]


## Spielt einen Klang; mit Ort räumlich, sonst direkt (Knöpfe, eigene Meldungen).
static func play(id: StringName, at: Vector3 = Vector3.INF, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if instance != null and volume() > 0.0:
		instance._play(id, at, volume_db, pitch)


func _play(id: StringName, at: Vector3, volume_db: float, pitch: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(id, -1.0)) < MIN_GAP:
		return
	_last[id] = now
	var wav: AudioStreamWAV = stream(id)
	if wav == null:
		return
	if at == Vector3.INF:
		var flat: AudioStreamPlayer = _players_2d[_next_2d]
		_next_2d = (_next_2d + 1) % _players_2d.size()
		flat.stream = wav
		flat.volume_db = volume_db
		flat.pitch_scale = pitch
		flat.play()
		return
	var spatial: AudioStreamPlayer3D = _players_3d[_next_3d]
	_next_3d = (_next_3d + 1) % _players_3d.size()
	spatial.stream = wav
	spatial.volume_db = volume_db
	spatial.pitch_scale = pitch
	spatial.global_position = at
	spatial.play()


## Gu-Wirken: Klangfarbe nach dem Pfad-Tag der Familie, leicht variierte Tonhöhe, höhere Ränge tiefer und voller.
static func cast(family: GuFamilyData, rank: int, at: Vector3) -> void:
	var id: StringName = &"cast_luft"
	for tag: StringName in family.tags:
		if TAG_SOUNDS.has(tag):
			id = TAG_SOUNDS[tag]
			break
	play(id, at, -4.0 + rank, randf_range(0.92, 1.08) * (1.1 - rank * 0.04))


## Treffer: am Spieler dumpf („hurt"), sonst heller Schlag.
static func hit(at: Vector3, on_player: bool) -> void:
	play(&"hurt" if on_player else &"hit", at, -6.0, randf_range(0.9, 1.1))


## Alle Klänge nach und nach vorbauen (einer pro Bild), damit der erste Einsatz nicht ruckelt.
const WARM: Array[StringName] = [&"click", &"hit", &"hurt", &"pickup", &"cast_wucht", &"cast_luft", &"cast_schnitt", &"cast_feuer",
	&"cast_blitz", &"cast_eis", &"cast_licht", &"cast_gift", &"cast_wasser", &"cast_seele", &"cast_klang", &"cast_stern", &"cast_erde",
	&"cast_raum", &"cast_zeit", &"cast_metall", &"cast_holz", &"killer", &"stage", &"gong", &"fail", &"drum", &"warn"]


func _process(delta: float) -> void:
	var warming: bool = false
	for id: StringName in WARM:
		if not _streams.has(id):
			stream(id)
			warming = true
			break
	if not warming:
		_warm_music()
	_play_music(delta)
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_INTERVAL
	var world: Node = get_tree().get_first_node_in_group(World.GROUP_WORLD)
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Player
	var outside: bool = world != null and not get_tree().paused
	var night: bool = Formulas.is_night(Balance.values, GameState.time_of_day)
	_fade(_wind, outside, AMBIENT_DB)
	_fade(_crickets, outside and night, CRICKETS_DB)
	_fade(_hum, player != null and player.aperture.meditating, HUM_DB)


## Ein Ton nach dem anderen, in kleinen Schritten über die Tonleiter der Region; manchmal zwei Töne zugleich.
func _play_music(delta: float) -> void:
	_music_left -= delta
	if _music_left > 0.0:
		return
	var night: bool = Formulas.is_night(Balance.values, GameState.time_of_day)
	_music_left = randf_range(MUSIC_GAP.x, MUSIC_GAP.y) * (1.6 if night else 1.0)
	var scale: Array = _music_scale()
	if scale.is_empty() or get_tree().paused or volume() <= 0.0:
		return
	_note = clampi(_note + randi_range(-2, 2), 0, scale.size() - 1)
	var octave: float = 0.5 if night else 1.0
	_pluck(_pluck_id(ROOT_HZ * octave * pow(2.0, float(scale[_note]) / 12.0)))
	if randf() < 0.25:
		_pluck(_pluck_id(ROOT_HZ * octave * 0.5 * pow(2.0, float(scale[0]) / 12.0)))


static func _pluck_id(freq: float) -> StringName:
	return StringName("pluck_%d" % roundi(freq))


func _pluck(id: StringName) -> void:
	var voice: AudioStreamPlayer = _music[_next_music]
	_next_music = (_next_music + 1) % _music.size()
	voice.stream = stream(id)
	voice.play()


## Tonleiter der aktuellen Region; im Startmenü die des Qing-Mao-Bergs; sonst keine Musik.
func _music_scale() -> Array:
	var world: World = get_tree().get_first_node_in_group(World.GROUP_WORLD) as World
	if world != null:
		return SCALES.get(world.area.region, SCALES[1])
	if get_tree().get_first_node_in_group(StartMenu.GROUP) != null:
		return SCALES[1]
	return []


## Die Töne der aktuellen Region vorbauen (einer pro Bild).
func _warm_music() -> bool:
	for octave: float in [1.0, 0.5, 0.25]:
		for step: Variant in _music_scale():
			var id: StringName = _pluck_id(ROOT_HZ * octave * pow(2.0, float(step) / 12.0))
			if not _streams.has(id):
				stream(id)
				return true
	return false


func _fade(player: AudioStreamPlayer, active: bool, target_db: float) -> void:
	var on: bool = active and volume() > 0.0
	if on and not player.playing:
		player.play()
	player.volume_db = move_toward(player.volume_db, target_db if on else -80.0, 12.0)
	if not on and player.volume_db <= -79.0 and player.playing:
		player.stop()


# --- Lautstärke ---

static func volume() -> float:
	if _volume_index < 0:
		var config := ConfigFile.new()
		_volume_index = int(config.get_value("ton", "stufe", 0)) if config.load(SETTINGS_PATH) == OK else 0
	return VOLUMES[clampi(_volume_index, 0, VOLUMES.size() - 1)]


static func cycle_volume() -> void:
	_volume_index = (maxi(_volume_index, 0) + 1) % VOLUMES.size()
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("ton", "stufe", _volume_index)
	config.save(SETTINGS_PATH)
	apply_volume()


static func apply_volume() -> void:
	var master: int = AudioServer.get_bus_index(&"Master")
	var level: float = volume()
	AudioServer.set_bus_mute(master, level <= 0.0)
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(level, 0.001)))


static func label() -> String:
	volume()
	return Loc.t("Ton: %s") % Loc.t(VOLUME_NAMES[clampi(_volume_index, 0, VOLUME_NAMES.size() - 1)])
