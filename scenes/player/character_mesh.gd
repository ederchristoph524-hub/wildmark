class_name CharacterMesh
extends RefCounted
## Baut Menschen-Figuren als ein Mesh – stehend (Glieder schwingen im Shader) oder im Schneidersitz. Proportionen
## natürlich (etwa 6,5 Kopfhöhen, 1,85 m): Hals, schmale Schultern, Robe mit überkreuztem Kragen und Schärpe, Ärmel
## zum Handgelenk weit, Hände, Gesicht mit Augen, Brauen, Nase und Mund, Haarknoten oder Kopfbedeckung (Anhang in
## CharacterHats). Gleiche Farben teilen sich das Mesh (Cache), damit viele Dorfbewohner billig bleiben.

const HIP: float = 0.92
const SHOULDER: float = 1.45
const LEG_SWING: float = 1.0
const ARM_SWING: float = 0.7
## Im Sitzen liegt die Hüfte hier.
const SIT_HIP: float = 0.24
## Kopf: Mitte und Radien (etwas höher als breit).
const HEAD_Y: float = 1.69
const HEAD_R: float = 0.125
const HEAD_TALL: float = 1.16
const BOOT: Color = Color(0.12, 0.1, 0.08)
const EYE: Color = Color(0.08, 0.06, 0.05)
const LIP: Color = Color(0.6, 0.35, 0.3)

static var _cache: Dictionary = {}


## colors: robe, sleeve, trousers, sash, skin, hair, optional hat (Art der Kopfbedeckung).
static func build(colors: Dictionary, sitting: bool) -> ArrayMesh:
	var key: String = "%s|%s" % [str(colors.values()), sitting]
	if _cache.has(key):
		return _cache[key]
	var b := MeshBuilder.new()
	var drop: float = HIP - SIT_HIP if sitting else 0.0
	_head(b, colors, drop)
	_torso(b, colors, drop)
	if sitting:
		_sitting_legs(b, colors)
		_sitting_arms(b, colors, drop)
	else:
		_legs(b, colors)
		_arms(b, colors)
	var mesh: ArrayMesh = b.build()
	_cache[key] = mesh
	return mesh


## Kopf mit Hals, Gesicht und Haar; Kopfbedeckung obenauf.
static func _head(b: MeshBuilder, c: Dictionary, drop: float) -> void:
	var y: float = HEAD_Y - drop
	var skin: Color = c["skin"]
	b.add(MeshBuilder.cylinder(0.05, 0.06, 0.16, 7), MeshBuilder.at(Vector3(0.0, SHOULDER - drop + 0.07, 0.0)), skin)
	b.add(MeshBuilder.sphere(HEAD_R, 10, 7), MeshBuilder.at(Vector3(0.0, y, 0.0), Vector3(1.0, HEAD_TALL, 1.04)), skin)
	# Kinn und Wangen etwas voller, Ohren.
	b.add(MeshBuilder.sphere(HEAD_R * 0.7, 7, 5), MeshBuilder.at(Vector3(0.0, y - 0.07, -0.02), Vector3(1.05, 0.8, 1.0)), skin)
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.sphere(0.025, 5, 4), MeshBuilder.at(Vector3(side * HEAD_R * 0.98, y - 0.005, 0.0), Vector3(0.5, 1.2, 1.0)), skin.darkened(0.05))
	# Gesicht: Augen mit Weiß, Brauen, Nase, Mund (vorn = −Z).
	var front: float = -HEAD_R * 1.02
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.sphere(0.02, 6, 4), MeshBuilder.at(Vector3(side * 0.045, y + 0.015, front + 0.008), Vector3(1.3, 0.8, 0.6)), Color(0.95, 0.94, 0.92))
		b.add(MeshBuilder.sphere(0.012, 5, 4), MeshBuilder.at(Vector3(side * 0.045, y + 0.015, front - 0.004)), EYE)
		b.add(MeshBuilder.box(Vector3(0.05, 0.008, 0.012)), MeshBuilder.at(Vector3(side * 0.045, y + 0.048, front + 0.004), Vector3.ONE, Vector3(0.0, 0.0, side * 0.15)), (c["hair"] as Color).lightened(0.1))
	b.add(MeshBuilder.sphere(0.014, 5, 4), MeshBuilder.at(Vector3(0.0, y - 0.015, front - 0.008), Vector3(0.9, 1.4, 1.0)), skin.darkened(0.06))
	b.add(MeshBuilder.box(Vector3(0.042, 0.007, 0.01)), MeshBuilder.at(Vector3(0.0, y - 0.058, front + 0.006)), LIP)
	# Haar: Kappe hinten und oben, Haarlinie vorn höher, Knoten mit Nadel.
	b.add(MeshBuilder.sphere(HEAD_R * 1.06, 10, 6), MeshBuilder.at(Vector3(0.0, y + 0.035, 0.02), Vector3(1.02, 0.85, 1.02)), c["hair"])
	b.add(MeshBuilder.sphere(HEAD_R * 0.95, 8, 5), MeshBuilder.at(Vector3(0.0, y - 0.01, 0.05), Vector3(1.0, 1.0, 0.9)), c["hair"])
	if c.get("hat", &"") == &"" or c.get("hat", &"") == &"band" or c.get("hat", &"") == &"feder":
		b.add(MeshBuilder.sphere(0.055, 7, 5), MeshBuilder.at(Vector3(0.0, y + HEAD_R * HEAD_TALL + 0.03, 0.04)), c["hair"])
		b.add(MeshBuilder.cylinder(0.012, 0.012, 0.17, 4), MeshBuilder.at(Vector3(0.0, y + HEAD_R * HEAD_TALL + 0.035, 0.04), Vector3.ONE, Vector3(0.0, 0.0, PI * 0.5)), c["sash"])
	CharacterHats.add(b, c, y)


## Rumpf: Robe mit Kragen und Schärpe; im Stehen fällt sie bis über die Knie, im Sitzen breitet sie sich aus.
static func _torso(b: MeshBuilder, c: Dictionary, drop: float) -> void:
	var y: float = -drop
	var robe: Color = c["robe"]
	b.add(MeshBuilder.cylinder(0.19, 0.17, 0.56, 10), MeshBuilder.at(Vector3(0.0, 1.19 + y, 0.0), Vector3(1.0, 1.0, 0.8)), robe)
	# Schultern und Brust.
	b.add(MeshBuilder.sphere(0.2, 9, 5), MeshBuilder.at(Vector3(0.0, SHOULDER + y - 0.03, 0.0), Vector3(1.25, 0.32, 0.75)), robe)
	b.add(MeshBuilder.sphere(0.16, 8, 5), MeshBuilder.at(Vector3(0.0, 1.3 + y, -0.03), Vector3(1.1, 0.7, 0.55)), robe)
	# Überkreuzter Kragen (heller Saum), Schärpe mit Knoten.
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.box(Vector3(0.045, 0.3, 0.02)), MeshBuilder.at(Vector3(side * 0.05, 1.33 + y, -0.165), Vector3.ONE, Vector3(0.0, 0.0, -side * 0.45)), (c["sash"] as Color).lightened(0.3))
	b.add(MeshBuilder.cylinder(0.185, 0.185, 0.09, 10), MeshBuilder.at(Vector3(0.0, 0.99 + y, 0.0), Vector3(1.0, 1.0, 0.82)), c["sash"])
	b.add(MeshBuilder.sphere(0.035, 5, 4), MeshBuilder.at(Vector3(0.06, 0.99 + y, -0.155)), (c["sash"] as Color).darkened(0.15))
	if drop <= 0.0:
		b.add(MeshBuilder.cylinder(0.19, 0.27, 0.48, 10), MeshBuilder.at(Vector3(0.0, 0.7, 0.0), Vector3(1.0, 1.0, 0.85)), robe)
		# Faltenwurf: dunkle Streifen vorn und seitlich.
		for i: int in 3:
			b.add(MeshBuilder.box(Vector3(0.012, 0.42, 0.02)), MeshBuilder.at(Vector3(-0.09 + i * 0.09, 0.68, -0.235 + absf(i - 1) * 0.02)), robe.darkened(0.2))
	else:
		b.add(MeshBuilder.cylinder(0.22, 0.48, 0.24, 12), MeshBuilder.at(Vector3(0.0, SIT_HIP - 0.02, 0.0)), robe)


static func _legs(b: MeshBuilder, c: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var custom := Vector2(-side * LEG_SWING, HIP)
		var x: float = side * 0.1
		b.add(MeshBuilder.cylinder(0.08, 0.07, 0.5, 7), MeshBuilder.at(Vector3(x, 0.66, 0.0)), c["trousers"], custom)
		b.add(MeshBuilder.cylinder(0.068, 0.06, 0.38, 7), MeshBuilder.at(Vector3(x, 0.25, 0.0)), c["trousers"], custom)
		b.add(MeshBuilder.box(Vector3(0.11, 0.08, 0.26)), MeshBuilder.at(Vector3(x, 0.04, -0.05)), BOOT, custom)
		b.add(MeshBuilder.cylinder(0.075, 0.075, 0.1, 7), MeshBuilder.at(Vector3(x, 0.1, 0.0)), BOOT.lightened(0.05), custom)


static func _arms(b: MeshBuilder, c: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var custom := Vector2(side * ARM_SWING, SHOULDER)
		var shoulder := Vector3(side * 0.24, SHOULDER - 0.02, 0.0)
		var elbow := Vector3(side * 0.29, 1.15, 0.03)
		var wrist := Vector3(side * 0.31, 0.9, -0.03)
		b.add(MeshBuilder.cylinder(0.065, 0.075, shoulder.distance_to(elbow) + 0.05, 7), MeshBuilder.between(shoulder, elbow), c["sleeve"], custom)
		b.add(MeshBuilder.cylinder(0.075, 0.11, elbow.distance_to(wrist), 7), MeshBuilder.between(elbow, wrist), c["sleeve"], custom)
		_hand(b, wrist + Vector3(0.0, -0.06, -0.01), c["skin"], custom)


## Hand: Handfläche mit Daumen, zur Seite hin leicht gewölbt.
static func _hand(b: MeshBuilder, at: Vector3, skin: Color, custom: Vector2 = Vector2.ZERO) -> void:
	b.add(MeshBuilder.sphere(0.045, 6, 4), MeshBuilder.at(at, Vector3(0.7, 1.15, 1.0)), skin, custom)
	b.add(MeshBuilder.sphere(0.018, 5, 4), MeshBuilder.at(at + Vector3(0.0, 0.01, -0.04)), skin, custom)


## Schneidersitz: Knie seitlich, Unterschenkel gekreuzt.
static func _sitting_legs(b: MeshBuilder, c: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * 0.1, SIT_HIP, 0.0)
		var knee := Vector3(side * 0.4, 0.14, -0.2)
		var ankle := Vector3(-side * 0.1, 0.1, -0.34)
		b.add(MeshBuilder.cylinder(0.08, 0.07, hip.distance_to(knee) + 0.08, 7), MeshBuilder.between(hip, knee), c["trousers"])
		b.add(MeshBuilder.cylinder(0.07, 0.06, knee.distance_to(ankle), 7), MeshBuilder.between(knee, ankle), c["trousers"])
		b.add(MeshBuilder.box(Vector3(0.11, 0.08, 0.24)), Transform3D(Basis(Vector3.UP, side * 1.2), ankle + Vector3(-side * 0.06, -0.03, 0.0)), BOOT)


## Hände ruhen auf den Knien, Handflächen nach oben.
static func _sitting_arms(b: MeshBuilder, c: Dictionary, drop: float) -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * 0.24, SHOULDER - drop - 0.02, 0.0)
		var elbow := Vector3(side * 0.31, SHOULDER - drop - 0.3, -0.08)
		var wrist := Vector3(side * 0.32, 0.27, -0.26)
		b.add(MeshBuilder.cylinder(0.065, 0.075, shoulder.distance_to(elbow) + 0.05, 7), MeshBuilder.between(shoulder, elbow), c["sleeve"])
		b.add(MeshBuilder.cylinder(0.075, 0.11, elbow.distance_to(wrist), 7), MeshBuilder.between(elbow, wrist), c["sleeve"])
		_hand(b, wrist + Vector3(0.0, -0.02, -0.04), c["skin"])
