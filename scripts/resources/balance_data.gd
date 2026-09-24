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
@export var insight_base: float = 0.15
@export var insight_max: float = 0.5
@export var insight_window: float = 2.0
@export var insight_pair_cooldown: float = 30.0
@export var killer_radius: float = 6.0

@export_group("Zustände")
## Dauer je Zustand in Sekunden (GU_SYSTEM.md, Abschnitt 3).
@export var status_durations: Dictionary[StringName, float] = {
	&"brand": 4.0, &"nass": 6.0, &"frost": 5.0, &"ladung": 6.0, &"gift": 8.0, &"wunde": 8.0,
}
## Schaden pro Sekunde und Stapel (Brand × Rangfaktor, Gift pro Stapel).
@export var status_dps: Dictionary[StringName, float] = {&"brand": 4.0, &"gift": 2.0}
## Tempo-Änderung pro Stapel (Frost −20 %).
@export var status_speed_per_stack: Dictionary[StringName, float] = {&"frost": -0.2}
## Heilungsfaktor, solange der Zustand aktiv ist (Gift halbiert Heilung).
@export var status_heal_mult: Dictionary[StringName, float] = {&"gift": 0.5}
## Was bei vollen Stapeln passiert: freeze (einfrieren) oder discharge (Entladung).
@export var status_on_max: Dictionary[StringName, StringName] = {&"frost": &"freeze", &"ladung": &"discharge"}
@export var freeze_time: float = 2.0
@export var discharge_damage: float = 25.0
@export var discharge_radius: float = 2.0
@export var discharge_stun: float = 0.5
@export var wound_bonus: float = 0.3
@export var cut_wound_chance: float = 0.2
## Licht blendet Nacht- und Schattenwesen so lange.
@export var light_blind_time: float = 2.0
@export var knockback_force: float = 7.0
@export var status_tick: float = 0.5
## Parameter der acht Reaktionen (Texte in gu_system.json → reaktionen).
@export var reaction_rules: Dictionary[StringName, Dictionary] = {
	&"ueberschlag": {"mult": 2.0, "chain_status": &"nass", "chain_radius": 6.0},
	&"schockfrost": {"freeze": 2.0},
	&"dampf": {"blind_radius": 3.0, "blind_time": 4.0},
	&"schmelze": {"mult": 1.5, "apply": &"nass"},
	&"zerschmettern": {"mult": 2.5},
	&"feuerwirbel": {"spread_status": &"brand", "spread_radius": 4.0},
	&"giftexplosion": {"explode_per_stack": 8.0, "explode_radius": 3.0, "stack_status": &"gift"},
	&"blutgift": {"stack_mult": 2.0, "stack_status": &"gift"},
}
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
## Wirkungen der Hilfs-Gu (Texte in gu_system.json → hilfs_gu).
@export var support_rules: Dictionary[StringName, Dictionary] = {
	&"liquor": {"regen_mult": 1.35},
	&"hoffnung": {"capacity_add": 1, "cap_mult": 1.1},
	&"kleineslicht": {"light": true, "reveal": true},
	&"signal": {"detection_mult": 2.0},
	&"stealthstein": {"aggro_mult": 0.6},
	&"bohr": {"harvest_hits": -1},
	&"zweiaufgaben": {"cooldown_mult": 0.8},
}
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
## Schalter je Gu-ID (GU_SYSTEM.md, Familien-Tabelle). Höhere Ränge erben die Ranggaben der niedrigeren.
## pierce = zusätzlich durchdrungene Ziele, radius_add = Explosionsradius, beam_all = Strahl trifft alle,
## pierce_armor, stacks_add, spread_on_death (Gift springt beim Tod über), pull (Sog), reflect (Geschosse zurück),
## cleanse (Heilung entfernt Gift, Brand, Frost), companions_add, glide und air_dash (Wolkenschritt).
@export var rank_gifts: Dictionary[StringName, Dictionary] = {
	&"mondsichel": {"pierce": 1},
	&"flammenzunge": {"radius_add": 1.0},
	&"wasserbohrer": {"beam_all": true},
	&"blauplasma": {"pierce_armor": true},
	&"eisvogel": {"stacks_add": 1},
	&"giftskorpion": {"spread_on_death": true},
	&"sogwirbel": {"pull": 3.0},
	&"knochenspeer": {"pierce_armor": true, "pierce": 1},
	&"eisenhaut": {"reflect": true},
	&"frischesblatt": {"cleanse": true},
	&"wolfssklave": {"companions_add": 1},
	&"wolkenschritt": {"glide": true, "air_dash": true},
}
## Gift springt beim Tod auf das nächste Ziel in diesem Umkreis über.
@export var poison_spread_radius: float = 5.0

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

@export_group("Killer-Move-Effekte")
## Zusätzliche Parameter je Killer Move (Texte in gu_system.json → killer_moves).
@export var killer_rules: Dictionary[StringName, Dictionary] = {
	&"feuersturm": {"radius": 5.0, "status": &"brand", "stacks": 1, "spread_radius": 4.0},
	&"mondschritt": {"distance": 10.0, "width": 2.2},
	&"gewitterflut": {"length": 13.0, "width": 4.0, "delay": 0.35},
	&"gletscherbruch": {"radius": 5.0, "delay": 0.5},
	&"pestfeuer": {"radius": 5.0, "gift_stacks": 5, "ground_time": 4.0},
	&"knochenfestung": {"time": 6.0, "thorn_mult": 0.6, "reduction": 0.3},
	&"donnerpanzer": {"time": 6.0, "charge_stacks": 3, "reduction": 0.3},
	&"rudelsegen": {"heal": 0.5, "summon_time": 20.0, "summon": &"wolf"},
}

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

@export_group("Gu-Meister und Duell")
## Kultivierung des Dorf-Gu-Meisters (Rang 2, Stufe 1, durchschnittliches Talent).
@export var master_rank: int = 2
@export var master_stage: int = 1
@export var master_apt: float = 60.0
## Wie oft die KI neu entscheidet (Sekunden) – kürzer = schwerer.
@export var master_think_interval: float = 0.35
## Ausholen vor Angriffs-Gu: Richtung steht fest, seitliches Ausweichen hilft (KAMPFSYSTEM: keine Treffer ohne Vorwarnung).
@export var master_cast_windup: float = 0.45
@export var master_preferred_range: float = 8.0
@export var master_speed: float = 4.6
@export var master_fist_cooldown: float = 1.3
## Unter diesem Lebensanteil greift er zu Schild oder Heilung.
@export var master_defend_ratio: float = 0.7
@export var duel_countdown: float = 3.0
## Der Gu-Meister gibt bei 25 % Leben auf, der Spieler unterliegt bei 15 %.
@export var duel_surrender_ratio: float = 0.25
@export var duel_player_floor: float = 0.15
## Entfernt sich der Spieler weiter vom Duellplatz, endet das Duell.
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
