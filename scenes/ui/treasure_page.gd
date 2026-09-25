class_name TreasurePage
extends RefCounted
## Seite „Schatzhimmel“ im Gu-Menü: Auktion unsterblicher Gu und Killer-Move-Eingebungen, sterbliche Gu nach Rang,
## Materialien, Verkauf und Umtausch von Ursteinen (TreasureHeaven).

const RANKS: Array[int] = [5, 4, 3]

static var _rank: int = 5


static func build(refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	var info: Dictionary = TreasureHeaven.data()
	column.add_child(UiTheme.label(Loc.t(String(info.get("n", "Schatzhimmel"))), 22, TreasureHeaven.COLOR))
	column.add_child(UiTheme.label(Loc.t(String(info.get("d", ""))), 16, UiTheme.MUTED))
	if not TreasureHeaven.can_enter():
		column.add_child(UiTheme.label(Loc.t("Erst als Unsterblicher (Rang 6) findest du den Weg hinauf."), 17, UiTheme.DANGER))
		return column
	column.add_child(UiTheme.label(Loc.t("Deine Unsterblichen-Essenzsteine: %d") % TreasureHeaven.stones(), 20, TreasureHeaven.COLOR))
	_exchange(column, refresh)
	_auction(column, refresh)
	_mortal(column, refresh)
	_materials(column, refresh)
	_sales(column, refresh)
	return column


static func _exchange(column: VBoxContainer, refresh: Callable) -> void:
	var rate: int = TreasureHeaven.primeval_rate()
	var have: int = GameState.item_count(TreasureHeaven.PRIMEVAL_ITEM)
	if have < rate:
		return
	var on_exchange: Callable = func() -> void:
		var got: int = TreasureHeaven.exchange_primeval()
		EventBus.message.emit(Loc.t("%d Essenzsteine eingetauscht.") % got, TreasureHeaven.COLOR)
		refresh.call()
	column.add_child(UiTheme.button(Loc.t("Ursteine tauschen: %d → %d Essenzsteine (%d je Stein)") % [have, floori(float(have) / rate), rate], on_exchange))


static func _auction(column: VBoxContainer, refresh: Callable) -> void:
	column.add_child(UiTheme.label(Loc.t("Auktion von Tag %d") % GameState.day, 20, UiTheme.ACCENT))
	var offers: Array[ImmortalGuData] = TreasureHeaven.auction_gu()
	if offers.is_empty():
		column.add_child(UiTheme.label(Loc.t("Heute bietet niemand einen unsterblichen Gu an."), 16, UiTheme.MUTED))
	for gu: ImmortalGuData in offers:
		var price: int = TreasureHeaven.auction_price(gu.rank)
		var text: String = "%s · Rang %d · %s" % [Loc.t(gu.display_name), gu.rank, Loc.t(DataRegistry.gu_system().path_name(gu.path))]
		column.add_child(UiTheme.label(text, 18, DataRegistry.gu_system().path_color(gu.path).lerp(TreasureHeaven.COLOR, 0.35)))
		column.add_child(UiTheme.label(Loc.t(gu.description), 15))
		var effects: String = ImmortalGuPage.effects_text(gu)
		if effects != "":
			column.add_child(UiTheme.label(effects, 15, UiTheme.ESSENCE))
		var on_buy: Callable = func() -> void:
			TreasureHeaven.buy_immortal(gu)
			refresh.call()
		column.add_child(UiTheme.button(Loc.t("Ersteigern für %d Steine") % price, on_buy))
	for move: ImmortalKillerData in TreasureHeaven.auction_killers():
		column.add_child(UiTheme.label(Loc.t("Eingebung: %s") % Loc.t(move.display_name), 18, TreasureHeaven.COLOR))
		column.add_child(UiTheme.label(Loc.t(move.description), 15))
		var on_learn: Callable = func() -> void:
			TreasureHeaven.buy_killer(move)
			refresh.call()
		column.add_child(UiTheme.button(Loc.t("Eingebung kaufen für %d Steine") % TreasureHeaven.killer_price(), on_learn))


static func _mortal(column: VBoxContainer, refresh: Callable) -> void:
	column.add_child(UiTheme.label(Loc.t("Sterbliche Gu"), 20, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Was Sterbliche ein Leben lang suchen, liegt hier für eine Handvoll Steine. Ein Unsterblicher trägt sie zu Dutzenden – als Glieder seiner Killer Moves."), 15, UiTheme.MUTED))
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	for rank: int in RANKS:
		var on_rank: Callable = func() -> void:
			_rank = rank
			refresh.call()
		var mark: String = " ✓" if rank == _rank else ""
		tabs.add_child(UiTheme.button(Loc.t("Rang %d · %d Steine%s") % [rank, TreasureHeaven.mortal_price(rank), mark], on_rank))
	var held: Dictionary = ImmortalGu.held_families()
	for gu: GuData in TreasureHeaven.mortal_offers(_rank):
		var family: GuFamilyData = DataRegistry.family_of(gu.id)
		var owned: String = Loc.t(" (Familie schon in der Apertur)") if family != null and held.has(family.id) else ""
		var on_buy: Callable = func() -> void:
			TreasureHeaven.buy_mortal(gu)
			refresh.call()
		var color: Color = DataRegistry.gu_system().path_color(family.path) if family != null else UiTheme.TEXT
		var button: Button = UiTheme.button("%s%s" % [Loc.t(gu.display_name), owned], on_buy, 44.0)
		button.add_theme_color_override(&"font_color", color.lerp(UiTheme.TEXT, 0.4))
		column.add_child(button)


static func _materials(column: VBoxContainer, refresh: Callable) -> void:
	column.add_child(UiTheme.label(Loc.t("Materialien"), 20, UiTheme.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)
	for key: Variant in TreasureHeaven.materials():
		var id := StringName(String(key))
		var item: ItemData = DataRegistry.item(id)
		if item == null:
			continue
		var on_buy: Callable = func() -> void:
			TreasureHeaven.buy_material(id)
			refresh.call()
		grid.add_child(UiTheme.button(Loc.t("%s · %d (hast %d)") % [Loc.t(item.display_name), int(TreasureHeaven.materials()[key]), GameState.item_count(id)], on_buy, 44.0))


static func _sales(column: VBoxContainer, refresh: Callable) -> void:
	var any: bool = false
	for key: Variant in TreasureHeaven.sales():
		var id := StringName(String(key))
		var count: int = GameState.item_count(id)
		var item: ItemData = DataRegistry.item(id)
		if count <= 0 or item == null:
			continue
		if not any:
			column.add_child(UiTheme.label(Loc.t("Verkaufen"), 20, UiTheme.ACCENT))
			any = true
		var on_sell: Callable = func() -> void:
			TreasureHeaven.sell(id)
			refresh.call()
		column.add_child(UiTheme.button(Loc.t("%s verkaufen: +%d Steine (hast %d)") % [Loc.t(item.display_name), int(TreasureHeaven.sales()[key]), count], on_sell, 44.0))
