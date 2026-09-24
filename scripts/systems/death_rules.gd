class_name DeathRules
extends RefCounted
## Folgen des Todes je Todesmodus (KAMPFSYSTEM.md, Abschnitt 10).


## Wendet die Verluste an. Liefert false, wenn das Spiel vorbei ist (Hardcore).
static func apply(death_position: Vector3) -> bool:
	var b: BalanceData = Balance.values
	match GameState.death_mode:
		GameState.DEATH_HARDCORE:
			SaveSystem.delete_save()
			return false
		GameState.DEATH_RELAXED:
			for id: StringName in GameState.inventory.keys():
				var lost: int = floori(GameState.item_count(id) * b.relaxed_material_loss)
				if lost > 0:
					GameState.add_item(id, -lost)
			EventBus.message.emit(Loc.t("Du hast die Hälfte deiner Materialien verloren."), UiTheme.DANGER)
		_:
			if not GameState.inventory.is_empty():
				GameState.loot_sack = {"position": death_position + Vector3.UP * 0.5, "items": GameState.inventory.duplicate()}
			for id: StringName in GameState.inventory.keys():
				GameState.add_item(id, -GameState.item_count(id))
			GameState.essence *= 1.0 - b.death_essence_loss
			for instance: GuInstance in GameState.gu:
				instance.satiety = 0.0
				instance.starved_time = 0.0
			EventBus.message.emit(Loc.t("Deine Materialien liegen im Beutesack am Todesort. Deine Gu hungern – füttere sie."), UiTheme.DANGER)
	return true


static func description(mode: StringName) -> String:
	match mode:
		GameState.DEATH_HARDCORE:
			return Loc.t("Hardcore – dein Weg endet hier. Der Spielstand ist gelöscht.")
		GameState.DEATH_RELAXED:
			return Loc.t("Du erwachst am Lagerfeuer.")
	return Loc.t("Du erwachst am Lagerfeuer. Hol dir deinen Beutesack zurück!")
