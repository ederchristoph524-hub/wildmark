class_name ReactionEffects
extends RefCounted
## Führt die Reaktionen aus gu_system.json aus; Parameter stehen in Balance.reaction_rules.

const REACTION_COLOR: Color = Color(1.0, 0.85, 0.3)


## Prüft alle Reaktionen für einen Treffer und liefert den gesamten Schadensfaktor.
static func resolve(status: StatusComponent, hit: HitInfo) -> float:
	var total: float = 1.0
	for resource: Resource in DataRegistry.all(&"reactions"):
		var reaction: ReactionData = resource as ReactionData
		if reaction.trigger_tag not in hit.tags:
			continue
		if not status.condition_met(reaction.target_status, reaction.min_stacks):
			continue
		total *= _apply(reaction, status, hit)
		for removed: StringName in reaction.removes:
			status.remove_status(removed)
		_announce(reaction, status.host)
	return total


static func _apply(reaction: ReactionData, status: StatusComponent, hit: HitInfo) -> float:
	var rule: Dictionary = Balance.values.reaction_rules.get(reaction.id, {})
	var host: Combatant = status.host
	if rule.has("freeze"):
		status.freeze(float(rule["freeze"]))
	if rule.has("apply"):
		status.apply_status(rule["apply"], 1)
	if rule.has("blind_radius"):
		_blind_area(host, float(rule["blind_radius"]), float(rule["blind_time"]))
	if rule.has("spread_status"):
		_spread(host, rule["spread_status"], float(rule["spread_radius"]))
	if rule.has("explode_per_stack"):
		var damage: float = float(rule["explode_per_stack"]) * status.stacks_of(rule["stack_status"])
		explosion(host, hit, damage, float(rule["explode_radius"]))
	if rule.has("stack_mult"):
		var id: StringName = rule["stack_status"]
		var doubled: int = roundi(status.stacks_of(id) * float(rule["stack_mult"]))
		status.set_stacks(id, doubled)
	if rule.has("chain_status"):
		_chain(host, hit, rule["chain_status"], float(rule["chain_radius"]), float(rule.get("mult", 1.0)))
	return float(rule.get("mult", 1.0))


## Überschlag: springt auf alle Ziele desselben Teams mit dem Zustand.
static func _chain(host: Combatant, hit: HitInfo, status_id: StringName, radius: float, mult: float) -> void:
	var tree: SceneTree = host.get_tree()
	for other: Combatant in Combat.in_radius(Combat.members(tree, host.team), host.global_position, radius):
		if other == host or not other.status.has_status(status_id):
			continue
		other.status.remove_status(status_id)
		other.receive_hit(hit.derived(hit.damage * mult))
		Fx.beam(tree, host.aim_point(), other.aim_point(), Color(0.6, 0.8, 1.0), 0.25)


static func _spread(host: Combatant, status_id: StringName, radius: float) -> void:
	var tree: SceneTree = host.get_tree()
	for other: Combatant in Combat.in_radius(Combat.members(tree, host.team), host.global_position, radius):
		if other != host:
			other.status.apply_status(status_id, 1)
	Fx.ring(tree, host.global_position, radius, Color(1.0, 0.45, 0.15), 0.4)


static func _blind_area(host: Combatant, radius: float, duration: float) -> void:
	var tree: SceneTree = host.get_tree()
	for other: Combatant in Combat.in_radius(Combat.members(tree, host.team), host.global_position, radius):
		other.status.blind_time = maxf(other.status.blind_time, duration)
	Fx.sphere(tree, host.global_position + Vector3.UP, radius, Color(0.9, 0.95, 1.0, 0.5), duration)


## Flächenschaden auf alle Ziele desselben Teams wie host (inklusive host).
static func explosion(host: Combatant, hit: HitInfo, damage: float, radius: float) -> void:
	var tree: SceneTree = host.get_tree()
	for other: Combatant in Combat.in_radius(Combat.members(tree, host.team), host.global_position, radius):
		if other != host:
			other.receive_hit(hit.derived(damage))
	host.receive_hit(hit.derived(damage))
	Fx.sphere(tree, host.global_position + Vector3.UP * 0.5, radius, Color(0.6, 1.0, 0.3, 0.6), 0.35)


## Entladung bei vollen Ladungsstapeln: trifft alles in der Nähe (auch den Träger).
static func discharge(host: Combatant, damage: float, radius: float) -> void:
	var hit := HitInfo.create(damage, null, -1)
	hit.can_react = false
	var tree: SceneTree = host.get_tree()
	for other: Combatant in Combat.in_radius(Combat.members(tree, host.team), host.global_position, radius):
		other.receive_hit(hit.derived(damage))
	Fx.sphere(tree, host.global_position + Vector3.UP, radius, Color(0.55, 0.75, 1.0, 0.6), 0.3)
	EventBus.floating_text.emit(Loc.t("Entladung!"), host.aim_point(), Color(0.6, 0.8, 1.0))


static func _announce(reaction: ReactionData, host: Combatant) -> void:
	EventBus.floating_text.emit(Loc.t(reaction.display_name) + "!", host.aim_point() + Vector3.UP * 0.6, REACTION_COLOR)
	EventBus.reaction_triggered.emit(reaction.id, host.global_position)
