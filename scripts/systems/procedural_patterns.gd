class_name ProceduralPatterns
extends RefCounted
## Gezeichnete Muster für ProceduralTextures, möglichst ohne Pixelschleifen (Kacheln werden klein gezeichnet und
## kopiert, Verläufe kommen aus Gradienten): Holzbretter, Dachziegel, Gewebe, Laubdecke mit Löchern, Wolkendecke.

const SIZE: int = ProceduralTextures.SIZE


## Holz: Maserung (grain, L8) mit vier waagrechten Brettern, Fugen dunkel, Bretter abwechselnd etwas heller.
static func wood(grain: Image) -> Image:
	grain.convert(Image.FORMAT_RGBA8)
	var planks: int = 4
	var plank_height: int = floori(float(SIZE) / planks)
	for i: int in planks:
		var y: int = i * plank_height
		grain.fill_rect(Rect2i(0, y, SIZE, 2), Color(0.12, 0.12, 0.12))
		grain.fill_rect(Rect2i(0, y + 2, SIZE, 1), Color(0.3, 0.3, 0.3))
		grain.fill_rect(Rect2i(0, y + plank_height - 1, SIZE, 1), Color(0.2, 0.2, 0.2))
		if i % 2 == 1:
			# Aufhellen über eine geblendete Fläche (fill_rect ersetzt Pixel statt zu mischen).
			var lighten := Image.create(SIZE, plank_height - 4, false, Image.FORMAT_RGBA8)
			lighten.fill(Color(1.0, 1.0, 1.0, 0.08))
			grain.blend_rect(lighten, Rect2i(0, 0, SIZE, plank_height - 4), Vector2i(0, y + 3))
	grain.convert(Image.FORMAT_L8)
	return grain


## Dachziegel: ein gewölbter Ziegel wird gezeichnet (kleine Schleife) und in versetzten Reihen kopiert; darüber Rauschen.
static func tiles(noise: Image) -> Image:
	var rows: int = 8
	var columns: int = 8
	var h: int = floori(float(SIZE) / rows)
	var w: int = floori(float(SIZE) / columns)
	var tile := Image.create(w, h, false, Image.FORMAT_L8)
	for y: int in h:
		var v_in: float = float(y) / h
		for x: int in w:
			var u_in: float = float(x) / w
			var curve: float = sqrt(maxf(0.0, 1.0 - pow(u_in * 2.0 - 1.0, 2.0)))
			var lip: float = 1.0 - smoothstep(0.8, 1.0, v_in) * 0.7
			var v: float = 0.3 + 0.55 * curve * lip - v_in * 0.12
			tile.set_pixel(x, y, Color(v, v, v))
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for row: int in rows:
		var shift: int = floori(w * 0.5) if row % 2 == 1 else 0
		for column: int in range(-1, columns + 1):
			image.blit_rect(tile, Rect2i(0, 0, w, h), Vector2i(column * w + shift, row * h))
	_overlay(image, noise, 0.15)
	return image


## Stoff: Gewebe aus einer 8×8-Zelle (Kette und Schuss), darüber leichtes Rauschen.
static func fabric(noise: Image) -> Image:
	var cell := Image.create(8, 8, false, Image.FORMAT_L8)
	for y: int in 8:
		for x: int in 8:
			var weave: float = sin(x * TAU / 8.0) * sin(y * TAU / 8.0) * 0.5 + 0.5
			var v: float = 0.45 + weave * 0.35
			cell.set_pixel(x, y, Color(v, v, v))
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y: int in range(0, SIZE, 8):
		for x: int in range(0, SIZE, 8):
			image.blit_rect(cell, Rect2i(0, 0, 8, 8), Vector2i(x, y))
	_overlay(image, noise, 0.2)
	return image


## Laubdecke (kachelbar, RGBA): Helligkeit des Laubs, Alpha mit organischen Löchern für den Ausschnitt der Kronen.
static func leaf_cover(tone: Image, holes: Image) -> Image:
	tone.convert(Image.FORMAT_L8)
	holes.convert(Image.FORMAT_L8)
	var tone_data: PackedByteArray = tone.get_data()
	var hole_data: PackedByteArray = holes.get_data()
	var data := PackedByteArray()
	data.resize(SIZE * SIZE * 4)
	for i: int in SIZE * SIZE:
		var v: int = tone_data[i]
		data[i * 4] = v
		data[i * 4 + 1] = v
		data[i * 4 + 2] = v
		data[i * 4 + 3] = int(smoothstep(0.34, 0.5, hole_data[i] / 255.0) * 255.0)
	return Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGBA8, data)


## Wolken als Himmelsdecke (equirektangular 2:1, oben Zenit, Mitte Horizont): Ballen aus Rauschen mit Kontrast,
## unter dem Horizont schwarz, darüber ein weicher Übergang.
static func clouds(noise: FastNoiseLite) -> Image:
	noise.fractal_lacunarity = 2.2
	var width: int = SIZE * 2
	var height: int = SIZE
	var image: Image = noise.get_seamless_image(width, height, false, false, 0.2, true)
	image.convert(Image.FORMAT_RGBA8)
	image.adjust_bcs(0.7, 2.6, 1.0)
	var half: int = floori(height * 0.5)
	image.fill_rect(Rect2i(0, half, width, height - half), Color.BLACK)
	# Weicher Übergang zum Horizont: Streifen mit Verlauf (Alpha), darüber geblendet.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0, 0, 0, 1))
	var strip := GradientTexture2D.new()
	strip.gradient = gradient
	strip.width = width
	strip.height = floori(height * 0.14)
	strip.fill_from = Vector2(0.0, 0.0)
	strip.fill_to = Vector2(0.0, 1.0)
	var fade: Image = strip.get_image()
	fade.convert(Image.FORMAT_RGBA8)
	image.blend_rect(fade, Rect2i(0, 0, width, fade.get_height()), Vector2i(0, half - fade.get_height()))
	image.convert(Image.FORMAT_RGB8)
	return image


## Rauschen (L8) anteilig über ein Bild legen (Weich- statt Pixelschleife: über Alpha geblendet).
static func _overlay(image: Image, noise: Image, amount: float) -> void:
	image.convert(Image.FORMAT_RGBA8)
	noise.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = noise.get_data()
	var value: int = int(amount * 255.0)
	for i: int in range(3, data.size(), 4):
		data[i] = value
	noise.set_data(noise.get_width(), noise.get_height(), false, Image.FORMAT_RGBA8, data)
	image.blend_rect(noise, Rect2i(0, 0, image.get_width(), image.get_height()), Vector2i.ZERO)
	image.convert(Image.FORMAT_L8)
