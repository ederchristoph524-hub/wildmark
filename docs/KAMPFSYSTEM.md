# Kampfsystem – Wildmark

Verbindliches Design für Kampfablauf, Steuerung, Tod und die Optionen beim Spielstart. Welche Gu es gibt, wie Zustände, Reaktionen und Killer Moves inhaltlich aussehen, regelt `docs/GU_SYSTEM.md`. Alle Zahlen sind Startwerte fürs Balancing; die zugrunde liegenden Formeln stehen in `docs/FORMELN.md`, die Werte gehören ins `Balance`-Resource.

## 1. Grundprinzip

Gekämpft wird mit Gu, nicht mit Waffen. Der Körper allein ist schwach: Ein Faustschlag macht wenig Schaden und ist nur die Notlösung. Stärker wirst du nicht durch Level, sondern durch bessere Gu, eine klügere Auswahl, entdeckte Killer Moves, Dao-Markierungen und einen höheren Rang.

**Tempo:** mittel, taktisch, gut lesbar. Jeder Kampf ist eine Folge von Entscheidungen: welcher Gu jetzt, einzeln oder als Killer Move, angreifen oder Essenz sparen, bleiben oder fliehen. Das trägt die Design-Säule „Knappheit" und funktioniert zuverlässig mit Touch-Steuerung.

## 2. Ressourcen im Kampf

- **Uressenz** ist die einzige Kampfressource; es gibt keinen Ausdauerbalken. Jeder aktive Gu kostet Essenz (`ess` in `gu.json`, multipliziert mit Pfad- und Rang-Passung laut `FORMELN.md`).
- **Cooldowns** pro Gu (`cd`), verkürzt durch Pfad-Beherrschung.
- **Unterhalt:** Passive Gu ziehen laufend Essenz ab. Wer viele passive Gu besitzt, hat im Kampf weniger Essenz übrig. Das ist gewollt: Jeder Gu hat einen Preis.
- **Essenz leer:** Nur noch Faustschlag und Dash; nicht-dauerhafte passive Gu fallen aus. Urstein essen füllt Essenz auf, dauert aber 2 s, in denen du verwundbar bist.

### Hunger der Gu

| Sättigung | Zustand | Wirkung |
|---|---|---|
| 100–31 | satt | 100 % |
| 30–1 | hungrig (Symbol blinkt) | 80 % |
| 0 | ausgehungert | wirkt nicht |
| 0 für einen ganzen Spieltag | verhungert | Gu stirbt |

Der Tod verhungerter Gu ist neu gegenüber dem Prototyp und entspricht dem Roman. Fütterung wird dadurch Teil der Kampfvorbereitung. Dauerhafte Körper-Gu (Liste `PERM`) brauchen kein Futter.

## 3. Loadout

- **4 aktive Slots** für Familien-Gu (alle zwölf Familien sind aktiv, auch Haut, Blatt und Schritt). Der Prototyp hatte 3; 4 passen zum Button-Bogen am Handy und erlauben zwei Killer-Move-Paare gleichzeitig.
- **Passive Gu brauchen keinen Slot.** Körper-Gu sind dauerhaft eingeprägt. Hilfs-Gu wirken automatisch, solange sie satt sind, ihr Rang höchstens 1 über deinem liegt und deine Essenz den Unterhalt trägt. Die Entscheidung ist, **welche Gu du überhaupt behältst**, denn die Gu-Kapazität der Apertur ist begrenzt (`FORMELN.md`).
- **Wechsel der aktiven Slots** ist außerhalb des Kampfes frei, im Kampf nur mit 3 s Kanalisierung.
- **Pfad-Konflikte** entstehen aus deinen gesammelten Dao-Markierungen: Wer viel Feuer genutzt hat, zahlt mehr für Wasser-Gu. Spezialisierung wird belohnt.
- **Loadout-Denken:** Gute Loadouts kombinieren einen Vorbereiter (Strömung, Frost, Gift), einen Auslöser (Blitz, Wirbel, Flamme), eine Verteidigung oder Heilung und eine Bewegung. Das ergibt sich aus den Reaktionen und muss nicht erzwungen werden.

## 4. Killer Moves

Das Herzstück des Kampfes.

**Voraussetzungen:** Du kennst den Killer Move, besitzt je ein beliebiges Mitglied der beiden Familien, beide liegen in einem aktiven Slot und sind nicht ausgehungert. Die Stärke richtet sich nach dem niedrigeren Rang der beiden.

**Ablauf:**
1. Sobald ein bekannter Killer Move ausführbar ist, leuchtet der Killer-Move-Button. Sind mehrere möglich, schaltest du durch (Mausrad bzw. Wischen über den Button).
2. **Kanalisierung** 0,6–1,5 s (Feld `kanal_s`). Ein Kreis um die Spielfigur füllt sich; Gegner sehen es auch.
3. Wirst du während der Kanalisierung getroffen, bricht der Killer Move ab, die Essenz ist verloren, die Gu gehen trotzdem auf Cooldown.
4. Bei Erfolg: 2,5- bis 4-facher Schaden bzw. deutlich stärkerer Effekt (Feld `mult`) als der stärkere Einzel-Gu.

**Kosten:** `(ess_a + ess_b) × 2` mit Pfad-Multiplikator. Knochen-Gu zahlen ihren Anteil in HP statt Essenz.

**Cooldown:** Beide beteiligten Gu gehen auf Cooldown. Daraus entsteht die Kernentscheidung: zwei sichere Einzelangriffe oder ein starker, riskanter Kombo-Angriff im richtigen Moment.

### Entdeckung

- **Eingebung:** Setzt du zwei Gu innerhalb von 2 s nacheinander ein und bilden sie ein unbekanntes Paar, besteht eine Chance, den Killer Move zu begreifen. Grundchance 15 %, +5 % pro Beherrschungsstufe im Weisheits-Pfad, maximal 50 %. Pro Paar höchstens ein Versuch alle 30 s, damit man es nicht erzwingen kann.
- **Hinweise:** Schriftrollen, NPC-Gespräche, Sekten-Bibliotheken und Erbschaften verraten Killer Moves direkt oder deuten die Kombination an („Wo Flamme auf Wirbel trifft …").
- Bekannte Killer Moves stehen im **Kombinationsbuch** im Gu-Menü; unbekannte erscheinen als „???" mit dem Hinweis, sobald man einen gefunden hat.

### Die Killer Moves

Die acht Killer Moves auf Familienebene stehen in `docs/GU_SYSTEM.md`, Abschnitt 7, und in `gu_system.json`. Für den Vertical Slice sind alle acht als Daten vorhanden; mindestens vier davon werden vollständig ausgearbeitet: Feuersturm, Gewitterflut, Gletscherbruch und Mondschritt.

## 5. Rang-Unterdrückung

Wie im Roman entscheidet der Rang fast alles. Das entsteht direkt aus den Formeln, ohne Sonderregel: Ein Rang-3-Gu wirkt 2,2-mal so stark wie ein Rang-1-Gu, und ein Rang-3-Gu-Meister hat durch seine Durchbrüche ein Vielfaches an HP und Essenz. Ein Kampf zwei Ränge über dir ist praktisch aussichtslos.

- Rang und Stufe jedes Gegners werden sichtbar angezeigt (Farbe des Namensschilds nach `RANKS`).
- Erst wenn Playtests zeigen, dass die Unterdrückung zu schwach ist, kommt ein zusätzlicher Faktor hinzu. Nicht vorsorglich einbauen, sonst wird doppelt gezählt.

## 6. Verteidigung

- **Dash** mit kurzer Unverwundbarkeit (0,25 s), keine Essenzkosten, Cooldown 1,2 s. Er ist immer verfügbar (im Prototyp war er freischaltbar).
- **Haut-Familie** als aktive Verteidigung mit Timing; **Körper-Gu** (Eisenknochen) für dauerhafte Zähigkeit. Alle Schadensreduktionen werden multiplikativ verrechnet, insgesamt höchstens 60 %.
- **Telegraphen:** Jeder starke Gegnerangriff wird vorher angezeigt, durch einen roten Bodenindikator oder eine klare Aufladeanimation. Unfaire Treffer ohne Vorwarnung gibt es nicht.

## 7. Gegner

- **Bestien:** einfache Muster, klare Telegraphen, Stärken und Schwächen über Zustände (z. B. Schleime sind dauerhaft nass, Feuerwesen immun gegen Brand, aber anfällig für Dampf). Werte aus `gegner.json`; das Feld `beh` beschreibt das Verhalten. Jede Bestie kann mit der Sklaverei-Familie gezähmt werden.
- **Gegnergruppen** nutzen Zustände gegen dich: Ein Wasserschamane durchnässt dich, der Blitzschütze daneben profitiert. Das macht Gruppen taktisch, ohne eigene KI-Tricks.
- **Gu-Meister (NPCs):** spielen nach exakt denselben Regeln wie du – Loadout, Uressenz, Unterhalt, Cooldowns, Killer Moves. Sie können leerlaufen, und das ist dein Moment. Ihre Kanalisierung ist sichtbar und unterbrechbar. Unterlegene Gu-Meister fliehen oder ergeben sich; das öffnet Raum für Entscheidungen (töten, laufen lassen, ausrauben).
- **Beute von Gu-Meistern:** mit Chance einer ihrer Gu, der danach wild wird und verfeinert werden muss.

## 8. Steuerung

| Aktion | PC | Handy |
|---|---|---|
| Bewegen | WASD | Joystick links |
| Springen | Leertaste | Sprung-Button |
| Kamera | Maus | Wischen auf der rechten Bildschirmhälfte |
| Faustschlag | Linksklick | großer Button rechts unten |
| Gu 1–4 | Tasten 1–4 | vier Buttons im Bogen um den Faust-Button |
| Killer Move | Q | Button über dem Bogen, leuchtet wenn verfügbar |
| Killer Move wechseln | Mausrad | Wischen über den Killer-Move-Button |
| Dash | Shift | Dash-Button |
| Ziel fixieren | Tab | Gegner antippen |
| Ziel wechseln | Mittelklick | anderen Gegner antippen |
| Urstein essen | R | Button im Schnellmenü |

Aktionsnamen in der Input Map: `move_forward/back/left/right`, `jump`, `attack_fist`, `gu_slot_1`–`gu_slot_4`, `killer_move`, `killer_move_next`/`killer_move_prev`, `dash`, `target_lock`, `target_switch`, `eat_primeval_stone`.

**Zielerfassung:** Soft-Lock auf das nächste Ziel in Blickrichtung; Fernkampf-Gu zielen automatisch darauf. Option im Menü: harte Zielerfassung (Kamera folgt dem Ziel).

Jeder Button zeigt Cooldown als Ring und wird grau, wenn die Essenz nicht reicht.

## 9. Beispiel: ein Kampf auf Rang 1

Der Spieler hat Wasserlicht, Frostnadel, Wirbelwind und Sprungwurm in den Slots, dazu Schnaps-Wurm als Hilfs-Gu. Drei Wölfe greifen an. Er spritzt die Gruppe mit Wasserlicht nass, und eine Frostnadel auf den vordersten Wolf friert ihn sofort ein (Schockfrost). Die beiden anderen erreichen ihn; er springt mit dem Doppelsprung über sie hinweg und landet neben dem eingefrorenen Wolf. Wirbelwind: Der gefrorene Wolf zerspringt (Zerschmettern), die anderen werden zurückgestoßen. Jetzt ist die Essenz halb leer. Er kann Gletscherbruch kanalisieren, riskiert aber einen Treffer, der ihn abbricht, oder er zieht sich zurück und nutzt die Abklingzeiten. Genau diese Entscheidungen sind das Ziel.

## 10. Tod und Optionen beim Spielstart

Beim Anlegen eines neuen Spielstands wählt der Spieler. Die Wahl ist danach für diesen Spielstand fest und wird im Spielstand gespeichert.

**Todesmodus**
- **Hardcore** – Permadeath, der Spielstand wird gelöscht.
- **Standard** – Respawn am letzten Ruheort (Dorf, Lager). Du verlierst alle mitgeführten Materialien und 30 % deiner Uressenz, deine Gu verlieren ihre Sättigung. Die Beute liegt als Beutesack am Todesort und kann zurückgeholt werden; stirbst du vorher erneut, ist sie verloren.
- **Entspannt** – Respawn am letzten Ruheort, nur die Hälfte der mitgeführten Materialien geht verloren.

**Kindheit**
- **Spielbar** – kurzes Tutorial im Klan-Dorf: Bewegung, Sammeln, Gespräche. Endet mit dem Erwachen der Apertur (Alter `AWAKEN_AGE`), dem Talenttest und der Wahl des ersten Gu.
- **Überspringen** – Start direkt nach dem Erwachen. Talentgrad wird ausgewürfelt oder im erweiterten Menü gewählt (wie `customStart` im Prototyp; Optionen in `CFG`).

**Weitere Startoptionen** aus dem Prototyp (`CFG`): Herkunft/Stand, Startregion, Sekte, Körperkonstitution, Vital-Gu. Für den Vertical Slice reichen Todesmodus, Kindheit und Talent; der Rest folgt ab M3.
