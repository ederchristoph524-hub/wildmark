class_name Trade
extends RefCounted
## Tausch mit NPCs nach ihrem Angebot aus gegner.json (NPCTYPE → trade).


## Preis eines Tauschguts mit Aufschlag (Renown.trade_markup).
static func cost(npc: NpcTypeData, item: StringName, markup: float = 1.0) -> int:
	return ceili(npc.trade_give[item] * markup)


static func blocked_reason(npc: NpcTypeData, markup: float = 1.0) -> String:
	for item: StringName in npc.trade_give:
		if GameState.item_count(item) < cost(npc, item, markup):
			return Loc.t("Es fehlt: %s (%d/%d)") % [Loc.t(DataRegistry.item(item).display_name), GameState.item_count(item), cost(npc, item, markup)]
	if npc.trade_gu > 0 and GameState.held_count() >= PassiveGu.capacity():
		return Loc.t("Deine Apertur fasst keine weiteren Gu.")
	return ""


static func offer_text(npc: NpcTypeData, markup: float = 1.0) -> String:
	var give: PackedStringArray = []
	for item: StringName in npc.trade_give:
		give.append("%d %s" % [cost(npc, item, markup), Loc.t(DataRegistry.item(item).display_name)])
	var get_parts: PackedStringArray = []
	for item: StringName in npc.trade_get:
		get_parts.append("%d %s" % [npc.trade_get[item], Loc.t(DataRegistry.item(item).display_name)])
	if npc.trade_gu > 0:
		get_parts.append(Loc.t("einen zufälligen Gu") if npc.trade_gu_rank <= 1 else Loc.t("einen zufälligen Gu (Rang %d)") % npc.trade_gu_rank)
	return Loc.t("%s gegen %s") % [", ".join(give), ", ".join(get_parts)]


static func trade(npc: NpcTypeData, markup: float = 1.0) -> bool:
	if blocked_reason(npc, markup) != "":
		return false
	for item: StringName in npc.trade_give:
		GameState.take_item(item, cost(npc, item, markup))
	for item: StringName in npc.trade_get:
		GameState.add_item(item, npc.trade_get[item])
	for i: int in npc.trade_gu:
		_give_random_gu(npc.trade_gu_rank)
	EventBus.message.emit(Loc.t("Getauscht"), Color(0.85, 0.75, 0.5))
	return true


## Ein Gu des Rangs einer Familie, die der Spieler noch nicht besitzt (sonst irgendeiner dieses Rangs).
static func _give_random_gu(rank: int = 1) -> void:
	var owned: Array[StringName] = []
	for instance: GuInstance in GameState.gu:
		owned.append(DataRegistry.gu(instance.gu_id).family)
	var options: Array[GuData] = []
	for resource: Resource in DataRegistry.all(&"families"):
		var family: GuFamilyData = resource as GuFamilyData
		if family.id not in owned and family.member_for_rank(rank) != null:
			options.append(family.member_for_rank(rank))
	if options.is_empty():
		options.assign(DataRegistry.all_gu().filter(func(g: GuData) -> bool: return g.rank == rank))
	var gu: GuData = options[randi() % options.size()]
	GameState.add_gu(GuInstance.create(gu.id, GuRefining.roll_trait()))
	EventBus.message.emit(Loc.t("Du erhältst: %s") % Loc.t(gu.display_name), Color(1.0, 0.85, 0.3))
