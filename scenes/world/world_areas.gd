class_name WorldAreas
extends RefCounted
## Besondere Gebiete mit Materialquellen: Aschefeld (Glutasche), Frostquelle (Frostsplitter), alter Friedhof (Knochenmehl).

## Mittelpunkt, Radius, Gegenstand, Anzahl Sammelstellen, Bodenfarbe.
const AREAS: Array[Dictionary] = [
	{"name": "Aschefeld", "center": Vector2(72.0, -68.0), "radius": 11.0, "item": &"glutasche", "count": 8, "ground": Color(0.16, 0.15, 0.14)},
	{"name": "Frostquelle", "center": Vector2(-86.0, 68.0), "radius": 7.0, "item": &"frostsplitter", "count": 5, "ground": Color(0.75, 0.88, 0.95)},
	{"name": "Alter Friedhof", "center": Vector2(-62.0, -78.0), "radius": 9.0, "item": &"knochenmehl", "count": 6, "ground": Color(0.3, 0.3, 0.27)},
]
const GRAVE_COLOR: Color = Color(0.5, 0.5, 0.48)
const ICE_COLOR: Color = Color(0.7, 0.92, 1.0)


static func build(world: World) -> void:
	for area: Dictionary in AREAS:
		var center: Vector2 = area["center"]
		var radius: float = area["radius"]
		_ground_patch(world, center, radius, area["ground"])
		for i: int in int(area["count"]):
			world.add_resource(area["item"], 1, world.random_point_near(center, radius * 0.9))
		match area["item"]:
			&"knochenmehl":
				_graves(world, center, radius)
			&"frostsplitter":
				_ice(world, center, radius)
		_sign(world, center, area["name"])


## Flache, eingefärbte Scheibe, die dem Gelände grob folgt.
static func _ground_patch(world: World, center: Vector2, radius: float, color: Color) -> void:
	var b := MeshBuilder.new()
	var steps: int = 5
	for ix: int in range(-steps, steps + 1):
		for iz: int in range(-steps, steps + 1):
			var offset := Vector2(ix, iz) * (radius / steps)
			if offset.length() > radius:
				continue
			var point: Vector3 = world.ground_point(center.x + offset.x, center.y + offset.y)
			b.add(MeshBuilder.cylinder(radius / steps * 0.9, radius / steps * 0.9, 0.1, 6), MeshBuilder.at(point + Vector3.UP * 0.03), color)
	var node := MeshInstance3D.new()
	node.mesh = b.build()
	node.material_override = WorldMaterials.vertex_colored()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)


static func _graves(world: World, center: Vector2, radius: float) -> void:
	var b := MeshBuilder.new()
	for i: int in 7:
		var point: Vector3 = world.random_point_near(center, radius)
		b.add(MeshBuilder.box(Vector3(0.6, 1.0, 0.2)), MeshBuilder.at(point + Vector3.UP * 0.45, Vector3.ONE, Vector3(0, randf() * 0.6, randf_range(-0.15, 0.15))), GRAVE_COLOR)
	_add(world, b.build(), WorldMaterials.vertex_colored())


static func _ice(world: World, center: Vector2, radius: float) -> void:
	var b := MeshBuilder.new()
	for i: int in 9:
		var point: Vector3 = world.random_point_near(center, radius)
		b.add(MeshBuilder.cylinder(0.0, 0.35, randf_range(0.8, 1.8), 5), MeshBuilder.at(point + Vector3.UP * 0.5, Vector3.ONE, Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))), Color.WHITE)
	_add(world, b.build(), WorldMaterials.glowing(ICE_COLOR))


static func _sign(world: World, center: Vector2, title: String) -> void:
	var label := Label3D.new()
	label.text = Loc.t(title)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	label.pixel_size = 0.01
	label.outline_size = 12
	label.visibility_range_end = 45.0
	world.add_child(label)
	label.position = world.ground_point(center.x, center.y) + Vector3.UP * 3.5


static func _add(world: World, mesh: ArrayMesh, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	world.add_child(node)
