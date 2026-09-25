class_name ProceduralCards
extends RefCounted
## Gezeichnete Alpha-Karten für ProceduralTextures: ein Laubbüschel aus vielen Blättern und ein Grasbüschel aus
## Halmen. Farbe im Bild ist Helligkeit (die Tönung kommt aus den Vertex-Farben), Alpha schneidet die Form aus.

const LEAF_COUNT: int = 90
const BLADE_COUNT: int = 16


## Laubbüschel: gedrehte Blattellipsen mit Mittelrippe, außen dünner besetzt (weicher Rand).
static func leaves(size: int) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 0.5, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in LEAF_COUNT:
		# Um die Mitte gehäuft, damit die Karte einen vollen Kern und einen lockeren Rand hat.
		var angle: float = rng.randf() * TAU
		var spread: float = pow(rng.randf(), 0.6) * size * 0.42
		var center := Vector2(size * 0.5 + cos(angle) * spread, size * 0.5 + sin(angle) * spread)
		var length: float = size * rng.randf_range(0.09, 0.15)
		var width: float = length * rng.randf_range(0.42, 0.6)
		var tilt: float = rng.randf() * TAU
		var tone: float = rng.randf_range(0.35, 0.8)
		_leaf(image, center, length, width, tilt, tone)
	return image


static func _leaf(image: Image, center: Vector2, length: float, width: float, tilt: float, tone: float) -> void:
	var reach: int = ceili(length)
	var along := Vector2(cos(tilt), sin(tilt))
	var across := Vector2(-along.y, along.x)
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var x: int = int(center.x) + dx
			var y: int = int(center.y) + dy
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var offset := Vector2(dx, dy)
			var u: float = offset.dot(along) / length
			var v: float = offset.dot(across) / width
			# Blattform: Ellipse, zur Spitze hin schmaler.
			var edge: float = u * u + v * v / maxf(0.2, 1.0 - 0.5 * maxf(u, 0.0))
			if edge > 1.0:
				continue
			var rib: float = 1.0 - smoothstep(0.0, 0.08, absf(v))
			var shade: float = tone * (0.75 + 0.25 * (1.0 - absf(v))) * (1.0 - rib * 0.25) + (0.5 - u) * 0.06
			image.set_pixel(x, y, Color(shade, shade, shade, 1.0))


## Grasbüschel: Halme vom unteren Rand nach oben, gebogen, zur Spitze dünner.
static func tuft(size: int) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 0.5, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i: int in BLADE_COUNT:
		var base := Vector2(size * rng.randf_range(0.3, 0.7), size - 1.0)
		var height: float = size * rng.randf_range(0.55, 0.95)
		var bend: float = rng.randf_range(-0.55, 0.55)
		var thickness: float = size * rng.randf_range(0.02, 0.035)
		var tone: float = rng.randf_range(0.4, 0.85)
		_blade(image, base, height, bend, thickness, tone)
	return image


static func _blade(image: Image, base: Vector2, height: float, bend: float, thickness: float, tone: float) -> void:
	var steps: int = int(height)
	for s: int in steps:
		var f: float = float(s) / steps
		var x: float = base.x + bend * height * f * f
		var y: float = base.y - f * height
		var half: float = thickness * (1.0 - f * 0.85)
		var shade: float = tone * (0.7 + 0.3 * f)
		for dx: int in range(floori(-half), ceili(half) + 1):
			var px: int = int(x) + dx
			var py: int = int(y)
			if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
				continue
			var side: float = 1.0 - absf(dx) / maxf(half, 0.5) * 0.35
			image.set_pixel(px, py, Color(shade * side, shade * side, shade * side, 1.0))
