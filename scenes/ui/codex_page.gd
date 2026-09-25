class_name CodexPage
extends RefCounted
## Seite „Lexikon" im Gu-Menü: alle Gu der sterblichen Welt nach Pfaden und Familien, dazu Hilfs- und Körper-Gu.
## Bekannte Gu mit Name und Beschreibung, unbekannte als „???" (Codex). Ein RichTextLabel statt hunderter Labels,
## damit die Seite auch am Handy schnell aufgebaut ist.

const UNKNOWN: Color = Color(0.45, 0.45, 0.5)


static func build() -> Control:
	Codex.sync_owned()
	var column := VBoxContainer.new()
	column.add_child(UiTheme.label(Loc.t("Gu-Lexikon · bekannt: %d / %d") % [Codex.known_count(), Codex.total()], 22, UiTheme.ACCENT))
	column.add_child(UiTheme.label(Loc.t("Ein Gu wird bekannt, sobald du ihn besitzt, ihn wild aus der Nähe siehst oder ein Gu-Meister ihn gegen dich einsetzt."), 15, UiTheme.MUTED))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.selection_enabled = false
	text.add_theme_font_size_override(&"normal_font_size", 16)
	text.add_theme_font_size_override(&"bold_font_size", 18)
	text.text = _families_text() + _support_text() + _body_text()
	column.add_child(text)
	return column


static func _families_text() -> String:
	var system: GuSystemData = DataRegistry.gu_system()
	var by_path: Dictionary[StringName, Array] = {}
	for resource: Resource in DataRegistry.all(&"families"):
		var family: GuFamilyData = resource as GuFamilyData
		if not by_path.has(family.path):
			by_path[family.path] = []
		by_path[family.path].append(family)
	var paths: Array = by_path.keys()
	paths.sort_custom(func(a: StringName, b: StringName) -> bool: return Loc.t(system.path_name(a)) < Loc.t(system.path_name(b)))
	var out: String = ""
	for path: StringName in paths:
		out += "\n[b][color=#%s]%s[/color][/b]\n" % [system.path_color(path).to_html(false), _escape(Loc.t(system.path_name(path)))]
		for family: GuFamilyData in by_path[path]:
			out += "[b]%s[/b] [color=#%s]· %s[/color]\n" % [_escape(Loc.t(family.display_name)), UiTheme.MUTED.to_html(false), _escape(Loc.t(family.role))]
			for member: GuData in family.members:
				out += _line(member.id, member.rank, Loc.t(member.display_name), Loc.t(member.description))
	return out


static func _support_text() -> String:
	var system: GuSystemData = DataRegistry.gu_system()
	var list: Array[Resource] = DataRegistry.all(&"support")
	list.sort_custom(func(a: Resource, b: Resource) -> bool: return (a as SupportGuData).rank < (b as SupportGuData).rank)
	var out: String = "\n[b][color=#%s]%s[/color][/b]\n" % [UiTheme.ACCENT.to_html(false), _escape(Loc.t("Hilfs-Gu"))]
	for resource: Resource in list:
		var support: SupportGuData = resource as SupportGuData
		var effect: String = "%s · %s" % [Loc.t(system.path_name(support.path)), Loc.t(support.effect_text)]
		out += _line(support.id, support.rank, Loc.t(support.display_name), effect)
	return out


static func _body_text() -> String:
	var list: Array[Resource] = DataRegistry.all(&"body")
	list.sort_custom(func(a: Resource, b: Resource) -> bool: return (a as BodyGuData).rank < (b as BodyGuData).rank)
	var out: String = "\n[b][color=#%s]%s[/color][/b]\n" % [UiTheme.ACCENT.to_html(false), _escape(Loc.t("Körper-Gu"))]
	for resource: Resource in list:
		var body: BodyGuData = resource as BodyGuData
		out += _line(body.id, body.rank, Loc.t(body.display_name), PassivePage._effects_text(body))
	return out


## Eine Zeile: „R2 Name – Beschreibung" oder „R2 ???".
static func _line(id: StringName, rank: int, title: String, detail: String) -> String:
	var tag: String = "  R%d " % rank
	if not Codex.knows(id):
		return "%s[color=#%s]???[/color]\n" % [tag, UNKNOWN.to_html(false)]
	var line: String = tag + _escape(title)
	if detail != "":
		line += " [color=#%s]– %s[/color]" % [UiTheme.MUTED.to_html(false), _escape(detail)]
	return line + "\n"


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
