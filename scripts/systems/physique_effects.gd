class_name PhysiqueEffects
extends RefCounted
## Die Zehn Extremen Physiques im Spiel: Pfad-Verstärkung, Treffer-Zusätze (Krit, Entzünden), Dornen, Immunität und Wirkungstexte.
## Zahlenwerte stehen in BalanceData.physique_rules; einfache Werte fließen über PassiveGu (mult/add/body) ein.

const GRADE: StringName = &"Durchbrochen"
const CRIT_COLOR: Color = Color(1.0, 0.85, 0.3)
## Wirkungstexte je Regel-Schlüssel (Wert eingesetzt; Faktoren als Prozent-Änderung).
const LABELS: Dictionary[String, String] = {
	"grundschaden": "+%d Grundschaden",
	"max_hp": "+%d max. Leben",
	"schaden_erlitten": "%d %% weniger erlittener Schaden",
	"cooldown_mult": "Abklingzeiten −%d %%",
	"essence_cost_mult": "Gu kosten %d %% weniger Uressenz",
	"hunger_mult": "Gu hungern %d %% langsamer",
	"move_speed_mult": "+%d %% Lauftempo",
	"insight_mult": "Eingebung ×%.1f",
	"hp_regen": "heilt %.1f Leben pro Sekunde",
	"harvest_mult": "Sammeln bringt ×%.0f",
	"capacity_add": "+%d Gu-Kapazität",
	"refine_bonus": "+%d %% Verfeinerungschance",
	"crit_chance": "%d %% Chance auf kritische Treffer",
	"thorns": "Dornen: Angreifer erleiden %d Schaden",
}


static func current() -> PhysiqueData:
	return DataRegistry.progression().physique(GameState.physique) if GameState.physique != &"" else null


## Regeln einer Physique (ohne ID: die des Spielers; keine Physique = leer).
static func rule(id: StringName = &"") -> Dictionary:
	return Balance.values.physique_rules.get(GameState.physique if id == &"" else id, {})


## Zufällige Physique (beim Talentgrad „Durchbrochen“).
static func roll() -> StringName:
	var all: Array[PhysiqueData] = DataRegistry.progression().physiques
	return all[randi() % all.size()].id if not all.is_empty() else &""


## Gu der zugehörigen Pfade wirken stärker.
static func path_power(family_id: StringName) -> float:
	var families: Array = rule().get("families", [])
	return Balance.values.physique_path_power if family_id in families else 1.0


## Zustände, die dem Spieler nichts anhaben (Eisseele: Gift und Brand).
static func immune_statuses() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: Variant in rule().get("immune", []):
		result.append(StringName(str(id)))
	return result


## Treffer: kritisch (Metall-Physique oder Glückspfad) oder entzündend (Blitzglanz). Glück wirkt für jeden Wirker,
## die Physique nur beim Spieler.
static func decorate_hit(hit: HitInfo, caster: Combatant) -> void:
	if caster == null or hit.damage <= 0.0 or hit.is_crit:
		return
	var luck: float = caster.luck_chance if caster.luck_time > 0.0 else 0.0
	var physique_rule: Dictionary = rule() if caster is Player and GameState.physique != &"" else {}
	if randf() < maxf(luck, float(physique_rule.get("crit_chance", 0.0))):
		hit.damage *= Balance.values.physique_crit_mult
		hit.is_crit = true
	var burn: StringName = StringName(str(physique_rule.get("on_hit_status", "")))
	if burn != &"" and hit.status == &"":
		hit.with_status(burn, 1)


## Dornen: wer den Spieler aus der Nähe trifft, verletzt sich selbst.
static func thorns(player: Player, attacker: Combatant) -> void:
	var damage: float = float(rule().get("thorns", 0.0))
	if damage <= 0.0 or attacker.global_position.distance_to(player.global_position) > Balance.values.fist_range * 1.5:
		return
	var thorn := HitInfo.create(damage, player, player.team)
	thorn.can_react = false
	attacker.receive_hit(thorn)


## Text der Wirkungen für Menüs.
static func effect_lines(id: StringName) -> PackedStringArray:
	var lines: PackedStringArray = [Loc.t("Apertur 100 %, Wand verfeinert sich von selbst")]
	var physique_rule: Dictionary = rule(id)
	var names: PackedStringArray = []
	for family_id: Variant in physique_rule.get("families", []):
		names.append(Loc.t(DataRegistry.family(StringName(str(family_id))).display_name))
	if not names.is_empty():
		lines.append(Loc.t("%s wirken %d %% stärker") % [", ".join(names), roundi((Balance.values.physique_path_power - 1.0) * 100.0)])
	for key: String in LABELS:
		if physique_rule.has(key):
			lines.append(Loc.t(LABELS[key]) % _shown_value(key, float(physique_rule[key])))
	if physique_rule.has("immune"):
		var statuses: PackedStringArray = []
		for status_id: Variant in physique_rule["immune"]:
			statuses.append(Loc.t(DataRegistry.status(StringName(str(status_id))).display_name))
		lines.append(Loc.t("immun gegen %s") % ", ".join(statuses))
	if physique_rule.has("on_hit_status"):
		lines.append(Loc.t("Treffer lösen %s aus") % Loc.t(DataRegistry.status(StringName(str(physique_rule["on_hit_status"]))).display_name))
	return lines


## Faktoren als Prozent (0,6 → 40), Anteile als Prozent (0,3 → 30), sonst der Wert selbst.
static func _shown_value(key: String, value: float) -> float:
	if key in ["cooldown_mult", "essence_cost_mult", "hunger_mult"]:
		return roundf((1.0 - value) * 100.0)
	if key == "move_speed_mult":
		return roundf((value - 1.0) * 100.0)
	if key in ["schaden_erlitten", "refine_bonus", "crit_chance"]:
		return roundf(absf(value) * 100.0)
	return value
