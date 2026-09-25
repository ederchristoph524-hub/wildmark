class_name ApertureView
extends Control
## Blick in die eigene Apertur (Seite „Kultivierung"): das Urmeer in der Farbe des Rangs (Grünkupfer, Roteisen,
## Weißsilber, Gelbgold, Purpurkristall) steht so hoch wie die Uressenz, die Aperturwand zeigt ihre vier Stufen
## (die aktuelle füllt sich mit der Verfeinerung), und darüber schweben die Gu in den Farben ihrer Pfade.

const HEIGHT: float = 230.0
const RADIUS_SHARE: float = 0.42
const WALL_WIDTH: float = 10.0
const GU_DOT: float = 6.0
const MAX_DOTS: int = 24

var essence_ratio: float = 0.0
var _time: float = 0.0
var _colors: Array[Color] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var system: GuSystemData = DataRegistry.gu_system()
	for instance: GuInstance in GameState.gu:
		var gu: GuData = DataRegistry.gu(instance.gu_id)
		if gu != null:
			_colors.append(system.path_color(DataRegistry.family(gu.family).path))
	for instance: GuInstance in GameState.support:
		var support: SupportGuData = DataRegistry.support_gu(instance.gu_id)
		if support != null:
			_colors.append(system.path_color(support.path))
	_colors.resize(mini(_colors.size(), MAX_DOTS))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var radius: float = size.y * RADIUS_SHARE
	var sea: Color = DataRegistry.progression().rank_color(GameState.rank)
	# Hintergrund der Apertur: dunkler Raum.
	draw_circle(center, radius, Color(0.03, 0.04, 0.06))
	_draw_sea(center, radius - WALL_WIDTH * 0.5, sea)
	_draw_wall(center, radius, sea)
	_draw_gu(center, radius - WALL_WIDTH, sea)


## Urmeer: Wasserspiegel nach Füllstand, sanfte Wellen, heller Glanz an der Oberfläche.
func _draw_sea(center: Vector2, radius: float, color: Color) -> void:
	var level: float = center.y + radius - 2.0 * radius * clampf(essence_ratio, 0.0, 1.0)
	var points := PackedVector2Array()
	var steps: int = 48
	for i: int in steps + 1:
		var angle: float = PI * float(i) / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var surface := PackedVector2Array()
	for i: int in steps + 1:
		var x: float = center.x - radius + 2.0 * radius * float(i) / steps
		var y: float = level + sin(x * 0.08 + _time * 2.0) * 2.5
		var half: float = sqrt(maxf(0.0, radius * radius - pow(y - center.y, 2.0)))
		if absf(x - center.x) <= half:
			surface.append(Vector2(x, y))
	if surface.size() < 2 or essence_ratio <= 0.01:
		return
	# Fläche unter der Oberfläche: Oberflächenpunkte plus unterer Kreisbogen.
	var fill := PackedVector2Array(surface)
	var right_angle: float = atan2(surface[surface.size() - 1].y - center.y, surface[surface.size() - 1].x - center.x)
	var left_angle: float = atan2(surface[0].y - center.y, surface[0].x - center.x)
	if left_angle < right_angle:
		left_angle += TAU
	for i: int in steps + 1:
		var angle: float = lerpf(right_angle, left_angle, float(i) / steps)
		fill.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(fill, Color(color.darkened(0.25), 0.9))
	draw_polyline(surface, color.lightened(0.45), 2.0, true)


## Aperturwand: vier Bögen für die Stufen; erreichte leuchten, die aktuelle füllt sich mit der Verfeinerung.
func _draw_wall(center: Vector2, radius: float, color: Color) -> void:
	var stages: int = Balance.values.max_stage + 1
	var gap: float = 0.08
	for stage: int in stages:
		var start: float = -PI * 0.5 + TAU * float(stage) / stages + gap
		var span: float = TAU / stages - gap * 2.0
		draw_arc(center, radius, start, start + span, 24, Color(0.25, 0.25, 0.3), WALL_WIDTH, true)
		var filled: float = 1.0 if stage < GameState.stage else (GameState.wall if stage == GameState.stage else 0.0)
		if GameState.stage >= Balance.values.max_stage and stage == GameState.stage:
			filled = 1.0
		if filled > 0.0:
			draw_arc(center, radius, start, start + span * filled, 24, color.lightened(0.2), WALL_WIDTH - 3.0, true)


## Gu als leuchtende Punkte auf einer Bahn über dem Meer.
func _draw_gu(center: Vector2, radius: float, sea: Color) -> void:
	var count: int = _colors.size()
	for i: int in count:
		var angle: float = TAU * float(i) / maxf(1.0, count) + _time * 0.25
		var orbit: float = radius * (0.55 + 0.15 * sin(_time * 0.7 + i))
		var at: Vector2 = center + Vector2(cos(angle) * orbit, sin(angle) * orbit * 0.55 - radius * 0.15)
		draw_circle(at, GU_DOT + 3.0, Color(_colors[i], 0.25))
		draw_circle(at, GU_DOT, _colors[i])
	if count == 0:
		draw_string(get_theme_default_font(), center + Vector2(-60.0, -radius * 0.3), Loc.t("keine Gu"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(sea, 0.8))
