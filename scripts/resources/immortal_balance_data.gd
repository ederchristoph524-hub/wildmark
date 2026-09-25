class_name ImmortalBalanceData
extends Resource
## Balancing-Konstanten des Unsterblichen-Reichs (docs/UNSTERBLICH.md): Kraft unsterblicher Gu, Kampf Unsterbliche
## gegen Sterbliche, Leben, Perlen, Kalamitäten, Apertur-Erträge und Weltregeln der Dimensionen.

@export_group("Kraft und Kampf")
## Unsterblichen-Kraft eines unsterblichen Gu: kraft_basis × kraft_wachstum^(Rang − 6).
@export var power_base: float = 30.0
@export var power_growth: float = 3.5
## Ein Unsterblicher trifft Sterbliche × immortal_vs_mortal (je Rang über 6 × rank_factor); Sterbliche treffen
## Unsterbliche nur × mortal_vs_immortal. Unter Unsterblichen gilt je Rang Unterschied × rank_factor.
@export var immortal_vs_mortal: float = 4.0
@export var mortal_vs_immortal: float = 0.03
@export var rank_factor: float = 1.8
## Leben eines Unsterblichen: hp_base × hp_growth^(Rang − 6) (zusätzlich zum sterblichen Leben).
@export var hp_base: float = 2600.0
@export var hp_growth: float = 3.5
## Fester Schadenszuschlag der Faust und sterblicher Gu eines Unsterblichen je Rang.
@export var flat_damage_base: float = 25.0
## NPC-Unsterbliche: Leben × master_hp_mult (Unsterblichen-Teil) und Schadensfaktor statt master_damage_rank_mult,
## damit ein Duell unter Gleichrangigen 10–25 s dauert (Messung: balance_probe --masters).
@export var master_hp_mult: float = 3.0
@export var master_damage_mult: float = 1.6
## Wüste, Uralte und Urzeitliche Bestien (Rang 6–8): Leben und Schaden, damit sie auf ihrem Rang 15–30 s halten und
## einen gleichrangigen Unsterblichen in etwa 20–40 s bedrohen (balance_probe --player-rank=N --rank=N).
@export var beast_hp_mult: float = 2.2
@export var beast_damage_mult: float = 2.6
## Unsterbliche Gu der NPC-Unsterblichen: Anteil der vollen Kraft (sie wirken alle 7 s mit Warnkreis).
@export var npc_cast_mult: float = 0.3
## Killer Moves: je sterbliche Familie + killer_component_bonus auf den Grundschaden.
@export var killer_component_bonus: float = 0.12
## Obergrenze eines Unsterblichen-Killer-Moves (Summe der mult, wie killer_total_cap bei Sterblichen).
@export var killer_total_cap: float = 30.0
## Perlen, die ein sterblicher Gu je Einsatz verbraucht (fast nichts: eine Perle ist unerschöpflich).
@export var mortal_cast_beads: float = 0.001
## Dao-Markierungen des Pfads verstärken unsterbliche Gu: × (1 + Markierungen / dao_power_marks), höchstens
## dao_power_max; der Dao-Herr (Ehrwürdiger) × dao_lord_mult.
@export var dao_power_marks: float = 400.0
@export var dao_power_max: float = 4.0
@export var dao_lord_mult: float = 2.0
## Zwei Tasten für unsterbliche Gu.
@export var slot_count: int = 2

@export_group("Aufstieg und Kalamitäten")
## Kalamitäts-Blitz: Schaden = Anteil des Höchstlebens, Telegraph-Zeit, Radius.
@export var bolt_hp_fraction: float = 0.18
@export var bolt_warning: float = 1.3
@export var bolt_radius: float = 3.2
## Beben: Anteil des Höchstlebens, Radius, verwurzelt.
@export var quake_hp_fraction: float = 0.1
@export var quake_radius: float = 5.0
## Bestien je Welle (+ je Kalamität-Stärke), Abstand vom Spieler beim Erscheinen.
@export var wave_beasts: int = 3
@export var wave_spawn_distance: float = 18.0
## Wer nicht in seiner Apertur ist, lässt das Land allein kämpfen: Verlust der gelagerten Erträge.
@export var unattended_loss: float = 0.5
## Dao-Markierungen einer Kalamität (Lore-Zahlen) geteilt durch diesen Wert.
@export var calamity_dao_divisor: float = 10.0
## Ohne Rückfall-Tag: nach so vielen Tagen bricht eine angekündigte Kalamität auch ohne dich los.
@export var calamity_grace_days: int = 1
## Rang 5 → 6: so viele Tage nach dem Aufstieg bleibt das Land ruhig.
@export var first_calamity_delay: int = 3

@export_group("Apertur und Handel")
## Rang 7+: Essenzsteine je Perle beim Verdichten (Rang 6: 1).
@export var stones_per_bead_growth: float = 3.0
## Pfad-Materialien je Tag in der eigenen Apertur (× Ertrag des Grades).
@export var land_materials_per_day: float = 3.0
## Grotto-Himmel ab Rang 8: +50 % Fläche, Himmelskristalle je Tag.
@export var grotto_size_mult: float = 1.5
@export var grotto_crystals_per_day: float = 1.0
## Annexion: Zugewinn an Essenzsteinen je Tag je annektiertem Land.
@export var annex_stones_per_day: float = 2.0

@export_group("Dimensionen")
## Dang-Hun-Berg: Seelenschaden je s (Anteil Höchstleben) je 10 m Höhe; Seelenfundament je s Aufenthalt über 20 m.
@export var soul_load_per_10m: float = 0.0022
@export var soul_foundation_rate: float = 0.02
## Seelenfundament: + so viel Anteil Höchstleben je Punkt (höchstens soul_foundation_max Punkte).
@export var soul_foundation_hp: float = 0.01
@export var soul_foundation_max: float = 100.0
## Luo-Po-Tal: Seelensturm alle n s, Schaden (Anteil), Deckung hinter Felsen innerhalb dieses Radius.
@export var soul_storm_interval: float = 14.0
@export var soul_storm_damage: float = 0.22
@export var soul_storm_cover: float = 4.0
@export var soul_storm_dao: float = 6.0
## Sterbliche in Himmeln: Anteil Leben je s.
@export var mortal_drain: float = 0.04
## Traumreich: Dao-Faktor.
@export var dream_dao_mult: float = 5.0
## Halbe Schwerkraft.
@export var light_gravity: float = 0.5

@export_group("Sterbliche Gu und freier Start")
## Sterbliche Gu, die eine Unsterblichen-Apertur tragen kann (Killer Moves aus Dutzenden Gliedern).
@export var mortal_gu_capacity: int = 120
## Freier Start: Ursteine je Rang² und Unsterblichen-Essenzsteine je Unsterblichen-Rang.
@export var free_start_stones: int = 30
@export var free_start_immortal_stones: int = 80
## Freier Start: sterbliche Gu je Rang (ohne Glieder der Killer Moves).
@export var free_start_gu: int = 4
