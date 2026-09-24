class_name Settlement
extends RefCounted
## Baut ein Klan-Dorf aus den Gebietsdaten: Mauerring mit Haupt- und Hintertor, Wachtürme, Ahnenhalle am Dorfplatz,
## Akademie, Übungsplatz, Wohnhäuser entlang der Straßen, Brunnen, Markt, Laternen und Banner – alles ein Mesh.
## Liefert Ankerpunkte (Weltkoordinaten) für Bewohner: hall, gate, back_gate, market, training, well, tower, garden.

const WALL_SEGMENTS: int = 32
const HOUSE_SPACING: float = 12.5
const STREET_HALF: float = 5.5
const VIEW_DISTANCE: float = 420.0


## Baut die Siedlung in die Welt. center = Bodenpunkt der Mitte (Plateau), Tor zeigt nach +Z.
static func build(world: World, data: Dictionary, center: Vector3) -> Dictionary:
	var palette: Dictionary = data["colors"]
	var radius: float = data["radius"]
	var b := MeshBuilder.new()
	var boxes: Array[Array] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = String(data["id"]).hash()
	var anchors: Dictionary = {}
	var base := Transform3D(Basis.IDENTITY, center)
	var hall_size := Vector2(clampf(radius * 0.3, 12.0, 20.0), clampf(radius * 0.2, 9.0, 13.0))
	var hall_at := Vector3(0, 0, -radius * 0.38)
	boxes.append_array(Architecture.hall(b, base.translated_local(hall_at), hall_size.x, hall_size.y, palette))
	anchors["hall"] = center + hall_at + Vector3(2.5, 0, hall_size.y * 0.5 + 4.5)
	var academy_at := Vector3(-radius * 0.42, 0, -radius * 0.3)
	boxes.append_array(Architecture.house(b, base.translated_local(academy_at), 12.0, 8.5, palette))
	anchors["academy"] = center + academy_at + Vector3(0, 0, 6.0)
	var training_at := Vector3(radius * 0.42, 0, -radius * 0.28)
	for i: int in 4:
		Architecture.training_dummy(b, base.translated_local(training_at + Vector3(-4.5 + i * 3.0, 0, -3.0)), palette)
	anchors["training"] = center + training_at + Vector3(0, 0, 3.0)
	_walls_and_gates(b, boxes, world, center, radius, palette, anchors)
	_plaza(b, boxes, base, radius, palette, anchors, center)
	_houses(b, boxes, base, radius, int(data["houses"]), palette, rng, hall_size)
	anchors["garden"] = center + Vector3(-radius * 0.55, 0, radius * 0.25)
	_finish(world, b, boxes)
	return anchors


static func _walls_and_gates(b: MeshBuilder, boxes: Array[Array], world: World, center: Vector3, radius: float, palette: Dictionary, anchors: Dictionary) -> void:
	var ring: float = radius * 0.94
	var step: float = TAU / WALL_SEGMENTS
	# Segmente sind so versetzt, dass vorn (+Z) und hinten (−Z) je genau eines für das Tor ausfällt.
	for i: int in WALL_SEGMENTS:
		var a0: float = (i - 0.5) * step
		var mid: float = i * step
		if absf(angle_difference(mid, PI * 0.5)) < step * 0.25 or absf(angle_difference(mid, PI * 1.5)) < step * 0.25:
			continue
		var p0: Vector3 = world.ground_point(center.x + cos(a0) * ring, center.z + sin(a0) * ring)
		var p1: Vector3 = world.ground_point(center.x + cos(a0 + step) * ring, center.z + sin(a0 + step) * ring)
		boxes.append_array(Architecture.wall(b, p0, p1, palette))
	var gate_width: float = 2.0 * ring * sin(step * 0.5) - 2.6
	var front := Transform3D(Basis.IDENTITY, world.ground_point(center.x, center.z + ring))
	boxes.append_array(Architecture.gate(b, front, gate_width, palette))
	var back := Transform3D(Basis.IDENTITY, world.ground_point(center.x, center.z - ring))
	boxes.append_array(Architecture.gate(b, back, gate_width, palette))
	anchors["gate"] = front.origin + Vector3(4.5, 0, -3.0)
	anchors["gate_outside"] = front.origin + Vector3(-6.0, 0, 7.0)
	anchors["back_gate"] = back.origin + Vector3(3.5, 0, 3.0)
	for angle: float in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
		var at: Vector3 = world.ground_point(center.x + cos(angle) * (ring - 3.0), center.z + sin(angle) * (ring - 3.0))
		boxes.append_array(Architecture.tower(b, Transform3D(Basis(Vector3.UP, -angle), at), palette))
	anchors["tower"] = world.ground_point(center.x + cos(PI * 0.25) * (ring - 7.0), center.z + sin(PI * 0.25) * (ring - 7.0))
	for side: float in [-1.0, 1.0]:
		Architecture.banner_pole(b, front.translated_local(Vector3(side * (gate_width * 0.5 + 2.2), 0, -1.8)), palette)


## Dorfplatz: Brunnen, Marktstände, Laternen entlang der Hauptstraße, Banner vor der Halle.
static func _plaza(b: MeshBuilder, boxes: Array[Array], base: Transform3D, radius: float, palette: Dictionary, anchors: Dictionary, center: Vector3) -> void:
	var well_at := Vector3(-8.0, 0, radius * 0.02)
	boxes.append_array(Architecture.well(b, base.translated_local(well_at), palette))
	anchors["well"] = center + well_at + Vector3(2.5, 0, 1.5)
	var goods: Array[Color] = [Color(0.8, 0.3, 0.3), Color(0.9, 0.75, 0.3), Color(0.4, 0.7, 0.35)]
	for i: int in 3:
		var at := Vector3(10.0, 0, radius * 0.02 + (i - 1) * 4.2)
		boxes.append_array(Architecture.stall(b, base * Transform3D(Basis(Vector3.UP, -PI * 0.5), at), palette, goods[i]))
	anchors["market"] = center + Vector3(7.5, 0, radius * 0.02)
	var street_end: float = radius * 0.85
	var z: float = radius * 0.15
	while z < street_end:
		for side: float in [-1.0, 1.0]:
			Architecture.lantern_post(b, base * Transform3D(Basis(Vector3.UP, PI * 0.5 * side), Vector3(side * (STREET_HALF - 1.0), 0, z)), palette)
		z += 11.0
	for side: float in [-1.0, 1.0]:
		Architecture.banner_pole(b, base.translated_local(Vector3(side * 6.0, 0, -radius * 0.38 + 12.0)), palette)


## Wohnhäuser auf Rasterplätzen innerhalb der Mauer, frei von Straße, Platz, Halle, Akademie und Übungsplatz.
static func _houses(b: MeshBuilder, boxes: Array[Array], base: Transform3D, radius: float, count: int, palette: Dictionary, rng: RandomNumberGenerator, hall_size: Vector2) -> void:
	var slots: Array[Vector2] = []
	var steps: int = ceili(radius / HOUSE_SPACING)
	for gz: int in range(-steps, steps + 1):
		for gx: int in range(-steps, steps + 1):
			var slot := Vector2(gx * HOUSE_SPACING + (HOUSE_SPACING * 0.5 if gz % 2 == 0 else 0.0), gz * HOUSE_SPACING)
			if _slot_free(slot, radius, hall_size):
				slots.append(slot)
	slots.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.length() < c.length())
	for i: int in mini(count, slots.size()):
		var slot: Vector2 = slots[i]
		var width: float = rng.randf_range(7.5, 9.5)
		var depth: float = rng.randf_range(6.0, 7.5)
		var facing: float = 0.0
		if absf(slot.x) < radius * 0.45 and slot.y > -radius * 0.2:
			facing = -PI * 0.5 if slot.x > 0.0 else PI * 0.5
		var t := base * Transform3D(Basis(Vector3.UP, facing), Vector3(slot.x, 0, slot.y))
		boxes.append_array(Architecture.house(b, t, width, depth, palette))


static func _slot_free(slot: Vector2, radius: float, hall_size: Vector2) -> bool:
	if slot.length() > radius * 0.8 or absf(slot.x) < STREET_HALF + 4.5:
		return false
	var blocked: Array[Rect2] = [
		Rect2(-hall_size.x * 0.5 - 6.0, -radius * 0.38 - hall_size.y * 0.5 - 6.0, hall_size.x + 12.0, hall_size.y + 16.0),
		Rect2(-radius * 0.42 - 11.0, -radius * 0.3 - 10.0, 22.0, 20.0),
		Rect2(radius * 0.42 - 10.0, -radius * 0.28 - 8.0, 20.0, 16.0),
		Rect2(-15.0, -radius * 0.2, 30.0, radius * 0.35),
		Rect2(-radius * 0.55 - 7.0, radius * 0.25 - 7.0, 14.0, 14.0),
	]
	for rect: Rect2 in blocked:
		if rect.has_point(slot):
			return false
	return true


static func _finish(world: World, b: MeshBuilder, boxes: Array[Array]) -> void:
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = WorldMaterials.vertex_colored()
	node.visibility_range_end = VIEW_DISTANCE
	world.add_child(node)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	world.add_child(body)
	for entry: Array in boxes:
		var t: Transform3D = entry[0]
		var box_size: Vector3 = entry[1]
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = box_size
		shape.shape = box
		shape.transform = Transform3D(t.basis, t.origin + Vector3.UP * box_size.y * 0.5)
		body.add_child(shape)
