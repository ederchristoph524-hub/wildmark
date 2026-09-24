class_name SettlementLayouts
extends RefCounted
## Siedlungsarten außer dem Klan-Dorf: Handelsstadt (Shang), Festung (Wu), Sektenberg mit Terrassen; Zeltlager,
## Oasenstadt und Inseldorf baut SettlementOutposts. Alles landet in einem Mesh (Settlement.finish).
## Liefert Ankerpunkte (Weltkoordinaten) für Bewohner und Gu-Meister wie Settlement.build.

const HOUSE_GRID: float = 12.5
const STREET_HALF: float = 6.5
const WALL_PIECE: float = 12.0
const GATE_HALF: float = 5.0


static func build(world: World, data: Dictionary, center: Vector3) -> Dictionary:
	var b := MeshBuilder.new()
	var boxes: Array[Array] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = String(data["id"]).hash()
	var anchors: Dictionary = {}
	match data["type"]:
		&"stadt":
			_city(world, data, center, b, boxes, rng, anchors)
		&"festung":
			_fortress(world, data, center, b, boxes, rng, anchors)
		&"sekte":
			_sect(world, data, center, b, boxes, rng, anchors)
		_:
			SettlementOutposts.build(world, data, center, b, boxes, rng, anchors)
	Settlement.finish(world, b, boxes)
	return anchors


# --- Handelsstadt ---

## Quadratische Stadtmauer mit vier Toren und Ecktürmen, Straßenkreuz, Marktplatz mit Brunnen, Klanhalle,
## Pagode, Arena und Häuserblöcke.
static func _city(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var half: float = float(data["radius"]) * 0.9
	var base := Transform3D(Basis.IDENTITY, center)
	_square_walls(world, b, boxes, center, half, p, 3.0, false)
	for side: float in [-1.0, 1.0]:
		boxes.append_array(ArchitectureExtra.city_tower(b, base.translated_local(Vector3(side * (GATE_HALF + 3.2), 0, half)), 5.0, 8.0, p))
	var hall_at := Vector3(-half * 0.5, 0, -half * 0.5)
	boxes.append_array(Architecture.hall(b, base.translated_local(hall_at), 20.0, 13.0, p))
	var pagoda_at := Vector3(half * 0.5, 0, -half * 0.5)
	boxes.append_array(ArchitectureExtra.pagoda(b, base.translated_local(pagoda_at), 5, 8.0, p))
	var arena_at := Vector3(half * 0.5, 0, half * 0.48)
	boxes.append_array(ArchitectureExtra.arena(b, base.translated_local(arena_at), 11.0, p))
	boxes.append_array(Architecture.well(b, base.translated_local(Vector3(-9.0, 0, -9.0)), p))
	_market_ring(b, boxes, base, 12.0, p)
	var blocked: Array[Rect2] = [_rect(hall_at, 30.0, 28.0), _rect(pagoda_at, 16.0, 16.0), _rect(arena_at, 38.0, 38.0), Rect2(-19.0, -19.0, 38.0, 38.0)]
	_houses_in_grid(b, boxes, base, half - 8.0, blocked, int(data["houses"]), p, rng)
	_lantern_cross(b, base, half, p)
	anchors["hall"] = center + hall_at + Vector3(3.0, 0, 11.0)
	anchors["academy"] = center + hall_at + Vector3(-6.0, 0, 11.0)
	anchors["gate"] = center + Vector3(4.0, 0, half - 6.0)
	anchors["gate_outside"] = center + Vector3(-7.0, 0, half + 7.0)
	anchors["back_gate"] = center + Vector3(4.0, 0, -half + 6.0)
	anchors["market"] = center + Vector3(7.0, 0, 7.0)
	anchors["well"] = center + Vector3(-6.5, 0, -6.5)
	anchors["tower"] = center + pagoda_at + Vector3(0, 0, 8.0)
	anchors["training"] = center + arena_at
	anchors["arena"] = center + arena_at
	anchors["garden"] = center + Vector3(-half * 0.5, 0, half * 0.5)
	anchors["fire"] = center + Vector3(-9.0, 0, 18.0)


# --- Festung ---

## Hohe Mauern mit Ecktürmen, Torhaus, Bergfried auf einer Terrasse, Kasernen, Übungshof, Wachpagode, Markt.
static func _fortress(world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var half: float = float(data["radius"]) * 0.88
	var base := Transform3D(Basis.IDENTITY, center)
	_square_walls(world, b, boxes, center, half, p, 6.0, true)
	for side: float in [-1.0, 1.0]:
		boxes.append_array(ArchitectureExtra.city_tower(b, base.translated_local(Vector3(side * (GATE_HALF + 3.5), 0, half)), 6.0, 10.0, p))
	var keep_at := Vector3(0, 0, -half * 0.5)
	boxes.append_array(ArchitectureExtra.terrace(b, base.translated_local(keep_at), 30.0, 22.0, 1.6, p))
	boxes.append_array(Architecture.hall(b, base.translated_local(keep_at + Vector3(0, 1.6, -1.5)), 20.0, 13.0, p))
	var pagoda_at := Vector3(half * 0.6, 0, -half * 0.6)
	boxes.append_array(ArchitectureExtra.pagoda(b, base.translated_local(pagoda_at), 7, 7.5, p))
	var training_at := Vector3(half * 0.45, 0, half * 0.35)
	for i: int in 6:
		Architecture.training_dummy(b, base.translated_local(training_at + Vector3(-7.5 + i * 3.0, 0, -2.0)), p)
	boxes.append_array(Architecture.well(b, base.translated_local(Vector3(-8.0, 0, 4.0)), p))
	for i: int in 3:
		boxes.append_array(Architecture.stall(b, base * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-half * 0.45 + i * 5.0, 0, half * 0.55)), p, Color(0.8, 0.3 + i * 0.2, 0.3)))
	var blocked: Array[Rect2] = [_rect(keep_at, 38.0, 40.0), _rect(pagoda_at, 16.0, 16.0), _rect(training_at, 26.0, 14.0), _rect(Vector3(-half * 0.4, 0, half * 0.55), 22.0, 10.0)]
	_houses_in_grid(b, boxes, base, half - 9.0, blocked, int(data["houses"]), p, rng)
	_lantern_cross(b, base, half, p)
	anchors["hall"] = center + keep_at + Vector3(3.0, 0, 16.0)
	anchors["academy"] = center + keep_at + Vector3(-9.0, 0, 16.0)
	anchors["gate"] = center + Vector3(4.0, 0, half - 7.0)
	anchors["gate_outside"] = center + Vector3(-8.0, 0, half + 8.0)
	anchors["back_gate"] = center + Vector3(4.0, 0, -half + 7.0)
	anchors["market"] = center + Vector3(-half * 0.4, 0, half * 0.45)
	anchors["well"] = center + Vector3(-5.5, 0, 5.5)
	anchors["tower"] = center + pagoda_at + Vector3(0, 0, 8.0)
	anchors["training"] = center + training_at + Vector3(0, 0, 3.0)
	anchors["arena"] = anchors["training"]
	anchors["garden"] = center + Vector3(-half * 0.5, 0, -half * 0.1)
	anchors["fire"] = center + Vector3(-9.0, 0, 14.0)


# --- Sektenberg ---

## Torbogen, Vorhof mit Hallen und Übungsplatz, zwei Terrassen mit Rampen: Haupthalle, darüber Pagode und Bibliothek.
static func _sect(_world: World, data: Dictionary, center: Vector3, b: MeshBuilder, boxes: Array[Array], _rng: RandomNumberGenerator, anchors: Dictionary) -> void:
	var p: Dictionary = data["colors"]
	var r: float = data["radius"]
	var base := Transform3D(Basis.IDENTITY, center)
	boxes.append_array(ArchitectureExtra.paifang(b, base.translated_local(Vector3(0, 0, r * 0.85)), 8.0, p))
	for side: float in [-1.0, 1.0]:
		for row: int in 2:
			var at := Vector3(side * r * 0.45, 0, r * (0.42 - row * 0.3))
			boxes.append_array(HouseStyles.two_story(b, base * Transform3D(Basis(Vector3.UP, -side * PI * 0.5), at), 11.0, 8.0, p))
	var first := Vector3(0, 0, -r * 0.08)
	boxes.append_array(ArchitectureExtra.terrace(b, base.translated_local(first), 34.0, 24.0, 3.0, p))
	boxes.append_array(Architecture.hall(b, base.translated_local(first + Vector3(0, 3.0, -2.0)), 18.0, 12.0, p))
	var second := Vector3(0, 0, -r * 0.62)
	boxes.append_array(ArchitectureExtra.terrace(b, base.translated_local(second), 26.0, 16.0, 6.0, p))
	boxes.append_array(ArchitectureExtra.pagoda(b, base.translated_local(second + Vector3(-6.0, 6.0, -1.0)), 5, 6.5, p))
	boxes.append_array(Architecture.house(b, base.translated_local(second + Vector3(6.5, 6.0, -1.0)), 9.0, 7.0, p))
	var training_at := Vector3(r * 0.2, 0, r * 0.55)
	for i: int in 5:
		Architecture.training_dummy(b, base.translated_local(training_at + Vector3(-6.0 + i * 3.0, 0, 0)), p)
	boxes.append_array(Architecture.well(b, base.translated_local(Vector3(-r * 0.2, 0, r * 0.6)), p))
	var z: float = r * 0.8
	while z > r * 0.25:
		for side: float in [-1.0, 1.0]:
			Architecture.lantern_post(b, base * Transform3D(Basis(Vector3.UP, PI * 0.5 * side), Vector3(side * 3.5, 0, z)), p)
		z -= 9.0
	for side: float in [-1.0, 1.0]:
		Architecture.banner_pole(b, base.translated_local(Vector3(side * 8.0, 3.0, first.z + 11.0)), p)
	anchors["gate"] = center + Vector3(4.0, 0, r * 0.75)
	anchors["gate_outside"] = center + Vector3(-5.0, 0, r * 0.95)
	anchors["hall"] = center + first + Vector3(3.0, 3.0, 8.0)
	anchors["academy"] = center + second + Vector3(6.5, 6.0, 4.5)
	anchors["tower"] = center + second + Vector3(-6.0, 6.0, 5.5)
	anchors["training"] = center + training_at + Vector3(0, 0, 3.0)
	anchors["arena"] = anchors["training"]
	anchors["market"] = center + Vector3(-r * 0.3, 0, r * 0.3)
	anchors["well"] = center + Vector3(-r * 0.2 + 2.5, 0, r * 0.6 + 1.5)
	anchors["back_gate"] = center + Vector3(r * 0.3, 0, -r * 0.3)
	anchors["garden"] = center + Vector3(-r * 0.35, 0, -r * 0.3)
	anchors["fire"] = center + Vector3(-r * 0.3, 0, r * 0.45)


# --- Bausteine ---

## Quadratischer Mauerring (Seitenlänge 2 × half) mit Tor in der Mitte jeder Seite und Ecktürmen.
static func _square_walls(world: World, b: MeshBuilder, boxes: Array[Array], center: Vector3, half: float, p: Dictionary, height: float, high: bool) -> void:
	var corners: Array[Vector2] = [Vector2(-half, half), Vector2(half, half), Vector2(half, -half), Vector2(-half, -half)]
	for side: int in 4:
		var a: Vector2 = corners[side]
		var c: Vector2 = corners[(side + 1) % 4]
		var middle: Vector2 = (a + c) * 0.5
		var along: Vector2 = (c - a).normalized()
		for run: Array in [[a, middle - along * GATE_HALF], [middle + along * GATE_HALF, c]]:
			var from: Vector2 = run[0]
			var to: Vector2 = run[1]
			var pieces: int = maxi(1, ceili(from.distance_to(to) / WALL_PIECE))
			for i: int in pieces:
				var p0: Vector2 = from.lerp(to, i / float(pieces))
				var p1: Vector2 = from.lerp(to, (i + 1) / float(pieces))
				var g0: Vector3 = world.ground_point(center.x + p0.x, center.z + p0.y)
				var g1: Vector3 = world.ground_point(center.x + p1.x, center.z + p1.y)
				boxes.append_array(ArchitectureExtra.high_wall(b, g0, g1, height, p) if high else Architecture.wall(b, g0, g1, p))
		var gate_t := Transform3D(Basis(Vector3.UP, 0.0 if side % 2 == 0 else PI * 0.5), world.ground_point(center.x + middle.x, center.z + middle.y))
		boxes.append_array(Architecture.gate(b, gate_t, GATE_HALF * 2.0 - 2.6, p))
		var corner: Vector3 = world.ground_point(center.x + a.x, center.z + a.y)
		boxes.append_array(ArchitectureExtra.city_tower(b, Transform3D(Basis.IDENTITY, corner), 6.0 if high else 5.0, height + 4.0, p))


## Marktstände im Kreis um den Platz (Straßen bleiben frei), Stände schauen zur Mitte.
static func _market_ring(b: MeshBuilder, boxes: Array[Array], base: Transform3D, radius: float, p: Dictionary) -> void:
	var goods: Array[Color] = [Color(0.8, 0.3, 0.3), Color(0.9, 0.75, 0.3), Color(0.4, 0.7, 0.35), Color(0.5, 0.5, 0.85)]
	for i: int in 8:
		var angle: float = PI * 0.25 * i + PI * 0.125
		var at := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		boxes.append_array(Architecture.stall(b, base * Transform3D(Basis(Vector3.UP, -angle - PI * 0.5), at), p, goods[i % goods.size()]))


## Häuser auf einem Raster innerhalb der Mauer, frei von Straßenkreuz und gesperrten Flächen; Fronten zur nächsten Straße.
static func _houses_in_grid(b: MeshBuilder, boxes: Array[Array], base: Transform3D, limit: float, blocked: Array[Rect2], count: int, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var slots: Array[Vector2] = []
	var steps: int = ceili(limit / HOUSE_GRID)
	for gz: int in range(-steps, steps + 1):
		for gx: int in range(-steps, steps + 1):
			var slot := Vector2(gx * HOUSE_GRID + HOUSE_GRID * 0.5, gz * HOUSE_GRID + HOUSE_GRID * 0.5)
			if absf(slot.x) > limit or absf(slot.y) > limit or absf(slot.x) < STREET_HALF + 4.5 or absf(slot.y) < STREET_HALF + 4.5:
				continue
			var free: bool = true
			for rect: Rect2 in blocked:
				if rect.has_point(slot):
					free = false
			if free:
				slots.append(slot)
	slots.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.length() < c.length())
	for i: int in mini(count, slots.size()):
		var slot: Vector2 = slots[i]
		var facing: float = (0.0 if slot.y < 0.0 else PI) if absf(slot.y) < absf(slot.x) else (PI * 0.5 if slot.x < 0.0 else -PI * 0.5)
		var t := base * Transform3D(Basis(Vector3.UP, facing), Vector3(slot.x, 0, slot.y))
		boxes.append_array(HouseStyles.build(b, t, rng.randf_range(8.0, 10.0), rng.randf_range(6.5, 8.0), p, rng))


## Laternen entlang beider Hauptstraßen.
static func _lantern_cross(b: MeshBuilder, base: Transform3D, half: float, p: Dictionary) -> void:
	var d: float = 20.0
	while d < half - 6.0:
		for dir: float in [-1.0, 1.0]:
			for side: float in [-1.0, 1.0]:
				Architecture.lantern_post(b, base * Transform3D(Basis(Vector3.UP, PI * 0.5 * side), Vector3(side * (STREET_HALF - 1.0), 0, dir * d)), p)
				Architecture.lantern_post(b, base * Transform3D(Basis(Vector3.UP, PI * (0.5 - 0.5 * side)), Vector3(dir * d, 0, side * (STREET_HALF - 1.0))), p)
		d += 12.0


static func _rect(at: Vector3, width: float, depth: float) -> Rect2:
	return Rect2(at.x - width * 0.5, at.z - depth * 0.5, width, depth)
