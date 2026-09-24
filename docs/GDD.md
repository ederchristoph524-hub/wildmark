# Wildmark – Game Design Document

## Vision

Ein düsteres Open-World-Survival-RPG, in dem du als junger Gu-Meister in einer gnadenlosen Welt überlebst und aufsteigst. Stärke kommt nicht von Leveln, sondern davon, welche Gu du findest, fütterst, verfeinerst und wie klug du sie kombinierst. Ressourcen sind knapp, jede Entscheidung kostet etwas.

**Maßstab:** Valheim-Größe, nicht GTA. Eine kleinere, handgebaute Welt mit tiefen Systemen statt einer riesigen, leeren Karte.

**Plattformen:** Browser am Handy (Hauptziel beim Entwickeln) und PC. Ein Spieler, offline.

## Design-Säulen

Jedes neue Feature muss mindestens eine Säule stärken und darf keine schwächen.

1. **Knappheit:** Uressenz, Gu-Futter und Urstein sind immer knapp. Jeder Gu hat laufende Kosten.
2. **Kombination statt Grind:** Tiefe entsteht aus Zuständen, Reaktionen und Killer Moves, nicht aus Zahlen, die nach oben gehen.
3. **Gefährlicher Aufstieg:** Durchbrüche können scheitern, höhere Ränge sind tödlich, Kalamitäten können alles kosten.
4. **Moralisch grau:** Keine gute oder böse Seite, nur Interessen. Klans, Sekten, Einzelgänger.

## Nicht-Ziele

Damit der Umfang beherrschbar bleibt, wird Folgendes bewusst **nicht** gebaut: Mehrspieler, Fahrzeuge, Sprachausgabe, prozedural generierte Endloswelt, realistische Grafik, Crafting von Waffen und Rüstungen als Kernsystem.

## Kern-Loop

- **Minuten:** erkunden → sammeln und jagen → Gu füttern → kämpfen mit Gu und Killer Moves → Beute
- **Stunden:** Gu finden und verfeinern → Killer Moves entdecken → meditieren und die Aperturwand verfeinern → Durchbruch
- **Langfristig:** Ränge aufsteigen → neue Regionen → Sekte oder eigener Weg → Unsterblichkeit (Rang 6+) mit eigener Apertur-Welt und Kalamitäten

## Zeit

Ein Spieltag dauert 20 Minuten Echtzeit, davon 7 Minuten Nacht. Nachts sind Bestien stärker und zahlreicher, manche erscheinen nur nachts. Gu brauchen etwa einmal pro Spieltag Futter. Alle Raten werden aus der Taglänge abgeleitet (siehe `docs/FORMELN.md`, Abschnitt Zeit).

## Systeme

Die meisten Systeme existieren im 2D-Prototyp und werden mit dessen Werten übernommen. Daten: `docs/daten/`, Formeln: `docs/FORMELN.md`.

### Geburt und Talent
Zufälliger oder gewählter Talentgrad D, C, B, A oder „Durchbrochen". Er bestimmt Essenz-Kapazität, Regeneration, Durchbruchschance und den höchsten erreichbaren sterblichen Rang (D: Rang 2, C: 3, B: 4, A: 5). Ein D-Talent ist damit ein echtes Handicap, das nur über Umwege (seltene Gu, Erbschaften) überwunden werden kann.

### Apertur, Uressenz und Kultivierung
- Rang 1–9, je vier Stufen (Anfangs-, Mittel-, Ober-, Höchststufe).
- Uressenz regeneriert von selbst; Urstein und bestimmte Gu beschleunigen das.
- **Meditation:** Der Spieler leitet Essenz gegen die Aperturwand. Ist die Wand verfeinert, steigt er eine Stufe auf (mehr HP und Grundschaden). Meditieren macht verwundbar, also sucht man dafür sichere Orte.
- **Durchbruch** zum nächsten Rang ab der Höchststufe mit fast voller Apertur; Erfolgschance nach Talentgrad. Scheitern kostet 60 % der Essenz.

### Gu
Vollständig in `docs/GU_SYSTEM.md`. Kurz: 12 Gu-Familien mit je drei Rängen, aufgebaut aus wenigen Wirkformen, sechs Zuständen und acht Reaktionen; dazu Körper-Gu (dauerhaft eingeprägt) und Hilfs-Gu. Die 126 Prototyp-Gu dienen als Ideenpool für spätere Familien.
- Jeder Gu hat Pfad, Rang, Essenzkosten, Cooldown und Futter; wilde Gu können ein Merkmal tragen.
- **Gu-Kapazität:** Die Apertur fasst nur eine begrenzte Zahl Gu (wächst mit Rang und Talent).
- **Hunger:** Gu müssen gefüttert werden, sonst wirken sie schwächer, fallen aus und sterben schließlich.
- **Unterhalt:** Passive Gu kosten laufend Essenz.
- **Rang-Passung:** Ein Gu wirkt am besten auf deinem eigenen Rang. Niedrigere Gu verlieren Wirkung, höhere kosten quadratisch mehr.
- **Verfeinerung:** Wilde Gu aufspüren, einfangen und mit Essenz und Materialien verfeinern. Die Chance sinkt stark mit dem Rangunterschied.
- **Aufstieg:** Ein Gu steigt durch Aufstiegsverfeinerung zum nächsten Mitglied seiner Familie auf und behält dabei sein Merkmal.
- **Welt-Interaktion:** Zustände wirken auch auf Objekte (brennbare Hecken, gefrierbares Wasser, Ruinenschalter). Wilde Gu und Schätze liegen hinter solchen Hindernissen.

### Pfade und Dao-Markierungen
Jede Gu-Nutzung sammelt Markierungen im jeweiligen Pfad. Beherrschung senkt Kosten und Cooldowns dieses Pfades. Gegensätzliche Pfade (Feuer/Wasser, Licht/Seele, Kraft/Weisheit, Blut/Holz, Zeit/Raum) verteuern sich gegenseitig. Spezialisierung wird belohnt.

### Kampf
Ausschließlich über Gu und Killer Moves, taktisch, mittleres Tempo. Vollständig in `docs/KAMPFSYSTEM.md`.

### Survival
- Eigene HP; Nahrung heilt. Kein eigener Hungerbalken für den Spieler, damit der Fokus auf dem Gu-Hunger liegt (Entscheidung, siehe unten).
- Materialknoten (Holz, Stein, Beeren, Kräuter, Erze) und Jagdbeute.
- Einfaches Bauen aus dem Prototyp (`BUILD`): Lagerfeuer, Fackel, Holz- und Steinwände, Bett, Falle und Gu-Köder (lockt wilde Gu zum Einfangen an). Ein Lager mit Bett ist ein Ruheort (Respawn, sicheres Meditieren, Speichern).
- Die Waffen und Rüstungen des Prototyps (`GEAR`) werden nicht übernommen; ihre Rolle übernehmen Gu.

### Wirtschaft
Urstein ist Währung, Essenzquelle und Gu-Futter zugleich. Diese Dreifachrolle ist die zentrale Knappheit: Jeder Urstein, den du ausgibst, fehlt dir anderswo.

### Welt
- Fünf Regionen: Südliche Grenze (Dschungel, Gift, Klans – Startregion), Nördliche Ebene (Steppe, Stämme), Östliches Meer (Inseln, Seeungeheuer), Westliche Wüste (Dünen, Tempel), Zentralkontinent (reich, Himmlischer Hof).
- Jede Region hat Zonen steigender Gefahr. Regionalmauern trennen die Regionen und sind erst ab höheren Rängen passierbar.
- Wilde Gu kommen in bestimmten Zonen vor (`zone` in `gu.json`).

### Soziales
- Dörfer mit NPCs, Händlern und Quests; Ruf pro Fraktion.
- 15 Klans, Sekten und Stämme mit Rivalitäten, Beitrittsbedingungen, internen Rängen und Aufträgen.
- NPC-Gu-Meister nach denselben Regeln wie der Spieler.

### Unsterblichen-Phase (Rang 6+)
Eigene Apertur-Welt mit Landgeist, Gesegnete Länder annektieren, Kalamitäten und Trübsale in festen Abständen, Erbschaften, Schatzhimmel, Langya-Händler, Eingebungen.

## UI

- **HUD:** HP, Uressenz mit Unterhalts-Anzeige, Rang und Stufe, Tageszeit, Minimap, Gu-Buttons mit Cooldown-Ringen und Hunger-Symbol, Killer-Move-Button.
- **Gu-Menü:** Besitz, Slots, Fütterung, Rang-Passung, Kombinationsbuch.
- **Kultivierungs-Menü:** Aperturwand-Fortschritt, Durchbruch, Dao-Markierungen pro Pfad.
- **Inventar, Karte, Quests, Fraktionen.**
- Alle Menüs am Handy mit einem Daumen bedienbar, Schrift mindestens 14 px.

## Audio

Dezente Ambient-Musik pro Region, klare Soundeffekte für Gu-Fähigkeiten (jeder Pfad mit eigenem Klangcharakter), deutliche Warnsounds für Telegraphen und Killer-Move-Kanalisierung von Gegnern.

## Speichern

Automatisch beim Schlafen, beim Betreten eines Ruheorts und alle 5 Minuten; zusätzlich manuell im Menü. Im Hardcore-Modus nur ein Spielstand, der beim Tod gelöscht wird. Spielstände haben eine Versionsnummer, damit Updates alte Stände nicht zerstören.

## Meilensteine

**M0 – Fundament:** Godot-Projekt, Struktur, Autoloads, Git, automatischer Web-Export auf GitHub Pages, Eingabe für Touch und Tastatur, Datenimport aus `docs/daten/`.

**M1 – Bewegung und Welt:** Third-Person-Charakter (laufen, springen, Dash, Kamera), kleines Dschungelgebiet mit Vegetation, Tag-Nacht-Zyklus.

**M2 – Vertical Slice (Südliche Grenze, Rang 1–2)**
- Neues-Spiel-Menü mit Todesmodus, Kindheit und Talent
- Apertur, Meditation, Stufen, Durchbruch auf Rang 2
- Alle 12 Gu-Familien in Rang 1 und 2 (24 Gu), Körper-Gu Rosa-Eber und Zehn-Jin, die fünf Rang-1-Hilfs-Gu; Wahl des ersten Gu beim Erwachen
- Alle 6 Zustände und 8 Reaktionen, Merkmale, Aufstiegsverfeinerung von Rang 1 auf 2
- Die sieben wiederverwendbaren Welt-Hindernisse, mit mindestens einem versteckten wilden Gu hinter jedem
- Hunger, Unterhalt, Verfeinerung wilder Gu
- Alle 8 Killer Moves als Daten, davon mindestens 4 vollständig ausgearbeitet; Entdeckung durch Eingebung
- Gegner: Schleim, Ratte, Wolf, Wildschwein, Riesenspinne sowie ein NPC-Gu-Meister auf Rang 2
- Ein Klan-Dorf mit NPCs, Händler und 3 Quests; Lager bauen
- Speichern und Laden; HUD, Gu-Menü mit Kombinationsbuch, Inventar

**Erfolgskriterium M2:** Ein neuer Spieler spielt 60–90 Minuten freiwillig weiter, erreicht Rang 2 nach etwa 45 Minuten, hat mindestens drei Reaktionen und einen Killer Move selbst entdeckt und spricht von „seinem“ Gu. Erst wenn das erreicht ist, geht es weiter.

**M3 – Tiefe:** Ränge 3–5 (Rang 3 aller Familien, erste neue Familien wie Zeit und Glück), mehr Killer Moves, Dao-Beherrschung, Sekten mit Rängen und Aufträgen, weitere Startoptionen
**M4 – Welt:** weitere Regionen, Regionalmauern, Schnellreise, regionale Bosse
**M5 – Unsterblichkeit:** Apertur-Welt, Kalamitäten, Gesegnete Länder, Erbschaften
**M6 – Politur:** einheitliche Assets, Sound, Musik, Balancing, Performance

## Entschiedene Grundsatzfragen

- **Kampfstil:** Gu- und Killer-Move-zentriert, taktisch (siehe `KAMPFSYSTEM.md`).
- **Tod:** beim Anlegen wählbar – Hardcore, Standard (Beutesack), Entspannt.
- **Kindheit:** beim Anlegen wählbar – spielbar als Tutorial oder übersprungen.
- **Spieler-Hunger:** kein eigener Hungerbalken; Nahrung dient der Heilung. Kann nach Playtests überdacht werden.
- **Level-System und Ausrüstung:** entfallen; Fortschritt nur über Stufen, Rang, Gu und Dao-Markierungen.

## Risiken

- **Scope:** Der Prototyp hat sehr viele Systeme. Größtes Risiko ist, zu viel gleichzeitig zu portieren. Gegenmittel: strikte Meilensteine, Erfolgskriterium für M2.
- **Handy-Performance:** 3D im Browser ist begrenzt. Gegenmittel: Performance-Budget in `CLAUDE.md`, früh am echten Handy testen.
- **Balancing:** Die Formeln wurden für 2D und einen 180-s-Tag gebaut. Gegenmittel: alle Werte im `Balance`-Resource, frühe Playtests.
- **Urheberrecht:** Namen und Lore aus Reverend Insanity. Gegenmittel: alle Namen nur über Daten und `tr()`, damit sie vor einer Veröffentlichung austauschbar sind.

## Ideen (nicht im aktuellen Meilenstein)

*Hier landen Ideen, die während der Entwicklung aufkommen, damit sie nicht verloren gehen, aber den Scope nicht sprengen.*
