class_name SectLife
extends RefCounted
## Leben in einer Sekte oder einem Klan (GDD: Soziales): beitreten beim Oberhaupt einer Siedlung, Verdienst durch
## Aufgaben, Jagd und Spenden, Aufstieg durch die Ränge aus fraktionen.json → SECTRANKS mit Geschenken, tägliche
## Zuteilung an Urstein, ab dem dritten Rang das Signatur-Gu der Sekte. Zustand in GameState (sect, sect_merit …).

const STONE: StringName = &"kristall"
## Ab diesem Rang-Index schenkt die Sekte ihr Signatur-Gu (Kernschüler).
const SIGNATURE_RANK: int = 2
const COLOR: Color = Color(0.95, 0.8, 0.4)


static func is_member(sect_id: StringName = &"") -> bool:
	return GameState.sect != &"" and (sect_id == &"" or GameState.sect == sect_id)


static func current_sect() -> SectData:
	return DataRegistry.sect(GameState.sect) if GameState.sect != &"" else null


static func current_rank() -> SectRankData:
	return DataRegistry.progression().sect_rank(GameState.sect_rank)


## Nächster Rang oder null auf dem höchsten.
static func next_rank() -> SectRankData:
	var ranks: Array[SectRankData] = DataRegistry.progression().sect_ranks
	return ranks[GameState.sect_rank + 1] if GameState.sect_rank + 1 < ranks.size() else null


## Leer = Beitritt möglich, sonst der Grund.
static func join_blocked(sect: SectData) -> String:
	if sect == null:
		return Loc.t("Hier gibt es nichts, dem du beitreten könntest.")
	if is_member(sect.id):
		return Loc.t("Du gehörst schon dazu.")
	if sect.min_rank > GameState.rank:
		return Loc.t("Erst ab %s.") % Loc.t(DataRegistry.progression().rank_name(sect.min_rank))
	return ""


## Tritt bei (verlässt eine andere Sekte, Verdienst dort verfällt) und erhält das Beitrittsgeschenk.
static func join(sect: SectData) -> bool:
	if join_blocked(sect) != "":
		return false
	if GameState.sect != &"":
		EventBus.message.emit(Loc.t("Du verlässt %s – dein Verdienst dort verfällt.") % Loc.t(current_sect().display_name), UiTheme.MUTED)
	GameState.sect = sect.id
	GameState.sect_merit = 0
	GameState.sect_rank = 0
	GameState.sect_stipend_day = GameState.day
	for item: StringName in sect.join_gift:
		GameState.add_item(item, sect.join_gift[item])
	EventBus.message.emit(Loc.t("Willkommen bei %s! Du bist jetzt %s.") % [Loc.t(sect.display_name), Loc.t(current_rank().display_name)], COLOR)
	return true


static func leave() -> void:
	if GameState.sect == &"":
		return
	EventBus.message.emit(Loc.t("Du verlässt %s.") % Loc.t(current_sect().display_name), UiTheme.MUTED)
	GameState.sect = &""
	GameState.sect_merit = 0
	GameState.sect_rank = 0


## Verdienst gutschreiben und Aufstiege auslösen (auch mehrere auf einmal).
static func add_merit(amount: int) -> void:
	if GameState.sect == &"" or amount <= 0:
		return
	GameState.sect_merit += amount
	var next: SectRankData = next_rank()
	while next != null and GameState.sect_merit >= next.merit_needed:
		GameState.sect_rank += 1
		_promote(next)
		next = next_rank()


static func _promote(rank: SectRankData) -> void:
	for item: StringName in rank.reward:
		GameState.add_item(item, rank.reward[item])
	EventBus.message.emit(Loc.t("Aufstieg in %s: %s") % [Loc.t(current_sect().display_name), Loc.t(rank.display_name)], rank.color)
	if GameState.sect_rank == SIGNATURE_RANK:
		_grant_signature_gu(current_sect())


## Signatur-Gu der Sekte als Geschenk (bei Familien das Mitglied deines Rangs).
static func _grant_signature_gu(sect: SectData) -> void:
	var id: StringName = sect.signature_gu
	var title: String = ""
	if DataRegistry.has_gu(id):
		var family: GuFamilyData = DataRegistry.family_of(id)
		var gu: GuData = family.member_for_rank(clampi(GameState.rank, 1, 5)) if family != null else DataRegistry.gu(id)
		GameState.add_gu(GuInstance.create(gu.id))
		title = gu.display_name
	elif DataRegistry.has(&"support", id):
		GameState.support.append(GuInstance.create(id))
		title = DataRegistry.support_gu(id).display_name
	elif DataRegistry.has(&"body", id):
		GameState.body_gu.append(id)
		title = DataRegistry.body_gu(id).display_name
	else:
		return
	EventBus.message.emit(Loc.t("Die Sekte schenkt dir ihr Gu: %s") % Loc.t(title), COLOR)
	EventBus.gu_obtained.emit(id)


## Tägliche Zuteilung (auch für verpasste Tage höchstens einmal).
static func on_new_day(day: int) -> void:
	if GameState.sect == &"" or day <= GameState.sect_stipend_day:
		return
	GameState.sect_stipend_day = day
	var amount: int = stipend()
	GameState.add_item(STONE, amount)
	EventBus.message.emit(Loc.t("Zuteilung von %s: %d Urstein") % [Loc.t(current_sect().display_name), amount], COLOR)


static func stipend() -> int:
	var rank: SectRankData = current_rank()
	return roundi(Balance.values.sect_stipend * (rank.stipend_mult if rank != null else 1.0))


static func on_enemy_killed(enemy_id: StringName, _where: Vector3) -> void:
	var data: EnemyData = DataRegistry.enemy(enemy_id)
	if data != null:
		add_merit(data.rank * Balance.values.sect_merit_per_beast_rank)


## Aufgabe bei einem Bewohner der eigenen Sekte abgegeben.
static func on_quest_done(sect_id: StringName) -> void:
	if is_member(sect_id) and sect_id != &"":
		add_merit(Balance.values.sect_merit_quest)


static func donate() -> bool:
	var b: BalanceData = Balance.values
	if GameState.sect == &"" or not GameState.take_item(STONE, b.sect_donation_stones):
		return false
	add_merit(b.sect_donation_merit)
	return true


## Kurzzeile für die Statusanzeige, leer ohne Mitgliedschaft.
static func status_line() -> String:
	if GameState.sect == &"":
		return ""
	var next: SectRankData = next_rank()
	var progress: String = "%d/%d" % [GameState.sect_merit, next.merit_needed] if next != null else str(GameState.sect_merit)
	return "%s · %s (%s)" % [Loc.t(current_sect().display_name), Loc.t(current_rank().display_name), progress]
