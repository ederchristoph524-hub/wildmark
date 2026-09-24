# Formeln – Balancing-Referenz

Die Kernformeln aus dem Prototyp, bereinigt und kommentiert. Sie sind der Startpunkt fürs Balancing in Godot. Alle Konstanten gehören in ein zentrales `Balance`-Resource, damit sie ohne Codeänderung angepasst werden können.

Abkürzungen: `rank` = Rang des Spielers (1–9), `stage` = Stufe (0–3: Anfangs- bis Höchststufe), `apt` = Talentwert in Prozent (20–100), `g.rank` = Rang des Gu, `dt` = Sekunden seit dem letzten Frame.

## Zeit

| Größe | Prototyp | Empfehlung 3D |
|---|---|---|
| Länge eines Spieltags | 180 s (Nacht ab 120 s) | 20 min (Nacht letzte 7 min) |

Alle zeitbasierten Raten unten sind im Prototyp „pro Sekunde" bei einem 180-s-Tag. **Bei einem längeren Tag müssen Hunger- und Unterhaltsraten mit demselben Faktor skaliert werden** (bei 20 min: Hunger ÷ 6,7), sonst verhungern Gu mehrmals pro Spieltag. Am saubersten: alle Raten in „pro Spieltag" angeben und aus der Taglänge umrechnen.

## Apertur und Uressenz

```
essence_cap   = 25 × 3.2^(rank−1) × (1 + stage × 0.55) × (apt / 100) × gu_cap_mult
essence_regen = essence_cap / (88 − apt × 0.55) × regen_mults     // pro Sekunde
```
Eine leere Apertur füllt sich bei durchschnittlichem Talent in rund 150 s reinen Wartens. `regen_mults` kommen von Gu wie Schnaps-Wurm (×1,35).

**Essenz-Grad:** Bestimmte Gu (Schnaps-Wurm u. a.) heben den Essenz-Grad um 1 über den Rang. Bonus auf Schaden: `1 + (ess_grade − rank) × 0.22` (ab Rang 8: 0.45).

## Kultivierung (Aperturwand)

Stufen steigen, indem Essenz gegen die Aperturwand geleitet wird (Meditation).
```
wall_need = essence_cap × (1.6 + stage × 0.5)       // Rang 6+: × 2.2
```
Stufenaufstieg: +12 max HP, +1,5 Grundschaden. Auf der Höchststufe (stage 3) ist ein Durchbruch möglich.

## Durchbruch (Rang 1–5)

Bedingungen: Höchststufe, Essenz ≥ 90 % der Kapazität, Rang < Rang-Obergrenze des Talentgrads (`RANKCAP`: D 2, C 3, B 4, A/Durchbrochen 5).
```
Erfolg:  Chance = SUCCESS[Talentgrad]   // D .45, C .62, B .80, A .95, Durchbrochen 1.0
         rank += 1, stage = 0, essence = 0, max_hp += 15 × rank, Grundschaden +3
Scheitern: essence × 0.4
```

## Gu-Stärke

```
gu_rank_pow(g) = 1.48^(g.rank − 1)          // R1 ×1 · R3 ×2,2 · R5 ×4,8 · R9 ×22,9

gu_fit(g):  d = g.rank − rank
            d = 0 → 1
            d < 0 → max(0.25, 1 + d × 0.22)  // Gu unter deinem Rang wird schwächer
            d > 0 → 1 + d × 0.12             // Gu über deinem Rang wirkt stärker …
gu_fit_cost(g): d > 0 → 1 + d² × 0.85       // … kostet aber quadratisch mehr Essenz
```
Wirkung eines Gu = Basiswert × `gu_rank_pow` × `gu_fit` × Pfad-Bonus.

## Pfade und Dao-Markierungen

```
path_cost(p) = max(0.4, 1 − attain(p) × 0.09 + conflict(p) × 0.5)   // Multiplikator auf Essenzkosten
path_cd(p)   = max(0.5, 1 − attain(p) × 0.07)                        // Multiplikator auf Cooldown
conflict(p)  = min(0.45, foes / (own + foes) × 0.6)
               foes = Summe der Markierungen gegensätzlicher Pfade (PATH_CONFLICT)
               own  = Markierungen des eigenen Pfads + 1
```
`attain(p)` ist die Beherrschungsstufe aus `ATTAIN` (Schwellen in `gu.json`). Konflikte entstehen also aus deiner **Geschichte** (welche Pfade du genutzt hast), nicht nur aus dem aktuellen Loadout.

## Gu-Haltung

```
Anzahl Gu (Kapazität) = floor((3 + rank × 2 + floor(apt / 25)) × second_aperture_mult)   // apt 100: +4
Hunger: 100 → 0, sinkt pro Sekunde um 0.085 / 1.28^(g.rank − 1)
Futter (Menge) = max(1, round(feed.n × 1.45^(g.rank − 1) / 2))   // bereits als feed_effektiv in gu.json
```
Ein Gu mit Hunger 0 wirkt nicht mehr. Passive Gu wirken nur, wenn sie satt sind und ihr Rang höchstens 1 über deinem liegt.

**Unterhalt passiver Gu:** Jeder passive Gu kostet laufend `g.rank × 0.55` Essenz pro Sekunde. Ausnahmen (dauerhafte Körper-Gu, Liste `PERM` im Prototyp): Rosa-Eber, Zehn-Jin, Eisenknochen u. a. Übersteigt der Unterhalt die Regeneration und fällt die Essenz auf 0, fallen alle nicht-dauerhaften passiven Gu aus, bis wieder 8 % der Kapazität gefüllt sind.

## Verfeinerung

```
d = g.rank − rank
Grundchance: d ≤ 0 → .95 · d = 1 → .60 · d = 2 → .30 · d = 3 → .12 · sonst .04
Chance × (0.6 + apt / 250) × (1 + attain(g.path) × 0.10)  + Boni    // begrenzt auf 2 %–98 %
Kosten = round(12 × 1.8^(g.rank − 1) × path_cost(g.path)) Essenz + Materialien
```
Gu mit mehr als 3 Rängen über dir können nicht verfeinert werden. Die benötigten Materialien werden aus `MATS` gewählt (Rang ≈ Gu-Rang, bevorzugt gleicher Pfad; Anzahl `ceil(g.rank / 2)`).

## Killer Moves (Prototyp)

Im Prototyp: zweiter Gu innerhalb von 0,8 s nach dem ersten, Kosten `(ess_a + ess_b) × 2`. Im 3D-Spiel wird das durch den Killer-Move-Button mit Kanalisierung ersetzt (siehe `KAMPFSYSTEM.md`), die Kostenformel bleibt.

## Schaden

```
dmg = (dmg_base + flat_gu_dmg) × ess_bonus
dmg_base = 8 + Stärke-Skills + floor(level × 0.8) + Ausrüstung
```
Hinweis: Die Stärke-Skills und das Level-System stammen aus der frühen Prototyp-Phase. Im 3D-Spiel entfallen Level-System und Ausrüstung laut Design; Grundschaden steigt nur über Stufen und Rang (siehe Kultivierung und Durchbruch).
