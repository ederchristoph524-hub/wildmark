class_name WorldMapView
extends Control
## Weltkarte der Gu-Welt: die fünf Regionen mit ihren Regionalmauern, Landschaftszeichen, Gebiete und dein Standort.
## Antippen eines Gebiets wählt es aus (Beschreibung und – sobald offen – Reisen).

signal area_selected(area: AreaData)

const OCEAN: Color = Color(0.07, 0.13, 0.2)
const OCEAN_LINE: Color = Color(0.14, 0.24, 0.34)
const LABEL: Color = Color(0.95, 0.92, 0.84)
const CLOSED: Color = Color(0.55, 0.55, 0.55)
const HERE: Color = Color(1.0, 0.85, 0.3)
const WALL_WIDTH: float = 4.0
const AREA_RADIUS: float = 7.0
const PICK_RADIUS: float = 26.0
const DECOR_SEED: int = 99

var current_area: StringName = &""
var selected: AreaData = null
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(520, 360)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press: InputEventMouseButton = event as InputEventMouseButton
	if press == null or not press.pressed or press.button_index != MOUSE_BUTTON_LEFT:
		return
	var best: AreaData = null
	var best_distance: float = PICK_RADIUS
	for resource: Resource in DataRegistry.all(&"areas"):
		var area: AreaData = resource
		var distance: float = _to_screen(area.map_position).distance_to(press.position)
		if distance < best_distance:
			best = area
			best_distance = distance
	if best != null:
		selected = best
		area_selected.emit(best)
		accept_event()


## Karte füllt die Fläche, Seitenverhältnis 3:2.
func _map_rect() -> Rect2:
	var width: float = minf(size.x, size.y * 1.5)
	var height: float = width / 1.5
	return Rect2((size - Vector2(width, height)) * 0.5, Vector2(width, height))


func _to_screen(uv: Vector2) -> Vector2:
	var rect: Rect2 = _map_rect()
	return rect.position + uv * rect.size


func _draw() -> void:
	var rect: Rect2 = _map_rect()
	draw_rect(rect, OCEAN)
	for i: int in 9:
		var y: float = rect.position.y + rect.size.y * (i + 0.5) / 9.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), OCEAN_LINE, 1.0)
	var regions: Array[Resource] = DataRegistry.all(&"regions")
	for resource: Resource in regions:
		var region: RegionData = resource
		if region.map_polygon.size() >= 3:
			draw_colored_polygon(_screen_polygon(region), region.color.darkened(0.45))
	_draw_decor(regions)
	for resource: Resource in regions:
		var region: RegionData = resource
		if region.map_polygon.size() >= 3:
			var outline: PackedVector2Array = _screen_polygon(region)
			outline.append(outline[0])
			var glow: float = 0.6 + 0.4 * sin(_time * 1.5 + region.id)
			draw_polyline(outline, Color(region.wall_color, 0.35 * glow), WALL_WIDTH * 2.2, true)
			draw_polyline(outline, region.wall_color, WALL_WIDTH * 0.6, true)
			_draw_label(_centroid(region) + Vector2(0, -22), tr(region.display_name), 17, LABEL)
	for resource: Resource in DataRegistry.all(&"areas"):
		_draw_area(resource as AreaData)
	draw_rect(rect, Color(0.86, 0.72, 0.36), false, 2.0)


func _draw_area(area: AreaData) -> void:
	var point: Vector2 = _to_screen(area.map_position)
	var here: bool = area.id == current_area
	var color: Color = HERE if here else (DataRegistry.progression().rank_color(area.rank_min) if area.open else CLOSED)
	if here:
		draw_circle(point, AREA_RADIUS + 5.0 + 2.0 * sin(_time * 4.0), Color(HERE, 0.35))
	if selected == area:
		draw_arc(point, AREA_RADIUS + 9.0, 0.0, TAU, 24, LABEL, 2.0)
	draw_circle(point, AREA_RADIUS + 1.5, Color.BLACK)
	draw_circle(point, AREA_RADIUS, color)
	var ranks: String = "R%d" % area.rank_min if area.rank_min == area.rank_max else "R%d–%d" % [area.rank_min, area.rank_max]
	_draw_label(point + Vector2(0, AREA_RADIUS + 16.0), "%s · %s" % [tr(area.display_name), ranks], 13, LABEL if area.open else CLOSED)


## Landschaftszeichen: Berge im Süden, Gras im Norden, Dünen im Westen, Inseln im Osten, Tempel in der Mitte.
func _draw_decor(regions: Array[Resource]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = DECOR_SEED
	for resource: Resource in regions:
		var region: RegionData = resource
		if region.map_polygon.size() < 3:
			continue
		var poly: PackedVector2Array = _screen_polygon(region)
		var bounds: Rect2 = Rect2(poly[0], Vector2.ZERO)
		for p: Vector2 in poly:
			bounds = bounds.expand(p)
		for i: int in 26:
			var point := Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
			if Geometry2D.is_point_in_polygon(point, poly):
				_decor_symbol(region.id, point, region.color)


func _decor_symbol(region_id: int, p: Vector2, color: Color) -> void:
	var ink: Color = color.lightened(0.15)
	match region_id:
		1:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 5), p + Vector2(0, -8), p + Vector2(7, 5)]), color.darkened(0.15))
			draw_polyline(PackedVector2Array([p + Vector2(-7, 5), p + Vector2(0, -8), p + Vector2(7, 5)]), ink, 1.0)
		0:
			for dx: float in [-3.0, 0.0, 3.0]:
				draw_line(p + Vector2(dx, 3), p + Vector2(dx * 1.6, -4), ink, 1.0)
		3:
			draw_arc(p, 7.0, PI * 1.15, PI * 1.85, 8, ink, 1.5)
		2:
			draw_circle(p, 4.0, color.lightened(0.05))
			draw_arc(p, 6.5, 0.0, TAU, 12, OCEAN_LINE.lightened(0.3), 1.0)
		4:
			draw_rect(Rect2(p + Vector2(-4, -2), Vector2(8, 6)), color.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -2), p + Vector2(0, -7), p + Vector2(6, -2)]), ink)


func _draw_label(center: Vector2, text: String, font_size: int, color: Color) -> void:
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos: Vector2 = center - Vector2(width * 0.5, 0.0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _screen_polygon(region: RegionData) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in region.map_polygon:
		result.append(_to_screen(point))
	return result


func _centroid(region: RegionData) -> Vector2:
	var sum := Vector2.ZERO
	for point: Vector2 in region.map_polygon:
		sum += point
	return _to_screen(sum / region.map_polygon.size())
