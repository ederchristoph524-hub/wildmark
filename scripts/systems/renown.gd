class_name Renown
extends RefCounted
## Ruf auf beiden Pfaden (GDD: Soziales). Ansehen (GameState.fame) für verschonte Gegner und erschlagene Dämonen,
## Berüchtigtheit (GameState.infamy) für Überfälle, Raub und Mord an Rechtschaffenen; sie verblasst täglich ein wenig.
## Ab „Gesucht" jagen dich Kopfgeldjäger (Wanderers), rechtschaffene Wanderer greifen an, rechtschaffene Siedlungen
## verlangen Aufschlag und nehmen dich nicht mehr auf; als „Dämon" handeln und duellieren sie gar nicht mehr.
## Dämonische Wanderer lassen Berüchtigte und Mitglieder dämonischer Sekten in Ruhe; dämonische Sekten nehmen
## nur auf, wer sich schon einen Namen gemacht hat.

const RIGHTEOUS: StringName = &"righteous"
const DEMONIC: StringName = &"demonic"
const FAME_COLOR: Color = Color(0.55, 0.85, 1.0)
const INFAMY_COLOR: Color = Color(0.95, 0.35, 0.35)


static func add_fame(amount: int, reason: String) -> void:
	if amount <= 0:
		return
	GameState.fame += amount
	EventBus.message.emit(Loc.t("%s – Ansehen +%d (%s)") % [reason, amount, title()], FAME_COLOR)


static func add_infamy(amount: int, reason: String) -> void:
	if amount <= 0:
		return
	var was_wanted: bool = is_wanted()
	GameState.infamy += amount
	EventBus.message.emit(Loc.t("%s – Berüchtigtheit +%d (%s)") % [reason, amount, title()], INFAMY_COLOR)
	if is_wanted() and not was_wanted:
		EventBus.message.emit(Loc.t("Die rechtschaffenen Klans setzen ein Kopfgeld auf dich aus!"), INFAMY_COLOR)


static func is_wanted() -> bool:
	return GameState.infamy >= Balance.values.renown_wanted


static func is_demon() -> bool:
	return GameState.infamy >= Balance.values.renown_demon


static func demonic_member() -> bool:
	var sect: SectData = SectLife.current_sect()
	return sect != null and sect.faction == DEMONIC


## Menschenhaut-Gu (Verkleidung): Rechtschaffene erkennen dich nicht, Kopfgeldjäger verlieren deine Spur.
static func disguised() -> bool:
	return PassiveGu.flag("disguise")


## Rechtschaffene Wanderer greifen an.
static func hunted_by_righteous() -> bool:
	return (is_wanted() or demonic_member()) and not disguised()


## Dämonische Wanderer lassen dich ziehen.
static func spared_by_demons() -> bool:
	return is_wanted() or demonic_member()


static func title() -> String:
	var b: BalanceData = Balance.values
	if GameState.infamy >= b.renown_demon:
		return Loc.t("Dämon")
	if GameState.infamy >= b.renown_wanted:
		return Loc.t("Gesucht")
	if GameState.fame >= b.renown_hero:
		return Loc.t("Held")
	if GameState.fame >= b.renown_famous:
		return Loc.t("Geachtet")
	if GameState.infamy >= b.renown_demonic_join:
		return Loc.t("Berüchtigt")
	return Loc.t("Unbekannt")


## Kurzzeile für die Statusanzeige, leer solange niemand von dir gehört hat.
static func status_line() -> String:
	if GameState.fame <= 0 and GameState.infamy <= 0:
		return ""
	return Loc.t("Ruf: %s · Ansehen %d · Berüchtigtheit %d") % [title(), GameState.fame, GameState.infamy]


static func faction_of(sect_id: StringName) -> StringName:
	if sect_id == &"" or not DataRegistry.has(&"sects", sect_id):
		return &""
	return DataRegistry.sect(sect_id).faction


## Aufschlag auf Tauschpreise in einer Siedlung dieser Sekte.
static func trade_markup(sect_id: StringName) -> float:
	return Balance.values.renown_wanted_markup if faction_of(sect_id) == RIGHTEOUS and is_wanted() and not disguised() else 1.0


## Leer = Handel möglich, sonst der Grund (Dämonen bekommen in rechtschaffenen Siedlungen nichts).
static func trade_refused(sect_id: StringName) -> String:
	if faction_of(sect_id) == RIGHTEOUS and is_demon() and not disguised():
		return Loc.t("„Mit Dämonen handeln wir nicht. Verschwinde!“")
	return ""


static func join_blocked(sect: SectData) -> String:
	var b: BalanceData = Balance.values
	if sect.faction == RIGHTEOUS and is_wanted():
		return Loc.t("Auf deinen Kopf ist ein Preis ausgesetzt – hier nimmt dich niemand auf.")
	if sect.faction == DEMONIC and GameState.infamy < b.renown_demonic_join:
		return Loc.t("Berüchtigtheit %d nötig – beweise erst, dass du keiner von ihnen bist.") % b.renown_demonic_join
	return ""


## Verdienst-Faktor: Ansehen zählt in rechtschaffenen Sekten, Berüchtigtheit in dämonischen.
static func merit_mult() -> float:
	var b: BalanceData = Balance.values
	var sect: SectData = SectLife.current_sect()
	if sect == null:
		return 1.0
	var standing: int = GameState.infamy if sect.faction == DEMONIC else GameState.fame
	if standing >= b.renown_hero:
		return b.renown_merit_hero
	if standing >= b.renown_famous:
		return b.renown_merit_famous
	return 1.0


static func on_new_day(_day: int) -> void:
	GameState.infamy = maxi(0, GameState.infamy - Balance.values.renown_decay)
