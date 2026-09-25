class_name ImmortalTravel
extends RefCounted
## Reisen und Tod auf der Unsterblichen-Ebene: Zutritt nach Rang (AreaData.immortal.entry_rank), sofortige Reise in die
## eigene Apertur und zurück oder mit einem Reise-Gu (Feste Unsterblichen-Reise), Erwachen im Traumreich statt Tod und
## die Frühling-Herbst-Zikade, die einmal am Tag die Zeit zurückdreht.

static var _rewind_day: int = -1


## Darf der Spieler dorthin? Meldet den Grund, wenn nicht.
static func allowed(target: AreaData) -> bool:
	var entry: int = target.entry_rank() if not target.immortal.is_empty() else 1
	if GameState.rank >= entry:
		return true
	if entry >= Immortal.FIRST_RANK:
		EventBus.message.emit(Loc.t("%s ist nur Unsterblichen ab Rang %d zugänglich.") % [Loc.t(target.display_name), entry], UiTheme.DANGER)
	else:
		EventBus.message.emit(Loc.t("%s verschlingt jeden unter Rang %d.") % [Loc.t(target.display_name), entry], UiTheme.DANGER)
	return false


## Ohne Reisezeit: in die eigene Apertur, aus ihr heraus oder mit einem Reise-Gu.
static func is_instant(area_id: StringName) -> bool:
	return area_id == ImmortalAperture.AREA_ID or GameState.area == ImmortalAperture.AREA_ID or Immortal.has_world_effect(&"reise")


## Traumreich: Tod weckt dich am Eingang. Frühling-Herbst-Zikade: einmal am Tag zurück an den Ruheort. true = kein Tod.
static func escape_death(player: Player, world: World) -> bool:
	if player == null or world == null:
		return false
	if DimensionRules.dream_death():
		EventBus.message.emit(Loc.t("Du erwachst am Rand des Traums – nichts davon war wirklich."), Color(0.8, 0.7, 1.0))
		player.get_tree().create_timer(1.0).timeout.connect(_revive.bind(weakref(player), world.spawn_point()))
		return true
	if Immortal.has_world_effect(&"zeitruecksprung") and _rewind_day != GameState.day:
		_rewind_day = GameState.day
		GameState.time_of_day = Balance.values.start_time_of_day
		EventBus.message.emit(Loc.t("Die Frühling-Herbst-Zikade schlägt mit den Flügeln – die Zeit fließt zurück an den Morgen."), Color(0.6, 1.0, 0.7))
		player.get_tree().create_timer(1.0).timeout.connect(_revive.bind(weakref(player), GameState.rest_point))
		return true
	return false


static func _revive(player_ref: WeakRef, at: Vector3) -> void:
	var player: Player = player_ref.get_ref() as Player
	if player != null and player.is_inside_tree():
		player.respawn(at)
