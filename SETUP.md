# SETUP – So startest du Wildmark

Diese Datei ist für dich, nicht für Claude. Arbeite sie von oben nach unten ab.

## 1. Einmalige Einrichtung

**Am Laptop**
1. **Godot 4** (Standard-Version, nicht .NET) von godotengine.org herunterladen und entpacken. Die Versionsnummer merken.
2. **Git** installieren (git-scm.com), falls noch nicht vorhanden.
3. **GitHub-Konto** anlegen und ein leeres, **öffentliches** Repository `wildmark` erstellen (GitHub Pages ist nur bei öffentlichen Repos kostenlos; siehe Abschnitt 5).
4. **Claude Desktop** installieren und den Code-Tab öffnen.
5. Diesen entpackten Ordner als Projektordner verwenden und in Claude Code öffnen.

**Nur am Handy**
1. GitHub-Konto und Repository wie oben anlegen.
2. Den Inhalt dieser Zip im Repository hochladen (github.com → Repository → „Add file" → „Upload files"; Ordnerstruktur beibehalten).
3. In der Claude-App Claude Code öffnen und mit dem Repository verbinden. Ab Prompt 1 genauso weiter.

## 2. Prompts in dieser Reihenfolge

Einzeln schicken. Nach jedem Schritt die **Prüfung** machen, erst dann den nächsten.

**Prompt 1 – Fundament**
> Lies CLAUDE.md, docs/GDD.md, docs/GU_SYSTEM.md und docs/KAMPFSYSTEM.md. Lege ein Godot-4-Projekt mit Compatibility-Renderer an, mit der Ordnerstruktur und den Autoloads aus CLAUDE.md als leere Gerüste. Richte die Input Map für alle Aktionen aus der Steuerungstabelle im Kampfsystem ein. Git mit .gitignore und .gitattributes für Godot. Trag die Godot-Version in CLAUDE.md ein. Zeig mir zuerst deinen Plan.

*Prüfung:* Projekt öffnet sich in Godot ohne Fehler.

**Prompt 2 – Web-Build**
> Erstelle export_presets.cfg für einen Single-Threaded-Web-Export und einen GitHub-Actions-Workflow, der bei jedem Push auf main mit genau unserer Godot-Version exportiert und auf GitHub Pages veröffentlicht. Sag mir danach, was ich in den Repository-Einstellungen aktivieren muss.

Danach im Repository: Settings → Pages → Source „GitHub Actions".
*Prüfung:* `deinname.github.io/wildmark` lädt am Handy (noch leere Szene).

**Prompt 3 – Datenimport**
> Lege die Resource-Klassen aus CLAUDE.md an und schreibe tools/import_data.gd, das gu_system.json und die übrigen docs/daten/*.json nach data/ importiert und alle Verweise validiert. Führe es aus und nenne mir die Anzahl pro Typ.

*Prüfung:* 12 Familien mit 36 Gu, 4 Körper-Gu, 7 Hilfs-Gu, 6 Zustände, 8 Reaktionen, 10 Merkmale, 8 Killer Moves, 25 Gegner, keine Validierungsfehler.

**Prompt 4 – Charakter**
> Baue einen Third-Person-Charakter mit Laufen, Springen, Dash (laut Kampfsystem) und Kamera. Touch: Joystick links, Kamera durch Wischen rechts, Buttons für Springen und Dash. Platzhalter-Terrain.

*Prüfung:* Am Handy flüssig steuerbar, Kamera fühlt sich nicht hakelig an.

**Prompt 5 – Welt**
> Ersetze das Terrain durch ein kleines Dschungelgebiet der Südlichen Grenze nach docs/ART_STYLE.md, mit Bäumen und Gras als MultiMesh, Tag-Nacht-Zyklus (20 Minuten) und regionaler Nebel-/Himmelsfarbe. Halte das Performance-Budget ein und zeig mir die FPS im Debug-Overlay.

*Prüfung:* 30+ FPS am Handy.

**Prompt 6 – Neues Spiel und Apertur**
> Baue das Neues-Spiel-Menü (Todesmodus, Kindheit überspringen, Talent) und die ApertureComponent: Uressenz, Regeneration, Meditation mit Aperturwand, Stufen, Durchbruch auf Rang 2 – Formeln aus docs/FORMELN.md, Werte ins Balance-Resource. HUD-Anzeige. Mit Tests für die Formeln.

**Prompt 7 – Gu-Besitz**
> Baue die GuHolderComponent laut GU_SYSTEM.md und KAMPFSYSTEM.md: Gu-Kapazität, 4 aktive Slots, Hilfs-Gu mit Unterhalt, Körper-Gu, Hunger-Stufen und Verhungern, Fütterung, Merkmale, Rang-Passung. Gu-Menü. Wahl des ersten Gu beim Erwachen.

**Prompt 8 – Wirkformen und Zustände**
> Setze GU_SYSTEM.md Abschnitte 2 und 3 um: die Wirkformen geschoss, strahl, stich, kreis und selbst mit Tags, die StatusComponent mit allen 6 Zuständen und die Reaktionstabelle datengetrieben. Reaktionen als Schriftzug über dem Ziel. Teste mit Wasserlicht, Frostnadel, Funkenwurm, Glutfunke und Wirbelwind gegen Wölfe. Zeig mir zuerst deinen Plan.

**Prompt 9 – Kampf**
> Setze KAMPFSYSTEM.md Abschnitte 1–3 und 6–8 um: Faustschlag, Essenz und Cooldowns, Soft-Lock, Telegraphen, Schadensreduktion. Dann die restlichen Rang-1-Familien inklusive Sprungwurm (Doppelsprung) und Ratten-Sklaverei (Zähmen mit der Gegner-KI).

**Prompt 10 – Killer Moves**
> Setze Killer Moves auf Familienebene laut GU_SYSTEM.md Abschnitt 7 und KAMPFSYSTEM.md Abschnitt 4 um: Kanalisierung, Abbruch, gemeinsamer Cooldown, Eingebung, Kombinationsbuch. Zuerst Gewitterflut und Gletscherbruch.

**Prompt 11 – Welt-Interaktion**
> Setze GU_SYSTEM.md Abschnitt 8 um: StatusComponent auf Welt-Objekten und die sieben wiederverwendbaren Hindernisse (brennbare Hecke, Wasserfläche, Felsbrocken, Ruinenschalter, Lichtsiegel, Blutsiegel, Vorsprung). Baue im Testgebiet hinter jedes Hindernis einen wilden Gu.

**Danach (weiter M2):** Einfangen und Verfeinern wilder Gu mit Gu-Köder → Aufstiegsverfeinerung auf Rang 2 → restliche Gegner → NPC-Gu-Meister → Dorf, Händler, Quests → Bauen und Ruheorte → Speichern/Laden und Todesmodi → spielbare Kindheit. Immer ein System pro Prompt.

## 3. Gute Gewohnheiten mit Claude Code

- **Plan zuerst:** Bei größeren Aufgaben „Zeig mir zuerst deinen Plan" dazuschreiben. Fehler im Plan kosten Sekunden, Fehler im Code Stunden.
- **Frische Sitzung pro Feature:** Nach einem abgeschlossenen Feature eine neue Unterhaltung beginnen. Lange Sitzungen werden unübersichtlich und verbrauchen mehr Nutzungskontingent. Die CLAUDE.md sorgt dafür, dass nichts verloren geht.
- **Konkretes Feedback:** statt „fühlt sich komisch an" lieber „Kamera dreht zu schnell, Sprung zu schwebend, Dash zu kurz".
- **Roter Build:** „Der Actions-Build ist fehlgeschlagen, lies den Log und behebe es."
- **Aufräumen:** Alle paar Features „Prüf, ob CLAUDE.md und die docs noch zum Code passen, und aktualisiere sie."
- **Ideen parken:** „Schreib das ins GDD unter Ideen" statt sofort bauen.
- **Balancing:** Werte nie im Code ändern lassen, sondern im Balance-Resource oder in docs/daten.

## 4. Testen

- Am Handy immer im Querformat testen und einmal im Hochformat prüfen, dass nichts kaputtgeht.
- Nach jedem Meilenstein einem Freund zum Spielen geben und nur zuschauen, nichts erklären. Wo er hängen bleibt, ist das nächste Problem.
- Erfolgskriterium für M2 steht im GDD.

## 5. Später: gekaufte Assets

Sobald kostenpflichtige Assets ins Projekt kommen, muss das Repository privat werden (Lizenz). GitHub Pages aus privaten Repos kostet dann Geld. Lösung: „Stell den Workflow so um, dass der Web-Export auf Cloudflare Pages (oder itch.io mit privatem Link) veröffentlicht wird." Details in `docs/ART_STYLE.md`.
