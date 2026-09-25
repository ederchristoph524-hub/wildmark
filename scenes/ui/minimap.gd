class_name Minimap
extends Control
## Minikarte oben links: Gelände um den Spieler (Norden oben), Orte, Dorfbewohner, Bestien und Blickrichtung,
## unten eine Leiste mit Gebiet und Region.
## Antippen oder Klicken öffnet die große Karte.

signal opened

const MAP_SIZE: float = 150.0
## Sichtbarer Umkreis in Metern.
const VIEW_RADIUS: float = 55.0
const BORDER: Color = Color(0.86, 0.72, 0.36, 0.9)
const BACKGROUND: Color = Color(0.05, 0.08, 0.07, 0.85)
const PLAYER_COLOR: Color = Color(1.0, 1.0, 1.0)
const CAPTION_HEIGHT: float = 18.0
const CAPTION_SIZE: int = 12
const CAPTION_BACKGROUND: Color = Color(0.0, 0.0, 0.0, 0.6)

var player: Player = null
var _redraw_time: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		opened.emit()


func _process(delta: float) -> void:
	_redraw_time -= delta
	if _redraw_time <= 0.0:
		_redraw_time = 0.1
		queue_redraw()


func _draw() -> void:
	var world: World = _world()
	if world == null or player == null or not is_instance_valid(player):
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACKGROUND)
	var tex: ImageTexture = MapData.texture(world)
	var map_size: float = world.terrain.map_size()
	var center_uv: Vector2 = MapData.to_uv(world, player.global_position)
	var span_uv: float = VIEW_RADIUS * 2.0 / map_size
	var tex_size: Vector2 = tex.get_size()
	var src := Rect2((center_uv - Vector2.ONE * span_uv * 0.5) * tex_size, Vector2.ONE * span_uv * tex_size)
	draw_texture_rect_region(tex, rect, src)
	for marker: Dictionary in MapData.markers(world, true):
		var point: Vector2 = ((marker["uv"] as Vector2) - center_uv) / span_uv * size + size * 0.5
		if rect.has_point(point):
			_draw_marker(point, marker["kind"])
	_draw_player(size * 0.5)
	draw_string(get_theme_default_font(), Vector2(size.x - 16.0, 16.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, BORDER)
	_draw_caption(world)
	draw_rect(rect, BORDER, false, 2.0)


## Wo du bist: Gebiet und Region als Leiste am unteren Rand.
func _draw_caption(world: World) -> void:
	var region: RegionData = DataRegistry.region(world.area.region)
	var text: String = tr(world.area.display_name) + ("" if region == null else " · " + tr(region.display_name))
	var font: Font = get_theme_default_font()
	var font_size: int = CAPTION_SIZE
	while font_size > 8 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 8.0:
		font_size -= 1
	draw_rect(Rect2(0.0, size.y - CAPTION_HEIGHT, size.x, CAPTION_HEIGHT), CAPTION_BACKGROUND)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, size.y - 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BORDER)


func _draw_marker(point: Vector2, kind: StringName) -> void:
	var color: Color = MapData.KIND_COLORS.get(kind, Color.WHITE)
	match kind:
		MapData.KIND_ENEMY:
			draw_circle(point, 2.5, color)
		MapData.KIND_PERSON:
			draw_circle(point, 2.0, color)
		MapData.KIND_QUEST:
			draw_circle(point, 4.0, Color.BLACK)
			draw_circle(point, 3.0, color)
		_:
			draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), Color.BLACK)
			draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), color)


## Pfeil in Laufrichtung und heller Blickkegel der Kamera.
func _draw_player(point: Vector2) -> void:
	var view: Vector3 = player.camera_rig.flat_forward()
	var view_dir := Vector2(view.x, view.z).normalized()
	var left: Vector2 = view_dir.rotated(-0.5) * 34.0
	var right: Vector2 = view_dir.rotated(0.5) * 34.0
	draw_colored_polygon(PackedVector2Array([point, point + left, point + right]), Color(1.0, 1.0, 0.9, 0.18))
	var facing: Vector3 = player.model.global_transform.basis.z * -1.0
	var dir := Vector2(facing.x, facing.z).normalized()
	var tip: Vector2 = point + dir * 7.0
	var back_left: Vector2 = point + dir.rotated(2.5) * 5.0
	var back_right: Vector2 = point + dir.rotated(-2.5) * 5.0
	draw_colored_polygon(PackedVector2Array([tip, back_left, back_right]), PLAYER_COLOR)
	draw_polyline(PackedVector2Array([tip, back_left, back_right, tip]), Color.BLACK, 1.0)


func _world() -> World:
	return get_tree().get_first_node_in_group(World.GROUP_WORLD) as World
