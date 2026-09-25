class_name ProceduralTextures
extends RefCounted
## Erzeugte, nahtlos kachelbare Texturen für den realistischen Look (keine Bilddateien im Download): Gras, Erde,
## Fels, Putz, Holz, Dachziegel, Rinde, Stoff als Helligkeits-Details (die Farbe kommt weiter aus den Vertex-Farben),
## dazu Normal Maps daraus, Laub- und Grasbüschel-Karten mit Alpha, Wolken und Wellen. Einmal erzeugt, dann als PNG in
## user:// abgelegt (VERSION erhöhen, wenn sich ein Rezept ändert).

const SIZE: int = 256
const VERSION: int = 6
const CACHE_DIR: String = "user://textures/"
const NORMAL_SUFFIX: String = "_normal"
## Stärke der Normal Maps je Grundtextur (Höhenunterschied in Pixeln).
const BUMP: Dictionary[StringName, float] = {
	&"grass": 6.0, &"soil": 8.0, &"rock": 14.0, &"plaster": 4.0, &"wood": 6.0, &"tiles": 16.0, &"bark": 12.0,
	&"fabric": 3.0, &"waves": 10.0, &"leaves": 5.0, &"stone": 12.0, &"fur": 5.0, &"scales": 10.0,
}

static var _cache: Dictionary[StringName, Texture2D] = {}
static var _heights: Dictionary[StringName, Image] = {}
static var _seed: int = 7


## Textur nach Name; "<name>_normal" liefert die Normal Map der Grundtextur.
static func get_texture(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var image: Image = _load_cached(id)
	if image == null:
		image = _generate(id)
		_save_cached(id, image)
	image.generate_mipmaps()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_cache[id] = texture
	return texture


static func _cache_path(id: StringName) -> String:
	return "%sv%d_%s.png" % [CACHE_DIR, VERSION, id]


static func _load_cached(id: StringName) -> Image:
	if not FileAccess.file_exists(_cache_path(id)):
		return null
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(_cache_path(id))) != OK:
		return null
	return image


static func _save_cached(id: StringName, image: Image) -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	image.save_png(_cache_path(id))


static func _generate(id: StringName) -> Image:
	var name: String = String(id)
	if name.ends_with(NORMAL_SUFFIX):
		var base := StringName(name.trim_suffix(NORMAL_SUFFIX))
		var height: Image = _height(base)
		height.convert(Image.FORMAT_RGB8)
		height.bump_map_to_normal_map(BUMP.get(base, 8.0))
		return height
	match id:
		&"leaves":
			return ProceduralCards.leaves(SIZE)
		&"leaf_cover":
			return ProceduralPatterns.leaf_cover(_height(&"leaves"), _combine([_noise(0.1, 3, 70), _cellular(0.13, 71)], [0.55, 0.45], 0.5, 1.0))
		&"tuft":
			return ProceduralCards.tuft(SIZE)
		&"clouds":
			return ProceduralPatterns.clouds(_base_noise(0.006, 5, 60))
	var image: Image = _height(id)
	image.convert(Image.FORMAT_RGB8)
	return image


## Helligkeits-/Höhenbild einer Grundtextur (L8, 0 = tief, 255 = hoch); gemerkt, damit die Normal Map es wiederverwendet.
static func _height(id: StringName) -> Image:
	if _heights.has(id):
		return _heights[id].duplicate()
	var image: Image = _recipe(id)
	_heights[id] = image
	return image.duplicate()


static func _recipe(id: StringName) -> Image:
	match id:
		&"grass":
			return _combine([_noise(0.11, 4, 1), _stretched(0.09, 3, 2, 1, 5), _noise(0.03, 2, 3)], [0.45, 0.35, 0.2], 0.5, 1.0)
		&"soil":
			return _combine([_cellular(0.06, 4), _noise(0.04, 3, 5), _noise(0.3, 2, 6)], [0.4, 0.4, 0.2], 0.5, 0.7)
		&"rock":
			return _combine([_cellular(0.035, 7, FastNoiseLite.RETURN_CELL_VALUE), _ridged(0.06, 8), _noise(0.2, 2, 9)], [0.45, 0.4, 0.15], 0.5, 1.0)
		&"stone":
			return _combine([_cellular(0.05, 10, FastNoiseLite.RETURN_CELL_VALUE), _noise(0.18, 3, 11)], [0.6, 0.4], 0.5, 0.8)
		&"plaster":
			return _combine([_noise(0.3, 3, 12), _noise(0.06, 2, 13), _ridged(0.02, 14)], [0.4, 0.35, 0.25], 0.55, 0.45)
		&"wood":
			return ProceduralPatterns.wood(_combine([_stretched(0.06, 4, 30, 8, 1), _noise(0.2, 2, 31)], [0.7, 0.3], 0.55, 0.9))
		&"tiles":
			return ProceduralPatterns.tiles(_noise(0.15, 2, 40))
		&"bark":
			return _combine([_stretched(0.05, 4, 15, 1, 6), _ridged(0.08, 16), _noise(0.25, 2, 17)], [0.5, 0.35, 0.15], 0.5, 1.0)
		&"fabric":
			return ProceduralPatterns.fabric(_noise(0.2, 2, 50))
		&"fur":
			return _combine([_stretched(0.14, 3, 80, 1, 5), _noise(0.4, 2, 81), _noise(0.04, 2, 82)], [0.55, 0.25, 0.2], 0.5, 1.0)
		&"scales":
			return _combine([_cellular(0.16, 83), _noise(0.3, 2, 84)], [0.75, 0.25], 0.55, 1.0)
		&"waves":
			return _combine([_noise(0.03, 3, 18), _noise(0.08, 2, 19)], [0.7, 0.3], 0.5, 1.0)
		&"leaves":
			return _combine([_noise(0.12, 3, 20), _cellular(0.14, 21)], [0.5, 0.5], 0.5, 1.0)
	return _noise(0.1, 3, 99)


static func _base_noise(frequency: float, octaves: int, salt: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = _seed + salt
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM if octaves > 1 else FastNoiseLite.FRACTAL_NONE
	return noise


static func _noise(frequency: float, octaves: int, salt: int) -> Image:
	return _base_noise(frequency, octaves, salt).get_seamless_image(SIZE, SIZE, false, false, 0.15, true)


static func _ridged(frequency: float, salt: int) -> Image:
	var noise: FastNoiseLite = _base_noise(frequency, 3, salt)
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	return noise.get_seamless_image(SIZE, SIZE, false, false, 0.15, true)


static func _cellular(frequency: float, salt: int, kind: int = FastNoiseLite.RETURN_DISTANCE) -> Image:
	var noise: FastNoiseLite = _base_noise(frequency, 1, salt)
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = kind as FastNoiseLite.CellularReturnType
	noise.cellular_jitter = 0.9
	return noise.get_seamless_image(SIZE, SIZE, false, false, 0.15, true)


## Rauschen, gestreckt um along_x waagrecht bzw. along_y senkrecht (Halme, Maserung, Rinde): klein erzeugt, dann gezogen.
static func _stretched(frequency: float, octaves: int, salt: int, along_x: int, along_y: int) -> Image:
	var image: Image = _base_noise(frequency, octaves, salt).get_seamless_image(floori(float(SIZE) / along_x), floori(float(SIZE) / along_y), false, false, 0.15, true)
	image.resize(SIZE, SIZE, Image.INTERPOLATE_CUBIC)
	return image


## Gewichtete Überlagerung von Helligkeitsbildern (erste Lage voll, weitere anteilig eingeblendet – in C++ über
## blend_rect, keine Pixelschleife), dann Kontrast und Helligkeit um die Mitte.
static func _combine(layers: Array[Image], weights: Array[float], middle: float, contrast: float) -> Image:
	var result: Image = layers[0]
	result.convert(Image.FORMAT_RGBA8)
	var total: float = weights[0]
	for i: int in range(1, layers.size()):
		total += weights[i]
		var layer: Image = layers[i]
		layer.convert(Image.FORMAT_RGBA8)
		_set_alpha(layer, weights[i] / total)
		result.blend_rect(layer, Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
	result.adjust_bcs(1.0 + (middle - 0.5) * 2.0, 1.0 + contrast, 1.0)
	result.convert(Image.FORMAT_L8)
	return result


## Setzt das Alpha eines ganzen RGBA-Bildes (nur der Alpha-Kanal wird angefasst).
static func _set_alpha(image: Image, alpha: float) -> void:
	var data: PackedByteArray = image.get_data()
	var value: int = int(alpha * 255.0)
	for i: int in range(3, data.size(), 4):
		data[i] = value
	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)
