class_name DuelRewards
extends RefCounted
## Belohnung für ein gewonnenes Duell: Ursteine (der erste Sieg mehr) und einmal pro Tag mit Chance einer seiner Gu, der wild zurückbleibt.

const STONE_ITEM: StringName = &"kristall"


static func grant(master: GuMaster) -> void:
	var b: BalanceData = Balance.values
	GameState.duels_won += 1
	var key: String = String(master.data.id)
	var last_day: int = GameState.last_duel_day if key == "gu_yue" else int(GameState.duel_days.get(key, 0))
	if last_day == GameState.day:
		EventBus.message.emit(Loc.t("Heute gibt es keinen Lohn mehr – komm morgen wieder."), UiTheme.MUTED)
		return
	if key == "gu_yue":
		GameState.last_duel_day = GameState.day
	else:
		GameState.duel_days[key] = GameState.day
	# Höherrangige Meister zahlen mehr (Rang × Grundlohn).
	var stones: int = (b.duel_first_win_stones if GameState.duels_won == 1 else b.duel_reward_stones) * maxi(1, master.rank - 1)
	GameState.add_item(STONE_ITEM, stones)
	EventBus.message.emit(Loc.t("Lohn des Siegers: %d %s") % [stones, Loc.t(DataRegistry.item(STONE_ITEM).display_name)], Color(0.6, 1.0, 0.6))
	if randf() < b.duel_gu_drop_chance:
		drop_gu(master)


## Einer seiner Gu (ohne Angabe ein zufälliger) entkommt und bleibt wild neben ihm zurück (muss verfeinert werden).
## key: eindeutige ID des wilden Gu, sonst nach Duellzahl.
static func drop_gu(master: GuMaster, instance: GuInstance = null, key: String = "") -> WildGu:
	if master.gu_list.is_empty():
		return null
	if instance == null:
		instance = master.gu_list[randi() % master.gu_list.size()]
	var wild := WildGu.new()
	wild.setup(StringName(key if key != "" else "duell_%s_%d" % [instance.gu_id, GameState.duels_won]), DataRegistry.gu(instance.gu_id))
	master.get_parent().add_child(wild)
	wild.global_position = master.global_position + Vector3(1.2, 0.8, 0.0)
	EventBus.message.emit(Loc.t("%s entgleitet ihm und bleibt wild zurück – verfeinere ihn!") % Loc.t(DataRegistry.gu(instance.gu_id).display_name), Color(1.0, 0.85, 0.4))
	return wild
