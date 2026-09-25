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

## gu_system.json (sterbliche Ebene, Rang 1–5)

- `rezepte` – Verschmelzungen: `ergebnis` (Gu-ID), `aus` (verbrauchte Gu), `material` (Item → Menge), `chance` (0–1), `hinweis`.
- `familien` – 26 Familien: `pfad`, `rolle`, `wirkform` (20 Formen, siehe `GU_SYSTEM.md`), `tags`, `status` (ausgelöster Zustand), `futter`, `basis_r1` (Werte auf Rang 1, je nach Wirkform z. B. `schaden`, `cd`, `ess`, `hp_kosten` (Prozent des Höchstlebens), `reichweite`, `radius`, `dauer`, `takt`, `anzahl`, `winkel`, `rueckstoss`, `tempo`, `staerke`, `reduktion`, `wesen`), `aufstieg` (Materialien `r2`–`r5`), `mitglieder` (je Rang: `id`, `name`, `neu` = neu entworfen, sonst Lore aus `gu.json`, `ranggabe` als Text, `gaben` als Schalter), `welt` (Wirkung auf Objekte).
- `koerper_gu` – dauerhaft eingeprägte Gu (`wirkung`: `grundschaden`, `max_hp`, `schaden_erlitten`). `hilfs_gu` – passive Hilfs-Gu mit Futter und `regeln` (Schlüssel für `PassiveGu`).
- `zustaende` (mit `regel`: `dauer`, `dps`, `tempo`, `heilung`, `schaden_erlitten`, `bei_max`, `flucht`), `reaktionen` (`ausloeser` = Tag des Treffers, `auf` = Zustand des Ziels, `regel` = Parameter der Wirkung), `tags`, `merkmale` (`gewicht` für Zufallsauswahl), `merkmal_chance`.
- `killer_moves` – auf Familienebene (`a`, `b` = Familien-IDs), mit `kanal_s`, `mult`, `rang` (Mindestrang beider Gu), `hinweis`, `schritte` (Wirkungsschritte, siehe `GU_SYSTEM.md`, Abschnitt 9).
- `start_familien` – Auswahl beim Erwachen.

## gu.json (Ideenpool)

- `GUDEX` – 126 Gu. `type`: `act` (aktive Fähigkeit) oder `pas` (passiv). `cd`: Cooldown in s, `ess`: Essenzkosten (nur aktive), `decay`: wie schnell die Sättigung sinkt, `feed`: Grundfutter `{r: Material-ID, n: Menge}`, `feed_effektiv`: tatsächlicher Futterbedarf nach Prototyp-Formel (`n × 1,45^(Rang−1) / 2`), `zone`: Zone, in der der Gu wild vorkommt, `lore`: Lore-Text.
- `PATHS` – Pfad-IDs mit Anzeigenamen. `PATH_COLOR` – Farben. `PATH_CONFLICT` – gegensätzliche Pfade (Essenzaufschlag laut Kampfsystem).
- `ATTAIN` – Stufen der Dao-Beherrschung (`need` = benötigte Markierungen).
- `ACT` – Basis-Cooldowns der aktiven Effekttypen. `VITALGU` – wählbare Start-Gu (Vital-Gu). `GU_BOSSDROP` – Gu, die Bosse fallen lassen. `RANKGU_C` – Farbe pro Rang.

## killer_moves.json

- `KILLERS` – aus dem Prototyp (Gu-Paare), nur Referenz. Gültig sind die Killer Moves in `gu_system.json`. `run`: Referenzlogik.

## gegner.json

- `MON` – Bestien. `hp`, `dmg`, `spd` (Tempo), `xp`, `r` (Radius), `z` (Gefahrenzone), `rang` (1–5), `drop` (Liste `[Material-ID, Chance]`), `shape` (`quad`, `wolf`, `cat`, `boar`, `bear`, `croc`, `snake`, `monkey`, `scorpion`, `bird`, `spider`, `bat`, `slime`, `pilz`, `skel`, `ghost`, `golem` …), `beh` (Verhalten), optional `faehigkeit` (Wirkungsschritte wie bei Killer Moves) mit `f_reichweite` und `f_cd`, `poison`, `burn`, `fly`, `night` (nur nachts), `rng` (Fernkampf), `armor`, `boss`, `minion`, `nospawn` (nur Beschwörung).
- `VARIANTS` – regionale Varianten. `GUMASTER` – NPC-Gu-Meister mit ihren Gu (`gu`, der Meister nutzt das höchste Familienmitglied bis zu seinem Rang), Fraktion (`f`), `rang` und optional `stufe`. `NPCTYPE` – Händler/NPC-Typen mit `trade` (`give`, `get`, optional `gu` und `gu_rang` für zufällige Gu eines Rangs).

## materialien.json

- `BASIS_RES` – Grundressourcen des Inventars (Holz, Stein, Beeren, Fleisch, Fell, Urstein = `kristall` u. a.); dienen als Gu-Futter, Baumaterial und Währung. Anzeigenamen wurden ergänzt, der Prototyp zeigte nur Icons.
- `MATS` – Verfeinerungs-Materialien (Rang 1–9) mit `src` (Fundort). `BASIS_RES` und `MATS` teilen sich einen ID-Raum. `MAT_KEYS` – Reihenfolge. `GEAR` – Ausrüstung aus dem Prototyp (wird laut GDD nicht übernommen). `BUILD` – Bauteile (`cost`, `light`).

## welt.json

- `REGIONS` – die Regionen (die fünf Hauptregionen plus Sonderbereiche). `ZONE_NAMES` – Zonen innerhalb einer Region nach Gefahrenstufe.

## fortschritt.json

- `RANKS` – pro Rang: `n` Name, `ess` Essenzfarbe/-art, `realm`. `STAGES` – die vier Stufen.
- `SUCCESS` – Durchbruchschance pro Talentgrad. `RANKCAP` – maximal erreichbarer sterblicher Rang pro Talentgrad.
- `APT_FLAVOR`, `APT_COLOR` – Texte und Farben der Talentgrade. `AWAKEN_AGE` – Alter beim Erwachen. `ASCEND_LVL` – Aufstiegsschwelle.
- `PHYS` – die Zehn Extremen Physiques (Talentgrad `Durchbrochen`): `n` Name, `path` Pfad-Beschreibung, `d` und `apply` = Prototyp-Wirkung (nur Referenz), `hinweis` optionale Anmerkung zum Namen. Importiert werden ID, Name und Pfad nach `ProgressionData.physiques`; die Spielwirkung steht in `BalanceData.physique_rules`.
- `CFG` – Standardwerte fürs Neue-Spiel-Menü (Talent, Konstitution, Vital-Gu, Startrang, Spawn, Sekte, Kindheit).

## fraktionen.json

- `SECTS` – 15 Klans/Sekten/Stämme: `f` Fraktion (righteous/demonic/…), `type`, `imm`, `power`, `rivals`, `pol` (politische Lage), `gift` (Beitrittsgeschenk), `gu` (Signatur-Gu), `req` (Beitrittsbedingung).
- `SECTRANKS` – Ränge innerhalb einer Sekte (`need` Verdienst, `perk`, `give` Aufstiegsgeschenk als Item-IDs, `zuteilung` Faktor auf die tägliche Zuteilung); importiert in `ProgressionData.sect_ranks`. `gu` einer Sekte ist ihr Signatur-Gu (geschenkt ab Kernschüler). `FACTIONS`, `ORGTYPE`, `STANDING` (Herkunft im Klan: `gift` Startgeschenk, `aptBonus` Talentbonus, `rep` Verdienst im Gu-Yue-Klan beim Start; importiert als `StandingData`).

## quests.json

- `QUESTS` – Quests, `sp` Belohnung, `f` Abschlussbedingung (Referenzlogik) oder `regel` für das Spiel: `type` (`item` mit `item`, `kills`, `built`, `area`, `day`, `rogues` = besiegte dämonische Wanderer, `duels`, `refine` = verfeinerte wilde Gu, `rank`, `inheritance` mit Erbe-ID in `item`, `infamy`, `fame`), `count`, `reward`. Zähler-Arten zählen ab Annahme. Wer eine Aufgabe vergibt, steht in `SettlementPeople.RESIDENTS`. `GOALS` – Hauptziel-Kette als Referenzlogik.

## unsterblich.json

- `TRIALS` – Kalamitäten/Trübsale: `min` Mindestrang, `dmg` Schadensfaktor, `ranks`, `every` (Abstand in Apertur-Jahren, Referenzlogik), `warn` Warntext.
- `CALAMITY` – Bosse der Kalamitäten nach Index. `BLANDS` – Gesegnete Länder und eigene Apertur-Welt (`spirit` = Landgeist mit Dialogzeilen, `annex` = Annexionsbedingung). `LANDGRADE` – Qualitätsstufen der Apertur-Welt.
- `INHERIT` – Erbschaften (`bl` Ort, `need` Bedingung, `perk` Effekt). `HEAVEN` – Schatzhimmel. `LANGYA_SHOP` – Langya-Händler. `INSPIRATION` – Eingebungen mit dauerhaften Boni.

## Validierung

Stand der Extraktion: Alle Verweise sind gültig – jedes Gu-Futter, jeder Gegner-Drop, jedes Sekten-Geschenk, jeder Signatur-Gu, jeder Boss-Drop und jeder Gu in einem Killer Move existiert. Jeder aktive Gu hat Essenzkosten und Cooldown.

Verteilung der Gu nach Rang: R1 16 · R2 17 · R3 29 · R4 26 · R5 12 · R6 7 · R7 7 · R8 5 · R9 7.
Häufigste Pfade: Weisheit und Kraft (je 13), Metall (12), Verwandlung und Seele (je 10). Feuer, Wasser, Blitz und Eis haben nur 3–4 Gu – hier lohnt es sich, später Gu zu ergänzen, da diese Pfade im Kampf besonders sichtbar sind.

## gebiete.json

- `GEBIETE` – spielbare Gebiete der Gu-Welt (ID → Eintrag): `n` Name, `region` (ID aus `welt.json → REGIONS`), `karte` Position auf der Weltkarte (0–1, x Osten, y Süden), `rang` empfohlener Rang `[von, bis]`, `offen` bereits bereisbar, `d` Beschreibung. Offene Gebiete: `groesse` (m), `seed`, `biom`, `relief` (`hoehe`, `frequenz`, `detail`, `berge`, `rand`, `randhoehe`, `horizont` = Gebirgskranz, `basis` = Grundhöhe), `erhebungen` (`[x, z, Radius, Höhe]`, z. B. Inseln), `ankunft`, `siedlungen` (`typ`: `klan_dorf`, `stadt`, `festung`, `sekte`, `zeltlager`, `oasenstadt`, `inseldorf`, `versteck`; `fraktion`, `pos`, `radius`, `haeuser`, `farben` (`dach`, `wand`, `holz`, `saeule`, `banner`, `stein`, optional `platz`), `bewohner` (Gruppe in `SettlementPeople`), optional `teich`), `orte` (`geisterquelle`, `see`, `aschefeld`, `frostquelle`, `friedhof`, `erbe` mit `opfer`, `waechter`, `belohnung` {`gu`, `hilfs_gu`, `koerper_gu`, `items`}, `text`, `stil` (`hoehle`, `grab`, `tempel`, `altar`, `grotte`) und `akzent` (Leuchtfarbe); `ursteinader` mit `anzahl` Ursteinbrocken, `ertrag` je Brocken und optional `besitzer` (Sekten-ID: Mitglieder verdienen Verdienst, Fremde werden berüchtigt); `dao_ort` mit `pfad` (Kultivieren dort prägt Dao-Markierungen in diesen Pfad, `Balance.dao_site_rate`)), `hindernisse` (`art`, `belohnung`, `richtung`, `abstand`), `wege`, `ressourcen`, `gegner` (`radien`, `zonen`: Gefahrenzonen als Zahl oder Bestien-IDs), `wilde_gu` (`rang`, `abstand`), `wilde_passive`, optional `flut` (Bestienflut: `n`, `bestien`, `anfuehrer`, `anzahl`, `alle_tage`, `ziel` = Siedlungs-ID, `belohnung`), optional `wanderer` (wandernde Gu-Meister: `meister` = IDs aus `gegner.json → GUMASTER`, `anzahl` gleichzeitig unterwegs; ihre Fraktion entscheidet, ob sie überfallen oder patrouillieren).
- `BIOME` – Landschaften: `farben` (inkl. `strand`), `vegetation` (Anteile: `laubbaum`, `palme`, `nadelbaum`, `bambus`, `kaktus`, `totholz`; `steppengras` schaltet hohes Gras ein), Dichten je 1000 m², `himmel`, `himmel_oben`, `nebel`, `nebel_dichte`, `wasser`, optional `pflanzenfarbe` (Tönung) und `meeresspiegel`.

## welt.json → KARTE

- Weltkarte je Region (Schlüssel = Regions-ID): `poly` Umriss (0–1), `mauer` Name der Regionalmauer, `mauer_c` ihre Farbe, optional `fluesse` (Linienzüge 0–1) und `meer` (Meeresregion mit Inseln).
