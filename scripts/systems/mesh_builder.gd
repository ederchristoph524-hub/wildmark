class_name MeshBuilder
extends RefCounted
## Baut Low-Poly-Modelle aus einfachen Grundformen zu einem einzigen Mesh mit Vertex-Farben zusammen (ein Draw Call pro Modell).

var _vertices: PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
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
