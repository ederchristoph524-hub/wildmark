class_name ResourceNodeLooks
extends RefCounted
## Baut die Platzhalter-Modelle der Sammelstellen aus Grundformen.


static func build(node: ResourceNode, shape: StringName, base: Color, accent: Color) -> void:
	var b := MeshBuilder.new()
	match shape:
		&"bush":
			b.add(MeshBuilder.sphere(0.75, 6, 3), MeshBuilder.at(Vector3(0, 0.55, 0), Vector3(1.1, 0.8, 1.0)), base)
			node.add_mesh(b.build())
			var fruit := MeshBuilder.new()
			for offset: Vector3 in [Vector3(0.4, 0.8, -0.4), Vector3(-0.35, 0.9, -0.3), Vector3(0.1, 1.05, 0.4)]:
				fruit.add(MeshBuilder.sphere(0.12, 5, 3), MeshBuilder.at(offset), accent)
			node.add_mesh(fruit.build())
			return
		&"rock":
			b.add(MeshBuilder.sphere(0.8, 6, 3), MeshBuilder.at(Vector3(0, 0.45, 0), Vector3(1.2, 0.8, 1.0)), base)
			b.add(MeshBuilder.sphere(0.5, 5, 3), MeshBuilder.at(Vector3(0.6, 0.35, 0.3)), accent)
		&"crystal":
			b.add(MeshBuilder.sphere(0.6, 6, 3), MeshBuilder.at(Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 1.0)), Color(0.4, 0.4, 0.42))
			node.add_mesh(b.build())
			node.add_mesh(_spikes(3, 1.1, 0.2), accent)
			return
		&"log":
			b.add(MeshBuilder.cylinder(0.32, 0.36, 2.4, 6), MeshBuilder.at(Vector3(0, 0.35, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5)), base)
		&"herb":
			for i: int in 5:
				var angle: float = i * TAU / 5.0
				b.add(MeshBuilder.cylinder(0.0, 0.09, 0.7, 3), MeshBuilder.at(Vector3(cos(angle) * 0.15, 0.35, sin(angle) * 0.15), Vector3.ONE, Vector3(sin(angle) * 0.4, 0, cos(angle) * 0.4)), base)
			b.add(MeshBuilder.sphere(0.1, 5, 3), MeshBuilder.at(Vector3(0, 0.72, 0)), accent)
		&"ore":
			b.add(MeshBuilder.sphere(0.8, 6, 3), MeshBuilder.at(Vector3(0, 0.45, 0), Vector3(1.1, 0.9, 1.0)), base)
			for offset: Vector3 in [Vector3(0.5, 0.6, -0.4), Vector3(-0.4, 0.8, -0.3), Vector3(0.1, 0.9, 0.5)]:
				b.add(MeshBuilder.box(Vector3(0.25, 0.2, 0.25)), MeshBuilder.at(offset, Vector3.ONE, Vector3(0.4, 0.7, 0)), accent)
		&"dew":
			b.add(MeshBuilder.cylinder(0.0, 0.08, 0.5, 3), MeshBuilder.at(Vector3(0, 0.25, 0)), base)
			node.add_mesh(b.build())
			var drops := MeshBuilder.new()
			for offset: Vector3 in [Vector3(0.1, 0.5, 0), Vector3(-0.15, 0.4, 0.1), Vector3(0.05, 0.35, -0.15)]:
				drops.add(MeshBuilder.sphere(0.07, 5, 3), MeshBuilder.at(offset), Color.WHITE)
			node.add_mesh(drops.build(), accent)
			return
		&"ash":
			b.add(MeshBuilder.sphere(0.7, 6, 3), MeshBuilder.at(Vector3(0, 0.15, 0), Vector3(1.3, 0.35, 1.1)), base)
			node.add_mesh(b.build())
			var embers := MeshBuilder.new()
			for offset: Vector3 in [Vector3(0.2, 0.3, 0.1), Vector3(-0.3, 0.28, -0.2), Vector3(0.0, 0.33, 0.3)]:
				embers.add(MeshBuilder.sphere(0.08, 4, 2), MeshBuilder.at(offset), Color.WHITE)
			node.add_mesh(embers.build(), accent)
			return
		&"bones":
			b.add(MeshBuilder.sphere(0.22, 6, 3), MeshBuilder.at(Vector3(0, 0.2, 0)), base)
			for i: int in 4:
				b.add(MeshBuilder.cylinder(0.05, 0.05, 0.8, 4), MeshBuilder.at(Vector3(0.1 * i - 0.15, 0.08, 0.2), Vector3.ONE, Vector3(PI * 0.5, i * 0.6, 0)), accent)
	node.add_mesh(b.build())


static func _spikes(count: int, height: float, radius: float) -> ArrayMesh:
	var b := MeshBuilder.new()
	for i: int in count:
		var tilt := Vector3(0.3 * (i - 1), 0.0, 0.25 * (1 - i))
		b.add(MeshBuilder.cylinder(0.0, radius, height - i * 0.2, 5), MeshBuilder.at(Vector3(0.25 * (i - 1), 0.8, 0.15 * i), Vector3.ONE, tilt), Color.WHITE)
	return b.build()
