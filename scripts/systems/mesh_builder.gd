class_name MeshBuilder
extends RefCounted
## Baut Low-Poly-Modelle aus einfachen Grundformen zu einem einzigen Mesh mit Vertex-Farben zusammen (ein Draw Call pro Modell).

var _vertices: PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
var _indices: PackedInt32Array = PackedInt32Array()


## Fügt eine Grundform mit Transformation und Farbe hinzu.
func add(primitive: PrimitiveMesh, transform: Transform3D, color: Color) -> MeshBuilder:
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


static func at(position: Vector3, scale: Vector3 = Vector3.ONE, rotation: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(rotation).scaled(scale), position)
