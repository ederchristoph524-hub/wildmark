class_name MeshBuilder
extends RefCounted
## Baut Low-Poly-Modelle aus einfachen Grundformen zu einem einzigen Mesh mit Vertex-Farben zusammen (ein Draw Call pro Modell).

var _vertices: PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
## Kennung von Karten-Texturkoordinaten in UV2 (Werte ≥ 2 sind Karten).
const CARD_OFFSET: float = 2.0
## Zusatzdaten pro Vertex (UV2), z. B. Schwunggewicht und Drehpunkt für Figuren-Shader.
var _custom: PackedVector2Array = PackedVector2Array()
var _has_custom: bool = false
var _indices: PackedInt32Array = PackedInt32Array()


## Fügt eine Grundform mit Transformation und Farbe hinzu (custom landet in UV2).
func add(primitive: PrimitiveMesh, transform: Transform3D, color: Color, custom: Vector2 = Vector2.ZERO) -> MeshBuilder:
	var arrays: Array = primitive.get_mesh_arrays()
	var source_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var offset: int = _vertices.size()
	var normal_basis: Basis = transform.basis.inverse().transposed()
	for i: int in source_vertices.size():
		_vertices.append(transform * source_vertices[i])
		_normals.append((normal_basis * source_normals[i]).normalized())
		_colors.append(color)
		_custom.append(custom)
	if custom != Vector2.ZERO:
		_has_custom = true
	for index: int in source_indices:
		_indices.append(offset + index)
	return self


## Fügt Dreiecke (je drei Punkte) mit flacher Normale hinzu; beidseitig für dünne Blätter.
func add_triangles(points: PackedVector3Array, color: Color, double_sided: bool = true) -> MeshBuilder:
	for i: int in range(0, points.size() - 2, 3):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var c: Vector3 = points[i + 2]
		var normal: Vector3 = (b - a).cross(c - a).normalized()
		_triangle(a, b, c, -normal, color)
		if double_sided:
			_triangle(a, c, b, normal, color)
	return self


## Karte (Viereck a, b, c, d im Uhrzeigersinn) mit Textur-Koordinaten in UV2 (Blatt- und Grasbüschel-Karten,
## die der Vegetations-Shader ausschneidet); beidseitig.
func add_card(corners: Array[Vector3], color: Color, uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]) -> MeshBuilder:
	var normal: Vector3 = (corners[1] - corners[0]).cross(corners[3] - corners[0]).normalized()
	for flip: int in 2:
		var offset: int = _vertices.size()
		for i: int in 4:
			_vertices.append(corners[i])
			_normals.append(-normal if flip == 0 else normal)
			_colors.append(color)
			# + CARD_OFFSET markiert Karten (der Vegetations-Shader zieht ihn wieder ab).
			_custom.append(uvs[i] + Vector2.ONE * CARD_OFFSET)
		if flip == 0:
			_indices.append_array([offset, offset + 1, offset + 2, offset, offset + 2, offset + 3])
		else:
			_indices.append_array([offset, offset + 2, offset + 1, offset, offset + 3, offset + 2])
	_has_custom = true
	return self


func _triangle(a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
	var offset: int = _vertices.size()
	for point: Vector3 in [a, b, c]:
		_vertices.append(point)
		_normals.append(normal)
		_colors.append(color)
		_custom.append(Vector2.ZERO)
	_indices.append_array([offset, offset + 1, offset + 2])


func build() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	if _has_custom:
		arrays[Mesh.ARRAY_TEX_UV2] = _custom
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func cylinder(top: float, bottom: float, height: float, segments: int = 6) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


static func sphere(radius: float, segments: int = 7, rings: int = 4) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## Transformation, die eine Y-ausgerichtete Grundform (Zylinder, Kapsel) von a nach b legt.
static func between(a: Vector3, b: Vector3) -> Transform3D:
	var up: Vector3 = (b - a).normalized()
	var side: Vector3 = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x_axis: Vector3 = up.cross(side).normalized()
	var z_axis: Vector3 = x_axis.cross(up).normalized()
	return Transform3D(Basis(x_axis, up, z_axis), (a + b) * 0.5)


static func at(position: Vector3, scale: Vector3 = Vector3.ONE, rotation: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(rotation).scaled(scale), position)
