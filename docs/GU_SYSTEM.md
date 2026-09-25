# Gu-System – Wildmark

Das Herz des Spiels. Dieses Dokument ist verbindlich für alle Gu, ihre Wirkungen, Zustände, Reaktionen, Ränge und Killer Moves. Daten: `docs/daten/gu_system.json`. Die Tabellen unten sind aus den Daten erzeugt; bei Abweichungen gilt die JSON-Datei.

## 1. Das 80/20-Prinzip

**Spielerlebnis entsteht aus:** Entscheidungen, Kombinationen, die sich wie eigene Entdeckungen anfühlen, Bindung an „meine" Gu und dem Gefühl, dass Macht die Welt verändert.

**Aufwand entsteht aus:** einzigartigem Code pro Gu, Sonderfällen und Balancing vieler ähnlicher Dinge.

Deshalb gilt: **Wenige Bausteine werden einmal gebaut, das Erlebnis entsteht aus ihrem Zusammenspiel.** Ein neuer Gu ist ein Dateneintrag. Auch einzigartige Wirkungen (Sternschnuppe, Taifun, Seelenexplosion, Knochenräder) entstehen ohne neuen Code aus **Wirkungsschritten** (Abschnitt 9).

| Hebel | Einmal bauen | Ergibt |
|---|---|---|
| 1. Baukasten | 22 Wirkformen, 19 Tags, 21 Schrittarten | alle aktiven Gu als reine Daten |
| 2. Zustände und Reaktionen | 10 Zustände, 16 Reaktionen | Dutzende Kombos, die niemand einzeln programmiert hat |
| 3. Familien | 32 Familien mit je 5 Rängen | 160 aktive Gu mit spürbarem Aufstieg |
| 4. Dieselben Regeln in der Welt | Zustände wirken auch auf Objekte | Erkundung und Rätsel ohne eigenes Rätselsystem |

Dazu: **Merkmale** für wilde Gu, **23 Körper-Gu**, **34 Hilfs-Gu** und **125 Killer Moves** aus 96 Gu-Paaren in drei Stufen (Rang 1, 3, 5).

## 2. Hebel 1: der Baukasten

Jeder aktive Gu ist die Kombination aus einer **Wirkform**, einigen **Tags**, optional einem **Zustand**, Zahlenwerten (`basis_r1`) und **Ranggaben** (`gaben`). Neuer Code entsteht nur für eine neue Wirkform oder Schrittart, nie für einen einzelnen Gu.

**Wirkformen (22):**

| Wirkform | Beschreibung | Umsetzung |
|---|---|---|
| `geschoss` | fliegt geradeaus, trifft das erste Ziel | `GuCaster` |
| `geschoss_explodierend` | wie Geschoss, Explosion im Radius | `GuCaster` |
| `geschoss_schnell` | sehr schnell, kurze Abklingzeit | `GuCaster` |
| `strahl` | Linie von dir aus | `GuCaster` |
| `stich` | kurze Reichweite vor dir | `GuCaster` |
| `kreis` | Fläche um dich herum | `GuCaster` |
| `selbstschild` | Schadensreduktion auf Zeit | `GuCaster` |
| `selbst_heilung` | Heilung über Zeit | `GuCaster` |
| `bewegung` | Doppelsprung, Gleiten, Teleport | `GuCaster` + Spieler |
| `zaehmen` | macht eine geschwächte Bestie zum Gefährten | `GuCaster` + Gegner-KI |
| `zone` | Wirkungsfläche am Ziel (Takte, Zustand, Verlangsamung, Sog) | `GuForms` → `EffectZone` |
| `kegel` | Kegel vor dir (Phantome, Windstöße, Schreie) | `GuForms` → Schritt `cone` |
| `sturmlauf` | Ansturm durch eine Linie | `GuForms` → Schritt `line` |
| `aura` | Wirkungsfläche, die dir folgt | `GuForms` → `EffectZone` |
| `schwarm` | mehrere zielsuchende Geschosse | `GuForms` → Schritt `projectiles` |
| `umkreisen` | kreisende Klingen, Knochenräder, Sterne | `GuForms` → `OrbitBlades` |
| `falle` | verborgene Fallen, die bei Berührung explodieren | `GuForms` → `GuTrap` |
| `tarnung` | Bestien verlieren dich; erster Schlag verstärkt | `GuForms` → `Combatant.start_stealth` |
| `staerkung` | Schaden, Tempo und Schutz auf Zeit | `GuForms` → `Combatant.add_buff` |
| `beschwoerung` | Wesen kämpfen auf Zeit für dich (skalieren mit dem Rang) | `GuForms` → `EnemySpawner.spawn_companion` |
| `tausch` | tauscht den Platz mit einem Gegner und trifft ihn (Raum-Pfad) | `GuForms` → Schritt `swap` |
| `eingebung` | alle anderen Gu früher bereit und eine Weile schneller (Weisheits-Pfad) | `GuForms` → Schritt `haste` |

**Tags:** Wucht (stößt zurück, zerschmettert Eingefrorene), Schnitt (20 % Wunde), Durchbohren (ignoriert Rüstung), Wind (verteilt Brand und Gift), Licht (blendet Nachtwesen), Feuer, Wasser, Blitz, Eis, Gift, Seele, Holz, Raum, Erde, Stern, Klang, Metall, Blut, Zeit. Element-Tags lösen die Reaktionen aus Abschnitt 3 aus.

## 3. Hebel 2: Zustände und Reaktionen

Zustände und Reaktionen sind reine Daten (`zustaende[].regel`, `reaktionen[].regel`). Neue Einträge brauchen keinen Code, solange ihre Regel-Schlüssel existieren (Zustand: `dauer`, `dps`, `tempo`, `heilung`, `schaden_erlitten`, `bei_max`, `flucht`; Reaktion: `mult`, `freeze`, `apply`, `stun`, `spread_status`, `chain_status`, `explode_per_stack`, `stack_mult`, `blind_radius`, `heal_attacker`).

| Zustand | Regel |
|---|---|
| Brand | 4 Schaden/s (× Rangfaktor), 4 s |
| Nass | keine direkte Wirkung, 6 s; Vorbereitung für Blitz und Frost |
| Frost | je Stapel −20 % Tempo, 5 s; bei 3 Stapeln 2 s eingefroren |
| Ladung | bei 3 Stapeln Entladung: 25 Schaden im Umkreis 2 und 0,5 s Betäubung |
| Gift | 2 Schaden/s pro Stapel, 8 s, halbiert Heilung |
| Wunde | nächster Treffer +30 %; Blut-Gu heilen an verwundeten Zielen |
| Blutung | 2 Schaden/s pro Stapel (max. 3), 6 s; Blut-Gu heilen an blutenden Zielen |
| Schwäche | +15 % erlittener Schaden pro Stapel, 6 s |
| Verwurzelt | kann sich 2,5 s nicht bewegen (angreifen schon) |
| Furcht | flieht 3 s vor dem Angreifer und greift nicht an |

| Reaktion | Auslöser → Ziel | Ergebnis |
|---|---|---|
| Überschlag | Blitz → Nass | ×2 Schaden, springt auf alle nassen Ziele im Umkreis 6 |
| Schockfrost | Eis → Nass | sofort eingefroren (2 s) |
| Dampf | Feuer → Nass | Dampfwolke 4 s: Gegner darin verlieren ihr Ziel |
| Schmelze | Feuer → Frost | ×1,5 Schaden, Ziel wird nass |
| Zerschmettern | Wucht → Eingefroren | ×2,5 Schaden |
| Feuerwirbel | Wind → Brand | Brand springt auf alle Ziele im Umkreis 4 |
| Giftexplosion | Feuer → Gift ab 3 | Explosion: Stapel × 8 Schaden im Umkreis 3 |
| Blutgift | Gift → Wunde | Gift-Stapel werden verdoppelt |
| Schlammgrube | Erde → Nass | Ziel versinkt im Schlamm: 2,5 s verwurzelt |
| Giftsturm | Wind → Gift | Gift weht auf alle Ziele im Umkreis 4 |
| Seelenbruch | Seele → Furcht | ×2 Schaden gegen verängstigte Ziele |
| Aderlass | Blut → Blutung | ×1,2 Schaden, der Angreifer heilt 20 % davon |
| Sternenfall | Stern → Schwaeche | ×1,8 Schaden gegen geschwächte Ziele |
| Donnerschlag | Klang → Ladung | Ladung entlädt sich sofort: 1,5 s betäubt |
| Splitterbruch | Metall → Eingefroren | ×2 Schaden, Splitter verursachen Blutung |
| Waldbrand | Feuer → Verwurzelt | Wurzeln fangen Feuer: ×1,6 Schaden, Brand springt über (Umkreis 3) |

**Ketten, die daraus entstehen** (niemand muss sie programmieren):
- Wasserlicht → Frostnadel (Schockfrost) → Wirbelwind (Zerschmettern)
- Wasserlicht → Erdstachel (Schlammgrube, verwurzelt) → Glutfunke (Waldbrand)
- Seelenschrei (Furcht) → Stern-Schwarm mit Schwäche → Sternschnuppe (Sternenfall)
- Stachelwurm ×2 → Blutdorn (Wunde) → Stachelwurm (Blutgift) → Glutfunke (Giftexplosion) → Windklinge (Giftsturm)
- Verletzungswind (Blutung) → Blutsichel (Aderlass, heilt dich)

**Gegner nutzen dieselben Regeln.** Bestien mit Fähigkeit (`gegner.json → faehigkeit`) setzen Wirkungsschritte ein: Blitzwölfe springen geladen vor, Bergbären schlagen einen Kreis, Riesenskorpione spucken Gift.

## 4. Hebel 3: Familien

**32 Familien mit je fünf Rängen (Rang 1–5, sterbliche Ebene).** Jede Familie ist ein Verb mit eigener Wirkform. Höhere Ränge nutzen dieselbe Umsetzung mit stärkeren Werten (×1,48 pro Rang, `FORMELN.md`) und einer **Ranggabe**, die neu hinzukommt. Namen folgen, wo möglich, den Gu aus Reverend Insanity (Allumfassender-Goldlicht-Wurm, Alles-oder-nichts, Knochenschild, Tarnschuppen, Selbstentzündung …).

| Familie | Pfad | Wirkform | Rang 1 | Rang 2 | Rang 3 | Rang 4 | Rang 5 |
|---|---|---|---|---|---|---|---|
| Mondlicht | Licht | Geschoss | Mondlicht-Gu | Mondsichel-Gu (Klinge durchdringt ein weiteres Ziel) | Regenbogenlicht-Gu (Fächert in sieben Klingen auf) | Allumfassender-Goldlicht-Wurm (Durchdringt bis zu fünf Ziele und jede Rüstung) | Mondgift-Gu (Elf zielsuchende Klingen, jede hinterlässt Gift) |
| Flamme | Feuer | Geschoss (explodierend) | Glutfunken-Gu | Flammenzungen-Gu (Explosionsradius +1 m) | Feuerlotus-Gu (Hinterlässt 4 s brennenden Boden) | Phönixfeder-Gu (Drei Feuerbälle im Fächer) | Drachenatem-Gu (Jeder Aufschlag entfacht einen Flächenbrand (Radius 5)) |
| Strömung | Wasser | Strahl | Wasserlicht-Gu | Wasserbohrer-Gu (Durchbohrt alle Ziele auf der Linie) | Flutdrachen-Gu (Breiter Strahl mit Rückstoß, hinterlässt Wasserfläche) | Gezeitenstrahl-Gu (Sehr breiter Strahl, betäubt 0,6 s) | Meeresdrachen-Gu (Eine zweite, gewaltige Welle folgt) |
| Blitz | Blitz | Geschoss (schnell) | Funkenwurm-Gu | Blauplasma-Gu (Ignoriert Rüstung) | Kettenblitz-Gu (Springt auf bis zu 3 weitere Ziele) | Donnerwolf-Gu (Springt auf 3 weitere Ziele, jeder Treffer betäubt 0,3 s) | Himmelsdonner-Gu (Einschlag ruft einen Donnerschlag (Radius 3,5, doppelte Ladung)) |
| Frost | Eis | Geschoss | Frostnadel-Gu | Eisvogel-Gu (Trifft mit 2 Frost-Stapeln) | Frostnova-Gu (Wird zum Kreis um dich (Radius 3)) | Schneeball-Gu (Frostkreis Radius 5 und ein Eisfeld, das verlangsamt; längere Abklingzeit) | Frostdämon-Gu (Frostkreis Radius 7 mit drei Frost-Stapeln (sofort eingefroren) und einem Eisfeld; lange Abklingzeit) |
| Gift | Gift | Stich | Stachelwurm-Gu | Giftskorpion-Gu (Gift springt beim Tod des Ziels über) | Giftnebel-Gu (Wird zur Giftwolke (Zone, Radius 3); dreifache Abklingzeit) | Schwarzpfeil-Gu (Acht zielsuchende Giftpfeile) | Jadehimmel-Gu (Riesige Giftzone (Radius 6, 8 s, doppelte Stapel)) |
| Wirbel | Kraft | Kreis | Wirbelwind-Gu | Sogwirbel-Gu (Zieht Gegner vorher zu dir) | Bergschlag-Gu (Bodenschlag, betäubt 1 s) | Erdbeben-Gu (Größerer Wirbel, der 3 s nachzieht) | Berge-Ziehen-Gu (Betäubt 2 s, Radius +1,5) |
| Knochen | Blut | Geschoss | Blutdorn-Gu | Spiral-Knochenspeer-Gu (Durchbohrt Rüstung vollständig) | Blutschädel-Gu (Heilt dich um die Hälfte des Schadens) | Knochenerweichungs-Gu (Aufschlag schwächt alle im Umkreis 3 (2 Stapel)) | Blutschädel-Kaiser-Gu (Drei Speere, Hinrichtung (+60 % unter 30 % Leben)) |
| Haut | Metall | Schild | Steinhaut-Gu | Eisenhaut-Gu (Wirft Geschosse zurück) | Uralte-Bronzehaut-Gu (Unbeweglich: kein Rückstoß, keine Betäubung) | Goldglocken-Gu (Dornen: Angreifer werden zurückgestochen) | Schildkrötenjade-Wolfshaut-Gu (Heilt beim Aktivieren 15 % Leben, Dornen bleiben) |
| Blatt | Holz | Heilung | Lebenskraft-Blatt-Gu | Frisches-Blatt-Gu (Entfernt dabei Gift, Brand und Frost) | Lebensbrunnen-Gu (Wird zur Heilzone für dich und Gefährten) | Holzzauber-Gu (Zusätzlich 25 % Schadensreduktion für 8 s) | Lebensbaum-Gu (Heilzone Radius 6, sofortige Heilung für alle Verbündeten) |
| Sklaverei | Seele | Zähmen | Ratten-Sklaverei-Gu | Wolfs-Sklaverei-Gu (Auch mittelgroße Bestien; 2 Gefährten) | Bestien-Sklaverei-Gu (Ein Gefährte bleibt dauerhaft, bis er stirbt) | Bären-Sklaverei-Gu (Drei Gefährten, auch große Bestien) | Sklaverei-Gu (Fünf Gefährten) |
| Schritt | Raum | Bewegung | Sprungwurm-Gu | Wolkenschritt-Gu (Gleiten und ein Luft-Dash) | Schattenbild-Gu (Teleport 8 m, auch durch Gitter) | Blitzflügel-Gu (Teleport 14 m) | Blauer-Himmel-Gu (Teleport 20 m, danach 5 s +50 % Tempo) |
| Bestienphantom | Kraft | Kegel | Eberstoß-Gu | Großbär-Gu (Größerer Kegel (5 m, 120°)) | Alles-oder-nichts-Gu (Betäubt 0,6 s, danach 5 s +25 % Schaden) | Flugbär-Kraft-Gu (Nachschlag: Landung Radius 4 mit Rückstoß) | Kraft-leihen-Gu (Zweites Phantom (8 m, Wind), Hinrichtung) |
| Erdstachel | Erde | Zone | Dreh-Fels-Gu | Steinfaust-Gu (Radius 3, stößt weg) | Felssturz-Gu (Felsbrocken (Radius 3,5, betäubt 0,8 s)) | Berg-wie-zuvor-Gu (Stachelfeld Radius 4,5, Bergsturz Radius 5) | Erdloch-Gu (Taucht durch die Erde bis zu 10 m zum Ziel und bricht mit einem Beben hervor (Radius 6, betäubt 1,2 s)) |
| Windklinge | Wind | Kegel | Windklingen-Gu | Windwand-Gu (Breiter (80°), stärkerer Rückstoß) | Verletzungswind-Gu (Hinterlässt 3 s einen Klingenwirbel (Blutung)) | Sturmgeheul-Gu (Reichweite 10, betäubt 0,5 s) | Taifun-Gu (Taifun (Radius 5, 5 s) zieht Gegner hinein) |
| Sternschwarm | Stern | Schwarm | Sternenpfeil-Gu | Sternpfeil-Gu (Fünf Pfeile) | Sternlicht-Glühwürmchen-Gu (Sieben Sterne, jeder schwächt (Schwäche)) | Sternschnuppen-Gu (Sternschnuppe (Radius 3, doppelter Schaden)) | Sternentor-Gu (Zehn Sterne, Sternschnuppe, Teleport 6 m) |
| Schwertschatten | Schwert | Umkreisen | Klingenfaden-Gu | Schwertflügel-Gu (Drei Klingen, +2 s) | Schwertschatten-Gu (Vier Klingen, drei Schwertschatten als Geschosse) | Einzelklinge-Gu (+1 s, ignoriert Rüstung, Hinrichtung) | Zehntausend-Schwerter-Gu (Sieben Klingen (Radius 3, 9 s), sieben Schatten, stärkere Hinrichtung) |
| Seelenschrei | Seele | Kegel | Stummer-Mund-Gu | Wolfsseelen-Gu (Ruft einen Geisterwolf (12 s)) | Angstballung-Gu (Schwächt alle Getroffenen (2 Stapel)) | Seelenexplosion-Gu (Seelenexplosion am Ziel (Radius 4)) | Göttlicher-Sinn-Gu (Kegel 10 m / 120°, betäubt 0,8 s, zwei Wölfe) |
| Tarnung | Verbergen | Tarnung | Aura-Verschleierungs-Gu | Tarnschuppen-Gu (+2 s, +30 % Tempo) | Nebelschleier-Gu (Blendet alle im Umkreis 5 für 3 s) | Sternnebel-Tarn-Gu (Nebelzone folgt dir 6 s) | Aura-Verbergungs-Gu (Tarnung 12 s, danach 8 s +50 % Schaden und Tempo) |
| Blutmond | Blut | Geschoss | Blutstropfen-Gu | Blutmond-Gu (Drei Sicheln) | Blutguillotine-Gu (Hinrichtung, Blutspritzer am Aufschlag) | Blutrausch-Gu (20 % Lebensraub, 6 s +35 % Schaden) | Blutraserei-Gu (Sieben Sicheln, 3 s Rückprall) |
| Knochenrad | Knochen | Umkreisen | Knochensplitter-Gu | Knochenring-Gu (Drei Knochen, 20 % Schutz) | Knochenschild-Gu (30 % Schutz, +2 s) | Kampfknochenrad-Gu (Vier Räder, größer und schneller, stärkerer Schlag, +1 s) | Weißes-Knochenrad-Gu (Fünf Räder, 35 % Schutz, sechs Knochengeschosse) |
| Menschenfackel | Feuer | Aura | Glutatem-Gu | Feuerhaut-Gu (+2 s) | Selbstentzündungs-Gu (Radius +1, 6 s +20 % Schaden) | Glutpanzer-Gu (20 % Schutz, Dornen) | Sonnenkörper-Gu (Radius +3, 1,8-facher Schaden, 25 % Schutz) |
| Donnerknolle | Blitz | Falle | Knallsamen-Gu | Verkohlte-Donnerknolle-Gu (Drei Fallen, Blitz und Ladung) | Kettenknollen-Gu (Kettenblitz nach der Explosion) | Bebenknollen-Gu (Vier Fallen, Radius 3,5, betäubt 1 s) | Himmelsfeuer-Knollen-Gu (Sechs Fallen, Feuerfeld und Kettenblitz über 5 Ziele) |
| Wasserbild | Wasser | Beschwörung | Wasserspiegel-Gu | Zwillingsspiegel-Gu (Zwei Bilder) | Wasserbild-Gu (Zwei Wasserkrieger (12 s)) | Gezeitenwächter-Gu (Drei Krieger (15 s)) | Meeresgeist-Gu (Zwei Meeresgeister (20 s), Heilung für alle) |
| Goldener Tausendfüßler | Metall | Sturmlauf | Eisenzahn-Gu | Sägezahn-Gu (Durchbohrt Rüstung, +1 Blutung) | Stahlkiefer-Gu (Längerer Sturm, am Ende ein Rundumschnitt) | Kettensägen-Goldtausendfüßler-Gu (Hinrichtung, dreifacher Rundumschnitt – das Erbe des Blumenwein-Mönchs) | Himmelsgold-Tausendfüßler-Gu (Zwei Sturmläufe hintereinander, unaufhaltsam, jede Wunde blutet doppelt) |
| Kampfgeist | Kraft | Stärkung | Mutwurm-Gu | Tapferkeits-Gu (Stärker und länger, reinigt dich von Furcht und Schwäche) | Kampfrausch-Gu (Jeder Treffer heilt dich, du wirst schneller) | Berserkerherz-Gu (+50 % Schaden, unaufhaltsam, 20 % weniger Schaden) | Kriegsgott-Gu (+80 % Schaden, Rückprall, ein Kampfschrei stößt alle zurück) |
| Positionstausch | Raum | Positionstausch | Kleiner-Tausch-Gu | Sprungtor-Gu (Reichweite 14 m, am alten Platz blendet ein Lichtring (Radius 2,5)) | Positionstausch-Gu (Betäubt 1 s und verwundet) | Regenbogenlicht-Gu (Reichweite 18 m, Lichtexplosion (Radius 3,5) blendet 2 s) | Göttliche-Reise-Gu (Tauscht nacheinander mit drei Gegnern, jeder Tauschort explodiert) |
| Plünderhand | Diebstahl | Kegel | Langfinger-Gu | Raubgriff-Gu (Raub +50 %, Schwäche) | Plünder-Gu (Reichweite 6, zieht heran, Hinrichtung +40 %) | Gierige-Hand-Gu (Zweiter Griff nach 0,35 s mit doppeltem Raub) | Himmelsdieb-Gu (Zwei Griffe, danach 6 s +30 % Schaden) |
| Hartes Qi | Qi | Aura | Hartes-Qi-Gu | Kraft-Qi-Gu (25 % Schutz, stärkerer Stoß) | Himmelsschirm-Gu (Radius 5, 6 s, 30 % Schutz, 2 s Rückprall) | Menschen-Qi-Gu (35 % Schutz, heilt Verbündete darin) | Große-Qi-Mauer-Gu (40 % Schutz, Radius 6,5, 7 s, unaufhaltsam, am Ende eine Qi-Explosion) |
| Irrgarten-Formation | Formation | Zone | Irrweg-Gu | Drei-Wege-Irrgarten-Gu (Radius 3,7, Schwäche) | Schneekristall-Formation-Gu (Frost je Takt, am Ende 1,5 s eingefroren) | Sechs-Richtungen-Labyrinth-Gu (Radius 4,7, 6 s, zieht ins Zentrum) | Neun-Paläste-Formation-Gu (Zieht stärker, am Ende Einsturz (2,5×, betäubt 1,5 s)) |
| Zeitblase | Zeit | Zone | Dritte-Wache-Gu | Stundenglas-Gu (4,5 s, Zeitecho am Ende) | Jahresfluss-Gu (65 % langsamer, Echo 1,6× und 0,6 s Betäubung) | Tage-wie-Jahre-Gu (Radius 4, erstarrt 1 s zu Beginn, Echo 2×) | Frühling-Herbst-Hauch-Gu (Radius 5, erstarrt 1,5 s, Echo 2,5×; du heilst 25 % und wirst gereinigt) |
| Gedankenblitz | Weisheit | Eingebung | Gedankenblitz-Gu | Weisheits-Gu (2,5 s früher bereit, 25 % schneller) | Klarer-Geist-Gu (3,5 s früher, 30 % schneller für 6 s, +15 % Schaden) | Tausend-Gedanken-Gu (4,5 s früher, 35 % schneller für 7 s, ein Gedankenstoß betäubt 0,6 s) | Himmelsweisheit-Gu (Alle Gu sofort bereit, 8 s doppelt so schnell, +20 % Schaden, Gedankenstoß betäubt 0,8 s) |

### Gu-Aufstieg

Ein Gu steigt auf zwei Wegen zum nächsten Familienmitglied auf:
1. **Aufstiegsverfeinerung:** Gu + Pfad-Materialien (`aufstieg`, r2–r5) + Essenz. Chance und Kosten nach den Verfeinerungsformeln mit dem Zielrang. Bei Misserfolg sind die Materialien verloren, der Gu bleibt.
2. **Wild finden:** höherrangige Familienmitglieder leben in gefährlicheren Gebieten (`wilde_gu.rang` je Gebiet).

Der Zielrang darf höchstens 1 über dem eigenen Rang liegen. Ein aufgestiegener Gu **behält sein Merkmal**.

## 5. Merkmale: jeder wilde Gu ist ein Unikat

Wilde Gu tragen mit 40 % Chance ein Merkmal, mit etwa 1 % das seltene „Glänzend". Reine Daten, kein zusätzlicher Code außer Multiplikatoren.

| Merkmal | Wirkung |
|---|---|
| Genügsam | Hunger −50 % |
| Gierig | Hunger +50 %, Wirkung +15 % |
| Flink | Cooldown −20 % |
| Sparsam | Essenzkosten −20 % |
| Wild | Wirkung +25 %, 10 % Chance zu versagen |
| Zäh | verhungert nicht, fällt nur aus |
| Scheu | schwerer zu fangen, Aufstieg +15 % Chance |
| Dao-geprägt | doppelte Dao-Markierungen |
| Reizbar | Zustands-Stapel +1, Essenzkosten +15 % |
| Glänzend (selten) | Wirkung +30 %, leuchtet sichtbar |

Merkmale machen das Fangen wilder Gu spannend, auch wenn man die Familie schon besitzt. Das verlängert die Motivation ohne neue Inhalte.


## 6. Passive Gu

**Körper-Gu:** werden beim Verfeinern verbraucht und dauerhaft eingeprägt (kein Hunger, kein Unterhalt, kein Platz). Schlüssel: `grundschaden`, `max_hp`, `schaden_erlitten` (negativ = weniger).

| Körper-Gu | Rang | Wirkung |
|---|---|---|
| Rosa-Eber-Gu | 1 | grundschaden +4 |
| Schwarzeber-Gu | 1 | grundschaden +3, max_hp +10 |
| Weißer-Eber-Gu | 1 | grundschaden +3 |
| Jadehaut-Gu | 1 | schaden_erlitten -0.05 |
| Schlammhautkröten-Gu | 1 | max_hp +25 |
| Zehn-Jin-Kraft-Gu | 2 | grundschaden +12 |
| Weißjade-Gu | 2 | grundschaden +5, schaden_erlitten -0.08 |
| Eisenblut-Gu | 2 | max_hp +45 |
| Berserker-Gu | 2 | grundschaden +14, schaden_erlitten +0.1 |
| Jun-Kraft-Gu | 3 | grundschaden +27 |
| Eisenknochen-Gu | 3 | max_hp +60, schaden_erlitten -0.1 |
| Bitterkraft-Gu | 3 | grundschaden +20 |
| Jadeknochen-Gu | 3 | max_hp +90 |
| Tapferer-Kampf-Gu | 3 | grundschaden +12, max_hp +30 |
| Stahlsehnen-Gu | 3 | grundschaden +5, max_hp +30 |
| Krokodilkraft-Gu | 3 | grundschaden +8 |
| Panzer-Gu | 3 | max_hp +40, schaden_erlitten -0.12 |
| Knochen-Fleisch-Einheit-Gu | 4 | max_hp +180, schaden_erlitten -0.1 |
| Tausend-Jun-Kraft-Gu | 4 | grundschaden +55 |
| Berserker-Wut-Gu | 4 | grundschaden +40, schaden_erlitten +0.15 |
| Eiskristall-Gu | 4 | max_hp +50, schaden_erlitten -0.1 |
| Essenz-Eisenknochen-Gu | 5 | max_hp +320, schaden_erlitten -0.15 |
| Zehntausend-Jun-Kraft-Gu | 5 | grundschaden +110 |

**Hilfs-Gu:** belegen Kapazität und kosten Unterhalt; ihre Wirkung steht als Schlüssel in `hilfs_gu[].regeln` (`regen_mult`, `capacity_add`, `cap_mult`, `light`, `reveal`, `detection_mult`, `aggro_mult`, `harvest_hits`, `harvest_mult`, `cooldown_mult`, `essence_cost_mult`, `hunger_mult`, `insight_mult`, `move_speed_mult`, `hp_regen`, `refine_bonus`, `killer_mult`).

| Hilfs-Gu | Rang | Pfad | Wirkung |
|---|---|---|---|
| Schnaps-Wurm | 1 | Weisheit | Essenz-Regeneration +35 % |
| Hoffnungs-Gu | 1 | Weisheit | Gu-Kapazität +1, Apertur +10 % |
| Kleines-Licht-Gu | 1 | Licht | Lichtkreis bei Nacht; macht Lichtsiegel und versteckte wilde Gu sichtbar |
| Signal-Gu | 1 | Information | Zeigt Gegner und wilde Gu in doppelter Entfernung |
| Schleichstein-Gu | 1 | Metall | Wilde Gu fliehen seltener, Bestien bemerken dich später |
| Reisbeutel-Gras-Gu | 1 | Holz | Gu werden 30 % langsamer hungrig |
| Fußspur-Gu | 1 | Information | Namensschilder und wilde Gu 40 % weiter sichtbar |
| Brisen-Gu | 1 | Raum | Laufen 10 % schneller |
| Bohr-Gu | 2 | Metall | Rohstoffe brauchen einen Schlag weniger, seltenere Funde |
| Zwei-Aufgaben-Gu | 2 | Weisheit | Cooldowns −20 % |
| Vier-Geschmäcker-Schnapswurm | 2 | Weisheit | Essenz-Regeneration +50 % |
| Hellperlen-Gu | 2 | Licht | Lichtkreis, enthüllt Verborgenes, +30 % Sicht |
| Holzkohle-Gu | 2 | Raffinerie | Verfeinern +10 % Erfolg |
| Blitzauge-Gu | 2 | Blitz | Doppelte Sicht, 5 % schneller |
| Erdschatz-Blüte-Gu | 2 | Erde | Sammeln bringt 40 % mehr |
| Kaktuszeiger-Gu | 2 | Information | Zeigt alle wilden Gu des Gebiets auf der Karte |
| Sieben-Düfte-Schnaps-Wurm | 3 | Weisheit | Essenz-Regeneration +70 % |
| Wirkungs-Verstärker-Gu | 3 | Weisheit | Killer Moves +20 % Schaden, Eingebung ×1,5 |
| Schatzlicht-Gu | 3 | Glück | Sammeln +60 %, enthüllt Verborgenes |
| Seelensuch-Gu | 3 | Information | Dreifache Sicht auf Gegner und wilde Gu |
| Sofortiger-Erfolg-Gu | 3 | Raffinerie | Verfeinern +20 % Erfolg |
| Steinapertur-Gu | 3 | Erde | Aperturgröße +20 % |
| Luftsack-Gu | 3 | Raum | Gu-Kapazität +2 |
| Selbstständigkeits-Gu | 3 | Holz | Regeneriert 1,5 Leben/s |
| Menschenhaut-Gu | 3 | Verwandlung | Verkleidung: Rechtschaffene erkennen dich nicht (kein Angriff, kein Aufschlag, keine Kopfgeldjäger) |
| Donnerflügel-Gu | 3 | Blitz | Laufen 20 % schneller |
| Neun-Augen-Schnaps-Wurm | 4 | Weisheit | Essenz-Regeneration ×2, Eingebung ×1,5 |
| Sterngedanken-Gu | 4 | Weisheit | Eingebung ×2,5, Abklingzeiten −15 % |
| Himmels-Essenz-Schatzlotus-Gu | 4 | Holz | Essenz-Regeneration ×1,8, Apertur +15 % |
| Schneewäsche-Gu | 4 | Eis | Regeneriert 3 Leben/s |
| Bösartiger-Gedanken-Gu | 5 | Weisheit | Abklingzeiten −25 %, Essenzkosten −15 % |
| Hundert-Schlachten-unbesiegt-Gu | 5 | Raffinerie | Verfeinern +50 % Erfolg |
| Glücksschau-Gu | 5 | Glück | Sammeln ×2, enthüllt Verborgenes |
| Fadenspur-Gu | 5 | Information | Dreifache Sicht, Eingebung ×2 |

## 7. Killer Moves

Ein Killer Move verlangt je einen bereiten Gu zweier Familien. Es gibt drei Stufen: **Grundform (Rang 1)**, **Aufwertung (Rang 3)** und **Vollendung (Rang 5)**. Eine höhere Stufe desselben Paars wird erst erkannt, wenn beide Gu mindestens diesen Rang haben (Eingebung, `KAMPFSYSTEM.md`); sind mehrere bekannt, wird die höchste angeboten. Die Wirkung steht als Wirkungsschritte in `killer_moves[].schritte`.

| Killer Move | ab Rang | Familien | Wirkung |
|---|---|---|---|
| Bestiensturm | 1 | Bestienphantom + Wirbel | Ein Eberphantom stürmt im Wirbel: alles vor dir fliegt und bleibt betäubt liegen. |
| Blutgift-Stich | 1 | Gift + Blutmond | Blutklingen reißen Wunden, das Gift frisst sich hinein. |
| Blutknochenregen | 1 | Blutmond + Knochen | Sieben Blut-Knochen-Speere im Fächer, die Leben rauben. |
| Bronzebestie | 1 | Haut + Bestienphantom | Mit bronzener Haut stürmst du als Bestie durch die Reihen – unaufhaltsam. |
| Dampfexplosion | 1 | Strömung + Flamme | Wasser trifft auf Feuer: eine Dampfexplosion blendet und verbrüht alle. |
| Donnerfeld | 1 | Donnerknolle + Blitz | Fünf Donnerknollen im Kreis um dich; jede Explosion springt als Blitz weiter. |
| Donnerpanzer | 1 | Haut + Blitz | Panzer 6 s: jeder Angreifer erhält 3 Ladungsstapel |
| Mond der dritten Wache | 1 | Zeitblase + Mondlicht | Um Mitternacht dehnt sich die Zeit: Mondklingen hängen in der Luft und treffen Verlangsamte doppelt. |
| Eisflut | 1 | Frost + Strömung | Eine Flutwelle durchnässt alles, der Frost friert es im selben Atemzug ein. |
| Eislabyrinth | 1 | Irrgarten-Formation + Frost | Die Wände des Irrgartens sind aus Eis; wer lange genug umherirrt, erstarrt. |
| Erleuchtung | 1 | Gedankenblitz + Mondlicht | Ein Gedankenblitz im Mondlicht: sieben Klingen fliegen, und deine Gu laden schneller. |
| Feuersturm | 1 | Flamme + Wirbel | Flammenwirbel um dich; alle getroffenen Ziele brennen, Brand springt weiter |
| Feuerwind | 1 | Windklinge + Flamme | Ein Windstoß trägt Flammen weit nach vorn und facht sie immer wieder an. |
| Gewitterflut | 1 | Strömung + Blitz | Eine Flutwelle durchnässt alles vor dir, dann schlägt ein Blitz ein: garantierter Überschlag auf alle |
| Gletscherbruch | 1 | Frost + Wirbel | Eiswirbel friert alle im Umkreis ein und zerschmettert sie im Nachschlag |
| Glutwirbel | 1 | Menschenfackel + Wirbel | Ein Wirbel aus Glut dreht sich um dich und saugt Gegner in die Flammen. |
| Goldene Bestie | 1 | Goldener Tausendfüßler + Bestienphantom | Ein goldenes Bestienphantom mit Sägegliedern stürmt vor und zerfleischt alles. |
| Himmelsschild | 1 | Hartes Qi + Haut | Qi und eherne Haut legen sich übereinander – du und alle neben dir stehen wie ein Fels. |
| Klingenschritt | 1 | Schwertschatten + Schritt | Du jagst durch die Reihen, Klingen kreisen um dich. |
| Knochenbollwerk | 1 | Knochenrad + Haut | Sechs Knochenschilde und eine Steinhaut: fast nichts dringt zu dir durch. |
| Knochenfestung | 1 | Knochen + Haut | Knochenpanzer 6 s: jeder Treffer auf dich schießt einen Knochendorn zurück (kostet HP) |
| Knochensturm | 1 | Knochen + Knochenrad | Knochenräder kreisen um dich und schleudern Splitter in alle Richtungen. |
| Kriegsschrei | 1 | Kampfgeist + Seelenschrei | Dein Kampfschrei stärkt dich und lässt Gegner vor Angst erstarren. |
| Lebensschirm | 1 | Hartes Qi + Blatt | Unter dem Qi-Schirm wachsen Blätter: wer darin steht, heilt und hält aus. |
| Minenfeld | 1 | Donnerknolle + Erdstachel | Die Erde verschluckt Knollen in einem weiten Kreis – wer darauf tritt, fliegt. |
| Mondfrost | 1 | Mondlicht + Frost | Ein Kranz aus Mondsicheln fliegt nach außen; wen sie treffen, der erstarrt im Frost. |
| Mondschritt | 1 | Mondlicht + Schritt | Du jagst durch eine Gegnerreihe und hinterlässt Mondklingen auf deinem Weg |
| Pestfeuer | 1 | Gift + Flamme | Giftwolke, die sich entzündet: große Giftexplosion und brennender Boden |
| Phönixatem | 1 | Menschenfackel + Blatt | Glut heilt statt zu verzehren: du regenerierst, während ein Feuerkreis dich schützt. |
| Quellsegen | 1 | Blatt + Wasserbild | Eine Quelle heilt dich und deine Verbündeten, zwei Wasserbilder stehen dir bei. |
| Roter Mond | 1 | Mondlicht + Blutmond | Eine rote Mondsichel schneidet tief und lässt das Ziel bluten. |
| Rudelrausch | 1 | Kampfgeist + Sklaverei | Dein Kampfgeist springt auf das Rudel über: alle Gefährten werden geheilt und rasen. |
| Rudelsegen | 1 | Sklaverei + Blatt | Heilt und stärkt alle Gefährten, ein weiterer Gefährte erscheint für 20 s |
| Rudelsturm | 1 | Sklaverei + Windklinge | Ein Wind treibt dein Rudel an: Gefährten werden schneller und stärker, ein Wolf eilt herbei. |
| Schattendieb | 1 | Plünderhand + Tarnung | Du verschwindest und greifst aus dem Nichts zweimal zu – der Beraubte weiß nicht, wie ihm geschieht. |
| Schattenschritt | 1 | Tarnung + Schritt | Du verschwindest und tauchst hinter deinem Ziel wieder auf. |
| Schlammflut | 1 | Erdstachel + Strömung | Eine Flut durchnässt alles, dann brechen Erdstacheln hervor: Schlamm hält alle fest. |
| Schleichgift | 1 | Tarnung + Gift | Du verschwindest und hinterlässt eine Giftwolke; dein nächster Schlag trifft aus dem Nichts. |
| Seelenknechtschaft | 1 | Seelenschrei + Sklaverei | Ein Schrei lässt alle erstarren, zwei Geisterwölfe fallen über sie her. |
| Seelenraub | 1 | Plünderhand + Seelenschrei | Ein Schrei lähmt vor Angst, dann greift die Geisterhand zu und reißt Essenz aus den Erstarrten. |
| Sonnenflamme | 1 | Flamme + Menschenfackel | Dein Körper wird zur Fackel und entlädt eine Feuerwelle um dich. |
| Spiegelflut | 1 | Wasserbild + Strömung | Zwei Wasserbilder springen aus einer Flutwelle, die alles zurückwirft. |
| Sternenregen | 1 | Sternschwarm + Erdstachel | Sterne markieren die Feinde, dann stürzen drei Felsbrocken auf sie. |
| Sternenmond | 1 | Sternschwarm + Mondlicht | Neun Mond- und Sternenklingen suchen sich selbst ihr Ziel. |
| Sturmblitz | 1 | Blitz + Windklinge | Ein Windstoß trägt Blitze nach vorn; sie springen von Ziel zu Ziel. |
| Tauschfalle | 1 | Positionstausch + Donnerknolle | Du legst Knollen um dich – und tauschst den Platz mit einem Gegner, der mitten darauf landet. |
| Vorausgedacht | 1 | Gedankenblitz + Donnerknolle | Du weißt schon, wohin sie laufen werden: Knollen liegen bereit, und deine Gu laden schneller. |
| Klingenwirbel | 1 | Windklinge + Schwertschatten | Kreisende Klingen im Sturm: der Wind trägt sie weit nach außen. |
| Wirbeltausch | 1 | Positionstausch + Wirbel | Du springst an den Platz eines Gegners und wirbelst alles um dich herum durcheinander. |
| Alles verschlingen | 3 | Bestienphantom + Blutmond | Ein Blutphantom verschlingt alles vor dir und gibt dir das Leben zurück. |
| Bergleib | 3 | Erdstachel + Haut | Dein Körper wird zu Fels; wer dich trifft, bebt mit, und die Erde schlägt um dich aus. |
| Bergsturz | 3 | Erdstachel + Bestienphantom | Ein Bärenphantom schlägt auf den Boden, ein Bergsturz begräbt die Getroffenen. |
| Blitzklingen | 3 | Blitz + Schwertschatten | Klingen aus reinem Blitz kreisen um dich und entladen sich auf jeden, den sie berühren. |
| Blutfeuer | 3 | Blutmond + Menschenfackel | Dein Blut entzündet sich: brennende Sicheln, und jeder Treffer heilt dich. |
| Blutfrost | 3 | Frost + Blutmond | Gefrorenes Blut: Eissplitter reißen Wunden und frieren sie zu. |
| Blutraub | 3 | Plünderhand + Blutmond | Blutige Hände reißen Leben und Essenz zugleich heraus. |
| Blutsäge | 3 | Goldener Tausendfüßler + Blutmond | Blutige Sägezähne reißen tiefe Wunden – jede nährt dich. |
| Bösartiger Gedanke | 3 | Gedankenblitz + Gift | Ein kalt berechneter Plan: Gift, Furcht und schnellere Gu – alles in einem Augenblick. |
| Diebessprung | 3 | Plünderhand + Schritt | Ein Schritt durch den Raum bis vor den Gegner, zwei Griffe – und du bist mit seiner Essenz schon weg. |
| Donnerdrachen-Flut | 3 | Strömung + Blitz | Eine breite Flut, dann ein Blitzdrache, der über alle Nassen springt. |
| Donnerkönig | 3 | Haut + Blitz | Ein Donnerpanzer, der Angreifer auflädt und alle drei Sekunden entlädt. |
| Donnersturm | 3 | Blitz + Windklinge | Ein Gewittersturm zieht Gegner in seine Mitte und schlägt mit Blitzen ein. |
| Eismondsichel | 3 | Mondlicht + Frost | Drei riesige Eissicheln durchbohren alles in einer Reihe und frieren es ein. |
| Eissarg | 3 | Frost + Wirbel | Ein Eissturm friert alle im Umkreis 7 ein und zerschmettert sie doppelt. |
| Eistausch | 3 | Positionstausch + Frost | Du springst an den Platz des Gegners; wo du standest, erstarrt er in einem Eisblock. |
| Erdbebenfeld | 3 | Donnerknolle + Erdstachel | Ein Beben reißt den Boden auf; darin liegen Knollen, die nacheinander hochgehen. |
| Feuerlotus-Sturm | 3 | Flamme + Wirbel | Ein Lotus aus Flammen erblüht im Wirbel und brennt noch lange nach. |
| Flammenkaiser | 3 | Flamme + Menschenfackel | Eine Feuersäule steigt am Ziel auf, danach regnen Glutkugeln in weitem Kreis. |
| Frühlingsrückkehr | 3 | Zeitblase + Blatt | Für dich läuft die Zeit rückwärts zum Frühling: Wunden schließen sich, Gifte weichen, Feinde erstarren. |
| Geisterschrei | 3 | Seelenschrei + Tarnung | Ein unsichtbarer Schrei lähmt alle vor Angst, während du im Nebel verschwindest. |
| Giftquelle | 3 | Gift + Wasserbild | Ein vergiftetes Wasserbild wandelt umher und hinterlässt eine Giftlache. |
| Gifttausch | 3 | Positionstausch + Gift | Du hinterlässt eine Giftwolke und tauschst den Platz mit einem Gegner – er landet mitten darin. |
| Goldpanzer-Sturm | 3 | Goldener Tausendfüßler + Haut | Mit goldener Haut und Sägearm walzt du unaufhaltsam durch die Reihen. |
| Goldraub | 3 | Goldener Tausendfüßler + Plünderhand | Der goldene Tausendfüßler rast durch die Reihen und reißt jedem Uressenz aus dem Leib. |
| Klingenbestie | 3 | Schwertschatten + Bestienphantom | Ein Bestienphantom aus Klingen stürmt vor und zerfetzt alles vor dir. |
| Klingenrad | 3 | Knochenrad + Schwertschatten | Knochen und Klingen verschmelzen zu einem kreisenden Schutzrad, das schneidet und schützt. |
| Knochenkarussell | 3 | Knochenrad + Positionstausch | Du tauschst mit einem Gegner und landest mitten zwischen seinen Gefährten – Knochenräder fegen um dich. |
| Knochenzitadelle | 3 | Knochen + Haut | Ein Knochenpanzer, dazu vier kreisende Knochenspeere. |
| Lebensquell | 3 | Blatt + Wasserbild | Ein Heilteich breitet sich um dich aus, ein Wasserkrieger wacht darüber. |
| Mondschatten-Tanz | 3 | Mondlicht + Schritt | Du jagst durch die Reihe und entlässt am Ende einen Fächer aus Mondklingen. |
| Pestsonne | 3 | Gift + Flamme | Eine Giftsonne geht über dem Feld auf und entzündet sich zu einer riesigen Explosion. |
| Qi-Bestie | 3 | Hartes Qi + Bestienphantom | Kraft-Qi verfestigt dein Bestienphantom: es rast als harte Qi-Gestalt geradeaus durch alle Gegner. |
| Qi-Sturm | 3 | Hartes Qi + Windklinge | Die Qi-Hülle platzt in einem Sturm nach außen und fegt alle Gegner davon. |
| Rasende Bestie | 3 | Kampfgeist + Bestienphantom | Im Kampfrausch wird dein Bestienphantom doppelt so groß. |
| Rudelkönig | 3 | Sklaverei + Blatt | Heilt alle Gefährten voll und ruft zwei Blitzwölfe. |
| Schattenmord | 3 | Tarnung + Schritt | Aus dem Nichts ein Stich ins Herz – gegen Geschwächte tödlich. |
| Seelenlabyrinth | 3 | Irrgarten-Formation + Seelenschrei | Ein Schrei fährt in den Irrgarten: die Gefangenen verlieren den Verstand und fliehen blind. |
| Seelensturm | 3 | Seelenschrei + Windklinge | Ein heulender Sturm voller Seelenschreie: Furcht und Schwäche für alle. |
| Seuchenmond | 3 | Gift + Blutmond | Ein fauliger roter Mond schwebt über dem Ziel und saugt Leben aus allem darunter. |
| Steinlabyrinth | 3 | Irrgarten-Formation + Erdstachel | Steinwände wachsen aus dem Boden und drängen alle in die Mitte, wo die Erde einbricht. |
| Sternenklingen | 3 | Sternschwarm + Schwertschatten | Sterne werden zu Klingen und kreisen, dann schießen sie auf das Ziel. |
| Sternennebel-Hinterhalt | 3 | Tarnung + Sternschwarm | Aus dem Sternennebel stürzen zwölf Sterne auf alle Geblendeten. |
| Sterngedanke | 3 | Gedankenblitz + Sternschwarm | Deine Gedanken ordnen sich wie Sternbilder: Sterne suchen jeden Gegner, deine Gu sind früher bereit. |
| Unerschütterlicher Wille | 3 | Kampfgeist + Hartes Qi | Kampfgeist und hartes Qi: du wirst stärker, nichts wirft dich um, und wer neben dir kämpft, ist geschützt. |
| Zeitdonner | 3 | Zeitblase + Blitz | Blitze fallen in die Zeitblase – und fallen im Echo ein zweites Mal. |
| Zeitspiegel | 3 | Wasserbild + Zeitblase | Zwei Wasserbilder treten aus deiner Vergangenheit, während die Zeit um dich zäh wird. |
| Erdschlund | 5 | Erdstachel + Bestienphantom | Die Erde öffnet sich unter den Feinden und schließt sich wieder. |
| Ewiger Winter | 5 | Zeitblase + Frost | Die Zeit gefriert: in der Blase wird es kälter und kälter, bis alles zu Eis zerspringt. |
| Ewiges Eis | 5 | Frost + Wirbel | Alles im Umkreis 10 erstarrt zu ewigem Eis und zerspringt. |
| Glühendes Qi | 5 | Hartes Qi + Menschenfackel | Deine Qi-Hülle glüht wie ein Brennofen; wenn sie vergeht, explodiert sie in einer Feuerwelle. |
| Herr der Bestien | 5 | Sklaverei + Bestienphantom | Drei Bestienphantome brechen hervor und zwei Blitzwölfe folgen dir. |
| Himmelsbrand | 5 | Flamme + Wirbel | Der Himmel brennt: ein Feuersturm im Umkreis 10, Feuerregen und ein Flammenmeer. |
| Weißknochen-Himmelsrad | 5 | Knochen + Knochenrad | Ein gewaltiges Knochenrad walzt in einer Linie über das Schlachtfeld und schützt dich danach. |
| Jadehimmel-Brand | 5 | Gift + Flamme | Das uralte Jadegift senkt sich über das Land und entzündet sich. |
| Klingen-Sternbild | 5 | Sternschwarm + Schwertschatten | Ein Sternbild aus hundert Klingen senkt sich auf das Schlachtfeld. |
| Klingentausch | 5 | Positionstausch + Schwertschatten | Tausch um Tausch: an jedem Ort, an dem du auftauchst, kreisen Schwerter. |
| Irrgarten der Knollen | 5 | Donnerknolle + Irrgarten-Formation | Ein Irrgarten zieht alle in seine Mitte – dort liegen die Knollen schon bereit. |
| Kriegsrat | 5 | Kampfgeist + Gedankenblitz | Ein Plan wie ein Blitz: alle Gu sind sofort bereit, und du schlägst mit der Kraft eines Heeres. |
| Mondfinsternis | 5 | Mondlicht + Schritt | Drei Schritte durch die Dunkelheit, jeder hinterlässt einen Mondsturm. |
| Sarg des Nordmeers | 5 | Frost + Strömung | Das Meer steigt und gefriert: ein ganzes Feld erstarrt zu Eis, dann bricht es. |
| Raubtierrudel | 5 | Plünderhand + Sklaverei | Dein Rudel fällt über die Feinde her, und jeder Biss, jeder Griff raubt dir neue Essenz. |
| Schwertgedanke | 5 | Gedankenblitz + Schwertschatten | Jeder Gedanke wird zur Klinge: Schwerter kreisen um dich, und alle Gu sind früher bereit. |
| Sonnensturz | 5 | Flamme + Menschenfackel | Eine kleine Sonne stürzt herab und hinterlässt ein brennendes Feld. |
| Spiegelseelen | 5 | Wasserbild + Seelenschrei | Drei Seelenbilder schreien gleichzeitig – wer sie hört, zerbricht an der Angst. |
| Sternenformation | 5 | Irrgarten-Formation + Sternschwarm | Die Formation spiegelt den Sternenhimmel: aus ihren Ecken regnen Sterne auf alles darin. |
| Sternenkaiser | 5 | Sternschwarm + Mondlicht | Ein Sternenhimmel öffnet sich: sechzehn Sterne und drei Sternschnuppen. |
| Taifun der Seelen | 5 | Seelenschrei + Windklinge | Ein Taifun aus Seelen zieht alles in sein Zentrum, voller Furcht und Schwäche. |
| Tausend Donner | 5 | Strömung + Blitz | Eine Sturmflut, dann tausend Donner: jeder Nasse wird mehrfach getroffen. |
| Tausend-Jahre-Säge | 5 | Goldener Tausendfüßler + Zeitblase | Die Zeit steht fast still, und die goldene Säge fährt dreimal durch alles, was darin gefangen ist. |
| Tausend-Klingen-Sturm | 5 | Goldener Tausendfüßler + Schwertschatten | Tausend goldene Glieder lösen sich als Klingen und kreisen, während du durchbrichst. |
| Unsterblicher Knochen | 5 | Knochen + Haut | Ein unzerstörbarer Knochenleib: unaufhaltsam, Dornen, sechs Knochenräder. |
| Unsterblicher Krieger | 5 | Kampfgeist + Haut | Für einige Sekunden kann dich nichts fällen – du heilst, prallst zurück und schlägst doppelt. |
| Verlorener Pfad | 5 | Irrgarten-Formation + Positionstausch | Du baust einen Irrgarten um dich und tauschst den Platz mit dem stärksten Gegner – er bleibt darin gefangen. |
| Zehntausend Klingen | 5 | Schwertschatten + Schritt | Du wirst zum Klingensturm: Sprung, zehn kreisende Klingen, ein Hagel aus Schwertschatten. |
| Zeitsprung | 5 | Zeitblase + Schritt | Du springst durch die Zeit: am Ausgangspunkt bleibt eine Blase stehen, die alles erstarren lässt, und für dich laufen die Gu schneller. |

## 8. Hebel 4: dieselben Regeln in der Welt

Zustände wirken auch auf Objekte. Dadurch wird jede Familie zu einem Werkzeug der Erkundung, ohne dass ein eigenes Rätselsystem gebaut werden muss.

| Familie | In der Welt |
|---|---|
| Mondlicht / Kleines Licht | blendet Nachtwesen, lässt Lichtsiegel aufleuchten, enthüllt versteckte Gu |
| Flamme | brennt Ranken, Dornenhecken und Gras ab; entzündet Fackeln |
| Strömung | löscht Feuerbarrieren, füllt Becken, macht Flächen nass |
| Blitz | lädt Ruinenmechanismen auf; elektrisiert nasse Flächen (Falle für Gegner) |
| Frost | friert Wasser zu begehbarem Eis |
| Gift | zersetzt Pilzbarrieren und morsche Wurzeln |
| Wirbel | zertrümmert Felsbrocken, verweht Nebel und Giftwolken |
| Knochen | öffnet Blutsiegel an alten Klan-Toren |
| Haut | schützt beim Durchqueren von Dornen- und Giftfeldern |
| Blatt | lässt Kletterranken wachsen |
| Sklaverei | Ratten erreichen enge Gänge, Tiere lenken ab oder tragen Beute |
| Schritt | erreicht Vorsprünge, Schluchten, Inseln |

**Wilde Gu, Truhen und Erbschaften werden hinter solchen Hindernissen versteckt.** Das erzeugt die Metroidvania-Schleife „das sehe ich, komme aber noch nicht hin" und macht jeden neuen Gu doppelt wertvoll. Das Leveldesign braucht dafür nur eine Handvoll wiederverwendbarer Objekte: brennbare Hecke, Wasserfläche, Felsbrocken, Ruinenschalter, Lichtsiegel, Blutsiegel, Vorsprung.


Die zwölf neuen Familien haben ebenfalls Welt-Wirkungen (`welt` je Familie): Phantome zertrümmern Felsen, Erdstacheln brechen Felsbrocken, Wind verweht Wolken, Klingen zerschneiden Hecken, Seelenschreie vertreiben Geister, Tarnung schleicht an Wächtern vorbei, Knollen sprengen Tore, Wasserbilder lösen Druckplatten aus.

## 9. Wirkungsschritte und Ranggaben

**Wirkungsschritte** (`EffectSteps`, `scripts/systems/effect_steps.gd`) sind Dictionaries mit `t` (Art) und Parametern. Schaden eines Treffers = Grundschaden des Auslösers × `mult`.

| Art | Parameter |
|---|---|
| `circle` | `radius`, `at` (`self`, `target`, `aim`, `point`), `distance` |
| `line` | `length`, `width`, `dash` (Wirker gleitet ans Ende) |
| `cone` | `reach`, `angle` |
| `projectiles` | `count`, `spread` (Grad), `range`, `speed`, `pierce`, `homing`, `explode` |
| `chain` | `jumps`, `radius` |
| `zone` | `radius`, `time`, `tick`, `slow`, `pull`, `heal` (Anteil Leben je Takt für Verbündete), `ally_reduction` (Schutz für Verbündete darin), `end` (Schritte, wenn die Zone vergeht), `follow`, `at` |
| `orbit` | `count`, `radius`, `time`, `speed`, `tick`, `reduction`, `size` |
| `trap` | `count`, `spacing`, `trigger`, `radius`, `time`, `then` (Schritte am Explosionsort) |
| `delay` | `time`, `then` |
| `armor` | `kind` (`thorns`, `thunder`), `time`, `reduction`, `value` oder `value_mult` |
| `heal` | `frac`, `time`, `allies`, `radius` |
| `summon` | `enemy`, `count`, `time` (Spieler: Gefährten, Bestien: Diener) |
| `buff` | `key`, `damage`, `speed`, `reduction`, `time` |
| `stealth` | `time` |
| `teleport` / `dash` | `distance`; `teleport` mit `to: "target"` taucht direkt vor dem Ziel auf |
| `cleanse`, `unstoppable`, `reflect` | `time` |
| `swap` | `range`, `fresh` (ein anderes Ziel als zuletzt) – Positionstausch, dann Treffer |
| `haste` | `refund` (Sekunden sofort), `cd_mult`, `time` – Abklingzeiten der anderen Gu |

**Treffer-Parameter** jedes Schritts: `mult`, `tags`, `status`, `stacks`, `stun`, `knockback` (+ weg, − heran), `lifesteal`, `execute` (Bonus unter 30 % Leben), `pierce_armor`, `slow`/`slow_time`, `blind`, `freeze`, `set_stacks`, `essence_steal` (raubt Uressenz im Verhältnis zum Schaden), `color`.

**Ranggaben** (`mitglieder[].gaben`, `GuGifts`) erben sich nach oben; Zahlen addieren sich (Rang 3 mit `count_add: 1` nach Rang 2 mit `count_add: 1` = +2; der `ranggabe`-Text nennt das Ergebnis), außer `fan_angle`, `as_circle`, `teleport`, `chain_radius`, `width_mult`, `orbit_speed` und `cd_mult`, die der höhere Rang ersetzt. Listen und Objekte ersetzt der höhere Rang:
`pierce`, `pierce_armor`, `fan`/`fan_angle`, `homing`, `chain`/`chain_radius`, `impact` (Schritte am Aufschlag), `radius_add`, `beam_all`, `width_mult`, `knockback`, `stacks_add`, `spread_on_death`, `stun`, `lifesteal`, `execute`, `as_circle`, `as_zone`, `pull`, `reflect`, `unstoppable`, `cleanse`, `heal_zone`, `companions_add`, `permanent`, `glide`, `air_dash`, `teleport`, `extra` (Schritte nach dem Wirken), für die neuen Wirkformen außerdem `step` (überschreibt Schritt-Parameter), `then`, `count_add`, `time_add`.

### Verschmelzen (Rezepte)

`gu_system.json → rezepte` verbindet Gu zu stärkeren, wie in Reverend Insanity: **Weißjade = Weißer Eber + Jadehaut**, die Schnapswurm-Reihe (Schnaps-Wurm → Vier Geschmäcker → Sieben Düfte → Neun Augen), Tausend- und Zehntausend-Jun-Kraft, Knochen-Fleisch-Einheit, Essenz-Eisenknochen, Himmels-Essenz-Schatzlotus, Berserker-Wut. Dazu Menschenhaut (Tarnschuppe + Schlammhaut), Kaktuszeiger, Donnerflügel, Panzer, Krokodilkraft, Stahlsehnen, Eiskristall und zwei Abkürzungen für aktive Gu: Mondsichel (Fang Yuans Mondglanz-Versuch, 50 %) und Blutschädel. Jedes Rezept: `ergebnis`, `aus` (verbrauchte Gu), `material`, `chance`, `hinweis`. Misslingt die Verschmelzung, ist nur das Material verloren (`GuRecipes`, Seite „Verschmelzen“ im Gu-Menü).

## 10. Spielstart

Beim Erwachen wählt der Spieler seinen ersten Gu aus vier Rang-1-Familien: Mondlicht (Gu-Yue-Klan, Standard), Glutfunke, Wasserlicht oder Wirbelwind. Alle anderen Rang-1-Gu leben wild auf dem Qing-Mao-Berg.

## 11. Balancing-Grundlage

Ein Rang-1-Angriffs-Gu macht pro Sekunde Abklingzeit etwa 8–12 Schaden und kostet 4–8 Essenz; Kontroll-, Fallen- und Beschwörungs-Gu machen weniger Direktschaden, weil ihr Wert in Reaktionen, Kontrolle oder Gefährten liegt. Höhere Ränge skalieren über die Formel und die Ranggabe. Leitplanken gegen Ausreißer:
- **Fächer** (`fan`): jede Klinge trifft mit `min(1, 2,2 / Anzahl)`; Aufschlag-Wirkungen (`impact`) nur an der mittleren Klinge.
- **Schwarm**: alle Sterne zusammen höchstens 3-facher Grundschaden, **Fallen** zusammen höchstens 2,5-fach.
- Ranggaben, die eine Wirkform in eine lange Zone oder großen Kreis verwandeln, verlängern die Abklingzeit (`cd_mult`).
- **Fallen-Folgeschritte** (`then`, z. B. Feuerfeld und Kettenblitz) teilen sich den Schaden wie die Fallen selbst.
- Beschworene Wesen erhalten die Rangstärke des Gu relativ zu ihrem eigenen Rang (`EnemyData.rank`); Verbündete (Spieler, Gefährten) gehen durcheinander hindurch, damit Gefährten nicht hinter dir hängen bleiben.
- **Rückstoß** ist ein einmaliger Geschwindigkeitsstoß (`knockback_force` m/s je Punkt, mehrere Treffer zusammen höchstens `knockback_max_speed`); Rückstoß 1 schiebt etwa 2 m.
- **Kontrolle nimmt ab:** Betäubung und Einfrieren wirken in Folge 100 %, 50 %, 25 % … (`cc_diminish`), bis `cc_reset_time` Sekunden keine Kontrolle mehr kam; eine laufende Kontrolle wird nicht verlängert. Kein Dauer-Festsetzen, weder von Bestien noch vom Spieler.
- **Killer Moves** sind je Stufe gedeckelt (`killer_total_cap`: Stufe 1 ×7, Stufe 3 ×10, Stufe 5 ×15 Grundschaden auf ein Ziel, inklusive `mult`; Zonen mit allen Takten, zielsuchende Geschosse vollständig gezählt). Stärkere Einträge werden gleichmäßig gedämpft (`KillerMoveEffects.cap_scale`).
- **NPC-Gu-Meister** wirken Killer Moves nach denselben Regeln (höchste Stufe ihrer Gu-Paare, Kosten ×2), kündigen sie mit mindestens 1,45 s Ausholzeit und Warnkreis an und höchstens alle 14 s (`master_killer_*`).
- **Blutpfad** (`hp_kosten`) kostet Prozent des Höchstlebens, damit der Preis mit dem Rang wächst; NPC-Meister zahlen ihn auch.
- **Essenzraub** (`essence_steal`, Plünderhand): geraubte Essenz = Schaden × Faktor × (Essenzvorrat ÷ Höchstleben des Räubers), damit der Raub mit dem Rang mitwächst; Gu-Meister verlieren dieselbe Menge.
- **Eingebung** (Gedankenblitz) verkürzt nur die anderen Gu; sich selbst beschleunigt sie nicht.
- **Positionstausch** versetzt keine Unaufhaltsamen (sie werden nur getroffen).
- **Bestien-Leben** wächst stärker als die Formel allein (Rang 2 ×2,2 … Rang 5 ×3,8 gegenüber dem Prototyp), **Gu-Meister** bekommen `master_hp_rank_mult` (Schutz-Gu, Erfahrung).

Zielwerte (Spieler Stufe 2 mit vier Gu seines Rangs): gleichrangige Bestie in 3–15 s besiegt, gleichrangiger Gu-Meister im Duell in 6–17 s; Bestien brauchen ohne Ausweichen 15–60 s, um dich zu besiegen, starke Meister 5–10 s.

Messen mit `godot --headless --fixed-fps 60 --path . --script res://tools/balance_probe.gd`:
- ohne Zusatz: Spieler je Rang gegen typische Bestien,
- `-- --solo`: Schaden pro Sekunde jeder Familie je Rang gegen ein stehendes, nicht wegstoßbares Ziel in 2 m,
- `-- --masters`: Duell gegen jeden NPC-Gu-Meister auf seinem Rang (Lebenskosten des Meisters zählen nicht als dein Schaden).

## 12. Prüfung

`tests/test_gu_catalog.gd` löst jeden Gu (alle Familien, alle Ränge), jeden Killer Move und jede Bestien-Fähigkeit im laufenden Spiel aus und prüft, dass etwas wirkt (Schaden an Übungszielen, Schild, Heilung, Bewegung, Tarnung, Stärkung, Gefährten). Der Datenimport prüft alle Schritte, Zustände, Tags und Beschwörungs-IDs (`tools/step_validator.gd`).
