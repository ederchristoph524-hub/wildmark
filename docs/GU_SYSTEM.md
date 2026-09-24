# Gu-System – Wildmark

Das Herz des Spiels. Dieses Dokument ist verbindlich für alle Gu, ihre Wirkungen, Zustände, Reaktionen, Ränge und Killer Moves. Daten: `docs/daten/gu_system.json`.

## 1. Das 80/20-Prinzip

**Spielerlebnis entsteht aus:** Entscheidungen, Kombinationen, die sich wie eigene Entdeckungen anfühlen, Bindung an „meine" Gu und dem Gefühl, dass Macht die Welt verändert.

**Aufwand entsteht aus:** einzigartigem Code pro Gu, einzigartigen Modellen und Effekten, Sonderfällen und Balancing von vielen ähnlichen Dingen.

Der Prototyp hat 126 Gu, aber viele davon sind reine Zahlenwerte: sieben Gu, die nur „weniger Schaden erleiden" bewirken, fünf mit „mehr Grundschaden", zwei identische Berserker. Das ist viel Aufwand für wenig Erlebnis.

Das neue System dreht das um. **Wenige Bausteine werden einmal gebaut, und das Erlebnis entsteht daraus, wie sie zusammenwirken.** Vier Hebel tragen fast alles:

| Hebel | Einmal bauen | Ergibt |
|---|---|---|
| 1. Baukasten | 9 Wirkformen, 5 Tags | alle aktiven Gu als reine Daten |
| 2. Zustände und Reaktionen | 6 Zustände, 8 Reaktionen | Dutzende Kombos, die niemand einzeln programmiert hat |
| 3. Familien | 12 Familien mit je 3 Rängen | 36 Gu mit spürbarem Aufstieg, aber nur 12 Umsetzungen |
| 4. Dieselben Regeln in der Welt | Zustände wirken auch auf Objekte | Erkundung, Rätsel und Wege ohne eigenes Rätselsystem |

Dazu kommen zwei billige Zutaten mit großer Wirkung auf die Bindung: **Merkmale** für wilde Gu und **Killer Moves auf Familienebene**.

## 2. Hebel 1: der Baukasten

Jeder aktive Gu ist die Kombination aus einer **Wirkform**, einigen **Tags**, optional einem **Zustand** und Zahlenwerten. Neuer Code entsteht nur für eine neue Wirkform, nie für einen einzelnen Gu.

**Wirkformen (9):**

| Wirkform | Beschreibung | Familien |
|---|---|---|
| `geschoss` | fliegt geradeaus, trifft das erste Ziel | Mondlicht, Frost, Knochen |
| `geschoss_explodierend` | wie Geschoss, mit Explosion im Radius | Flamme |
| `geschoss_schnell` | sehr schnell, kurze Abklingzeit | Blitz |
| `strahl` | Linie von dir aus | Strömung |
| `stich` | kurze Reichweite vor dir | Gift |
| `kreis` | Fläche um dich herum | Wirbel |
| `selbst` | wirkt auf dich (Schild, Heilung) | Haut, Blatt |
| `bewegung` | Doppelsprung, Gleiten, Teleport | Schritt |
| `zaehmen` | wandelt einen Gegner in einen Gefährten | Sklaverei |

`selbst` deckt Schild und Heilung ab. `zaehmen` und `bewegung` sind die einzigen Formen mit eigener Logik; `zaehmen` ist trotzdem günstig, weil es die vorhandene Gegner-KI nutzt.

**Tags (5 Grundtags):**

| Tag | Wirkung |
|---|---|
| Wucht | stößt zurück, zerschmettert Eingefrorene, bricht Felsen |
| Schnitt | 20 % Chance auf Wunde |
| Durchbohren | ignoriert Rüstung |
| Wind | verteilt Brand und Gift auf Nachbarn, verweht Wolken und Nebel |
| Licht | blendet Nacht- und Schattenwesen, enthüllt Verborgenes |

Die Element-Tags (Feuer, Wasser, Blitz, Eis, Gift) lösen die Reaktionen aus Abschnitt 3 aus.

## 3. Hebel 2: Zustände und Reaktionen

Das ist der größte Hebel. Sechs Zustände mit je einer einfachen Regel, acht Reaktionen zwischen ihnen. Daraus entstehen Kombos, die der Spieler selbst herausfindet, und die sich wie echte Meisterschaft anfühlen.

**Zustände:**

| Zustand | Regel |
|---|---|
| Brand | 4 Schaden/s × Rangfaktor, 4 s |
| Nass | keine direkte Wirkung, 6 s; bereitet Blitz und Frost vor |
| Frost | je Stapel −20 % Tempo; bei 3 Stapeln 2 s eingefroren |
| Ladung | bei 3 Stapeln Entladung: Schaden im Umkreis und kurze Betäubung |
| Gift | 2 Schaden/s pro Stapel (max. 5), 8 s, halbiert Heilung |
| Wunde | nächster Treffer +30 %; Blut-Gu heilen an verwundeten Zielen |

**Reaktionen:**

| Reaktion | Auslöser → Ziel | Ergebnis |
|---|---|---|
| Überschlag | Blitz → Nass | ×2 Schaden, springt auf alle nassen Ziele in der Nähe |
| Schockfrost | Eis → Nass | sofort eingefroren |
| Dampf | Feuer → Nass | Dampfwolke, Gegner darin verlieren ihr Ziel |
| Schmelze | Feuer → Frost | ×1,5 Schaden, Ziel wird nass |
| Zerschmettern | Wucht → Eingefroren | ×2,5 Schaden |
| Feuerwirbel | Wind → Brand | Brand springt auf alle Ziele im Umkreis |
| Giftexplosion | Feuer → Gift (ab 3 Stapeln) | Explosion, Schaden nach Stapeln |
| Blutgift | Gift → Wunde | Gift-Stapel verdoppelt |

**Ketten, die daraus entstehen** (niemand muss sie programmieren):
- Wasserlicht → Frostnadel (Schockfrost) → Wirbelwind (Zerschmettern)
- Frostnadel ×3 → Glutfunke (Schmelze, jetzt nass) → Funkenwurm (Überschlag auf die ganze Gruppe)
- Stachelwurm ×2 → Blutdorn (Wunde) → Stachelwurm (Blutgift, 8 Stapel) → Glutfunke (Giftexplosion)
- Glutfunke in eine Gruppe → Wirbelwind (Feuerwirbel)

Mit vier Slots und zwölf Familien ergeben sich so hunderte sinnvolle Loadouts. Die Reaktionen werden im Spiel als kurzer Schriftzug über dem Ziel angezeigt („Überschlag!"), beim ersten Mal zusätzlich im Kombinationsbuch vermerkt.

**Gegner nutzen dieselben Regeln.** Ein Wasserschamane, der dich durchnässt, macht dich verwundbar für den Blitz-Gu-Meister daneben. Gegner-Gruppen werden dadurch interessant, ohne eigene KI-Tricks.

## 4. Hebel 3: Familien

Statt 126 Einzel-Gu gibt es **12 Familien**. Jede Familie ist ein Verb (werfen, verbrennen, einfrieren, heilen, springen …) mit drei Rangstufen. Höhere Ränge nutzen dieselbe Umsetzung mit stärkeren Werten (×1,48 pro Rang, siehe `FORMELN.md`) und genau **einer neuen Eigenschaft**, der **Ranggabe**. So fühlt sich jeder Aufstieg neu an, kostet aber kaum Arbeit.

| Familie | Pfad | Rolle | Zustand/Tag | Rang 1 | Rang 2 (Ranggabe) | Rang 3 (Ranggabe) |
|---|---|---|---|---|---|---|
| Mondlicht | Licht | Fernkampf-Allrounder | Schnitt, Licht | Mondlicht | Mondsichel* (durchdringt ein Ziel) | Regenbogenlicht (Fächer aus 7 Klingen) |
| Flamme | Feuer | Flächenschaden | Brand | Glutfunke* | Flammenzunge (größere Explosion) | Feuerlotus* (brennender Boden) |
| Strömung | Wasser | Kontrolle, Vorbereitung | Nass | Wasserlicht | Wasserbohrer (durchbohrt die Linie) | Flutdrache* (Rückstoß, Wasserfläche) |
| Blitz | Blitz | schneller Einzelschaden | Ladung | Funkenwurm* | Blauplasma (ignoriert Rüstung) | Kettenblitz (springt auf 3 Ziele) |
| Frost | Eis | Kontrolle | Frost | Frostnadel* | Eisvogel (2 Stapel pro Treffer) | Frostnova (Kreis um dich) |
| Gift | Gift | Schaden über Zeit | Gift | Stachelwurm* | Giftskorpion (springt beim Tod über) | Giftnebel (Wolke) |
| Wirbel | Kraft | Nahkampf, Positionierung | Wucht, Wind | Wirbelwind | Sogwirbel* (zieht Gegner heran) | Bergschlag* (Betäubung) |
| Knochen | Blut | hohes Risiko, hoher Schaden | Wunde, Durchbohren | Blutdorn* (kostet HP statt Essenz) | Spiral-Knochenspeer (volle Rüstungsdurchdringung) | Blutschädel (heilt dich) |
| Haut | Metall | Verteidigung | Wucht | Steinhaut (aktiv) | Eisenhaut (wirft Geschosse zurück) | Bronzehaut (unbeweglich) |
| Blatt | Holz | Heilung | – | Lebenskraft-Blatt | Frisches Blatt (reinigt) | Lebensbrunnen (Heilzone, auch Gefährten) |
| Sklaverei | Seele | Beschwörung | – | Ratten-Sklaverei* | Wolfs-Sklaverei (2 Gefährten) | Bestien-Sklaverei (ein dauerhafter Gefährte) |
| Schritt | Raum | Bewegung, Erkundung | – | Sprungwurm* (Doppelsprung) | Wolkenschritt* (Gleiten) | Schattenbild (Teleport) |

\* neu entworfen; alle anderen stammen aus dem Prototyp und behalten dort ihre Lore-Texte.

**Warum gerade diese zwölf:** Jede Familie hat genau eine Rolle, keine zwei machen dasselbe, und jede ist an mindestens einer Reaktion, einem Killer Move und einer Welt-Interaktion beteiligt. Damit ist jede Familie in Kampf und Erkundung nützlich.

**Besonderheiten, die viel Tiefe für wenig Aufwand geben:**
- **Knochen kostet HP statt Essenz.** Eine zweite Ressource im selben System, perfekt für Spieler, die Essenz sparen müssen. Zusammen mit Blatt (Heilung) entsteht ein eigener Spielstil.
- **Sklaverei nutzt die Gegner-KI.** Jede Bestie im Spiel wird automatisch zu einem möglichen Gefährten, ohne neue Inhalte.
- **Haut und Blatt sind aktiv statt passiv.** Aus sieben langweiligen „−X % Schaden"-Gu wird eine Entscheidung mit Timing.

### Gu-Aufstieg

Ein Gu steigt auf zwei Wegen zum nächsten Familienmitglied auf:
1. **Aufstiegsverfeinerung:** Gu + Pfad-Materialien (in `gu_system.json` → `aufstieg`) + Essenz. Chance und Kosten nach den Verfeinerungsformeln mit dem Zielrang. Bei Misserfolg sind die Materialien verloren, der Gu bleibt.
2. **Wild finden:** höherrangige Familienmitglieder leben in gefährlicheren Zonen.

Der Zielrang darf höchstens 1 über dem eigenen Rang liegen (Rang-Passung). Ein aufgestiegener Gu **behält sein Merkmal**. Genau das schafft Bindung: „mein glänzender Mondlicht-Gu", den man seit Rang 1 begleitet.

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

## 6. Passive Gu: nur noch zwei Sorten

**Körper-Gu (Kraft- und Metall-Linie):** werden beim Verfeinern verbraucht und dauerhaft in den Körper eingeprägt, so wie im Roman. Kein Hunger, kein Unterhalt, kein Kapazitätsplatz. Die Entscheidung liegt nur beim Preis. Rosa-Eber (+4 Schaden) → Zehn-Jin (+12) → Jun-Kraft (+27); Eisenknochen (+60 HP).

**Hilfs-Gu:** verändern, wie du spielst, statt nur Zahlen zu erhöhen. Sie belegen Kapazität und kosten Unterhalt.

| Gu | Wirkung |
|---|---|
| Schnaps-Wurm | Essenz-Regeneration +35 % |
| Hoffnungs-Gu | Gu-Kapazität +1, Apertur +10 % |
| Kleines-Licht-Gu | Lichtkreis bei Nacht; macht Lichtsiegel und versteckte wilde Gu sichtbar |
| Signal-Gu | zeigt Gegner und wilde Gu in doppelter Entfernung |
| Schleichstein-Gu | wilde Gu fliehen seltener, Bestien bemerken dich später |
| Bohr-Gu (R2) | schnellerer Abbau, seltenere Funde |
| Zwei-Aufgaben-Gu (R2) | Cooldowns −20 % |

Die reinen Zahlen-Passiven des Prototyps (die vielen Haut-, Kraft- und Verstärker-Varianten) entfallen oder gehen in den Körper-Gu und in die Haut-Familie auf.

## 7. Killer Moves auf Familienebene

Ein Killer Move verlangt **ein beliebiges Mitglied** zweier Familien. Seine Stärke richtet sich nach dem niedrigeren der beiden Ränge. Eine Definition deckt damit alle Rangkombinationen ab: 8 Killer Moves ergeben 72 spielbare Varianten.

| Killer Move | Familien | Wirkung |
|---|---|---|
| Feuersturm | Flamme + Wirbel | Flammenwirbel, Brand springt weiter |
| Mondschritt | Mondlicht + Schritt | Durch eine Gegnerreihe jagen und Mondklingen hinterlassen |
| Gewitterflut | Strömung + Blitz | Flutwelle, dann Blitz: garantierter Überschlag auf alle |
| Gletscherbruch | Frost + Wirbel | Alle einfrieren und im Nachschlag zerschmettern |
| Pestfeuer | Gift + Flamme | Giftwolke entzünden, große Explosion, brennender Boden |
| Knochenfestung | Knochen + Haut | Panzer, jeder Treffer auf dich schießt einen Dorn zurück |
| Donnerpanzer | Haut + Blitz | Panzer, Angreifer erhalten volle Ladung |
| Rudelsegen | Sklaverei + Blatt | Gefährten geheilt und gestärkt, ein zusätzlicher erscheint |

Jede der 12 Familien ist an mindestens einem Killer Move beteiligt. Die Killer Moves verstärken bewusst die Reaktionen aus Abschnitt 3: Wer Überschlag kennt, versteht Gewitterflut sofort. So lernt der Spieler das System über die Killer Moves. Kanalisierung, Kosten und Entdeckung wie in `KAMPFSYSTEM.md`.

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

## 9. Spielstart

Beim Erwachen wählt der Spieler seinen ersten Gu aus vier Rang-1-Familien: Mondlicht (Gu-Yue-Klan, Standard), Glutfunke, Wasserlicht oder Wirbelwind. Diese Wahl prägt die ersten Stunden, macht Wiederholungsdurchgänge interessant und kostet nichts extra.

## 10. Balancing-Grundlage

Basiswerte für Rang 1 stehen pro Familie in `gu_system.json` (`basis_r1`). Richtschnur für neue Familien: Ein Rang-1-Angriffs-Gu macht pro Sekunde Abklingzeit etwa 8–12 Schaden und kostet 4–8 Essenz; Kontroll- und Zustands-Gu machen weniger Direktschaden, weil ihr Wert in den Reaktionen liegt. Höhere Ränge skalieren nur über die Formel und die Ranggabe, nie über Handarbeit pro Gu.

Futter pro Familie ist eine Grundressource (`futter`), damit Rang-1-Gu leicht zu versorgen sind. Die Menge steigt mit dem Rang nach `FORMELN.md`.

## 11. Was bewusst weggelassen wird

- Die 126 Prototyp-Gu werden **nicht** alle portiert. Für M2 und M3 gilt ausschließlich dieses System (36 Familien-Gu, 4 Körper-Gu, 7 Hilfs-Gu).
- Später kommen neue Familien hinzu, idealerweise ohne neue Wirkform: Zeit (Verlangsamung als Zustand), Glück (Beute und Zufall), Weisheit (Eingebungen), Verwandlung. Jede neue Familie ist ein Dateneintrag plus Ranggaben.
- Die Unsterblichen-Gu (Rang 6+) werden erst in M5 gestaltet, dann als Rang 6–9 bestehender Familien plus wenige legendäre Einzelstücke.

## 12. Aufwand und Umsetzungsreihenfolge

**Einmal zu bauen:**
1. Wirkformen-System mit Tags und Hitbox (Geschoss, Strahl, Stich, Kreis, Selbst)
2. Zustandssystem (Stapel, Dauer, Ende) und Reaktionstabelle, datengetrieben
3. Familien und Rangskalierung aus `gu_system.json`, Ranggaben als kleine Schalter
4. Killer Moves auf Familienebene
5. Bewegung (Doppelsprung, Gleiten, Teleport)
6. Zähmen mit Nutzung der Gegner-KI
7. Merkmale als Multiplikatoren
8. Zustände auf Welt-Objekten plus die sieben wiederverwendbaren Hindernisse

**Visuell:** fünf Gu-Grundmodelle (Wurm, Käfer, Falter, Schnecke, Kristallwesen), eingefärbt nach Pfad; ein Effekt pro Wirkform, eingefärbt nach Pfad; ein Symbol pro Zustand.

Das ist die 20 %. Daraus entstehen 36 Gu mit spürbarem Aufstieg, hunderte Loadouts, acht Reaktionen und ihre Ketten, 72 Killer-Move-Varianten, zehn Merkmale, die jeden Fund einzigartig machen, und eine Welt, die auf jeden neuen Gu reagiert.
