class_name WorldMapPainter
extends RefCounted
## Zeichnet die Weltkarte wie eine gemalte Landkarte: Meer mit Wellen, ausgefranste Küsten mit Flachwasser-Saum,
## Landflächen mit Licht und Schatten, Flüsse, Inseln im Östlichen Meer, Windrose und Rahmen mit Eckzier.
## Die Umrisse kommen aus den Daten (welt.json → KARTE); die Küstenlinie wird daraus deterministisch verrauscht.

const OCEAN_DEEP: Color = Color(0.05, 0.1, 0.17)
const OCEAN: Color = Color(0.08, 0.16, 0.25)
const SHALLOW: Color = Color(0.2, 0.38, 0.48, 0.55)
const WAVE: Color = Color(0.3, 0.46, 0.58, 0.35)
const RIVER: Color = Color(0.35, 0.62, 0.8)
const FRAME: Color = Color(0.86, 0.72, 0.36)
const COAST_STEPS: int = 7
const COAST_NOISE: float = 0.012
const SHALLOW_WIDTH: float = 9.0
const ISLANDS: int = 11


## Verrauschter Umriss in Bildschirmkoordinaten (gleich bei jedem Zeichnen).
static func coast(region: RegionData, to_screen: Callable) -> PackedVector2Array:
	var noise := FastNoiseLite.new()
	noise.seed = 31 + region.id * 17
	noise.frequency = 18.0
	var result := PackedVector2Array()
	var count: int = region.map_polygon.size()
	for i: int in count:
		var a: Vector2 = region.map_polygon[i]
		var b: Vector2 = region.map_polygon[(i + 1) % count]
		var normal: Vector2 = (b - a).orthogonal().normalized()
		for k: int in COAST_STEPS:
			var t: float = float(k) / COAST_STEPS
			var p: Vector2 = a.lerp(b, t)
			var offset: float = noise.get_noise_2d(p.x, p.y) * COAST_NOISE * (1.0 if k > 0 else 0.4)
			result.append(to_screen.call(p + normal * offset))
	return result


static func ocean(canvas: CanvasItem, rect: Rect2, time: float) -> void:
	canvas.draw_rect(rect, OCEAN)
	# Dunklerer Rand wie ein Tiefseebecken.
	for i: int in 6:
		var inset: float = i * 3.0
		canvas.draw_rect(Rect2(rect.position + Vector2(inset, inset), rect.size - Vector2(inset, inset) * 2.0), Color(OCEAN_DEEP, 0.22 - i * 0.035), false, 3.0)
	# Alle Wellen als eine Linienliste (ein Draw Call).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var segments := PackedVector2Array()
	for i: int in 70:
		var p := Vector2(rng.randf_range(rect.position.x + 12.0, rect.end.x - 12.0), rng.randf_range(rect.position.y + 12.0, rect.end.y - 12.0))
		p.x += sin(time * 0.8 + i) * 2.0
		for k: int in 3:
			var a0: float = PI * (1.15 + k * 0.233)
			segments.append(p + Vector2(cos(a0), sin(a0)) * 5.0)
			segments.append(p + Vector2(cos(a0 + PI * 0.233), sin(a0 + PI * 0.233)) * 5.0)
	canvas.draw_multiline(segments, WAVE, 1.0)


## Landfläche mit Flachwasser-Saum, Füllung, Licht oben links und Schatten unten rechts.
static func land(canvas: CanvasItem, outline: PackedVector2Array, color: Color) -> void:
	var closed: PackedVector2Array = outline.duplicate()
	closed.append(outline[0])
	canvas.draw_polyline(closed, SHALLOW, SHALLOW_WIDTH * 2.0, true)
	canvas.draw_polyline(closed, Color(SHALLOW, 0.8), SHALLOW_WIDTH, true)
	canvas.draw_colored_polygon(outline, color.darkened(0.42))
	var center: Vector2 = _center(outline)
	canvas.draw_colored_polygon(_shrunk(outline, center, 0.86, Vector2(-3, -3)), color.darkened(0.3))
	canvas.draw_colored_polygon(_shrunk(outline, center, 0.62, Vector2(-5, -5)), color.darkened(0.2))
	canvas.draw_polyline(closed, Color(0.9, 0.85, 0.7, 0.55), 1.2, true)


## Meeresregion: helleres Wasser mit Inseln.
static func sea(canvas: CanvasItem, outline: PackedVector2Array, color: Color, seed_value: int) -> void:
	canvas.draw_colored_polygon(outline, Color(color.darkened(0.35), 0.55))
	var bounds := Rect2(outline[0], Vector2.ZERO)
	for p: Vector2 in outline:
		bounds = bounds.expand(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var placed: int = 0
	var tries: int = 0
	while placed < ISLANDS and tries < 200:
		tries += 1
		var p := Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
		if not Geometry2D.is_point_in_polygon(p, outline):
			continue
		var island := PackedVector2Array()
		var size: float = rng.randf_range(4.0, 10.0)
		for k: int in 9:
			var angle: float = k * TAU / 9.0
			island.append(p + Vector2(cos(angle), sin(angle) * 0.75) * size * rng.randf_range(0.7, 1.2))
		var ring: PackedVector2Array = island.duplicate()
		ring.append(island[0])
		canvas.draw_polyline(ring, SHALLOW, 5.0, true)
		canvas.draw_colored_polygon(island, Color(0.42, 0.55, 0.32))
		canvas.draw_circle(p + Vector2(-size * 0.15, -size * 0.15), size * 0.35, Color(0.5, 0.64, 0.38))
		placed += 1


static func river(canvas: CanvasItem, line: Array, to_screen: Callable) -> void:
	var points := PackedVector2Array()
	for i: int in line.size() - 1:
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		for k: int in 4:
			var t: float = k / 4.0
			points.append(to_screen.call(a.lerp(b, t) + (b - a).orthogonal() * sin(t * PI) * 0.12))
	points.append(to_screen.call(line[line.size() - 1]))
	canvas.draw_polyline(points, Color(RIVER, 0.35), 4.0, true)
	canvas.draw_polyline(points, RIVER, 1.6, true)


## Windrose unten rechts im Meer.
static func compass(canvas: CanvasItem, center: Vector2, radius: float, font: Font) -> void:
	canvas.draw_circle(center, radius * 1.05, Color(OCEAN_DEEP, 0.7))
	canvas.draw_arc(center, radius, 0.0, TAU, 32, FRAME, 1.5, true)
	for i: int in 8:
		var angle: float = i * TAU / 8.0 - PI * 0.5
		var length: float = radius * (0.95 if i % 2 == 0 else 0.55)
		var tip: Vector2 = center + Vector2(cos(angle), sin(angle)) * length
		var side: Vector2 = Vector2(cos(angle + PI * 0.5), sin(angle + PI * 0.5)) * radius * 0.14
		canvas.draw_colored_polygon(PackedVector2Array([center + side, tip, center - side]), FRAME if i % 2 == 0 else FRAME.darkened(0.35))
	canvas.draw_string(font, center + Vector2(-5, -radius - 4.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, FRAME)


## Doppelter Goldrahmen mit Eckzier.
static func frame(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, FRAME, false, 2.0)
	canvas.draw_rect(rect.grow(-5.0), Color(FRAME, 0.5), false, 1.0)
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var inward: Vector2 = (rect.get_center() - corner).sign()
		canvas.draw_colored_polygon(PackedVector2Array([corner, corner + Vector2(inward.x * 18.0, 0), corner + Vector2(0, inward.y * 18.0)]), FRAME)
		canvas.draw_circle(corner + inward * 11.0, 2.5, FRAME)


static func _center(points: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p: Vector2 in points:
		sum += p
	return sum / points.size()


static func _shrunk(points: PackedVector2Array, center: Vector2, factor: float, shift: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p: Vector2 in points:
		result.append(center + (p - center) * factor + shift)
	return result
