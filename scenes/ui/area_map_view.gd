class_name AreaMapView
extends Control
## Große Karte des aktuellen Gebiets: Gelände, Orte mit Namen, Dorfbewohner, Gu-Meister und dein Standort.

const LABEL: Color = Color(0.95, 0.92, 0.84)
## Rätselorte nur als Punkt (sieben gleiche Namen überdecken sonst die Karte).
const NAMED_KINDS: Array[StringName] = [MapData.KIND_VILLAGE, MapData.KIND_PLACE]

var world: World = null
var player: Player = null


func _ready() -> void:
	custom_minimum_size = Vector2(360, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _map_rect() -> Rect2:
	var side: float = minf(size.x, size.y)
	return Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))


func _draw() -> void:
	if world == null or not is_instance_valid(world):
		return
	var rect: Rect2 = _map_rect()
	draw_texture_rect(MapData.texture(world), rect, false)
	for marker: Dictionary in MapData.markers(world, false):
		var point: Vector2 = rect.position + (marker["uv"] as Vector2) * rect.size
		var color: Color = MapData.KIND_COLORS.get(marker["kind"], Color.WHITE)
		var named: bool = marker["kind"] in NAMED_KINDS
		draw_circle(point, 6.0 if named else 3.5, Color.BLACK)
		draw_circle(point, 4.5 if named else 2.5, color)
		if named and String(marker["label"]) != "":
			_draw_label(point + Vector2(0, -10), marker["label"], 14, color.lightened(0.3))
	if player != null and is_instance_valid(player):
		var at: Vector2 = rect.position + MapData.to_uv(world, player.global_position) * rect.size
		draw_circle(at, 9.0, Color(1, 1, 1, 0.3))
		draw_circle(at, 5.5, Color.BLACK)
		draw_circle(at, 4.0, Color.WHITE)
		_draw_label(at + Vector2(0, 22), tr("Du"), 14, Color.WHITE)
	draw_rect(rect, Color(0.86, 0.72, 0.36), false, 2.0)


func _draw_label(center: Vector2, text: String, font_size: int, color: Color) -> void:
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos: Vector2 = center - Vector2(width * 0.5, 0.0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
