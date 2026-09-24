# Spieldaten – Feldbedeutungen

Alle Dateien wurden automatisch aus dem Prototyp (`docs/referenz/wildmark_prototyp.html`) extrahiert. Schlüssel und IDs sind unverändert, damit sie mit der Prototyp-Logik übereinstimmen. Werte, die mit `[fn]` beginnen, sind JavaScript-Funktionen aus dem Prototyp: Sie dienen nur als Referenz dafür, was der Effekt tut, und müssen in GDScript neu umgesetzt werden. `[getter]` bedeutet einen im Prototyp berechneten Wert.

## Allgemeine Kurzschlüssel

| Feld | Bedeutung |
|---|---|
| `n` | Anzeigename |
| `ic` | Emoji-Icon (Platzhalter, später durch echtes Icon ersetzen) |
| `d` | Beschreibung / Effekttext |
| `c` | Farbe (Hex) |
| `rank` | Rang 1–9 |
| `path` | Pfad-ID (siehe `gu.json` → `PATHS`) |
| `imm` | Unsterblich (Rang 6+) bzw. Anzahl Unsterblicher bei Sekten |
| `reg` / `region` | Regions-ID (siehe `welt.json` → `REGIONS`) |

## gu_system.json (gültig für M2–M3)

- `familien` – 12 Familien: `pfad`, `rolle`, `wirkform`, `tags`, `status` (ausgelöster Zustand), `futter`, `basis_r1` (Werte auf Rang 1), `aufstieg` (Materialien für Rang 2 und 3), `mitglieder` (je Rang: `id`, `name`, `neu` = neu entworfen, `ranggabe`), `welt` (Wirkung auf Objekte).
- `koerper_gu` – dauerhaft eingeprägte Gu. `hilfs_gu` – passive Hilfs-Gu mit Futter.
- `zustaende`, `reaktionen` (`ausloeser` = Tag des Treffers, `auf` = Zustand des Ziels), `tags`, `merkmale` (`gewicht` für Zufallsauswahl), `merkmal_chance`.
- `killer_moves` – auf Familienebene (`a`, `b` = Familien-IDs), mit `kanal_s`, `mult`, `hinweis`.
- `start_familien` – Auswahl beim Erwachen.

## gu.json (Ideenpool)

- `GUDEX` – 126 Gu. `type`: `act` (aktive Fähigkeit) oder `pas` (passiv). `cd`: Cooldown in s, `ess`: Essenzkosten (nur aktive), `decay`: wie schnell die Sättigung sinkt, `feed`: Grundfutter `{r: Material-ID, n: Menge}`, `feed_effektiv`: tatsächlicher Futterbedarf nach Prototyp-Formel (`n × 1,45^(Rang−1) / 2`), `zone`: Zone, in der der Gu wild vorkommt, `lore`: Lore-Text.
- `PATHS` – Pfad-IDs mit Anzeigenamen. `PATH_COLOR` – Farben. `PATH_CONFLICT` – gegensätzliche Pfade (Essenzaufschlag laut Kampfsystem).
- `ATTAIN` – Stufen der Dao-Beherrschung (`need` = benötigte Markierungen).
- `ACT` – Basis-Cooldowns der aktiven Effekttypen. `VITALGU` – wählbare Start-Gu (Vital-Gu). `GU_BOSSDROP` – Gu, die Bosse fallen lassen. `RANKGU_C` – Farbe pro Rang.

## killer_moves.json

- `KILLERS` – aus dem Prototyp (Gu-Paare), nur Referenz. Gültig sind die Killer Moves in `gu_system.json`. `run`: Referenzlogik.

## gegner.json

- `MON` – 25 Gegner. `hp`, `dmg`, `spd` (Tempo), `xp`, `r` (Radius), `z` (Zone), `drop` (Liste `[Material-ID, Chance]`), `shape` (Platzhalterform), `beh` (Verhalten), optional `poison`, `burn`, `fly`, `night` (nur nachts), `rng` (Fernkampf), `armor`, `boss`, `minion`.
- `VARIANTS` – regionale Varianten. `GUMASTER` – NPC-Gu-Meister mit ihren Gu (`gu`) und Fraktion (`f`). `NPCTYPE` – Händler/NPC-Typen mit `trade`.

## materialien.json

- `BASIS_RES` – Grundressourcen des Inventars (Holz, Stein, Beeren, Fleisch, Fell, Urstein = `kristall` u. a.); dienen als Gu-Futter, Baumaterial und Währung. Anzeigenamen wurden ergänzt, der Prototyp zeigte nur Icons.
- `MATS` – 29 Verfeinerungs-Materialien mit `src` (Fundort). `BASIS_RES` und `MATS` teilen sich einen ID-Raum. `MAT_KEYS` – Reihenfolge. `GEAR` – Ausrüstung aus dem Prototyp (wird laut GDD nicht übernommen). `BUILD` – Bauteile (`cost`, `light`).

## welt.json

- `REGIONS` – die Regionen (die fünf Hauptregionen plus Sonderbereiche). `ZONE_NAMES` – Zonen innerhalb einer Region nach Gefahrenstufe.

## fortschritt.json

- `RANKS` – pro Rang: `n` Name, `ess` Essenzfarbe/-art, `realm`. `STAGES` – die vier Stufen.
- `SUCCESS` – Durchbruchschance pro Talentgrad. `RANKCAP` – maximal erreichbarer sterblicher Rang pro Talentgrad.
- `APT_FLAVOR`, `APT_COLOR` – Texte und Farben der Talentgrade. `AWAKEN_AGE` – Alter beim Erwachen. `ASCEND_LVL` – Aufstiegsschwelle.
- `PHYS` – besondere Körperkonstitutionen (z. B. Zehn-Extreme-Körper) mit `apply`-Referenz.
- `CFG` – Standardwerte fürs Neue-Spiel-Menü (Talent, Konstitution, Vital-Gu, Startrang, Spawn, Sekte, Kindheit).

## fraktionen.json

- `SECTS` – 15 Klans/Sekten/Stämme: `f` Fraktion (righteous/demonic/…), `type`, `imm`, `power`, `rivals`, `pol` (politische Lage), `gift` (Beitrittsgeschenk), `gu` (Signatur-Gu), `req` (Beitrittsbedingung).
- `SECTRANKS` – Ränge innerhalb einer Sekte (`need`, `perk`, `give`). `FACTIONS`, `ORGTYPE`, `STANDING` (Herkunft/Stand mit `aptBonus`).

## quests.json

- `QUESTS` – 18 Quests, `sp` Belohnung, `f` Abschlussbedingung (Referenzlogik). `GOALS` – Hauptziel-Kette als Referenzlogik.

## unsterblich.json

- `TRIALS` – Kalamitäten/Trübsale: `min` Mindestrang, `dmg` Schadensfaktor, `ranks`, `every` (Abstand in Apertur-Jahren, Referenzlogik), `warn` Warntext.
- `CALAMITY` – Bosse der Kalamitäten nach Index. `BLANDS` – Gesegnete Länder und eigene Apertur-Welt (`spirit` = Landgeist mit Dialogzeilen, `annex` = Annexionsbedingung). `LANDGRADE` – Qualitätsstufen der Apertur-Welt.
- `INHERIT` – Erbschaften (`bl` Ort, `need` Bedingung, `perk` Effekt). `HEAVEN` – Schatzhimmel. `LANGYA_SHOP` – Langya-Händler. `INSPIRATION` – Eingebungen mit dauerhaften Boni.

## Validierung

Stand der Extraktion: Alle Verweise sind gültig – jedes Gu-Futter, jeder Gegner-Drop, jedes Sekten-Geschenk, jeder Signatur-Gu, jeder Boss-Drop und jeder Gu in einem Killer Move existiert. Jeder aktive Gu hat Essenzkosten und Cooldown.

Verteilung der Gu nach Rang: R1 16 · R2 17 · R3 29 · R4 26 · R5 12 · R6 7 · R7 7 · R8 5 · R9 7.
Häufigste Pfade: Weisheit und Kraft (je 13), Metall (12), Verwandlung und Seele (je 10). Feuer, Wasser, Blitz und Eis haben nur 3–4 Gu – hier lohnt es sich, später Gu zu ergänzen, da diese Pfade im Kampf besonders sichtbar sind.
