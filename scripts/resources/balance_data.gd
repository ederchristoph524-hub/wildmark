class_name BalanceData
extends Resource
## Alle Balancing-Konstanten aus docs/FORMELN.md und docs/KAMPFSYSTEM.md an einer Stelle (Startwerte).

@export_group("Zeit")
## Ein Spieltag in Sekunden Echtzeit (GDD: 20 min).
@export var day_length: float = 1200.0
## Davon Nacht am Ende des Tages (GDD: 7 min).
@export var night_length: float = 420.0
## Tageszeit beim Spielstart (0–1, 0 = Morgen).
@export var start_time_of_day: float = 0.05

@export_group("Apertur und Uressenz")
@export var essence_base: float = 25.0
@export var essence_rank_growth: float = 3.2
@export var essence_stage_bonus: float = 0.55
@export var regen_divisor: float = 88.0
@export var regen_apt_factor: float = 0.55
## Anteil der Kapazität, den ein gegessener Urstein auffüllt.
@export var stone_essence_fraction: float = 0.5
## Dauer des Urstein-Essens (KAMPFSYSTEM: 2 s, verwundbar).
@export var stone_eat_time: float = 2.0

@export_group("Talent")
## Auswürfeln wie im Prototyp (rollAptitude): Grad, Schwelle in Prozent (kumulativ), Talentwert von–bis.
@export var talent_grades: Array[String] = ["Durchbrochen", "A", "B", "C", "D"]
@export var talent_roll_thresholds: Array[float] = [0.5, 3.0, 15.0, 45.0, 100.0]
@export var talent_pct_min: Array[int] = [100, 80, 60, 40, 20]
@export var talent_pct_max: Array[int] = [100, 99, 79, 59, 39]

@export_group("Kultivierung")
@export var wall_base: float = 1.6
@export var wall_per_stage: float = 0.5
## Anteil der Kapazität, der pro Sekunde Meditation in die Wand fließt.
@export var meditation_burn: float = 0.09
## Gegner in diesem Umkreis verhindern Meditation.
@export var meditation_danger_radius: float = 14.0
## Auf der Höchststufe sammelt Kultivieren Uressenz schneller (für den Durchbruch).
@export var meditation_peak_regen_mult: float = 2.5
## So lange stürmt die Essenz beim Durchbruch gegen die Wand (sichtbar, durch Treffer unterbrechbar).
@export var breakthrough_ritual_time: float = 3.0
## An einer Geisterquelle verfeinert Kultivieren die Wand so viel schneller und sammelt mehr Uressenz.
@export var spirit_spring_mult: float = 2.0
@export var stage_max_hp: float = 12.0
@export var stage_damage: float = 1.5
@export var breakthrough_min_essence: float = 0.9
@export var breakthrough_fail_keep: float = 0.4
@export var breakthrough_hp_per_rank: float = 15.0
@export var breakthrough_damage: float = 3.0
@export var max_stage: int = 3

@export_group("Gu-Stärke")
@export var gu_rank_growth: float = 1.48
@export var gu_fit_below: float = 0.22
@export var gu_fit_min: float = 0.25
@export var gu_fit_above: float = 0.12
@export var gu_fit_cost_above: float = 0.85

@export_group("Gu-Haltung")
## Hunger pro Spieltag für Rang-1-Gu (GDD: etwa einmal Füttern pro Spieltag).
@export var hunger_per_day: float = 85.0
@export var hunger_rank_divisor: float = 1.28
@export var satiety_max: float = 100.0
## Ab dieser Sättigung (und darunter) gilt ein Gu als hungrig.
@export var satiety_hungry: float = 30.0
@export var hungry_effect: float = 0.8
## So lange (in Spieltagen) darf ein Gu ausgehungert sein, bevor er stirbt.
@export var starve_days: float = 1.0
@export var feed_growth: float = 1.45
@export var capacity_base: int = 3
@export var capacity_per_rank: int = 2
@export var capacity_apt_divisor: int = 25

@export_group("Verfeinerung")
## Grundchance nach Rangabstand d = 0 (oder kleiner), 1, 2, 3, sonst letzter Wert.
@export var refine_chances: Array[float] = [0.95, 0.60, 0.30, 0.12, 0.04]
@export var refine_apt_base: float = 0.6
@export var refine_apt_divisor: float = 250.0
@export var refine_min: float = 0.02
@export var refine_max: float = 0.98
@export var refine_cost_base: float = 12.0
@export var refine_cost_growth: float = 1.8
## Wilde Gu mit mehr Rängen über dir lassen sich nicht verfeinern.
@export var refine_max_rank_gap: int = 3

@export_group("Spieler")
@export var player_base_hp: float = 100.0
@export var player_base_damage: float = 8.0
@export var walk_speed: float = 5.5
@export var acceleration: float = 40.0
@export var jump_velocity: float = 6.5
@export var double_jump_velocity: float = 6.5
@export var glide_fall_speed: float = 2.0
@export var gravity: float = 18.0
@export var dash_speed: float = 17.0
@export var dash_time: float = 0.2
@export var dash_invulnerable: float = 0.25
@export var dash_cooldown: float = 1.2
@export var hit_invulnerable: float = 0.5
@export var fist_range: float = 2.2
@export var fist_cooldown: float = 0.5
@export var fist_knockback: float = 3.0
## Soft-Lock: Ziele in dieser Entfernung und diesem Winkel (Grad) zur Blickrichtung.
@export var target_range: float = 22.0
@export var target_angle: float = 70.0
## Obergrenze aller Schadensreduktionen (KAMPFSYSTEM: 60 %).
@export var max_damage_reduction: float = 0.6
## Heilung pro Beere beim Essen im Inventar.
@export var berry_heal: float = 12.0
@export var meat_heal: float = 25.0

@export_group("Killer Moves")
@export var killer_cost_mult: float = 2.0
## Obergrenze für den Gesamtschaden eines Killer Moves auf ein Ziel (× Grundschaden, inkl. damage_mult), je Stufe
## (Index = min_rank − 1): Zonen zählen mit allen Takten, zielsuchende Geschosse alle, andere höchstens drei.
## Stärkere Einträge werden gleichmäßig gedämpft – ein Killer Move ist etwa drei bis vier normale Gu-Einsätze wert.
@export var killer_total_cap: Array[float] = [7.0, 7.0, 10.0, 10.0, 15.0]
@export var insight_base: float = 0.15
@export var insight_max: float = 0.5
@export var insight_window: float = 2.0
@export var insight_pair_cooldown: float = 30.0
@export var killer_radius: float = 6.0

@export_group("Zustände")
@export var freeze_time: float = 2.0
## Abnehmende Wirkung von Betäubung und Einfrieren: jede weitere Kontrolle in Folge wirkt nur noch so stark
## (0,5 → 100 %, 50 %, 25 % …); nach cc_reset_time ohne Kontrolle wieder voll. Verhindert Dauer-Festsetzen.
@export var cc_diminish: float = 0.5
@export var cc_reset_time: float = 3.0
@export var discharge_damage: float = 25.0
@export var discharge_radius: float = 2.0
@export var discharge_stun: float = 0.5
@export var wound_bonus: float = 0.3
@export var cut_wound_chance: float = 0.2
## Licht blendet Nacht- und Schattenwesen so lange.
@export var light_blind_time: float = 2.0
## Rückstoß als einmaliger Geschwindigkeitsstoß (m/s je Rückstoß-Punkt); die normale Bremsung stoppt ihn
## (bei 30 m/s² fliegt ein Ziel mit Rückstoß 1 etwa 2 m). Mehrere Treffer im selben Moment höchstens bis knockback_max_speed.
@export var knockback_force: float = 11.0
@export var knockback_max_speed: float = 18.0
@export var status_tick: float = 0.5
## Multiplikatoren der Merkmale (Texte in gu_system.json → merkmale).
## effect = Wirkung, cost = Essenzkosten, cooldown, hunger, fail = Versagenschance, stacks = zusätzliche Stapel.
@export var trait_rules: Dictionary[StringName, Dictionary] = {
	&"genuegsam": {"hunger": 0.5},
	&"gierig": {"hunger": 1.5, "effect": 1.15},
	&"flink": {"cooldown": 0.8},
	&"sparsam": {"cost": 0.8},
	&"wild": {"effect": 1.25, "fail": 0.1},
	&"zaeh": {"no_starve": true},
	&"scheu": {"catch": 0.7, "upgrade": 0.15},
	&"dao": {"dao": 2.0},
	&"reizbar": {"stacks": 1, "cost": 1.15},
	&"glaenzend": {"effect": 1.3, "glow": true},
}

@export_group("Passive Gu")
## Unterhalt je Rang des Hilfs-Gu pro Sekunde. FORMELN.md nennt 0,55 – das übersteigt auf Rang 1 die
## gesamte Regeneration (ca. 0,2/s) und macht jeden Hilfs-Gu unbrauchbar. Startwert daher deutlich niedriger.
@export var support_upkeep_per_rank: float = 0.05
## Dauerhafte Gu ohne Unterhalt (Prototyp: PERM).
@export var upkeep_free: Array[StringName] = [&"hoffnung", &"bohr"]
## Nach leerer Apertur wirken Hilfs-Gu erst wieder ab diesem Füllstand.
@export var passive_restart_fraction: float = 0.08
## Sichtweite von Namensschildern und wilden Gu (Signal-Gu verdoppelt sie).
@export var detection_range: float = 26.0

@export_group("Dorf und Quests")
## Quests im Klan-Dorf (Texte in quests.json): Bedingung und Belohnung.
## type: item (Gegenstand abgeben), kills (seit Annahme), built (Bauteile gesamt), area (Gebiet besucht), day (Spieltag).
@export var quest_rules: Dictionary[StringName, Dictionary] = {
	&"holz": {"type": &"item", "item": &"holz", "count": 10, "reward": {&"kristall": 3, &"beeren": 5}},
	&"bau": {"type": &"built", "count": 5, "reward": {&"kristall": 4, &"fell": 2}},
	&"j10": {"type": &"kills", "count": 10, "reward": {&"kristall": 5, &"wildfell": 2}},
	&"ero": {"type": &"area", "area": "Aschefeld", "count": 1, "reward": {&"kristall": 6, &"glutasche": 3}},
}
## Umkreis des Dorfes, in dem keine Bestien erscheinen.
@export var village_safe_radius: float = 32.0
## Beim Schlafen im Bett: so viel Tageszeit wird übersprungen (bis zum Morgen).
@export var bed_heal: float = 1.0

@export_group("Ranggaben")
## Gift springt beim Tod auf das nächste Ziel in diesem Umkreis über.
@export var poison_spread_radius: float = 5.0
## Tarnung: so lange verlieren Bestien, die dich jagten, die Spur; erster Treffer aus der Tarnung × stealth_strike_mult.
@export var stealth_lose_time: float = 1.5
@export var stealth_strike_mult: float = 1.6

@export_group("Materialquellen")
## Zusätzliche Beute nach dem Fundort (src) der Materialien in materialien.json:
## beast = Bestien (Vierbeiner, Spinnen, Käfer), poison = giftige Bestien, fly = fliegende Bestien, skeleton = Skelette.
@export var material_drops: Dictionary[StringName, Dictionary] = {
	&"wildfell": {"filter": &"beast", "chance": 0.35},
	&"windfeder": {"filter": &"fly", "chance": 0.5},
	&"knochenmehl": {"filter": &"skeleton", "chance": 0.5},
	&"giftdrüse": {"filter": &"poison", "chance": 0.3},
}

@export_group("Wirkformen")
@export var projectile_speed: float = 24.0
@export var fast_projectile_speed: float = 48.0
@export var projectile_radius: float = 0.35
@export var beam_width: float = 0.9
@export var stab_angle: float = 70.0
@export var heal_over_time: bool = true
@export var leap_forward_speed: float = 9.0
## Zähmen: Größenklasse der Ränge (Rang 1 nur kleine Bestien bis zu diesem Radius).
@export var tame_max_radius_r1: float = 0.4
@export var companion_follow_distance: float = 3.0

@export_group("Gegner")
@export var aggro_radius: float = 13.0
@export var leash_radius: float = 30.0
@export var attack_range: float = 1.7
@export var attack_telegraph: float = 0.55
@export var attack_cooldown: float = 1.4
## Prototyp-Einheiten → Meter.
@export var enemy_speed_scale: float = 1.0
@export var enemy_size_scale: float = 2.0
@export var enemy_projectile_speed: float = 14.0
@export var charge_speed_mult: float = 3.2
@export var spawn_minion_interval: float = 7.0
@export var heal_amount: float = 8.0
@export var armor_front_reduction: float = 0.5
@export var explode_radius: float = 2.5
## Entfernung vom Lager, ab der Zone 1 bzw. 2 beginnt.
@export var zone_radii: Array[float] = [45.0, 85.0]
@export var night_damage_mult: float = 1.25
@export var night_spawn_mult: float = 1.8
@export var max_enemies: int = 14
@export var spawn_interval: float = 5.0
@export var spawn_min_distance: float = 22.0
@export var spawn_max_distance: float = 40.0
@export var despawn_distance: float = 70.0
@export var pickup_radius: float = 1.6

@export_group("Zehn Extreme Physiques")
## Extreme Physiques verfeinern ihre Aperturwand von selbst: Anteil der Meditationsgeschwindigkeit, ohne Essenz zu verbrauchen.
@export var physique_auto_wall: float = 0.2
## Gu der zugehörigen Familien wirken so viel stärker („massive Verstärkung ihres Pfades“).
@export var physique_path_power: float = 1.3
@export var physique_crit_mult: float = 1.75
## Wirkung je Physique (ID aus fortschritt.json PHYS). Schlüssel wie bei Körper- und Hilfs-Gu:
## grundschaden, max_hp, schaden_erlitten (negativ = weniger), cooldown_mult, essence_cost_mult, hunger_mult,
## move_speed_mult, insight_mult (Faktoren); hp_regen (/s), capacity_add, refine_bonus, crit_chance, thorns (Zuschläge);
## immune (Zustände), on_hit_status (Zustand bei jedem Treffer), families (Pfad-Verstärkung).
@export var physique_rules: Dictionary[StringName, Dictionary] = {
	&"strength": {"families": [&"wirbel"], "grundschaden": 5.0, "max_hp": 50.0},
	&"wisdom": {"families": [], "insight_mult": 2.5, "refine_bonus": 0.15},
	&"dream": {"families": [], "essence_cost_mult": 0.6},
	&"moon": {"families": [&"mondlicht"], "cooldown_mult": 0.5},
	&"ice": {"families": [&"frost", &"sklaverei"], "schaden_erlitten": -0.3, "immune": [&"gift", &"brand"]},
	&"forest": {"families": [&"blatt"], "hp_regen": 2.5, "harvest_mult": 2.0},
	&"lightning": {"families": [&"flamme", &"blitz"], "move_speed_mult": 1.3, "on_hit_status": &"brand"},
	&"earth": {"families": [&"haut"], "max_hp": 120.0, "thorns": 6.0},
	&"universe": {"families": [&"schritt"], "capacity_add": 4.0, "hunger_mult": 0.5},
	&"metal": {"families": [&"haut"], "grundschaden": 6.0, "crit_chance": 0.3},
}

@export_group("Reisen")
## Reisezeit in Spieltagen innerhalb einer Region und über eine Regionalmauer.
@export var travel_days_region: float = 0.3
@export var travel_days_wall: float = 1.0

@export_group("Slots im Kampf")
## Im Kampf: Gegner näher als combat_radius oder Treffer/Gu-Einsatz vor weniger als combat_linger Sekunden.
@export var combat_radius: float = 12.0
@export var combat_linger: float = 5.0
## Slot-Wechsel im Kampf braucht so lange Kanalisierung (KAMPFSYSTEM: 3 s).
@export var slot_switch_channel: float = 3.0

@export_group("Dao-Markierungen (FORMELN.md, Pfade)")
## Markierungen je Gu-Einsatz, je Killer Move (für beide Pfade), beim Verfeinern (Basis + je Rang) und je Erbe.
@export var dao_per_use: float = 1.0
@export var dao_per_killer: float = 3.0
@export var dao_refine_base: float = 4.0
@export var dao_refine_per_rank: float = 3.0
@export var dao_inheritance: float = 30.0
## Kosten: max(dao_cost_min, 1 − Stufe × dao_cost_per_attain + Konflikt × dao_conflict_cost).
@export var dao_cost_per_attain: float = 0.09
@export var dao_cost_min: float = 0.4
@export var dao_conflict_cost: float = 0.5
## Abklingzeit: max(dao_cd_min, 1 − Stufe × dao_cd_per_attain).
@export var dao_cd_per_attain: float = 0.07
@export var dao_cd_min: float = 0.5
## Konflikt = min(dao_conflict_max, gegensätzliche / (eigene + 1 + gegensätzliche) × dao_conflict_scale).
@export var dao_conflict_max: float = 0.45
@export var dao_conflict_scale: float = 0.6

@export_group("Sektenleben")
## Tägliche Zuteilung an Urstein im Eintrittsrang (× SectRankData.stipend_mult).
@export var sect_stipend: int = 4
## Verdienst: je abgegebener Aufgabe in einer Siedlung der Sekte, je Rang einer erlegten Bestie, je Spende.
@export var sect_merit_quest: int = 25
@export var sect_merit_per_beast_rank: int = 1
@export var sect_donation_stones: int = 10
@export var sect_donation_merit: int = 8
## Sektenaufträge (SectTasks): Bestien (+ 2 je Rang), Material (+ 1 je Rang), Lohn in Urstein (+ je Sektenrang) und Verdienst.
@export var sect_task_hunt: int = 6
@export var sect_task_deliver: int = 4
@export var sect_task_stones: int = 8
@export var sect_task_stones_per_rank: int = 4
@export var sect_task_merit: int = 30

@export_group("Ruf und Wanderer")
## Berüchtigtheit: ab renown_wanted Kopfgeld (Jäger, Aufschlag, keine rechtschaffene Sekte), ab renown_demon kein
## Handel und kein Duell in rechtschaffenen Siedlungen; dämonische Sekten erst ab renown_demonic_join. Verblasst täglich.
@export var renown_wanted: int = 40
@export var renown_demon: int = 80
@export var renown_demonic_join: int = 15
@export var renown_decay: int = 2
@export var renown_wanted_markup: float = 1.5
## Ansehen (bzw. Berüchtigtheit in dämonischen Sekten): Verdienst-Faktor ab „Geachtet" und „Held".
@export var renown_famous: int = 30
@export var renown_hero: int = 80
@export var renown_merit_famous: float = 1.25
@export var renown_merit_hero: float = 1.5
## Taten: Rechtschaffene überfallen, ausrauben, töten; Dämonen töten; Besiegte verschonen.
@export var renown_attack: int = 4
@export var renown_rob: int = 6
@export var renown_kill_righteous: int = 15
@export var renown_kill_demonic: int = 8
@export var renown_spare: int = 3
## Wandernde Gu-Meister (gebiete.json → wanderer): Angriffsreichweite, Vorwarnung, Aufgabe ab Lebensanteil (wie Duell),
## Verfolgung bis wanderer_leash, Geldbeutel je Rang (± 30 %), Chance auf einen zweiten Gu beim Töten, Nachschub.
@export var wanderer_aggro: float = 14.0
@export var wanderer_warning: float = 1.2
@export var wanderer_leash: float = 40.0
@export var wanderer_purse: int = 6
@export var wanderer_second_gu: float = 0.3
@export var wanderer_respawn: float = 180.0
## Kopfgeldjäger erscheinen morgens so weit entfernt (einer, als Dämon zwei).
@export var bounty_distance: float = 55.0

@export_group("Gu-Meister und Duell")
## Kultivierung des Dorf-Gu-Meisters (Rang 2, Stufe 1, durchschnittliches Talent).
@export var master_rank: int = 2
@export var master_stage: int = 1
@export var master_apt: float = 60.0
## Lebensfaktor erfahrener Gu-Meister je Rang (Index = Rang − 1; darüber gilt der letzte Wert): Schutz-Gu und
## Kampferfahrung. Ohne ihn endet ein Duell auf Rang 5 nach einer Sekunde (tools/balance_probe.gd -- --masters).
@export var master_hp_rank_mult: Array[float] = [1.0, 1.5, 1.6, 2.2, 6.0]
## Wie oft die KI neu entscheidet (Sekunden) – kürzer = schwerer.
@export var master_think_interval: float = 0.35
## Ausholen vor Angriffs-Gu: Richtung steht fest, seitliches Ausweichen hilft (KAMPFSYSTEM: keine Treffer ohne Vorwarnung).
@export var master_cast_windup: float = 0.45
@export var master_preferred_range: float = 8.0
## Killer Moves der Meister: höchstens alle master_killer_cooldown Sekunden, nur bis zu dieser Entfernung,
## mindestens so lange Ausholzeit (zusätzlich zu master_cast_windup) – genug Zeit zum Ausweichen.
@export var master_killer_cooldown: float = 14.0
@export var master_killer_range: float = 11.0
@export var master_killer_windup: float = 1.0
@export var master_speed: float = 4.6
@export var master_fist_cooldown: float = 1.3
## Unter diesem Lebensanteil greift er zu Schild oder Heilung.
@export var master_defend_ratio: float = 0.7
@export var duel_countdown: float = 3.0
## Der Gu-Meister gibt bei 25 % Leben auf, der Spieler unterliegt bei 15 %.
@export var duel_surrender_ratio: float = 0.25
@export var duel_player_floor: float = 0.15
## Entfernt sich der Spieler weiter vom Gu-Meister, endet das Duell (Wanderer: wanderer_leash).
@export var duel_leash: float = 26.0
@export var duel_reward_stones: int = 4
@export var duel_first_win_stones: int = 10
## Chance, dass einer seiner Gu nach einem Sieg wild zurückbleibt (einmal pro Tag).
@export var duel_gu_drop_chance: float = 0.35

@export_group("Tod und Speichern")
@export var death_essence_loss: float = 0.3
@export var relaxed_material_loss: float = 0.5
@export var autosave_interval: float = 300.0
@export var respawn_delay: float = 2.5
