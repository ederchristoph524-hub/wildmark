class_name CharacterMesh
extends RefCounted
## Baut Menschen-Figuren (Robe, Schärpe, Haarknoten) als ein Mesh – stehend (Glieder schwingen im Shader) oder im Schneidersitz.
## Gleiche Farben teilen sich das Mesh (Cache), damit viele Dorfbewohner billig bleiben.

const HIP: float = 0.92
const SHOULDER: float = 1.4
const LEG_SWING: float = 1.0
const ARM_SWING: float = 0.7
## Im Sitzen liegt die Hüfte hier.
const SIT_HIP: float = 0.24

static var _cache: Dictionary = {}


## colors: robe, sleeve, trousers, sash, skin, hair.
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


static func _head(b: MeshBuilder, c: Dictionary, drop: float) -> void:
	var y: float = -drop
	b.add(MeshBuilder.cylinder(0.065, 0.075, 0.12, 6), MeshBuilder.at(Vector3(0.0, 1.5 + y, 0.0)), c["skin"])
	b.add(MeshBuilder.sphere(0.165, 8, 5), MeshBuilder.at(Vector3(0.0, 1.66 + y, 0.0), Vector3(1.0, 1.12, 1.0)), c["skin"])
	# Haar: Kappe hinten/oben, Haarknoten obenauf.
	b.add(MeshBuilder.sphere(0.175, 8, 5), MeshBuilder.at(Vector3(0.0, 1.73 + y, 0.03), Vector3(1.03, 0.78, 1.06)), c["hair"])
	b.add(MeshBuilder.sphere(0.075, 6, 4), MeshBuilder.at(Vector3(0.0, 1.88 + y, 0.05)), c["hair"])
	b.add(MeshBuilder.cylinder(0.02, 0.02, 0.18, 4), MeshBuilder.at(Vector3(0.0, 1.89 + y, 0.05), Vector3.ONE, Vector3(0.0, 0.0, PI * 0.5)), c["sash"])
	# Augen zeigen die Blickrichtung (vorn = −Z).
	for side: float in [-1.0, 1.0]:
		b.add(MeshBuilder.sphere(0.022, 5, 3), MeshBuilder.at(Vector3(side * 0.058, 1.68 + y, -0.152)), Color(0.08, 0.06, 0.05))


static func _torso(b: MeshBuilder, c: Dictionary, drop: float) -> void:
	var y: float = -drop
	b.add(MeshBuilder.cylinder(0.26, 0.22, 0.52, 8), MeshBuilder.at(Vector3(0.0, 1.2 + y, 0.0)), c["robe"])
	b.add(MeshBuilder.sphere(0.27, 8, 4), MeshBuilder.at(Vector3(0.0, 1.43 + y, 0.0), Vector3(1.15, 0.35, 0.8)), c["robe"])
	# Überkreuzter Kragen und Schärpe.
	b.add(MeshBuilder.box(Vector3(0.05, 0.3, 0.02)), MeshBuilder.at(Vector3(0.05, 1.32 + y, -0.235), Vector3.ONE, Vector3(0.0, 0.0, 0.5)), c["sash"].lightened(0.25))
	b.add(MeshBuilder.cylinder(0.235, 0.235, 0.08, 8), MeshBuilder.at(Vector3(0.0, 0.97 + y, 0.0)), c["sash"])
	if drop <= 0.0:
		# Robe bis über die Knie; die Beine schwingen darunter.
		b.add(MeshBuilder.cylinder(0.24, 0.33, 0.5, 8), MeshBuilder.at(Vector3(0.0, 0.7, 0.0)), c["robe"])
	else:
		b.add(MeshBuilder.cylinder(0.26, 0.5, 0.22, 10), MeshBuilder.at(Vector3(0.0, SIT_HIP - 0.02, 0.0)), c["robe"])


static func _legs(b: MeshBuilder, c: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var custom := Vector2(-side * LEG_SWING, HIP)
		var x: float = side * 0.12
		b.add(MeshBuilder.cylinder(0.09, 0.075, 0.5, 6), MeshBuilder.at(Vector3(x, 0.66, 0.0)), c["trousers"], custom)
		b.add(MeshBuilder.cylinder(0.075, 0.065, 0.36, 6), MeshBuilder.at(Vector3(x, 0.26, 0.0)), c["trousers"], custom)
		b.add(MeshBuilder.box(Vector3(0.13, 0.09, 0.27)), MeshBuilder.at(Vector3(x, 0.045, -0.04)), Color(0.12, 0.1, 0.08), custom)


static func _arms(b: MeshBuilder, c: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var custom := Vector2(side * ARM_SWING, SHOULDER)
		var shoulder := Vector3(side * 0.31, 1.4, 0.0)
		var elbow := Vector3(side * 0.35, 1.12, 0.02)
		var wrist := Vector3(side * 0.36, 0.86, -0.02)
		b.add(MeshBuilder.cylinder(0.08, 0.09, shoulder.distance_to(elbow) + 0.06, 6), MeshBuilder.between(shoulder, elbow), c["sleeve"], custom)
		b.add(MeshBuilder.cylinder(0.09, 0.13, elbow.distance_to(wrist), 6), MeshBuilder.between(elbow, wrist), c["sleeve"], custom)
		b.add(MeshBuilder.sphere(0.058, 6, 4), MeshBuilder.at(wrist + Vector3(0.0, -0.07, 0.0)), c["skin"], custom)


## Schneidersitz: Knie seitlich, Unterschenkel gekreuzt.
static func _sitting_legs(b: MeshBuilder, c: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * 0.12, SIT_HIP, 0.0)
		var knee := Vector3(side * 0.42, 0.14, -0.2)
		var ankle := Vector3(-side * 0.1, 0.1, -0.34)
		b.add(MeshBuilder.cylinder(0.09, 0.08, hip.distance_to(knee) + 0.08, 6), MeshBuilder.between(hip, knee), c["trousers"])
		b.add(MeshBuilder.cylinder(0.08, 0.068, knee.distance_to(ankle), 6), MeshBuilder.between(knee, ankle), c["trousers"])
		b.add(MeshBuilder.box(Vector3(0.12, 0.08, 0.22)), Transform3D(Basis(Vector3.UP, side * 1.2), ankle + Vector3(-side * 0.06, -0.03, 0.0)), Color(0.12, 0.1, 0.08))


## Hände ruhen auf den Knien, Handflächen nach oben.
static func _sitting_arms(b: MeshBuilder, c: Dictionary, drop: float) -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * 0.31, SHOULDER - drop, 0.0)
		var elbow := Vector3(side * 0.37, SHOULDER - drop - 0.28, -0.08)
		var wrist := Vector3(side * 0.36, 0.26, -0.26)
		b.add(MeshBuilder.cylinder(0.08, 0.09, shoulder.distance_to(elbow) + 0.06, 6), MeshBuilder.between(shoulder, elbow), c["sleeve"])
		b.add(MeshBuilder.cylinder(0.09, 0.13, elbow.distance_to(wrist), 6), MeshBuilder.between(elbow, wrist), c["sleeve"])
		b.add(MeshBuilder.sphere(0.058, 6, 4), MeshBuilder.at(wrist + Vector3(0.0, -0.02, -0.04)), c["skin"])
