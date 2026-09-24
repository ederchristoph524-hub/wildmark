class_name TouchButtonPainter
extends RefCounted
## Zeichnet einen Touch-Button: Kreis, Beschriftung, Cooldown-Ring, grau ohne Essenz, Hunger-Punkt, Leuchten bei Killer Moves.

const FILL: Color = Color(0.1, 0.14, 0.12, 0.45)
const FILL_PRESSED: Color = Color(0.86, 0.72, 0.36, 0.45)
const BORDER: Color = Color(0.86, 0.72, 0.36, 0.7)
const DISABLED: Color = Color(0.3, 0.3, 0.3, 0.5)
const COOLDOWN: Color = Color(1.0, 1.0, 1.0, 0.8)
const HUNGER: Color = Color(1.0, 0.55, 0.2)
const GLOW: Color = Color(1.0, 0.8, 0.3)
const TEXT: Color = Color(0.95, 0.93, 0.86)


static func paint(canvas: CanvasItem, font: Font, button: Dictionary, center: Vector2, player: Player, pressed: bool) -> void:
	var radius: float = button["radius"]
	var action: StringName = button["action"]
	var label: String = button["text"]
	var fill: Color = FILL_PRESSED if pressed else FILL
	var border: Color = BORDER
	if player != null:
		var slot: int = _slot_of(action)
		if slot >= 0:
			var instance: GuInstance = GameState.slot_instance(slot)
			if instance == null:
				label = "–"
				border = DISABLED
			else:
				label = _short(player.holder.gu_data(instance).display_name)
				if not player.holder.is_ready(slot):
					fill = DISABLED if instance.cooldown_left <= 0.0 else fill
				_paint_cooldown(canvas, center, radius, instance.cooldown_left / maxf(player.holder.cooldown_of(instance), 0.01))
				if player.holder.is_hungry(instance):
					canvas.draw_circle(center + Vector2(radius * 0.7, -radius * 0.7), 7.0, HUNGER)
		elif action == &"killer_move":
			var move: KillerMoveData = player.killer.current()
			if move != null:
				label = _short(move.display_name)
				border = GLOW
				canvas.draw_arc(center, radius + 6.0, 0.0, TAU, 32, Color(GLOW, 0.6), 4.0)
			else:
				fill = DISABLED
	canvas.draw_circle(center, radius, fill)
	canvas.draw_arc(center, radius, 0.0, TAU, 32, border, 2.0)
	var font_size: int = 18 if radius >= 40.0 else 15
	# Lange Beschriftungen (z. B. „Kultivieren“) schrumpfen, bis sie in den Kreis passen.
	while font_size > 11 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > radius * 1.85:
		font_size -= 1
	canvas.draw_string(font, center + Vector2(-radius, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, TEXT)


static func _paint_cooldown(canvas: CanvasItem, center: Vector2, radius: float, fraction: float) -> void:
	if fraction <= 0.0:
		return
	canvas.draw_arc(center, radius - 3.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(fraction, 0.0, 1.0), 32, COOLDOWN, 5.0)


static func _slot_of(action: StringName) -> int:
	var name: String = String(action)
	if name.begins_with("gu_slot_"):
		return name.substr(8).to_int() - 1
	return -1


static func _short(text: String) -> String:
	var translated: String = Loc.t(text).replace("-Gu", "")
	return translated.substr(0, 9)
