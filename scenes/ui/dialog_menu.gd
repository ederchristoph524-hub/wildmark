class_name DialogMenu
extends Control
## Gespräch mit einem Dorfbewohner: eine seiner Zeilen, seine Aufgabe (annehmen, Fortschritt, abgeben) und sein Tausch.

signal closed

var npc: Npc = null
var _column: VBoxContainer = null
var _line: String = ""


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", 10)
	panel.add_child(_column)
	if not npc.type.lines.is_empty():
		_line = npc.type.lines[randi() % npc.type.lines.size()]
	refresh()


func refresh() -> void:
	for child: Node in _column.get_children():
		child.queue_free()
	_column.add_child(UiTheme.label(npc.display_title(), 26, npc.type.color.lightened(0.3)))
	if Childhood.is_child():
		_column.add_child(UiTheme.label("„%s“" % tr(Childhood.line_for(npc.quest_id)), 18))
		_column.add_child(UiTheme.button(tr("Auf Wiedersehen"), close))
		return
	_column.add_child(UiTheme.label("„%s“" % tr(_line), 18))
	if npc.quest_id != &"":
		_add_quest()
	if npc.leader and npc.sect_id != &"" and DataRegistry.has(&"sects", npc.sect_id):
		_add_sect(DataRegistry.sect(npc.sect_id))
	if npc.offers_trade:
		_add_trade()
	_column.add_child(UiTheme.button(tr("Auf Wiedersehen"), close))


func _add_quest() -> void:
	var id: StringName = npc.quest_id
	var quest: QuestData = DataRegistry.quest(id)
	var text: String = "%s: %s" % [tr(quest.display_name), tr(quest.description)]
	match Quests.state(id):
		"":
			_column.add_child(UiTheme.label(text, 17, UiTheme.ACCENT))
			var on_accept: Callable = func() -> void:
				Quests.start(id)
				refresh()
			_column.add_child(UiTheme.button(tr("Aufgabe annehmen"), on_accept))
		Quests.ACTIVE:
			_column.add_child(UiTheme.label("%s (%d/%d)" % [text, mini(Quests.current(id), Quests.needed(id)), Quests.needed(id)], 17, UiTheme.ACCENT))
			var can_turn_in: bool = Quests.is_complete(id)
			var on_turn_in: Callable = func() -> void:
				if Quests.turn_in(id):
					SectLife.on_quest_done(npc.sect_id)
				refresh()
			var button: Button = UiTheme.button(tr("Aufgabe abgeben") if can_turn_in else tr("Noch nicht erfüllt"), on_turn_in)
			button.disabled = not can_turn_in
			_column.add_child(button)
		_:
			_column.add_child(UiTheme.label(tr("Danke für deine Hilfe."), 17, UiTheme.MUTED))


## Sektenleben: beitreten oder Rang, Verdienst, Zuteilung und Spende (SectLife).
func _add_sect(sect: SectData) -> void:
	var b: BalanceData = Balance.values
	if not SectLife.is_member(sect.id):
		_column.add_child(UiTheme.label(tr("%s: %s") % [tr(sect.display_name), tr(sect.description)], 17, UiTheme.ACCENT))
		var reason: String = SectLife.join_blocked(sect)
		var on_join: Callable = func() -> void:
			SectLife.join(sect)
			refresh()
		var text: String = tr("Beitreten") if not SectLife.is_member() else tr("Beitreten (du verlässt %s)") % tr(SectLife.current_sect().display_name)
		var button: Button = UiTheme.button(text if reason == "" else reason, on_join)
		button.disabled = reason != ""
		_column.add_child(button)
		return
	var rank: SectRankData = SectLife.current_rank()
	var next: SectRankData = SectLife.next_rank()
	var progress: String = tr("nächster Rang: %s ab %d Verdienst") % [tr(next.display_name), next.merit_needed] if next != null else tr("höchster Rang")
	_column.add_child(UiTheme.label(tr("%s · Verdienst %d (%s)") % [tr(rank.display_name), GameState.sect_merit, progress], 17, rank.color))
	_column.add_child(UiTheme.label(tr("%s Täglich %d Urstein. Verdienst durch Aufgaben hier, Jagd und Spenden.") % [tr(rank.perk), SectLife.stipend()], 15, UiTheme.MUTED))
	_add_sect_task()
	var on_donate: Callable = func() -> void:
		SectLife.donate()
		refresh()
	var donate: Button = UiTheme.button(tr("Spenden: %d Urstein → %d Verdienst") % [b.sect_donation_stones, b.sect_donation_merit], on_donate)
	donate.disabled = GameState.item_count(SectLife.STONE) < b.sect_donation_stones
	_column.add_child(donate)


func _add_sect_task() -> void:
	var task: Dictionary = SectTasks.today()
	if task["done"]:
		_column.add_child(UiTheme.label(tr("Sektenauftrag für heute erledigt. Komm morgen wieder."), 16, UiTheme.MUTED))
		return
	var shown: int = mini(SectTasks.progress(task), int(task["count"]))
	_column.add_child(UiTheme.label(tr("Sektenauftrag: %s (%d/%d) – Lohn %d Urstein, %d Verdienst") % [SectTasks.text(task), shown, int(task["count"]), SectTasks.reward_stones(), Balance.values.sect_task_merit], 17, UiTheme.ACCENT))
	var on_turn_in: Callable = func() -> void:
		SectTasks.turn_in()
		refresh()
	var button: Button = UiTheme.button(tr("Auftrag abgeben") if SectTasks.is_complete(task) else tr("Auftrag läuft"), on_turn_in)
	button.disabled = not SectTasks.is_complete(task)
	_column.add_child(button)


func _add_trade() -> void:
	var refused: String = Renown.trade_refused(npc.sect_id)
	if refused != "":
		_column.add_child(UiTheme.label(refused, 17, Renown.INFAMY_COLOR))
		return
	var markup: float = Renown.trade_markup(npc.sect_id)
	var note: String = tr(" (Aufschlag für Gesuchte)") if markup > 1.0 else ""
	_column.add_child(UiTheme.label(tr("Tausch: %s") % Trade.offer_text(npc.type, markup) + note, 17))
	var reason: String = Trade.blocked_reason(npc.type, markup)
	var on_trade: Callable = func() -> void:
		Trade.trade(npc.type, markup)
		refresh()
	var button: Button = UiTheme.button(tr("Tauschen") if reason == "" else reason, on_trade)
	button.disabled = reason != ""
	_column.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()
