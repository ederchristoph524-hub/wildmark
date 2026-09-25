class_name RecipePage
extends RefCounted
## Seite „Verschmelzen“ im Gu-Menü: alle Rezepte mit Zutaten, Material, Chance und Knopf (GuRecipes).


static func build(refresh: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_child(UiTheme.label(Loc.t("Gu verschmelzen"), 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Zwei Gu und etwas Material werden zu einem stärkeren. Misslingt es, ist nur das Material verloren."), 16, UiTheme.MUTED))
	for recipe: Dictionary in GuRecipes.all():
		column.add_child(_row(recipe, refresh))
	return column


static func _row(recipe: Dictionary, refresh: Callable) -> Control:
	var panel := PanelContainer.new()
	var row := VBoxContainer.new()
	panel.add_child(row)
	var inputs: PackedStringArray = []
	for input: StringName in recipe["inputs"]:
		inputs.append(Loc.t(GuRecipes.title(input)) + ("" if GuRecipes.owns(input) else " ✗"))
	var materials: PackedStringArray = []
	var items: Dictionary = recipe["materials"]
	for item: StringName in items:
		materials.append("%d %s (%d)" % [int(items[item]), Loc.t(DataRegistry.item(item).display_name), GameState.item_count(item)])
	row.add_child(UiTheme.label("%s = %s" % [Loc.t(GuRecipes.title(recipe["result"])), " + ".join(inputs)], 18, UiTheme.ACCENT))
	row.add_child(UiTheme.label("%s · %d %%" % [", ".join(materials), roundi(float(recipe["chance"]) * 100.0)], 15))
	if recipe["hint"] != "":
		row.add_child(UiTheme.label(Loc.t(recipe["hint"]), 15, UiTheme.MUTED))
	var reason: String = GuRecipes.blocked_reason(recipe)
	var on_fuse: Callable = func() -> void:
		GuRecipes.fuse(recipe)
		refresh.call()
	var button: Button = UiTheme.button(Loc.t("Verschmelzen") if reason == "" else reason, on_fuse)
	button.disabled = reason != ""
	row.add_child(button)
	return panel
