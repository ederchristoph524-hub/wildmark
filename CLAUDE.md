# CLAUDE.md – Wildmark

Claude Code liest diese Datei zu Beginn jeder Sitzung. Sie beschreibt Projekt, Architektur und Arbeitsregeln. Ändern sich Architektur oder Konventionen, wird diese Datei im selben Commit aktualisiert.

## Projekt

**Wildmark** ist ein Open-World-Survival-RPG in 3D mit stilisiertem Low-Poly-Look. Das Machtsystem ist inspiriert von *Reverend Insanity*: Gu, Apertur, Uressenz, Ränge 1–9, Pfade und Dao-Markierungen, Killer Moves. Hauptziel beim Entwickeln ist der Browser am Handy.

## Dokumente (Quelle der Wahrheit)

| Datei | Inhalt | Verbindlich für |
|---|---|---|
| `docs/GDD.md` | Vision, Systeme, Meilensteine, Nicht-Ziele | Features und Scope |
| `docs/GU_SYSTEM.md` | Familien, Wirkformen, Zustände, Reaktionen, Killer Moves, Merkmale, Welt-Interaktion | alle Gu-Inhalte |
| `docs/KAMPFSYSTEM.md` | Kampfablauf, Loadout, Steuerung, Tod, Startoptionen | Kampfablauf |
| `docs/FORMELN.md` | Balancing-Formeln aus dem Prototyp | Zahlen und Berechnungen |
| `docs/ART_STYLE.md` | Look, Paletten, Asset-Regeln | Grafik, Effekte, Assets |
| `docs/daten/gu_system.json` | 12 Familien, Körper- und Hilfs-Gu, Zustände, Reaktionen, Merkmale, Killer Moves | Quelle für alle Gu-Resources |
| `docs/daten/*.json` (übrige) | Gegner, Materialien, Sekten, Quests, Fortschritt, Unsterblichen-Systeme; `gu.json` nur als Ideenpool | Quelle für die übrigen `.tres` |
| `docs/daten/README.md` | Feldbedeutungen der JSON-Dateien | – |
| `docs/lore/` | RI-Enzyklopädie (zuerst `00_Übersicht_und_Index.md`) | Namen, Stimmung, Lore |
| `docs/referenz/wildmark_prototyp.html` | alter 2D-Prototyp | nur Referenz für Spiellogik |

Den Prototyp nie komplett einlesen (370 KB). Gezielt nach Funktionen suchen, z. B. `grep -o "function refineGu.\{0,800\}"`. Wichtige Funktionen: `breakthrough`, `wallDone`, `refineGu`, `refineChance`, `feedGu`, `useSkill`, `findKiller`, `guFit`, `upkeepOf`, `runTrial`, `joinSect`.

Widersprechen sich Dokumente, gilt: `GU_SYSTEM.md` > `KAMPFSYSTEM.md` > `GDD.md` > `FORMELN.md` > Prototyp. Widersprüche nicht still auflösen, sondern melden.

## Tech-Stack

- **Engine:** Godot **4.7.2** (stable, Standard-Version, nicht .NET). Dieselbe Version muss im Build-Workflow stehen, sonst passen die Export-Templates nicht.
- **Godot-Programm lokal (Windows):** `C:\Projekte\Godot\Godot_v4.7.2-stable_win64_console.exe` – diese Datei für alle Headless-Prüfungen verwenden, z. B. `C:\Projekte\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --import --path C:\Projekte\wildmark`. Läuft Claude in einer Linux-Umgebung (z. B. Cowork), kann es die `.exe` nicht starten und prüft mit dem offiziellen Linux-Build **derselben Version 4.7.2**; die Prüfung mit der `.exe` macht dann der Nutzer.
- **Sprache:** GDScript mit statischen Typen (`var hp: int = 10`, `func f(x: float) -> void`). Warnung für untypisierte Deklarationen in den Projekteinstellungen aktivieren.
- **Renderer:** Compatibility. Keine Features, die nur mit Forward+ funktionieren (z. B. SDFGI, volumetrischer Nebel, bestimmte Post-Effekte), ohne Fallback.
- **Web-Export:** Single-Threaded (ohne SharedArrayBuffer, damit er auf GitHub Pages läuft). Preset „Web“ in `export_presets.cfg`, Build und Veröffentlichung über `.github/workflows/web.yml` bei jedem Push auf `main` (`GODOT_VERSION` dort bei jedem Godot-Update mitändern). Die Engine allein sind ca. 10 MB komprimierter Download; der Workflow schreibt die Größe in die Build-Zusammenfassung. Für Handy-Texturen ist `import_etc2_astc` aktiv.
- **Eingabe:** Tastatur/Maus und Touch. Jede Aktion ist in der Input Map definiert und hat beide Eingabewege. Keine hart codierten Tasten.
- **Input Map** (in `project.godot`, Tasten als physische Tasten): `move_forward/back/left/right`, `jump`, `attack_fist`, `gu_slot_1`–`gu_slot_4`, `killer_move`, `killer_move_next`/`killer_move_prev`, `dash`, `target_lock`, `target_switch`, `eat_primeval_stone`. Touch-Bedienelemente lösen dieselben Aktionen aus. Die Kamera ist keine Aktion (Mausbewegung bzw. Wischen, im Code). Achtung: Godot emuliert Touch als Mausklick – Klicks mit `device == InputEvent.DEVICE_ID_EMULATION` dürfen `attack_fist` nicht auslösen.

## Ordnerstruktur

```
res://
  autoload/        EventBus, GameState, DataRegistry, SaveSystem, Balance
  data/            generierte Resources (.tres) – nie von Hand bearbeiten
    gu/            families/ (Mitglieder eingebettet), body/, support/, traits/, gu_system.tres
    combat/        statuses/, reactions/
    killer_moves/  items/  enemies/  regions/  sects/  quests/
  scripts/
    resources/     Resource-Klassen (GuData, KillerMoveData, …)
    components/    wiederverwendbare Node-Komponenten
    systems/       Spielsysteme ohne eigene Szene
  scenes/
    player/  enemies/  world/  ui/
  assets/
    models/  textures/  audio/  fonts/  LICENSES.md
  tools/           Editor-Skripte (Datenimport, Validierung)
  tests/
docs/
```

## Architektur

**Autoloads:**
- `EventBus` – nur Signale, keine Logik. Systeme kommunizieren darüber statt über direkte Referenzen.
- `GameState` – alles, was gespeichert wird (Spieler, Welt, Zeit, bekannte Killer Moves, gewählte Startoptionen).
- `DataRegistry` – lädt beim Start alle Resources aus `data/` und liefert sie per ID (`DataRegistry.gu(&"mondlicht")`).
- `SaveSystem` – JSON in `user://`, mit `save_version` und Migrationen bei Formatänderungen.
- `Balance` – ein Resource mit allen Balancing-Konstanten aus `FORMELN.md`.

**Datengetrieben:** Inhalte kommen ausschließlich aus `data/`. Ein neuer Gu darf keinen neuen Code erfordern, solange sein Effekttyp schon existiert. Gu-Wirkungen werden über die **Wirkformen** aus `GU_SYSTEM.md` (geschoss, strahl, stich, kreis, selbst, bewegung, zaehmen …) mit Tags und Zuständen umgesetzt, nie als Sonderfall pro Gu. Zustände und Reaktionen sind datengetrieben: Eine neue Reaktion ist ein Tabelleneintrag, kein neuer Code.

**Komponenten statt Vererbungsketten:** `StatusComponent` (Zustände, Stapel, Reaktionen – auch auf Welt-Objekten), `HealthComponent`, `ApertureComponent` (Rang, Stufe, Uressenz, Talent, Wand), `GuHolderComponent` (Besitz, Slots, Hunger, Unterhalt), `DaoComponent`, `HitboxComponent`. Spieler und NPC-Gu-Meister nutzen dieselben Komponenten; der Unterschied ist nur, ob Eingabe oder KI sie steuert.

**Kern-Resources:**
- `GuFamilyData`: `id`, `display_name`, `path`, `role`, `form`, `tags`, `status`, `feed_item`, `feed_amount`, `base_r1` (Dictionary), `members` (Array von `GuData`), `upgrade_materials`, `world_effect`
- `GuData`: `id`, `display_name`, `family`, `rank`, `rank_gift`, `description`, `lore`
- `GuInstance` (Laufzeit, gespeichert): `gu_id`, `trait_id`, `satiety`, `cooldown_left` (`trait` ist ab Godot 4.7 ein reserviertes Wort)
- `StatusData`, `ReactionData`, `TraitData`, `BodyGuData`, `SupportGuData`
- `ReactionData`: `target_status` ist eine Zustands-ID oder eine abgeleitete Bedingung aus `ReactionData.DERIVED_CONDITIONS` (derzeit `eingefroren`); `min_stacks` > 0 verlangt Mindeststapel (aus `gift_ab_3` wird `gift` mit 3)
- `GuSystemData`: Tags, Merkmal-Chancen, Start-Familien (`data/gu/gu_system.tres`)
- `KillerMoveData`: `id`, `display_name`, `family_a`, `family_b`, `channel_time`, `damage_mult`, `description`, `hint`
- `EnemyData` (Beute als `Array[DropEntry]`: jeder Eintrag wird einzeln gewürfelt, gleiche Items dürfen mehrfach vorkommen), `ItemData` (Grundressourcen und Materialien, ein ID-Raum), `RegionData` (ID ist int), `SectData`, `QuestData`

## Datenimport

`tools/import_data.gd` (EditorScript) liest `docs/daten/*.json` und erzeugt bzw. aktualisiert die `.tres`-Dateien in `data/`. Es validiert dabei alle Verweise (Futter, Drops, Killer-Move-Gu, Sekten-Gu) und bricht bei Fehlern mit klarer Meldung ab.

- **Editor:** `tools/import_data.gd` öffnen, „Datei → Ausführen“ (Strg+Umschalt+X).
- **Headless:** `godot --headless --path . --script res://tools/import_data_cli.gd` (Exit-Code 1 bei Fehlern). Danach `godot --headless --path . --script res://tests/test_data_import.gd`.
- Die Logik liegt in `tools/data_importer.gd` (Ablauf, Schreiben), `gu_import_builder.gd`, `world_import_builder.gd` und `import_validator.gd`.
- Erst wird alles gebaut und geprüft, dann geschrieben: Bei einem Fehler bleibt `data/` unverändert. Vorhandene UIDs bleiben erhalten; ein zweiter Lauf ohne Datenänderung ändert keine Datei.
- `.tres`-Dateien, deren ID nicht mehr in den Daten steht, werden nur als Warnung gemeldet, nicht gelöscht.
- Warnung statt Fehler: Sekten-Signatur-Gu, die nur im Ideenpool `gu.json` stehen (kommen in späteren Meilensteinen), und Material-Pfade, die in `gu.json → PATHS` fehlen.
- Nicht importiert: `fortschritt.json`, `unsterblich.json`, `KILLERS` aus `killer_moves.json`, `GEAR`, `BUILD`, `GUMASTER`, `VARIANTS`, `NPCTYPE`, `SECTRANKS`, `FACTIONS`, `STANDING`, `ZONE_NAMES` – dafür gibt es noch keine Resource-Klasse.

IDs aus dem JSON bleiben als `StringName` erhalten. Werte mit `[fn]` sind JavaScript-Referenzlogik und werden nicht importiert, sondern beim Umsetzen des Effekts gelesen. Nach Datenänderungen das Skript erneut ausführen.

`docs/` enthält eine `.gdignore`, damit Godot die Dokumente nicht als Ressourcen scannt. JSON-Dateien dort deshalb mit `FileAccess` lesen, nicht mit `load()`.

Für Gu wird ausschließlich `gu_system.json` importiert; `gu.json` liefert nur Lore-Texte für Mitglieder, die dort existieren (`neu: false`).

## Code-Konventionen

- Bezeichner englisch (`snake_case`, Klassen `PascalCase`), Kommentare dürfen deutsch sein.
- Spielertexte deutsch und über `tr()`. Lore-Eigennamen wie in den Daten.
- Jede Klasse hat `class_name` und einen `##`-Doc-Kommentar mit einem Satz Zweck. **Ausnahme:** Autoload-Skripte in `autoload/` haben kein `class_name`, weil ein gleichnamiges `class_name` den Autoload verdeckt und einen Fehler erzeugt.
- Keine Magic Numbers: Werte gehören in `Balance` oder in Resources.
- Signale statt `get_node("../../..")`; Node-Referenzen über `@export` oder `%UniqueName`.
- Funktionen ab ca. 40 Zeilen aufteilen. Keine Datei über 400 Zeilen.
- Zeitabhängige Logik immer mit `delta` und in „pro Spieltag"-Raten (siehe `FORMELN.md`, Zeit).

## Godot-Fallstricke

- `.tscn`- und `.tres`-Dateien nur über Skripte oder vorsichtig per Text ändern; keine `uid://`- oder `ExtResource`-IDs erfinden.
- `.uid`-Dateien (ab Godot 4.4) gehören ins Repository; nie löschen.
- Neue `class_name`-Klassen werden erst nach einem Import erkannt: nach dem Anlegen `godot --headless --import --path .` ausführen.
- `export_presets.cfg` gehört ins Repository (ohne Passwörter), sonst kann der Build-Workflow nicht exportieren.
- Physik in `_physics_process`, Eingabe-Aktionen über `Input.is_action_*`, nie über Tastencodes.

## Performance-Budget (Handy-Browser)

- Ziel 30+ FPS auf einem Mittelklasse-Handy, Download unter 50 MB.
- Maximal ca. 150 Draw Calls im sichtbaren Bereich; Vegetation als `MultiMeshInstance3D`.
- Nur die Sonne wirft Schatten; Gras-Sichtweite ca. 30 m; Welt in Chunks laden und entladen.
- Details in `docs/ART_STYLE.md`.

## Arbeitsweise

1. **Zu Beginn jeder Aufgabe:** relevante Dokumente lesen, bei größeren Aufgaben zuerst einen kurzen Plan vorlegen und auf Freigabe warten.
2. **Ein Feature pro Aufgabe.** Was nicht im aktuellen Meilenstein steht, wird nicht gebaut, sondern im GDD unter „Ideen" notiert.
3. **Prüfen vor dem Commit:** `godot --headless --import --path .` muss fehlerfrei laufen; vorhandene Tests ausführen. Nie einen kaputten Stand committen.
4. **Commit** mit deutscher Nachricht, die sagt, was sich für den Spieler ändert (z. B. `Gu-Fütterung: Hunger-Stufen und Verhungern`).
5. **Abschluss-Zusammenfassung:** was geändert wurde, wie man es am Handy und am PC testet, was offen oder unsicher ist.
6. **Nichts Unbestelltes umbauen.** Größere Refactorings nur nach Rückfrage.
7. **Tests** für reine Logik (Formeln, Hunger, Durchbruch, Killer-Move-Erkennung) als einfache Test-Skripte in `tests/`, die headless laufen.

## Definition of Done

Ein Feature ist fertig, wenn es im Web-Build am Handy funktioniert, per Touch und Tastatur bedienbar ist, seine Werte aus Daten oder `Balance` kommen, es gespeichert und geladen wird (falls es Zustand hat) und keine neuen Warnungen im Editor erzeugt.

## Assets und Recht

- Keine urheberrechtlich geschützten Dateien ohne Lizenz. Platzhalter (einfache Meshes, Farben) sind in Ordnung. Jede externe Quelle in `assets/LICENSES.md`.
- Das Projekt ist privat. Namen und Lore stammen teils aus *Reverend Insanity*. Namen deshalb nur über Daten und `tr()`, nie im Code verstreut, damit sie vor einer Veröffentlichung austauschbar sind.
