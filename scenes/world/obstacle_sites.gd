class_name ObstacleSites
extends RefCounted
## Die sieben Hindernis-Orte im Startgebiet, hinter jedem ein versteckter wilder Rang-2-Gu (GDD, M2).

const RING_RADIUS: float = 3.4
const POND_RADIUS: float = 6.0
const LEDGE_HEIGHT: float = 2.1
const SWITCH_OFFSET: float = 5.0
const FLAT_SLOPE: float = 0.18
## ID, Art, Belohnung (Gu-ID), Richtung vom Lager (Grad), Entfernung.
const SITES: Array[Array] = [
	[&"site_hecke", WorldObstacle.KIND_HEDGE, &"mondsichel", 20.0, 58.0],
	[&"site_wasser", WorldObstacle.KIND_WATER, &"wasserbohrer", 75.0, 66.0],
	[&"site_fels", WorldObstacle.KIND_BOULDER, &"blauplasma", 130.0, 60.0],
	[&"site_schalter", WorldObstacle.KIND_SWITCH, &"flammenzunge", 185.0, 64.0],
	[&"site_licht", WorldObstacle.KIND_LIGHT, &"eisvogel", 240.0, 58.0],
	[&"site_blut", WorldObstacle.KIND_BLOOD, &"sogwirbel", 290.0, 70.0],
	[&"site_vorsprung", &"vorsprung", &"giftskorpion", 335.0, 55.0],
]


## Mittelpunkte aller Orte (vor der Vegetation berechnet, damit dort keine Bäume stehen).
static func plan(world: World) -> Array[Vector3]:
	var centers: Array[Vector3] = []
	for site: Array in SITES:
		centers.append(_flat_spot(world, deg_to_rad(float(site[3])), float(site[4])))
	return centers


static func build(world: World, centers: Array[Vector3]) -> void:
	for index: int in SITES.size():
		var site: Array = SITES[index]
		var center: Vector3 = centers[index]
		var reward_height: float = 0.8
		match site[1]:
			WorldObstacle.KIND_HEDGE:
				var hedge: WorldObstacle = _obstacle(world, site, center, RING_RADIUS + 0.5)
				ObstacleBuilder.blocker_ring(hedge, world, center, RING_RADIUS, 2.8, ObstacleBuilder.HEDGE, true)
			WorldObstacle.KIND_WATER:
				var pond: WorldObstacle = _obstacle(world, site, center, POND_RADIUS)
				ObstacleBuilder.pond(pond, POND_RADIUS)
				ObstacleBuilder.blocker_ring(pond, world, center, POND_RADIUS - 0.5, 3.0, Color.WHITE, false)
				reward_height = 1.2
			&"vorsprung":
				var ledge := Node3D.new()
				world.add_child(ledge)
				ledge.position = center
				ObstacleBuilder.ledge(ledge, LEDGE_HEIGHT)
				reward_height = LEDGE_HEIGHT + 0.8
			_:
				_gated_site(world, site, center)
		_reward(world, site, center + Vector3.UP * (reward_height - 0.8))


## Mauerring mit Lücke zum Lager; in der Lücke Felsbrocken, Tor mit Siegel oder Tor mit Schalter daneben.
static func _gated_site(world: World, site: Array, center: Vector3) -> void:
	var to_camp: Vector3 = -center
	var gap_angle: float = fposmod(atan2(to_camp.z, to_camp.x), TAU)
	var holder := Node3D.new()
	world.add_child(holder)
	ObstacleBuilder.wall_ring(holder, world, center, RING_RADIUS, gap_angle, ObstacleBuilder.RUIN if site[1] != WorldObstacle.KIND_BOULDER else ObstacleBuilder.STONE)
	var gap: Vector3 = world.ground_point(center.x + cos(gap_angle) * RING_RADIUS, center.z + sin(gap_angle) * RING_RADIUS)
	var facing: float = -gap_angle + PI * 0.5
	match site[1]:
		WorldObstacle.KIND_BOULDER:
			ObstacleBuilder.boulder(_obstacle(world, site, gap, 1.6))
		WorldObstacle.KIND_SWITCH:
			var side := Vector3(cos(gap_angle + 0.9), 0.0, sin(gap_angle + 0.9)) * SWITCH_OFFSET
			var pillar: WorldObstacle = _obstacle(world, site, world.ground_point(center.x + side.x, center.z + side.z), 0.8)
			ObstacleBuilder.switch_pillar(pillar)
			ObstacleBuilder.gate(pillar, gap - pillar.position, facing, Color(0, 0, 0, 0))
		WorldObstacle.KIND_LIGHT:
			ObstacleBuilder.gate(_obstacle(world, site, gap, 1.6), Vector3.ZERO, facing, ObstacleBuilder.LIGHT_SEAL)
		WorldObstacle.KIND_BLOOD:
			ObstacleBuilder.gate(_obstacle(world, site, gap, 1.6), Vector3.ZERO, facing, ObstacleBuilder.BLOOD_SEAL)


static func _obstacle(world: World, site: Array, at: Vector3, radius: float) -> WorldObstacle:
	var obstacle := WorldObstacle.new()
	obstacle.setup(site[0], site[1], radius)
	obstacle.position = at
	world.add_child(obstacle)
	return obstacle


static func _reward(world: World, site: Array, at: Vector3) -> void:
	var spot: StringName = StringName(String(site[0]) + "_gu")
	if spot in GameState.collected_wild_gu:
		return
	var wild := WildGu.new()
	wild.setup(spot, DataRegistry.gu(site[2]))
	world.add_child(wild)
	wild.position = at


## Möglichst ebener Platz in der Nähe der gewünschten Richtung und Entfernung.
static func _flat_spot(world: World, angle: float, distance: float) -> Vector3:
	var best: Vector3 = world.ground_point(cos(angle) * distance, sin(angle) * distance)
	var best_slope: float = INF
	for attempt: int in 24:
		var a: float = angle + (attempt % 6 - 2.5) * 0.06
		var d: float = distance + floorf(attempt / 6.0) * 4.0 - 6.0
		var x: float = cos(a) * d
		var z: float = sin(a) * d
		var slope: float = world.terrain.slope_at(x, z) + world.terrain.slope_at(x + 3.0, z) + world.terrain.slope_at(x, z + 3.0)
		if slope < best_slope:
			best_slope = slope
			best = world.ground_point(x, z)
		if slope < FLAT_SLOPE:
			break
	return best
