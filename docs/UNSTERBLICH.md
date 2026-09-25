# Unsterblichen-Reich (Rang 6–9) – Systementwurf

Quelle der Lore: `docs/lore/01_Weltenbau_und_Kultivierungssystem.md` (4.4–4.8), `04_Gu-Lexikon_Unsterblich_Rang_6-10.md`, `05_Handlung_und_Glossar.md`. Daten: `docs/daten/unsterblich.json` (Systeme, Ränge, Kalamitäten, Gesegnete Länder, Schatzhimmel), `docs/daten/unsterbliche_gu.json` (Unsterbliche Gu und Unsterblichen-Killer-Moves). Verbindlich für alles ab Rang 5 Höchststufe; Widersprüche zu `GDD.md` gehen hierher.

## 1. Grundidee in einem Satz

Wer den Aufstieg übersteht, zerbricht seine sterbliche Apertur und trägt fortan eine eigene kleine Welt in sich; seine Essenz ist von anderer Art – **eine einzige Perle Unsterblichen-Essenz ist für sterbliche Gu unerschöpflich** – und seine Gu-Wirkungen spielen in einer anderen Liga: Rang-5-Meister auf der Höchststufe sind für einen Unsterblichen wie Ameisen.

## 2. Der Aufstieg (Rang 5 Höchststufe → Rang 6)

Voraussetzungen: Rang 5, Höchststufe, Apertur ≥ 90 % gefüllt. Dann braucht der Aufstieg die **drei Qi**:

| Qi | Woher (Spiel) | Lore |
|---|---|---|
| **Himmels-Qi** | Kultivieren auf Rang 5 Höchststufe unter freiem Himmel an hohen Orten (Höhe über dem Meeresspiegel des Gebiets) und an Dao-Orten der Himmelspfade (Wind, Stern, Licht, Wolke, Blitz, Glück, Zeit, Raum, Weisheit, Seele); Gegenstand `himmelsqi` | kosmische Energie, beim Zerbrechen der Apertur aufgenommen |
| **Erd-Qi** | Kultivieren an Urstein-Adern, Geisterquellen, Dao-Orten der Erdpfade (Erde, Holz, Wasser, Feuer, Metall, Kraft, Blut, Knochen, Gift, Eis); Gegenstand `erdqi` | irdische Energie des Aufstiegsortes |
| **Menschen-Qi** | wird aus deinem Leben berechnet: Dao-Markierungen gesamt, Siege, Duelle, abgeschlossene Aufgaben, geöffnete Erbschaften, besuchte Gebiete, Ansehen + Berüchtigtheit, Gu im Besitz | Summe von Erfahrung, Kampfkraft, Pfadverständnis und Fügung |

Die **Balance** ist das Verhältnis des kleinsten zum größten Qi (0–1). Menge und Balance bestimmen den **Grad des Gesegneten Landes** (niedrig, mittel, hoch, super; Zehn Extreme Physiques erhalten immer „super“). Unter `aufstieg.min_balance` droht Scheitern.

**Ablauf** (Ritual am Ort deiner Wahl, durch „Aufsteigen“ auf der Apertur-Seite ausgelöst):
1. **Frage an Himmel und Erde** – eine von fünf Eingebungen (`unsterblich.json → eingebungen`), gilt dauerhaft.
2. **Erdkalamität** – 35 s: Erdspalten, Felsregen und Bestien des Gebiets greifen an.
3. **Himmlische Trübsal** – 35 s: angekündigte Blitzeinschläge, dazu Wellen von Trübsal-Wesen.
4. Überstanden: Rang 6, Unsterblichen-Apertur mit Gesegnetem Land, erste Perlen Grüntrauben-Essenz (je nach Grad), Landgeist erwacht.
5. Tod während des Rituals = gescheitert: im Hardcore-Modus endgültig, sonst fällst du auf Rang 5 Mittelstufe zurück (die Apertur ist zerbrochen) und verlierst die gesammelten Qi.

## 3. Unsterblichen-Essenz

| Rang | Essenz | Farbe |
|---|---|---|
| 6 | Grüntrauben-Essenz (Green Grape) | grün |
| 7 | Rotdattel-Essenz (Red Date) | rot |
| 8 | Weißlitschi-Essenz (White Litchi) | weiß |
| 9 | Gelbaprikosen-Essenz (Yellow Apricot) | gelb |

- Essenz liegt als **Perlen** vor (`ImmortalState.beads`, Rang → Anzahl). Ein unsterblicher Gu des Rangs r verbraucht Perlen des Rangs ≥ r; niedrigere Essenz kann höhere Gu nicht nähren.
- **Sterbliche Gu kosten nichts**, solange du mindestens eine Perle hast (eine Perle = unerschöpfliche Uressenz); auch der Unterhalt der Hilfs-Gu entfällt. Die Uressenz-Leiste bleibt voll.
- Nachschub: **Unsterblichen-Essenzsteine** (`unsterblichen_stein`), die dein Gesegnetes Land täglich erzeugt; der Landgeist verdichtet Steine zu Perlen deines Rangs (1 : 1 für Rang 6, höhere Ränge mehr Steine). Steine sind zugleich Währung im Schatzhimmel.

## 4. Ränge 6–9 und Kalamitäten

Unsterbliche haben laut Lore keine Substufen – im Spiel zählen stattdessen die **überstandenen Kalamitäten**, und die Anzeige nutzt dieselben vier Stufen wie die sterblichen Ränge (Anfang, Mitte, Ober, Höchst), damit sich der Fortschritt gleich anfühlt:

| Rang | Kalamitäten (im Spiel) | Aufstieg |
|---|---|---|
| 6 | alle 3 Spieltage eine Erdkalamität, jede 3. ist eine Himmlische Trübsal | nach 3 Himmlischen Trübsalen (9 Kalamitäten) Höchststufe; Durchbruch braucht Rotdattel-Essenz (Steine) und 2.000 Dao-Markierungen im Hauptpfad |
| 7 | Erd-, Himmels- und Große Trübsal | nach 3 Großen Trübsalen; Durchbruch braucht 20.000 Markierungen |
| 8 | Himmels-, Große und Myriaden-Trübsal; das Land wird zum **Grotto-Himmel** (Himmelskristalle, Wetter, mehrere Teile) | Durchbruch zu Rang 9 nur mit den vier Bedingungen (Abschnitt 6) |
| 9 | alle 5 Tage eine Chaos-Katastrophe von jenseits der Weltgrenze | – |

Eine Kalamität wird am Morgen angekündigt und bricht in der Nacht **in deiner Apertur** los (Wellen von Kalamitätswesen, Blitze, Erdbeben). Bist du dort, kämpfst du selbst; bist du draußen, verteidigen Landgeist und Befestigungen allein – dann verliert das Land Ressourcen und womöglich an Grad. Überstanden: Dao-Markierungen (Lore: 250 je Erdkalamität, 750 je Himmelstrübsal, 7.250 je Großer, 86.750 je Myriaden-Trübsal – im Spiel geteilt durch `kalamitaet_dao_teiler`) und eine Stufe weiter.

## 5. Die Unsterblichen-Apertur (Gesegnetes Land / Grotto-Himmel)

Ein eigenes, jederzeit betretbares Gebiet (`apertur`), das aus deinem Zustand gebaut wird:
- **Größe** nach Grad (niedrig 280 m … super 520 m Kantenlänge; Grotto-Himmel +50 %).
- **Landschaft** nach Hauptpfad (Pfad mit den meisten Dao-Markierungen → Biom).
- **Landgeist** in der Mitte: Übersicht, Steine zu Perlen verdichten, nächste Kalamität, Erträge.
- **Erträge** je Spieltag: Unsterblichen-Essenzsteine und Pfad-Materialien (Zeitfluss: das Land arbeitet `zeitfluss`-mal schneller); ab Rang 8 Himmelskristalle.
- **Annektieren**: Erbschafts-Länder (Hu-Unsterblichen-Land, Lang Ya …) lassen sich nach ihrer Prüfung in deine Apertur eingliedern – das Land wächst, erhält einen Teil ihrer Ressourcen.

## 6. Rang 9 – Ehrwürdiger

Die vier Bedingungen aus der Lore: Weißlitschi-Essenz, **300.000 Dao-Markierungen** im Hauptpfad (im Spiel ÷ `kalamitaet_dao_teiler`), Höchster-Großmeister-Beherrschung im Hauptpfad und das Überstehen der **Höchsten Trübsal**. Danach Titel „Unsterblicher Ehrwürdiger“ (Ansehen > Berüchtigtheit) oder „Dämonischer Ehrwürdiger“ mit selbst gewähltem Pfad-Titel; ein Ehrwürdiger ist **Dao-Herr** seines Hauptpfads (alle Gu dieses Pfads ×2).

## 7. Unsterbliche Gu

- Jeder unsterbliche Gu ist **einzigartig** in der Welt. Quellen: Schatzhimmel-Auktion, Erbschaften, besiegte Unsterbliche, abgeschottete Dimensionen, freier Start.
- Wirkung: reine **Wirkungsschritte** (wie Killer Moves), Grundschaden × `unsterbliche_kraft(rang)`; Kosten in Perlen, lange Abklingzeiten. Passive Gu (Verteidigung, Bewegung, Wahrnehmung) wirken ohne Einsatz, solange sie in der Apertur liegen.
- Zwei eigene Tasten (`immortal_gu_1`, `immortal_gu_2`), Belegung im Gu-Menü.
- Rang-9-Gu (Stärke, Licht, Feuer, Blitz, Weisheit, Frühling-Herbst-Zikade …) sind spielbar; reine Konzept-Gu (Schicksals-Gu) sind Geschichte und Lexikon, keine Waffe.

## 8. Unsterblichen-Killer-Moves

Ein Unsterblichen-Killer-Move = **ein unsterblicher Gu als Kern + viele sterbliche Gu** (drei bis acht Familien, gleich welchen Rangs, in der Apertur). Kosten: Perlen des Kernrangs, Kanalisierung, Ausholzeit. Stärke = Kern × `unsterbliche_kraft` × (1 + `killer_komponenten_bonus` × Anzahl sterblicher Gu). Bekannt, sobald du alle Teile besitzt (Eingebung), aus Erbschaften oder als gekaufte Eingebung im Schatzhimmel (wirken lässt er sich erst mit allen Gliedern). Taste **T** wirkt, **Y** wechselt (Touch: goldener Knopf „Unst.“, Wischen wechselt).

## 9. Unsterbliche gegen Sterbliche

- Trifft ein Unsterblicher (Rang ≥ 6) einen Sterblichen, zählt der Schaden × `unsterblich_gegen_sterblich` (je Rang darüber × `unsterblich_rang_faktor`); Sterbliche richten gegen Unsterbliche nur × `sterblich_gegen_unsterblich` aus. Unter Unsterblichen gilt je Rang Unterschied × `unsterblich_rang_faktor`.
- Sterbliche Gu eines Unsterblichen gelten als voll passend (keine Rang-Abwertung): sie werden von Unsterblichen-Essenz genährt.
- Unsterbliche Leben: `unsterblich_leben` × Faktor je Rang.

## 10. Die Welt der Unsterblichen

- **Wenige Unsterbliche je Macht**: große Sekten und Klans haben ein bis drei (Oberster Ältester), der Himmlische Hof mehr. Sie stehen im Allerheiligsten (Anker `sanctum`), würdigen Sterbliche keines Kampfes und fordern Unsterbliche höchstens zum Duell.
- **Wüste Bestien**: Rang 6 (Wüste Bestie), Rang 7 (Uralte wüste Bestie), Rang 8 (Urzeitliche wüste Bestie) – in Unsterblichen-Gebieten, Dimensionen und als Kalamitätswesen.
- **Schatzhimmel** (Treasure Yellow Heaven): Handel unter Unsterblichen gegen Essenzsteine – sterbliche Rang-5-Gu jeder Familie zum Spottpreis, Materialien, täglich wechselnde Auktion unsterblicher Gu.
- **Gesegnete Länder und Grotto-Himmel der Geschichte** und **abgeschottete Dimensionen** als bereisbare Gebiete (`gebiete.json`, Abschnitt `unsterblich` je Gebiet mit Zutritt ab Rang und Weltregeln `regeln`).

## 11. Freier Start

Startmenü → Spielmodus **Freier Start** (statt „Geschichte“): Geburtsort (jedes Gebiet, auch Gesegnete Länder und Dimensionen, dazu Ankunftspunkt oder eine Siedlung), Rang 1–9 und Stufe, Talent bis zu den Zehn Extremen Physiques, Herkunft, erster Gu; ab Rang 6 Grad des Gesegneten Landes, Eingebung und 0/1/3/6/12 unsterbliche Gu (bevorzugt im Pfad des ersten Gu, samt allen sterblichen Gliedern ihrer Killer Moves). `FreeStart.apply` rechnet Rang- und Stufengaben wie echte Durchbrüche nach, setzt Dao-Markierungen für die erfüllten Durchbruch-Bedingungen, Perlen, Ursteine und Essenzsteine. Die Kindheit entfällt im freien Start.

## 12. Bedienung

- **Gu-Menü → Unsterblich** (ab Rang 5): vor dem Aufstieg die drei Qi als Balken, Gleichgewicht, voraussichtlicher Grad, Qi-Kristalle aufnehmen, „Aufstieg wagen“; danach Rang, Perlen je Essenz, Eingebung, Kraft, Kalamitäten mit Fortschritt, Durchbruch (Trübsal), Gesegnetes Land (Größe, Zeitfluss, Erträge) und Apertur betreten/verlassen, einsammeln, verdichten.
- **Gu-Menü → Unsterbliche Gu**: Besitz mit Wirkung, Perlenkosten, Tasten 5/6 belegen; alle Killer Moves der eigenen Kern-Gu mit ✓/✗ je sterblicher Familie.
- **Gu-Menü → Schatzhimmel** (ab Rang 6): Ursteine tauschen, Auktion des Tages (unsterbliche Gu und Killer-Move-Eingebungen), sterbliche Gu Rang 3–5, Materialien, Verkauf.
- **HUD**: Perlen statt Uressenz („Uressenz ∞“), Rang mit Kalamitäten-Zähler, Kalamitäts-Countdown, Gu-Leiste mit [5] [6] [T]; Touch: zwei goldene Knöpfe 5/6 und „Unst.“.
- **Kultivieren auf Rang 5 Höchststufe** zeigt das gesammelte Himmels-, Erd- und Menschen-Qi mit dem voraussichtlichen Grad.

## 13. Balancing (gemessen)

`balance_probe --masters` (Spieler auf dem Rang des Meisters, nur mit sterblichen Rang-5-Gu, ohne unsterbliche Gu) und `--player-rank=N --rank=N --beasts=…`:
- Unsterblicher Rang 6 gegen Rang-5-Meister: Duell nach **0,2 s** entschieden; Rang-5-Treffer richten 1,5 % aus (Ameisen).
- Gleichrangige NPC-Unsterbliche (6–8): Sieg nach 8–15 s, sie bedrohen dich in 15–60 s (`master_hp_mult` 3, `master_damage_mult` 1,6, `npc_cast_mult` 0,3).
- Wüste Bestien auf ihrem Rang: 8–26 s, bedrohen in 15–43 s (`beast_hp_mult` 2,2, `beast_damage_mult` 2,6); sterbliche Bestien fallen in unter 1 s.
