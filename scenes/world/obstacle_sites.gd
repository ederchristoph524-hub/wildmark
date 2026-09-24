class_name ObstacleSites
extends RefCounted
## Hindernis-Orte eines Gebiets (gebiete.json → hindernisse), hinter jedem ein versteckter wilder Gu (GDD, M2).

const RING_RADIUS: float = 3.4
const POND_RADIUS: float = 6.0
const LEDGE_HEIGHT: float = 2.1
const SWITCH_OFFSET: float = 5.0
## Mittelpunkte der Hindernis-Orte aus den Gebietsdaten (Richtung und Abstand von der Gebietsmitte).
static func centers(area: AreaData) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for site: Dictionary in area.obstacles:
		var angle: float = deg_to_rad(float(site["angle"]))
		result.append(Vector2(cos(angle), sin(angle)) * float(site["distance"]))
	return result


static func build(world: World, area: AreaData) -> void:
	var points: Array[Vector2] = centers(area)
	for index: int in area.obstacles.size():
		var entry: Dictionary = area.obstacles[index]
		var site: Array = [entry["id"], entry["kind"], entry["reward"]]
		var center: Vector3 = world.ground_point(points[index].x, points[index].y)
		world.add_poi(center, MapData.KIND_SITE, Loc.t("Rätselort"))
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
