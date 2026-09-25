class_name SoundSynth
extends RefCounted
## Erzeugt alle Klänge des Spiels zur Laufzeit als AudioStreamWAV (keine Audiodateien, keine Lizenzfragen):
## Schläge, Rauschen, Glocken, Blitz-Surren, Knistern, dazu nahtlose Schleifen für Wind, Grillen und das Summen
## beim Kultivieren. Jeder Klang wird einmal gebaut und zwischengespeichert (Sound.stream).

const RATE: int = 22050

static var _rng := RandomNumberGenerator.new()


## Klang nach Namen; leer, wenn es ihn nicht gibt.
static func build(id: StringName) -> AudioStreamWAV:
	_rng.seed = hash(id)
	match id:
		&"hit":
			return _make(_mix([_thump(140.0, 0.12, 0.9), _noise_burst(0.05, 0.5)]))
		&"hurt":
			return _make(_mix([_thump(90.0, 0.2, 1.0), _noise_burst(0.08, 0.35)]))
		&"cast_wucht":
			return _make(_mix([_thump(70.0, 0.25, 0.9), _whoosh(0.3, 0.25, 0.4)]))
		&"cast_luft":
			return _make(_whoosh(0.35, 0.55, 0.7))
		&"cast_schnitt":
			return _make(_whoosh(0.2, 0.8, 0.7))
		&"cast_feuer":
			return _make(_mix([_whoosh(0.35, 0.35, 0.45), _crackle(0.45, 0.6)]))
		&"cast_blitz":
			return _make(_zap(0.28, 1400.0, 180.0))
		&"cast_eis":
			return _make(_bell(1760.0, 0.5, 0.5))
		&"cast_licht":
			return _make(_mix([_bell(1180.0, 0.6, 0.45), _bell(1770.0, 0.4, 0.2)]))
		&"cast_gift":
			return _make(_bubble(0.4))
		&"cast_wasser":
			return _make(_mix([_whoosh(0.4, 0.2, 0.5), _bubble(0.3)]))
		&"cast_seele":
			return _make(_bell(520.0, 0.7, 0.55, 6.0))
		&"cast_klang":
			return _make(_bell(330.0, 1.1, 0.8))
		&"cast_stern":
			return _make(_mix([_bell(1500.0, 0.35, 0.35), _bell(2250.0, 0.5, 0.25)]))
		&"cast_erde":
			return _make(_mix([_thump(50.0, 0.4, 1.0), _noise_burst(0.2, 0.3)]))
		&"cast_raum":
			return _make(_zap(0.3, 300.0, 1200.0, 0.5))
		&"cast_zeit":
			return _make(_mix([_bell(880.0, 0.8, 0.35), _bell(660.0, 0.8, 0.3)]))
		&"cast_metall":
			return _make(_bell(930.0, 0.45, 0.6, 0.0, 2.41))
		&"cast_holz":
			return _make(_mix([_bell(440.0, 0.4, 0.3), _whoosh(0.3, 0.15, 0.2)]))
		&"killer":
			return _make(_mix([_thump(45.0, 0.9, 1.0), _whoosh(0.8, 0.3, 0.5), _bell(220.0, 1.2, 0.3)]))
		&"pickup":
			return _make(_mix([_tone(880.0, 0.08, 0.4, 0.0), _tone(1320.0, 0.12, 0.35, 0.07)]))
		&"click":
			return _make(_tone(1200.0, 0.03, 0.25, 0.0))
		&"stage":
			return _make(_mix([_bell(523.0, 1.4, 0.45), _bell(784.0, 1.4, 0.35), _bell(1046.0, 1.2, 0.25)]))
		&"gong":
			return _make(_bell(110.0, 3.0, 0.9, 3.0))
		&"fail":
			return _make(_mix([_thump(60.0, 0.6, 0.9), _noise_burst(0.3, 0.3)]))
		&"warn":
			return _make(_mix([_tone(660.0, 0.1, 0.35, 0.0), _tone(990.0, 0.14, 0.35, 0.09)]))
		&"drum":
			return _make(_mix([_thump(65.0, 0.35, 1.0), _thump(65.0, 0.35, 0.8, 0.3)]))
		&"wind":
			return _make(_wind(4.0), true)
		&"rain":
			return _make(_rain(3.0), true)
		&"crickets":
			return _make(_crickets(2.0), true)
		&"hum":
			return _make(_hum(2.0), true)
	# Gezupfte Saite (Guzheng-artig) für die Musik: "pluck_<Hz>".
	if String(id).begins_with("pluck_"):
		return _make(_pluck(float(String(id).trim_prefix("pluck_")), 2.2))
	return null


static func _make(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	# Nicht übersteuern: zu laute Mischungen auf 90 % herunterrechnen.
	var peak: float = 0.0
	for value: float in samples:
		peak = maxf(peak, absf(value))
	var gain: float = 0.9 / peak if peak > 0.9 else 1.0
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


## Summe mehrerer Klänge (Länge des längsten).
static func _mix(parts: Array) -> PackedFloat32Array:
	var length: int = 0
	for part: PackedFloat32Array in parts:
		length = maxi(length, part.size())
	var result := PackedFloat32Array()
	result.resize(length)
	for part: PackedFloat32Array in parts:
		for i: int in part.size():
			result[i] += part[i]
	return result


static func _count(seconds: float) -> int:
	return int(seconds * RATE)


## Dumpfer Schlag: Sinus mit fallender Tonhöhe; delay verschiebt den Einsatz.
static func _thump(freq: float, seconds: float, gain: float, delay: float = 0.0) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds + delay))
	var phase: float = 0.0
	var start: int = _count(delay)
	for i: int in range(start, result.size()):
		var t: float = float(i - start) / RATE
		phase += TAU * freq * (1.0 + 1.5 * exp(-t * 30.0)) / RATE
		result[i] = sin(phase) * exp(-t * 6.0 / seconds) * gain
	return result


static func _noise_burst(seconds: float, gain: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	for i: int in result.size():
		result[i] = _rng.randf_range(-1.0, 1.0) * exp(-float(i) / RATE * 5.0 / seconds) * gain
	return result


## Gefiltertes Rauschen, das an- und abschwillt; brightness 0–1 = Filterhöhe.
static func _whoosh(seconds: float, brightness: float, gain: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	var low: float = 0.0
	for i: int in result.size():
		var x: float = float(i) / result.size()
		var alpha: float = clampf(brightness * (0.2 + 0.8 * sin(x * PI)), 0.02, 0.95)
		low += (_rng.randf_range(-1.0, 1.0) - low) * alpha
		result[i] = low * sin(x * PI) * gain
	return result


static func _crackle(seconds: float, gain: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	for i: int in result.size():
		if _rng.randf() < 0.004:
			for k: int in mini(60, result.size() - i):
				result[i + k] += _rng.randf_range(-1.0, 1.0) * exp(-float(k) / 12.0) * gain
	return result


## Surrender Blitz: Rechteck mit gleitender Tonhöhe und etwas Rauschen.
static func _zap(seconds: float, from_freq: float, to_freq: float, gain: float = 0.35) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	var phase: float = 0.0
	for i: int in result.size():
		var x: float = float(i) / result.size()
		phase += TAU * lerpf(from_freq, to_freq, x) / RATE
		var square: float = 1.0 if sin(phase) > 0.0 else -1.0
		result[i] = (square * 0.7 + _rng.randf_range(-0.3, 0.3)) * (1.0 - x) * gain
	return result


## Glocke: Grundton mit unharmonischen Obertönen; vibrato in Hz, ratio = zweiter Oberton.
static func _bell(freq: float, seconds: float, gain: float, vibrato: float = 0.0, ratio: float = 2.76) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	for i: int in result.size():
		var t: float = float(i) / RATE
		var wobble: float = 1.0 + 0.004 * sin(TAU * vibrato * t)
		var tone: float = sin(TAU * freq * wobble * t) + 0.5 * sin(TAU * freq * ratio * t) * exp(-t * 4.0) + 0.25 * sin(TAU * freq * 5.4 * t) * exp(-t * 8.0)
		result[i] = tone * exp(-t * 4.0 / seconds) * minf(1.0, t * 400.0) * gain * 0.6
	return result


static func _tone(freq: float, seconds: float, gain: float, delay: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds + delay))
	var start: int = _count(delay)
	for i: int in range(start, result.size()):
		var t: float = float(i - start) / RATE
		result[i] = sin(TAU * freq * t) * exp(-t * 5.0 / seconds) * gain
	return result


static func _bubble(seconds: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	var phase: float = 0.0
	for i: int in result.size():
		var t: float = float(i) / RATE
		phase += TAU * (300.0 + 250.0 * abs(sin(TAU * 11.0 * t))) / RATE
		result[i] = sin(phase) * sin(PI * t / seconds) * 0.35
	return result


## Karplus-Strong: Rauschen in einer Verzögerungsschleife, die mittelt und abklingt – klingt wie eine gezupfte Saite.
static func _pluck(freq: float, seconds: float) -> PackedFloat32Array:
	var period: int = maxi(2, int(RATE / freq))
	var ring := PackedFloat32Array()
	ring.resize(period)
	for i: int in period:
		ring[i] = _rng.randf_range(-1.0, 1.0)
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	var index: int = 0
	for i: int in result.size():
		var next: int = (index + 1) % period
		var value: float = (ring[index] + ring[next]) * 0.5 * 0.996
		result[i] = ring[index] * 0.5 * minf(1.0, float(result.size() - i) / 2000.0)
		ring[index] = value
		index = next
	return result


## Nahtlose Schleife: das Ende wird in den Anfang überblendet.
static func _loop(samples: PackedFloat32Array, fade_seconds: float) -> PackedFloat32Array:
	var fade: int = _count(fade_seconds)
	var length: int = samples.size() - fade
	var result := samples.slice(0, length)
	for i: int in fade:
		var w: float = float(i) / fade
		result[i] = samples[i] * w + samples[length + i] * (1.0 - w)
	return result


static func _wind(seconds: float) -> PackedFloat32Array:
	var raw := PackedFloat32Array()
	raw.resize(_count(seconds + 0.5))
	var low: float = 0.0
	for i: int in raw.size():
		var t: float = float(i) / RATE
		low += (_rng.randf_range(-1.0, 1.0) - low) * (0.02 + 0.015 * sin(TAU * 0.35 * t))
		raw[i] = low * (0.6 + 0.4 * sin(TAU * 0.25 * t + 1.0)) * 2.2
	return _loop(raw, 0.5)


## Regen: weiches Rauschen und einzelne, kurz klingende Tropfen.
static func _rain(seconds: float) -> PackedFloat32Array:
	var raw := PackedFloat32Array()
	raw.resize(_count(seconds + 0.5))
	var soft: float = 0.0
	for i: int in raw.size():
		soft += (_rng.randf_range(-1.0, 1.0) - soft) * 0.3
		raw[i] = soft * 0.55
	for drop: int in int(seconds * 16.0):
		var start: float = _rng.randf() * seconds
		var pitch: float = _rng.randf_range(1400.0, 3600.0)
		for i: int in range(_count(start), mini(raw.size(), _count(start + 0.035))):
			var t: float = float(i) / RATE - start
			raw[i] += sin(TAU * pitch * t) * exp(-t * 130.0) * 0.4
	return _loop(raw, 0.5)


static func _crickets(seconds: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	for chirp: int in 6:
		var start: float = chirp * seconds / 6.0 + _rng.randf_range(0.0, 0.1)
		for i: int in range(_count(start), mini(result.size(), _count(start + 0.12))):
			var t: float = float(i) / RATE - start
			result[i] += sin(TAU * 4400.0 * t) * (0.5 + 0.5 * sin(TAU * 60.0 * t)) * sin(PI * t / 0.12) * 0.25
	return result


## Summen beim Kultivieren: tiefe Töne mit leichter Schwebung (ganze Perioden, damit die Schleife nahtlos ist).
static func _hum(seconds: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_count(seconds))
	for i: int in result.size():
		var t: float = float(i) / RATE
		result[i] = (sin(TAU * 110.0 * t) * 0.5 + sin(TAU * 110.5 * t) * 0.4 + sin(TAU * 330.0 * t) * 0.12) * 0.5
	return result
