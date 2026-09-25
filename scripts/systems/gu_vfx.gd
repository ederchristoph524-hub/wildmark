class_name GuVfx
extends RefCounted
## Partikel-Handschrift der Pfade: Feuer stiebt Funken, Eis zersplittert, Gift blubbert, Holz lässt Blätter fallen,
## Seele steigt als Irrlicht auf, Raum stürzt nach innen … Einmalige Ausbrüche (Wirken, Treffer, Aufschlag),
## Schweife an Geschossen und Schwaden in Zonen. Je Effekt ein CPUParticles3D (ein Draw Call); Meshes und
## Materialien sind geteilt, höchstens MAX_ACTIVE Effekte zugleich, damit das Handy flüssig bleibt.

const MAX_ACTIVE: int = 30
## Treffer-Funken je Ziel höchstens so oft (Zonen und Schwärme treffen in schnellen Takten).
const HIT_GAP_MSEC: int = 180
## Helligkeit leuchtender Teilchen (addiert); darunter bleiben Farben auch übereinander erkennbar.
const ADDITIVE_DIM: float = 0.62
const SHAPE_DOT: StringName = &"dot"
const SHAPE_LEAF: StringName = &"leaf"
const SHAPE_STREAK: StringName = &"streak"
const SHAPE_SHARD: StringName = &"shard"
## Stil je Pfad. shape; n = Teilchen beim Ausbruch; life; speed; grav (y, negativ fällt); size; add = leuchtend;
## col = Farben; spread (Grad um die Hochachse); flat (0–1, drückt die Streuung in die Ebene); damp; swirl
## (Wirbel); pull (negativ zieht nach innen); ring (Ausstoß aus einem Kreis dieses Radius); bolts (Blitzäste);
## rings (Schallringe).
const STYLES: Dictionary[StringName, Dictionary] = {
	&"feuer": {"shape": &"dot", "n": 22, "life": 0.8, "speed": 3.0, "grav": 3.2, "size": 0.18, "add": true, "spread": 55.0,
		"col": [Color(1.0, 0.92, 0.45), Color(1.0, 0.5, 0.12), Color(0.85, 0.18, 0.05)]},
	&"eis": {"shape": &"shard", "n": 14, "life": 0.9, "speed": 5.0, "grav": -9.0, "size": 0.2, "spread": 70.0,
		"col": [Color(0.95, 0.98, 1.0), Color(0.6, 0.88, 1.0), Color(0.4, 0.7, 0.95)]},
	&"blitz": {"shape": &"streak", "n": 16, "life": 0.22, "speed": 10.0, "grav": 0.0, "size": 0.45, "add": true, "spread": 180.0, "bolts": 3,
		"col": [Color(1.0, 1.0, 1.0), Color(0.65, 0.8, 1.0), Color(0.75, 0.55, 1.0)]},
	&"licht": {"shape": &"dot", "n": 14, "life": 0.7, "speed": 2.4, "grav": 0.6, "size": 0.12, "add": true, "spread": 180.0, "damp": 1.5,
		"col": [Color(1.0, 1.0, 0.95), Color(1.0, 0.92, 0.6), Color(0.75, 0.95, 1.0)]},
	&"gift": {"shape": &"dot", "n": 12, "life": 1.2, "speed": 1.0, "grav": 1.2, "size": 0.26, "spread": 70.0,
		"col": [Color(0.55, 0.95, 0.2), Color(0.3, 0.55, 0.12), Color(0.75, 0.9, 0.25)]},
	&"wasser": {"shape": &"dot", "n": 20, "life": 0.8, "speed": 4.5, "grav": -9.8, "size": 0.14, "spread": 55.0,
		"col": [Color(0.85, 0.95, 1.0), Color(0.35, 0.65, 0.95), Color(0.5, 0.8, 1.0)]},
	&"blut": {"shape": &"dot", "n": 18, "life": 0.7, "speed": 3.5, "grav": -9.8, "size": 0.13, "spread": 70.0,
		"col": [Color(0.8, 0.05, 0.08), Color(0.45, 0.02, 0.05), Color(1.0, 0.25, 0.25)]},
	&"metall": {"shape": &"streak", "n": 18, "life": 0.35, "speed": 8.0, "grav": -12.0, "size": 0.22, "add": true, "spread": 75.0, "damp": 2.0,
		"col": [Color(1.0, 0.97, 0.75), Color(1.0, 0.7, 0.3), Color(0.9, 0.9, 1.0)]},
	&"holz": {"shape": &"leaf", "n": 12, "life": 1.4, "speed": 2.5, "grav": -1.2, "size": 0.24, "spread": 80.0, "swirl": 1.5, "damp": 1.0,
		"col": [Color(0.35, 0.75, 0.25), Color(0.65, 0.85, 0.3), Color(0.2, 0.5, 0.18)]},
	&"seele": {"shape": &"dot", "n": 10, "life": 1.4, "speed": 0.8, "grav": 0.9, "size": 0.34, "add": true, "spread": 180.0, "swirl": 2.0,
		"col": [Color(0.75, 0.6, 1.0), Color(0.5, 0.95, 1.0), Color(0.95, 0.9, 1.0)]},
	&"raum": {"shape": &"shard", "n": 14, "life": 0.5, "speed": 0.4, "grav": 0.0, "size": 0.16, "add": true, "spread": 180.0, "pull": -9.0, "ring": 1.4,
		"col": [Color(0.7, 0.45, 1.0), Color(0.3, 0.35, 0.95), Color(1.0, 0.95, 1.0)]},
	&"erde": {"shape": &"shard", "n": 12, "life": 0.9, "speed": 5.0, "grav": -12.0, "size": 0.26, "spread": 50.0,
		"col": [Color(0.5, 0.38, 0.25), Color(0.45, 0.43, 0.4), Color(0.32, 0.25, 0.18)]},
	&"wind": {"shape": &"streak", "n": 14, "life": 0.5, "speed": 5.0, "grav": 0.0, "size": 0.5, "add": true, "spread": 90.0, "flat": 0.8, "swirl": 6.0,
		"col": [Color(0.95, 1.0, 0.97, 0.7), Color(0.75, 1.0, 0.85, 0.6)]},
	&"stern": {"shape": &"dot", "n": 24, "life": 0.9, "speed": 3.5, "grav": 0.0, "size": 0.1, "add": true, "spread": 180.0, "damp": 3.0,
		"col": [Color(1.0, 1.0, 1.0), Color(1.0, 0.85, 0.4), Color(0.6, 0.9, 1.0)]},
	&"schwert": {"shape": &"streak", "n": 12, "life": 0.25, "speed": 9.0, "grav": 0.0, "size": 0.45, "add": true, "spread": 180.0, "flat": 0.6, "damp": 6.0,
		"col": [Color(1.0, 1.0, 1.0), Color(0.7, 0.8, 0.95)]},
	&"verbergen": {"shape": &"dot", "n": 10, "life": 1.2, "speed": 1.0, "grav": 0.5, "size": 0.55, "spread": 180.0, "damp": 1.0,
		"col": [Color(0.25, 0.24, 0.3, 0.7), Color(0.4, 0.35, 0.5, 0.6)]},
	&"knochen": {"shape": &"shard", "n": 12, "life": 0.8, "speed": 4.5, "grav": -10.0, "size": 0.17, "spread": 70.0,
		"col": [Color(0.95, 0.93, 0.85), Color(0.85, 0.8, 0.68)]},
	&"diebstahl": {"shape": &"dot", "n": 14, "life": 0.7, "speed": 0.5, "grav": 0.0, "size": 0.14, "add": true, "spread": 180.0, "pull": -7.0, "ring": 1.2,
		"col": [Color(1.0, 0.85, 0.3), Color(1.0, 0.95, 0.6)]},
	&"qi": {"shape": &"dot", "n": 16, "life": 0.6, "speed": 3.5, "grav": 0.0, "size": 0.22, "add": true, "spread": 90.0, "flat": 0.7, "damp": 3.0,
		"col": [Color(0.7, 0.85, 1.0), Color(1.0, 1.0, 1.0)]},
	&"formation": {"shape": &"dot", "n": 16, "life": 0.9, "speed": 0.4, "grav": 0.6, "size": 0.14, "add": true, "spread": 20.0, "ring": 1.0,
		"col": [Color(0.4, 1.0, 0.95), Color(1.0, 1.0, 1.0), Color(1.0, 0.85, 0.4)]},
	&"zeit": {"shape": &"dot", "n": 16, "life": 1.1, "speed": 0.3, "grav": 0.0, "size": 0.12, "add": true, "spread": 20.0, "swirl": 5.0, "ring": 0.9,
		"col": [Color(0.95, 0.8, 0.45), Color(1.0, 0.95, 0.8), Color(0.8, 0.65, 0.35)]},
	&"weisheit": {"shape": &"dot", "n": 12, "life": 1.0, "speed": 1.0, "grav": 1.5, "size": 0.12, "add": true, "spread": 40.0,
		"col": [Color(0.7, 0.85, 1.0), Color(1.0, 1.0, 1.0)]},
	&"glueck": {"shape": &"dot", "n": 18, "life": 1.0, "speed": 2.0, "grav": 1.2, "size": 0.13, "add": true, "spread": 60.0,
		"col": [Color(1.0, 0.85, 0.3), Color(1.0, 0.5, 0.7), Color(0.4, 0.9, 1.0), Color(0.5, 1.0, 0.5)]},
	&"verwandlung": {"shape": &"dot", "n": 14, "life": 0.7, "speed": 2.5, "grav": -2.0, "size": 0.2, "spread": 90.0,
		"col": [Color(0.7, 0.45, 0.25), Color(0.85, 0.7, 0.5)]},
	&"ton": {"shape": &"dot", "n": 20, "life": 0.5, "speed": 1.0, "grav": 0.0, "size": 0.14, "add": true, "spread": 10.0, "pull": 9.0, "ring": 0.3, "rings": 2,
		"col": [Color(1.0, 0.95, 0.7), Color(1.0, 1.0, 1.0)]},
	&"kraft": {"shape": &"dot", "n": 16, "life": 0.6, "speed": 3.5, "grav": -1.0, "size": 0.3, "spread": 88.0, "flat": 0.85, "damp": 2.0,
		"col": [Color(0.75, 0.68, 0.55, 0.8), Color(0.6, 0.58, 0.55, 0.7)]},
}
## Ohne Pfad (Bestien, Welt): Stil nach dem ersten passenden Tag.
const TAG_STYLES: Dictionary[StringName, StringName] = {
	&"wucht": &"kraft", &"schnitt": &"schwert", &"durchbohren": &"knochen", &"klang": &"ton",
}

static var _active: int = 0
static var _meshes: Dictionary[StringName, Mesh] = {}
static var _materials: Dictionary[String, StandardMaterial3D] = {}
static var _palettes: Dictionary[int, Gradient] = {}
static var _fade: Gradient = null
static var _shrink: Curve = null
static var _dot_texture: GradientTexture2D = null


## Stil zu Pfad und Tags; leer, wenn keiner passt.
static func style_of(path: StringName, tags: Array[StringName] = []) -> StringName:
	if STYLES.has(path):
		return path
	for tag: StringName in tags:
		if STYLES.has(tag):
			return tag
		if TAG_STYLES.has(tag):
			return TAG_STYLES[tag]
	return &""


## Einmaliger Ausbruch am Ort (Aufschlag, Treffer, Wirken).
static func burst(tree: SceneTree, at: Vector3, style: StringName, scale: float = 1.0, amount_mult: float = 1.0) -> void:
	if style == &"" or _active >= MAX_ACTIVE or tree == null:
		return
	var look: Dictionary = STYLES[style]
	var particles: CPUParticles3D = _emitter(look, scale)
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = maxi(3, roundi(int(look["n"]) * amount_mult))
	Combat.fx_parent(tree).add_child(particles)
	particles.global_position = at
	particles.emitting = true
	_track(tree, particles, float(look["life"]) * 1.3 + 0.1)
	if int(look.get("bolts", 0)) > 0:
		_bolts(tree, at, int(look["bolts"]), scale, look["col"][1])
	for i: int in int(look.get("rings", 0)):
		var ring_color: Color = look["col"][0]
		tree.create_timer(0.08 * i).timeout.connect(func() -> void: Fx.ring(tree, at, 2.2 * scale, Color(ring_color, 0.6), 0.35))


## Treffer: kleiner Ausbruch am Ziel, je Ziel gedrosselt.
static func hit(target: Combatant, info: HitInfo) -> void:
	if info.is_dot:
		return
	var style: StringName = style_of(info.path, info.tags)
	var now: int = Time.get_ticks_msec()
	if style == &"" or now < target.vfx_ready_msec:
		return
	target.vfx_ready_msec = now + HIT_GAP_MSEC
	burst(target.get_tree(), target.aim_point(), style, 0.75, 0.55)


## Schweif an einem Geschoss (fließt weiter, bis release ihn vom Geschoss löst).
static func trail(parent: Node3D, style: StringName, scale: float) -> CPUParticles3D:
	if style == &"" or _active >= MAX_ACTIVE:
		return null
	var look: Dictionary = STYLES[style]
	var particles: CPUParticles3D = _emitter(look, scale * 0.6)
	particles.amount = clampi(roundi(int(look["n"]) * 0.5), 6, 12)
	particles.lifetime = minf(float(look["life"]), 0.6)
	particles.initial_velocity_min = 0.1
	particles.initial_velocity_max = 0.6
	particles.gravity = Vector3(0.0, float(look["grav"]) * 0.3, 0.0)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.15 * scale
	parent.add_child(particles)
	_active += 1
	particles.tree_exited.connect(func() -> void: _active -= 1, CONNECT_ONE_SHOT)
	return particles


## Löst einen Schweif vom Geschoss: die Teilchen verglimmen am Ort, statt mit dem Geschoss zu verschwinden.
static func release(particles: CPUParticles3D) -> void:
	if particles == null or not is_instance_valid(particles) or not particles.is_inside_tree():
		return
	var tree: SceneTree = particles.get_tree()
	var at: Transform3D = particles.global_transform
	particles.reparent(Combat.fx_parent(tree))
	particles.global_transform = at
	particles.emitting = false
	# An die Methode des Knotens gebunden (nicht als Lambda): wird der Knoten vorher frei, löst Godot die Verbindung.
	tree.create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)


## Schwaden über einer Zone (Glut über Feuerflächen, Blasen über Gift, Blätter über Heilkreisen …).
static func zone(parent: Node3D, style: StringName, radius: float) -> void:
	if style == &"" or _active >= MAX_ACTIVE:
		return
	var look: Dictionary = STYLES[style]
	var particles: CPUParticles3D = _emitter(look, 0.9)
	particles.amount = clampi(roundi(radius * radius * 2.0), 8, 36)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_axis = Vector3.UP
	particles.emission_ring_radius = radius
	particles.emission_ring_inner_radius = 0.0
	particles.emission_ring_height = 0.1
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.8
	particles.direction = Vector3.UP
	particles.spread = 25.0
	particles.gravity = Vector3(0.0, maxf(float(look["grav"]) * 0.2, 0.4), 0.0)
	particles.radial_accel_min = 0.0
	particles.radial_accel_max = 0.0
	particles.position.y = 0.2
	parent.add_child(particles)
	_active += 1
	particles.tree_exited.connect(func() -> void: _active -= 1, CONNECT_ONE_SHOT)


static func active_count() -> int:
	return _active


static func _track(tree: SceneTree, particles: CPUParticles3D, seconds: float) -> void:
	_active += 1
	particles.tree_exited.connect(func() -> void: _active -= 1, CONNECT_ONE_SHOT)
	tree.create_timer(seconds).timeout.connect(particles.queue_free)


## Grundeinstellungen eines Emitters nach Stil.
static func _emitter(look: Dictionary, scale: float) -> CPUParticles3D:
	var shape: StringName = look["shape"]
	var particles := CPUParticles3D.new()
	particles.mesh = _mesh(shape)
	particles.material_override = _material(shape, bool(look.get("add", false)))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.local_coords = false
	particles.lifetime = float(look["life"])
	particles.direction = Vector3.UP
	particles.spread = float(look.get("spread", 60.0))
	particles.flatness = float(look.get("flat", 0.0))
	var speed: float = float(look["speed"]) * sqrt(maxf(scale, 0.2))
	particles.initial_velocity_min = speed * 0.45
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0.0, float(look["grav"]), 0.0)
	particles.damping_min = float(look.get("damp", 0.0))
	particles.damping_max = float(look.get("damp", 0.0))
	particles.tangential_accel_min = float(look.get("swirl", 0.0)) * 0.6
	particles.tangential_accel_max = float(look.get("swirl", 0.0))
	particles.radial_accel_min = float(look.get("pull", 0.0))
	particles.radial_accel_max = float(look.get("pull", 0.0))
	var ring: float = float(look.get("ring", 0.0)) * scale
	if ring > 0.0:
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		particles.emission_ring_axis = Vector3.UP
		particles.emission_ring_radius = ring
		particles.emission_ring_inner_radius = ring * 0.85
		particles.emission_ring_height = 0.1
	else:
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 0.2 * scale
	var size: float = float(look["size"]) * clampf(sqrt(scale), 0.6, 1.4)
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size
	particles.scale_amount_curve = _shrink_curve()
	particles.color_initial_ramp = _palette(look["col"], bool(look.get("add", false)))
	particles.color_ramp = _fade_ramp()
	if shape == SHAPE_STREAK:
		particles.particle_flag_align_y = true
	elif shape == SHAPE_SHARD:
		particles.particle_flag_rotate_y = true
		particles.angle_min = 0.0
		particles.angle_max = 360.0
		particles.angular_velocity_min = -360.0
		particles.angular_velocity_max = 360.0
	elif shape == SHAPE_LEAF:
		particles.angle_min = 0.0
		particles.angle_max = 360.0
		particles.angular_velocity_min = -180.0
		particles.angular_velocity_max = 180.0
	return particles


## Blitzäste: kurze Zickzack-Strahlen vom Einschlag nach außen.
static func _bolts(tree: SceneTree, at: Vector3, count: int, scale: float, color: Color) -> void:
	for i: int in count:
		var from: Vector3 = at
		var heading := Vector3(randf_range(-1.0, 1.0), randf_range(-0.3, 0.8), randf_range(-1.0, 1.0)).normalized()
		for segment: int in 3:
			var jag := Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), randf_range(-0.4, 0.4))
			var to: Vector3 = from + (heading + jag).normalized() * 0.55 * scale
			Fx.beam(tree, from, to, color, 0.14, 0.05)
			from = to


## Farben der Teilchen; leuchtende (addierte) etwas dunkler, sonst überstrahlen viele davon zu Weiß.
static func _palette(colors: Array, additive: bool) -> Gradient:
	var key: int = colors.hash() + (1 if additive else 0)
	if _palettes.has(key):
		return _palettes[key]
	var gradient := Gradient.new()
	_palettes[key] = gradient
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var values := PackedColorArray()
	for i: int in colors.size():
		offsets.append(float(i) / colors.size())
		var color: Color = colors[i]
		values.append(Color(color.r * ADDITIVE_DIM, color.g * ADDITIVE_DIM, color.b * ADDITIVE_DIM, color.a) if additive else color)
	gradient.offsets = offsets
	gradient.colors = values
	return gradient


static func _fade_ramp() -> Gradient:
	if _fade == null:
		_fade = Gradient.new()
		_fade.offsets = PackedFloat32Array([0.0, 0.12, 0.65, 1.0])
		_fade.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.0)])
	return _fade


static func _shrink_curve() -> Curve:
	if _shrink == null:
		_shrink = Curve.new()
		_shrink.add_point(Vector2(0.0, 1.0))
		_shrink.add_point(Vector2(1.0, 0.35))
	return _shrink


static func _mesh(shape: StringName) -> Mesh:
	if _meshes.has(shape):
		return _meshes[shape]
	var mesh: Mesh = null
	match shape:
		SHAPE_STREAK:
			var box := BoxMesh.new()
			box.size = Vector3(0.08, 1.0, 0.08)
			mesh = box
		SHAPE_SHARD:
			var prism := PrismMesh.new()
			prism.size = Vector3(0.55, 1.0, 0.3)
			mesh = prism
		SHAPE_LEAF:
			var leaf := QuadMesh.new()
			leaf.size = Vector2(1.0, 0.5)
			mesh = leaf
		_:
			var quad := QuadMesh.new()
			quad.size = Vector2.ONE
			mesh = quad
	_meshes[shape] = mesh
	return mesh


static func _material(shape: StringName, additive: bool) -> StandardMaterial3D:
	var key: String = "%s_%s" % [shape, additive]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	if shape == SHAPE_DOT or shape == SHAPE_LEAF:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.albedo_texture = _dot()
	_materials[key] = material
	return material


static func _dot() -> GradientTexture2D:
	if _dot_texture == null:
		_dot_texture = Ambience._soft_dot()
	return _dot_texture
