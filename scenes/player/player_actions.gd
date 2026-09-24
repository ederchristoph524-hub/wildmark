class_name PlayerActions
extends RefCounted
## Prüfungen und Abschluss für Urstein essen und Meditieren (ausgelagert aus player.gd).


static func can_eat_stone(player: Player) -> bool:
	if GameState.item_count(Player.STONE_ITEM) <= 0:
		EventBus.message.emit(Loc.t("Kein Urstein im Gepäck"), Color(1.0, 0.6, 0.4))
		return false
	if player.aperture.ratio() >= 0.99:
		EventBus.message.emit(Loc.t("Deine Apertur ist schon voll"), Color(0.8, 0.9, 0.8))
		return false
	return true


static func finish_eating(player: Player) -> void:
	if GameState.take_item(Player.STONE_ITEM, 1):
		player.aperture.gain(player.aperture.capacity() * Balance.values.stone_essence_fraction)
		EventBus.message.emit(Loc.t("Urstein aufgenommen"), Color(0.5, 0.9, 1.0))


static func can_meditate(player: Player) -> bool:
	var danger: float = Balance.values.meditation_danger_radius
	var beasts: Array[Combatant] = Combat.hostiles(player.get_tree(), player.team).filter(func(c: Combatant) -> bool: return c.team != Combatant.TEAM_WORLD)
	if not Combat.in_radius(beasts, player.global_position, danger).is_empty():
		EventBus.message.emit(Loc.t("Zu gefährlich zum Meditieren – Bestien in der Nähe"), Color(1.0, 0.36, 0.45))
		return false
	if GameState.stage >= Balance.values.max_stage:
		EventBus.message.emit(Loc.t("Höchststufe – jetzt hilft nur der Durchbruch"), Color(0.8, 0.9, 0.8))
		return false
	return true
