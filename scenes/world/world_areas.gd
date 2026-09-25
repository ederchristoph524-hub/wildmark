class_name WorldAreas
extends RefCounted
## Besondere Orte eines Gebiets (gebiete.json → orte): Aschefeld, Frostquelle, alter Friedhof (Materialquellen),
## Urstein-Adern (Abbau, bei fremdem Besitz Diebstahl), Dao-Orte (Markierungen beim Kultivieren), Seen, die Geisterquelle (Kultivieren doppelt so schnell) und Erbschaften mit Opfergabe, Wächtern und Belohnung.

## Bodenfarbe der Materialorte (als Terrain.stains in den Boden gemalt).
const GROUND_COLORS: Dictionary[StringName, Color] = {
	&"aschefeld": Color(0.2, 0.19, 0.18), &"frostquelle": Color(0.6, 0.7, 0.78), &"friedhof": Color(0.33, 0.31, 0.26),
	&"ursteinader": Color(0.4, 0.38, 0.35),
}
const PRIMEVAL_STONE: StringName = &"kristall"


## Baut einen Ort; Seen müssen vorher im Gelände eingetragen sein (World).
static func build(world: World, place: Dictionary) -> void:
	var center: Vector2 = place["position"]
	var radius: float = place["radius"]
	var name_text: String = place["name"]
	match place["type"]:
		&"aschefeld", &"frostquelle", &"friedhof":
			# Der Boden ist über Terrain.stains eingefärbt (World trägt die Orte vor dem Geländebau ein).
			for i: int in int(place["count"]):
				world.add_resource(place["item"], 1, world.random_point_near(center, radius * 0.9))
			match place["type"]:
				&"friedhof":
					PlaceDecor.graveyard(world, center, radius)
				&"frostquelle":
					PlaceDecor.frost_spring(world, center, radius)
				_:
					PlaceDecor.ash_field(world, center, radius)
			_sign(world, center, name_text)
		&"ursteinader":
			# Ursteinbrocken vor dem Stollen; gehört die Ader einem Klan, ist Abbau ohne Mitgliedschaft Diebstahl.
			for i: int in maxi(1, int(place["count"])):
				var node: ResourceNode = world.add_resource(PRIMEVAL_STONE, maxi(1, int(place["amount"])), world.random_point_near(center + Vector2(0.0, radius * 0.1), radius * 0.6))
				node.owner_sect = place["owner"]
			PlaceDecor.stone_vein(world, center, radius)
			_sign(world, center, name_text)
		&"see":
			WaterSurface.lake(world, world.terrain.lake_at(center), world.terrain.biome.water, 0.0)
		&"dao_ort":
			var site := DaoSite.new()
			site.path = place["path"]
			site.radius = radius
			site.site_name = name_text
			world.add_child(site)
			site.position = world.ground_point(center.x, center.y)
			_sign(world, center, name_text)
		&"geisterquelle":
			var spring := SpiritSpring.new()
			spring.radius = radius
			world.add_child(spring)
			spring.position = world.ground_point(center.x, center.y)
			_sign(world, center, name_text)
		&"erbe":
			var inheritance := Inheritance.new()
			inheritance.data = place
			world.add_child(inheritance)
			inheritance.position = world.ground_point(center.x, center.y)
	world.add_poi(world.ground_point(center.x, center.y), MapData.KIND_PLACE, Loc.t(name_text))


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
