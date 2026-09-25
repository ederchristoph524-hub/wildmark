class_name StartBackground
extends Control
## Gemalter Hintergrund des Startmenüs: Nachthimmel mit Sternen und Vollmond, drei Bergketten im Tuschestil wie am
## Qing-Mao-Berg (auf der mittleren ein Dorf mit Pagode und warmen Fenstern, vorn Kiefern), ziehende Nebelbänder
## und aufsteigende Gu-Lichter in Pfadfarben. Alles wird gemalt (keine Texturen) und sanft animiert; Flächen als
## Dreiecksnetz in einem Zeichenbefehl.

const SKY_TOP: Color = Color(0.015, 0.025, 0.06)
const SKY_MID: Color = Color(0.05, 0.08, 0.14)
const SKY_HORIZON: Color = Color(0.2, 0.22, 0.3)
const MOON_COLOR: Color = Color(0.95, 0.96, 0.88)
const MOON_GLOW: Color = Color(0.6, 0.75, 0.9)
const MOON_AT: Vector2 = Vector2(0.14, 0.2)
const MOON_SIZE: float = 0.06
const MIST_COLOR: Color = Color(0.62, 0.7, 0.8)
const WINDOW_COLOR: Color = Color(1.0, 0.72, 0.32)
const STAR_COUNT: int = 110
const LIGHT_COUNT: int = 36
const LIGHT_COLORS: Array[Color] = [Color(0.55, 1.0, 0.45), Color(1.0, 0.85, 0.4), Color(0.5, 0.85, 1.0), Color(0.85, 0.6, 1.0), Color(1.0, 0.5, 0.35)]
const SEGMENTS: int = 80
const HALF_SEGMENTS: int = 40
## Bergketten von hinten nach vorn: Fußlinie und Ausschlag (Anteile der Höhe), Spitzen-Frequenz, Farben, Drift.
const RANGE_BASE: Array[float] = [0.6, 0.74, 0.9]
const RANGE_AMP: Array[float] = [0.26, 0.22, 0.16]
const RANGE_FREQ: Array[float] = [4.2, 6.5, 9.0]
const RANGE_TOP: Array[Color] = [Color(0.2, 0.24, 0.32), Color(0.09, 0.12, 0.16), Color(0.025, 0.04, 0.045)]
const RANGE_FOOT: Array[Color] = [Color(0.3, 0.33, 0.4), Color(0.13, 0.17, 0.2), Color(0.02, 0.03, 0.035)]
const RANGE_DRIFT: Array[float] = [4.0, 9.0, 16.0]
## Dorf und Pagode auf der mittleren Kette (Anteil der Breite).
const VILLAGE_RANGE: Vector2 = Vector2(0.74, 0.9)
const PINES: Array[float] = [0.03, 0.07, 0.1, 0.16, 0.84, 0.88, 0.93, 0.97]

var _time: float = 0.0
var _stars: Array[Vector4] = []
var _lights: Array[Vector4] = []
var _glow: GradientTexture2D = _soft_glow()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Feste Saat: jedes Mal derselbe Himmel (auch auf Bildschirmfotos).
	var random := RandomNumberGenerator.new()
	random.seed = 7
	for i: int in STAR_COUNT:
		_stars.append(Vector4(random.randf(), pow(random.randf(), 1.6) * 0.62, random.randf_range(0.6, 2.2), random.randf() * TAU))
	for i: int in LIGHT_COUNT:
		_lights.append(Vector4(random.randf(), random.randf_range(0.012, 0.035), random.randf(), float(i % LIGHT_COLORS.size())))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_sky()
	_draw_stars()
	_draw_moon()
	for layer: int in RANGE_BASE.size():
		var ridge: PackedVector2Array = _ridge_line(layer)
		_band(ridge, _floor_line(ridge), RANGE_TOP[layer], RANGE_FOOT[layer])
		if layer == 1:
			_draw_village(ridge)
		if layer == 2:
			_draw_pines(ridge)
		if layer < 2:
			_draw_mist(RANGE_BASE[layer] - 0.02, 0.07, 0.16 - 0.04 * layer, layer)
	_draw_mist(0.97, 0.06, 0.1, 3)
	_draw_lights()
	_draw_shade()


func _draw_sky() -> void:
	var top := PackedVector2Array([Vector2(0.0, 0.0), Vector2(size.x, 0.0)])
	var middle := PackedVector2Array([Vector2(0.0, size.y * 0.35), Vector2(size.x, size.y * 0.35)])
	var horizon := PackedVector2Array([Vector2(0.0, size.y * 0.7), Vector2(size.x, size.y * 0.7)])
	var bottom := PackedVector2Array([Vector2(0.0, size.y), Vector2(size.x, size.y)])
	_band(top, middle, SKY_TOP, SKY_MID)
	_band(middle, horizon, SKY_MID, SKY_HORIZON)
	_band(horizon, bottom, SKY_HORIZON, SKY_HORIZON)


func _draw_stars() -> void:
	for star: Vector4 in _stars:
		var shine: float = 0.35 + 0.35 * sin(_time * star.z + star.w)
		var at := Vector2(star.x * size.x, star.y * size.y)
		var dot: float = 1.0 + star.z * 0.6
		draw_rect(Rect2(at - Vector2.ONE * dot * 0.5, Vector2.ONE * dot), Color(0.9, 0.93, 1.0, shine))


func _draw_moon() -> void:
	var radius: float = size.y * MOON_SIZE
	var at := Vector2(size.x * MOON_AT.x, size.y * MOON_AT.y)
	_glow_at(at, radius * 7.0, Color(MOON_GLOW, 0.32))
	_glow_at(at, radius * 2.4, Color(MOON_GLOW, 0.55))
	draw_circle(at, radius, MOON_COLOR)
	# Mondmeere: weiche, leicht dunklere Flecken.
	_glow_at(at + Vector2(-0.3, -0.2) * radius, radius * 0.45, Color(0.55, 0.58, 0.55, 0.35))
	_glow_at(at + Vector2(0.28, 0.12) * radius, radius * 0.55, Color(0.55, 0.58, 0.55, 0.3))
	_glow_at(at + Vector2(-0.1, 0.48) * radius, radius * 0.3, Color(0.55, 0.58, 0.55, 0.3))


func _glow_at(at: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(_glow, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)


## Weicher runder Schein (Mitte hell, außen durchsichtig).
static func _soft_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.2, Color(1, 1, 1, 0.6))
	gradient.add_point(0.5, Color(1, 1, 1, 0.18))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


## Grat einer Kette: spitze Gipfel (1 − |sin|) mehrerer Frequenzen, langsam seitlich ziehend.
func _ridge_line(layer: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var shift: float = sin(_time * 0.05) * RANGE_DRIFT[layer]
	var salt: float = 1.3 + layer * 2.7
	var freq: float = RANGE_FREQ[layer]
	for i: int in SEGMENTS + 1:
		var u: float = float(i) / SEGMENTS
		var h: float = pow(1.0 - absf(sin(u * freq + salt)), 1.6) * 0.62
		h += pow(1.0 - absf(sin(u * freq * 2.3 + salt * 1.9)), 2.0) * 0.28
		h += sin(u * freq * 5.1 + salt * 3.1) * 0.05
		points.append(Vector2(u * size.x + shift, size.y * (RANGE_BASE[layer] - RANGE_AMP[layer] * h)))
	points[0].x = minf(points[0].x, 0.0)
	points[SEGMENTS].x = maxf(points[SEGMENTS].x, size.x)
	return points


func _floor_line(ridge: PackedVector2Array) -> PackedVector2Array:
	var base := PackedVector2Array()
	for point: Vector2 in ridge:
		base.append(Vector2(point.x, size.y))
	return base


## Nebelband um eine Höhe: oben und unten durchsichtig, in der Mitte dicht, welliger Rand, zieht langsam.
func _draw_mist(height: float, thickness: float, density: float, phase: int) -> void:
	var top := PackedVector2Array()
	var middle := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i: int in HALF_SEGMENTS + 1:
		var u: float = float(i) / float(HALF_SEGMENTS)
		var wave: float = sin(u * 9.0 + _time * 0.18 + phase * 1.7) * 0.012 + sin(u * 3.0 - _time * 0.1 + phase) * 0.018
		var x: float = u * size.x
		top.append(Vector2(x, size.y * (height - thickness + wave)))
		middle.append(Vector2(x, size.y * (height + wave * 0.6)))
		bottom.append(Vector2(x, size.y * (height + thickness * 0.8 + wave * 0.3)))
	_band(top, middle, Color(MIST_COLOR, 0.0), Color(MIST_COLOR, density))
	_band(middle, bottom, Color(MIST_COLOR, density), Color(MIST_COLOR, 0.0))


## Dorf am höchsten Punkt der mittleren Kette: eine Pagode auf dem Gipfel, Häuser mit geschwungenen Dächern und
## warmen Fenstern die Hänge hinab.
func _draw_village(ridge: PackedVector2Array) -> void:
	var from: int = int(VILLAGE_RANGE.x * SEGMENTS)
	var to: int = int(VILLAGE_RANGE.y * SEGMENTS)
	var peak: int = from
	for i: int in range(from, to + 1):
		if ridge[i].y < ridge[peak].y:
			peak = i
	var unit: float = size.y * 0.008
	var body: Color = RANGE_TOP[1].darkened(0.25)
	for offset: float in [-3.4, -2.3, -1.3, 1.4, 2.4, 3.5, 4.5]:
		var x: float = ridge[peak].x + offset * unit * 5.5
		_draw_house(Vector2(x, _ridge_y(ridge, x) + unit * 2.0), unit * (1.0 - absf(offset) * 0.04), body, int(offset * 10.0))
	_draw_pagoda(ridge[peak] + Vector2(0.0, unit), unit * 1.3, body)


## Höhe des Grats an einer Stelle (zwischen zwei Punkten gemittelt).
func _ridge_y(ridge: PackedVector2Array, x: float) -> float:
	for i: int in ridge.size() - 1:
		if x <= ridge[i + 1].x:
			return lerpf(ridge[i].y, ridge[i + 1].y, clampf((x - ridge[i].x) / maxf(1.0, ridge[i + 1].x - ridge[i].x), 0.0, 1.0))
	return ridge[ridge.size() - 1].y


func _draw_house(ground: Vector2, unit: float, color: Color, salt: int) -> void:
	var width: float = unit * 4.2
	var height: float = unit * 2.2
	draw_rect(Rect2(ground.x - width * 0.5, ground.y - height, width, height + unit * 5.0), color)
	_draw_roof(Vector2(ground.x, ground.y - height), width * 1.4, unit * 1.8, color)
	var flicker: float = 0.8 + 0.2 * sin(_time * (1.5 + absf(salt) * 0.1) + salt)
	var window := Vector2(unit * 0.8, unit * 0.9)
	var lit := Color(WINDOW_COLOR, flicker)
	draw_rect(Rect2(ground + Vector2(-width * 0.3, -height * 0.7), window), lit)
	if salt % 20 != 0:
		draw_rect(Rect2(ground + Vector2(width * 0.12, -height * 0.7), window), Color(lit, flicker * 0.85))
	_glow_at(ground + Vector2(0.0, -height * 0.5), unit * 6.0, Color(WINDOW_COLOR, 0.12 * flicker))


## Geschwungenes Dach: Traufe an den Enden hochgezogen.
func _draw_roof(base: Vector2, width: float, height: float, color: Color) -> void:
	var half: float = width * 0.5
	var roof := PackedVector2Array([
		base + Vector2(-half, -height * 0.35), base + Vector2(-half * 0.8, 0.0), base + Vector2(half * 0.8, 0.0),
		base + Vector2(half, -height * 0.35), base + Vector2(half * 0.45, -height * 0.7), base + Vector2(0.0, -height),
		base + Vector2(-half * 0.45, -height * 0.7),
	])
	draw_colored_polygon(roof, color)


func _draw_pagoda(ground: Vector2, unit: float, color: Color) -> void:
	var y: float = ground.y
	for tier: int in 5:
		var width: float = unit * (3.4 - tier * 0.5)
		var height: float = unit * 1.5
		draw_rect(Rect2(ground.x - width * 0.35, y - height, width * 0.7, height + 1.0), color)
		if tier < 4:
			draw_rect(Rect2(ground.x - width * 0.12, y - height * 0.75, width * 0.24, height * 0.45), Color(WINDOW_COLOR, 0.55 + 0.2 * sin(_time * 1.3 + tier)))
		_draw_roof(Vector2(ground.x, y - height), width * 1.2, unit * 0.9, color)
		y -= height + unit * 0.55
	draw_line(Vector2(ground.x, y + unit * 0.4), Vector2(ground.x, y - unit * 1.6), color, maxf(1.0, unit * 0.2))


## Kiefern auf der vorderen Kette: gestufte Dreiecke auf einem Stamm.
func _draw_pines(ridge: PackedVector2Array) -> void:
	var color: Color = RANGE_TOP[2].darkened(0.4)
	var unit: float = size.y * 0.016
	for at: float in PINES:
		var ground: Vector2 = ridge[clampi(int(at * SEGMENTS), 0, SEGMENTS)] + Vector2(0.0, unit)
		var height: float = unit * (5.0 + 2.0 * sin(at * 40.0))
		var sway: float = sin(_time * 0.6 + at * 20.0) * unit * 0.15
		draw_line(ground, ground - Vector2(0.0, height * 0.3), color, maxf(1.0, unit * 0.35))
		for tier: int in 4:
			var bottom: float = ground.y - height * (0.2 + tier * 0.2)
			var half: float = unit * (2.0 - tier * 0.4)
			var tip := Vector2(ground.x + sway * (tier + 1), bottom - height * 0.32)
			draw_colored_polygon(PackedVector2Array([Vector2(ground.x - half, bottom), Vector2(ground.x + half, bottom), tip]), color)


## Gu-Lichter: steigen langsam aus dem Tal, schwanken, leuchten auf und verlöschen oben.
func _draw_lights() -> void:
	var unit: float = size.y * 0.004
	for light: Vector4 in _lights:
		var rise: float = fposmod(_time * light.y + light.z, 1.0)
		var x: float = light.x * size.x + sin(_time * 0.7 + light.z * 20.0) * size.x * 0.015
		var y: float = size.y * (1.02 - rise * 0.75)
		var alpha: float = sin(rise * PI) * (0.7 + 0.3 * sin(_time * 3.0 + light.z * 9.0))
		var color: Color = LIGHT_COLORS[int(light.w)]
		var radius: float = unit * (1.0 + light.z)
		_glow_at(Vector2(x, y), radius * 6.0, Color(color, 0.85 * alpha))
		draw_circle(Vector2(x, y), radius, Color(color.lightened(0.5), alpha))


## Dunkler Schleier hinter der Menüspalte, damit die Schrift lesbar bleibt; weich auslaufende Ränder.
func _draw_shade() -> void:
	var half: float = minf(size.x * 0.5, 380.0)
	var soft: float = 90.0
	var center: float = size.x * 0.5
	var shade := Color(0.01, 0.02, 0.03, 0.42)
	var clear := Color(shade, 0.0)
	var column := PackedVector2Array([Vector2(center - half, 0.0), Vector2(center + half, 0.0)])
	var column_bottom := PackedVector2Array([Vector2(center - half, size.y), Vector2(center + half, size.y)])
	_band(column, column_bottom, shade, shade)
	for side: float in [-1.0, 1.0]:
		var inner: float = center + side * half
		var outer: float = inner + side * soft
		_band_horizontal(inner, outer, shade, clear)


## Fläche zwischen zwei Linien gleicher Punktzahl, Farbe oben und unten; ein Dreiecksnetz.
func _band(top: PackedVector2Array, bottom: PackedVector2Array, top_color: Color, bottom_color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i: int in top.size():
		points.append(top[i])
		points.append(bottom[i])
		colors.append(top_color)
		colors.append(bottom_color)
		if i > 0:
			var a: int = (i - 1) * 2
			indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors)


## Senkrechter Streifen von x_from nach x_to mit waagrechtem Farbverlauf.
func _band_horizontal(x_from: float, x_to: float, from_color: Color, to_color: Color) -> void:
	var points := PackedVector2Array([Vector2(x_from, 0.0), Vector2(x_to, 0.0), Vector2(x_to, size.y), Vector2(x_from, size.y)])
	var colors := PackedColorArray([from_color, to_color, to_color, from_color])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), PackedInt32Array([0, 1, 2, 0, 2, 3]), points, colors)
