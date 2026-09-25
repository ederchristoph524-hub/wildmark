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
| `docs/daten/gu_system.json` | 35 Familien, Körper- und Hilfs-Gu, Zustände, Reaktionen, Merkmale, Killer Moves | Quelle für alle Gu-Resources |
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
- **Input Map** (in `project.godot`, Tasten als physische Tasten): `move_forward/back/left/right`, `jump`, `attack_fist`, `gu_slot_1`–`gu_slot_4`, `killer_move`, `killer_move_next`/`killer_move_prev`, `dash`, `target_lock`, `target_switch`, `eat_primeval_stone`, `interact` (E), `meditate` (M), `gu_menu` (G), `pause_menu` (Esc). Touch-Bedienelemente lösen dieselben Aktionen aus. Die Kamera ist keine Aktion (Mausbewegung bzw. Wischen, im Code). Achtung: Godot emuliert Touch als Mausklick – Klicks mit `device == InputEvent.DEVICE_ID_EMULATION` dürfen `attack_fist` nicht auslösen. Die Touch-Steuerung (`scenes/ui/touch_controls.gd`) wertet Multitouch selbst aus (Joystick, Kamera-Wischen, Buttons) und sendet `InputEventAction`s; GUI-Buttons können nur einen Finger gleichzeitig.

## Ordnerstruktur

```
res://
  autoload/        EventBus, GameState, DataRegistry, SaveSystem, Balance
  data/            generierte Resources (.tres) – nie von Hand bearbeiten
    gu/            families/ (Mitglieder eingebettet), body/, support/, traits/, gu_system.tres
    progression.tres  Ränge, Stufen, Talentgrade (aus fortschritt.json)
    combat/        statuses/, reactions/
    killer_moves/  items/  enemies/  regions/  sects/  quests/
    npcs/  builds/  gu_masters/   NPC-Arten, Bauteile, NPC-Gu-Meister (aus gegner.json bzw. bauen.json)
    standings/     Herkünfte im Klan (aus fraktionen.json → STANDING)
    areas/  biomes/  Gebiete und Landschaften (aus gebiete.json)
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
  Abfragen: `gu`, `family`, `family_of`, `body_gu`, `support_gu`, `trait_data`, `status`, `reaction`, `killer_move`, `enemy`, `item`, `region` (int), `sect`, `quest`, `gu_system`; Listen: `all(&"enemies")`, `all_gu()`; dazu `has`, `has_gu`, `count`. Unbekannte IDs liefern `null` und einen Fehler im Log. Lädt über `ResourceLoader.list_directory`, damit es auch im Web-Export funktioniert.
- `SaveSystem` – JSON in `user://`, mit `save_version` und Migrationen bei Formatänderungen.
- `Balance` – `Balance.values` ist ein `BalanceData` mit allen Balancing-Konstanten aus `FORMELN.md` und `KAMPFSYSTEM.md` (Standardwerte im Skript; optional überschrieben durch `res://data/balance.tres`). Auch die Merkmale (`trait_rules`) und Physiques (`physique_rules`) stehen dort; Zustände, Reaktionen, Hilfs-Gu, Ranggaben und Killer Moves stehen dagegen als Daten in `gu_system.json` (`regel`, `regeln`, `gaben`, `schritte`).

**Datengetrieben:** Inhalte kommen ausschließlich aus `data/`. Ein neuer Gu darf keinen neuen Code erfordern, solange sein Effekttyp schon existiert. Gu-Wirkungen werden über die **Wirkformen** aus `GU_SYSTEM.md` (20 Formen) mit Tags, Zuständen, Ranggaben und **Wirkungsschritten** (`EffectSteps`) umgesetzt, nie als Sonderfall pro Gu. Zustände, Reaktionen und Killer Moves sind datengetrieben: Ein neuer Killer Move oder eine neue Reaktion ist ein Tabelleneintrag, kein neuer Code.

**Komponenten statt Vererbungsketten:** `StatusComponent` (Zustände, Stapel, Reaktionen – auch auf Welt-Objekten), `HealthComponent`, `ApertureComponent` (Rang, Stufe, Uressenz, Talent, Wand), `GuHolderComponent` (Besitz, Slots, Hunger, Unterhalt), `LoadoutComponent` (Slot-Wechsel, im Kampf mit Kanalisierung), `TargetingComponent` (weiches Ziel, Fixierung, Antippen), `DaoComponent`, `HitboxComponent`. Spieler und NPC-Gu-Meister folgen denselben Regeln; der Unterschied ist nur, ob Eingabe oder KI sie steuert. Ausnahme bisher: `ApertureComponent` und `GuHolderComponent` lesen `GameState` direkt und gehören nur dem Spieler – `GuMaster` (`scenes/enemies/gu_master.gd`, KI in `gu_master_brain.gd`) rechnet Essenz, Kosten und Cooldowns mit denselben `Formulas` selbst.

**Gebiete:** Die Welt besteht aus Gebieten (`docs/daten/gebiete.json` → `AreaData`, `BiomeData`); `GameState.area` ist das aktuelle. `World` baut daraus Gelände (`Terrain`: Rauschen + eingeebnete Plätze, Seen, Wege; Kacheln, Shader `assets/shaders/terrain.gdshader`), Vegetation nach Biom (`VegetationMeshes`, Tönung je Biom und Instanz), Fernansicht mit Gebirgskranz (`TerrainBackdrop`), Meer (`BiomeData.sea_level`, `WaterSurface.sea`), Erhebungen (`AreaData.hills`), Siedlungen (`Settlement` für Klan-Dörfer, `SettlementLayouts` für Stadt, Festung und Sekte, `SettlementOutposts` für Zeltlager, Oasenstadt, Inseldorf und Versteck; Bauten in `Architecture`, `ArchitectureExtra`, `HouseStyles`; ein Mesh pro Siedlung; Bewohner, Spaziergänger (`Npc.wander_points`) und Gu-Meister über `SettlementPeople`), Orte (`WorldAreas`: Materialquellen mit eingefärbtem Boden über `Terrain.stains` und Ausstattung aus `PlaceDecor`, `SpiritSpring`, `Inheritance` mit Bauform aus `InheritanceLooks` nach `stil`, Seen mit `WaterSurface`) und Hindernis-Orte; Bestienflut je Gebiet (`BeastTide`, `AreaData.tide`: angekündigt am Morgen, Wellen in der Nacht). Reisen: Weltkarte → `EventBus.travel_requested` → `Main._on_travel`. Karten: `MapData`, `Minimap`, `MapMenu` (`AreaMapView`, `WorldMapView`). Grafik-Rundgang: `tools/capture_tour.gd` → `build/tour/` (`-- --area=ID --only=ansicht1,ansicht2 --census`; `--census` listet sichtbare Meshes je Quelle für die Draw-Call-Suche).

**Spielablauf:** `scenes/main.gd` (Startmenü, Sitzung, Menüs mit Pause, Autospeichern, Tod, Reisen) → `World` (`scenes/world/`, siehe Gebiete) → `Player` (`scenes/player/`) und `Enemy` (`scenes/enemies/`), beide `Combatant` (`scripts/components/combatant.gd`: Team, `HealthComponent`, `StatusComponent`, Treffer). Gu-Wirkungen: `GuCaster` (Grund-Wirkformen, Ranggaben über `GuGifts`), `GuForms` (weitere Wirkformen als Schritte), `EffectSteps` + `EffectStepsSelf` (Wirkungsschritte mit `EffectContext`), `EffectZone`, `OrbitBlades`, `GuTrap`, `ReactionEffects`, `KillerMoveEffects` (führt `KillerMoveData.steps` aus), `Projectile` (Fächer, Zielsuche, Kette, Aufschlag-Schritte) in `scripts/systems/`. Bestien-Fähigkeiten: `EnemyData.ability` über `EnemyAbilities`. `Combatant` kennt Stärkungen (`buffs`), Tarnung, Unaufhaltsamkeit, Lebensraub, Betäubung und Hinrichtung. Oberfläche in `scenes/ui/`. Spielbare Kindheit: `Childhood` (`scripts/systems/childhood.gd`, `GameState.childhood_step`, -1 = erwacht) und `AwakeningMenu`. Gu verschmelzen: `GuRecipes` (Rezepte in `GuSystemData.recipes`, Seite `RecipePage`). Herkunft beim Erwachen: `Origins` (`StandingData`, Startmenü „Herkunft“). Sektenleben: `SectLife` (`scripts/systems/sect_life.gd`; Beitritt beim Oberhaupt einer Siedlung – `Npc.leader`, `Npc.sect_id` –, Verdienst, Ränge aus `ProgressionData.sect_ranks`, tägliche Zuteilung über `EventBus.day_started`; Tagesauftrag des Oberhaupts über `SectTasks`). Duell mit dem Klanlehrer: `GuMaster` + `DuelRewards`; `HealthComponent.floor_hp` verhindert den Tod im Duell. Dao-Markierungen und Pfad-Beherrschung: `Dao` (`scripts/systems/dao.gd`, `GameState.dao`, Stufen aus `GuSystemData.attain_*`; wirkt auf Kosten und Abklingzeit in `GuHolderComponent`; Seite `DaoPage` im Gu-Menü). `HitboxComponent` gibt es noch nicht (Kampfabfragen laufen über Gruppen in `Combat`).

**Kern-Resources:**
- `GuFamilyData`: `id`, `display_name`, `path`, `role`, `form`, `tags`, `status`, `feed_item`, `feed_amount`, `base_r1` (Dictionary), `members` (Array von `GuData`), `upgrade_materials`, `world_effect`
- `GuData`: `id`, `display_name`, `family`, `rank`, `rank_gift`, `description`, `lore`
- `GuInstance` (Laufzeit, gespeichert): `gu_id`, `trait_id`, `satiety`, `cooldown_left` (`trait` ist ab Godot 4.7 ein reserviertes Wort)
- `StatusData`, `ReactionData`, `TraitData`, `BodyGuData`, `SupportGuData`
- `ReactionData`: `target_status` ist eine Zustands-ID oder eine abgeleitete Bedingung aus `ReactionData.DERIVED_CONDITIONS` (derzeit `eingefroren`); `min_stacks` > 0 verlangt Mindeststapel (aus `gift_ab_3` wird `gift` mit 3)
- `GuSystemData`: Tags, Merkmal-Chancen, Start-Familien, Pfadnamen/-farben/-konflikte (`data/gu/gu_system.tres`)
- `ProgressionData`: Rangnamen und -farben, Stufen, Durchbruchschancen, Rang-Obergrenzen je Talentgrad, die Zehn Extremen Physiques als `Array[PhysiqueData]`, Sektenränge als `Array[SectRankData]` (aus `fraktionen.json → SECTRANKS`) (`data/progression.tres`)
- `PhysiqueData`: `id`, `display_name`, `path_label`; Wirkung in `BalanceData.physique_rules` (Schlüssel wie bei Körper-/Hilfs-Gu, fließen über `PassiveGu` ein; Sonderfälle in `PhysiqueEffects`). Nur beim Talentgrad `Durchbrochen`, gespeichert als `GameState.physique`
- `KillerMoveData`: `id`, `display_name`, `family_a`, `family_b`, `channel_time`, `damage_mult`, `description`, `hint`
- `GuMasterData`: `id`, `display_name`, `color`, `faction`, `gu` (IDs; der Meister nutzt das Familienmitglied seines Rangs); `NpcTypeData`, `BuildData`
- `EnemyData` (Beute als `Array[DropEntry]`: jeder Eintrag wird einzeln gewürfelt, gleiche Items dürfen mehrfach vorkommen), `ItemData` (Grundressourcen und Materialien, ein ID-Raum), `RegionData` (ID ist int), `SectData`, `QuestData`

## Datenimport

`tools/import_data.gd` (EditorScript) liest `docs/daten/*.json` und erzeugt bzw. aktualisiert die `.tres`-Dateien in `data/`. Es validiert dabei alle Verweise (Futter, Drops, Killer-Move-Gu, Sekten-Gu) und bricht bei Fehlern mit klarer Meldung ab.

- **Editor:** `tools/import_data.gd` öffnen, „Datei → Ausführen“ (Strg+Umschalt+X).
- **Headless:** `godot --headless --path . --script res://tools/import_data_cli.gd` (Exit-Code 1 bei Fehlern). Danach die Tests `res://tests/test_data_import.gd` und `res://tests/test_data_registry.gd` (jeweils mit `--headless --path . --script`).
- Die Logik liegt in `tools/data_importer.gd` (Ablauf, Schreiben), `gu_import_builder.gd`, `world_import_builder.gd` und `import_validator.gd`.
- Erst wird alles gebaut und geprüft, dann geschrieben: Bei einem Fehler bleibt `data/` unverändert. Vorhandene UIDs bleiben erhalten; ein zweiter Lauf ohne Datenänderung ändert keine Datei.
- `.tres`-Dateien, deren ID nicht mehr in den Daten steht, werden nur als Warnung gemeldet, nicht gelöscht.
- Warnung statt Fehler: Sekten-Signatur-Gu, die nur im Ideenpool `gu.json` stehen (kommen in späteren Meilensteinen), und Material-Pfade, die in `gu.json → PATHS` fehlen.
- Nicht importiert: `unsterblich.json`, aus `fortschritt.json` nur `CFG` (von `PHYS` nur ID, Name und Pfad), `KILLERS` aus `killer_moves.json`, `GEAR`, `BUILD`, `GUMASTER`, `VARIANTS`, `NPCTYPE`, `FACTIONS`, `ZONE_NAMES` – dafür gibt es noch keine Resource-Klasse.

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
- **Packed-Arrays in Resources** (`PackedStringArray`, `PackedColorArray` …) kamen im Web-Export leer an. In Resource-Klassen deshalb `Array[String]`, `Array[Color]` usw. verwenden.
- **Freigegebene Objekte:** Im Release-Build (auch Web) stürzt ein Methodenaufruf auf ein freigegebenes Objekt ab. Gespeicherte Verweise auf Figuren (Ziele, Angreifer) vor der Nutzung mit `is_instance_valid()` prüfen.
- **Test-Skripte** (`extends SceneTree`) kennen die Autoload-Namen beim Kompilieren nicht. Die eigentlichen Schritte stehen deshalb in einer eigenen Datei, die nach dem Start geladen wird (siehe `tests/test_game_smoke.gd`). Tests setzen `SaveSystem.save_path` auf einen eigenen Pfad.
- Controls, die per Code den ganzen Bildschirm füllen sollen, mit `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` anlegen, nicht nur `set_anchors_preset`.

## Prüfen und Testen

- `godot --headless --import --path .`
- Alle Skripte mit Warnungen als Fehler laden: `godot --headless --path . --script res://tools/check_scripts.gd` (dazu die Warnstufen per `override.cfg` auf 2 setzen; `override.cfg` nie committen).
- Tests: `tests/test_formulas.gd`, `tests/test_data_import.gd`, `tests/test_data_registry.gd` (erwartete Anzahlen aus den Quelldateien über `ExpectedCounts`), der Durchspiel-Test `tests/test_game_smoke.gd` (Schritte in `game_smoke_steps.gd`, `combat_smoke_steps.gd`, `world_smoke_steps.gd`), `tests/test_childhood.gd` der Katalog-Test `tests/test_gu_catalog.gd` (jeder Gu, Killer Move und jede Bestien-Fähigkeit) und `tests/test_areas.gd` (Reise in jedes Gebiet; alle mit `--fixed-fps 60`); Balancing-Messung mit `tools/balance_probe.gd` (Bestien, `-- --solo` je Familie, `-- --masters` Duelle; siehe `GU_SYSTEM.md`, Abschnitt 11), jeweils `godot --headless --path . --script res://tests/<name>.gd`.
- Touch in Tests: `InputEventScreenTouch` per `Input.parse_input_event` erwartet Fensterkoordinaten – Viewport-Punkte (z. B. aus `Camera3D.unproject_position`) vorher mit `get_tree().root.get_final_transform()` umrechnen.
- Bildschirmfotos samt Draw Calls: `xvfb-run godot --path . --rendering-driver opengl3 --fixed-fps 60 --script res://tools/capture_screenshots.gd` → `build/screenshots/`.

## Performance-Budget (Handy-Browser)

- Ziel 30+ FPS auf einem Mittelklasse-Handy, Download unter 50 MB.
- Maximal ca. 150 Draw Calls im sichtbaren Bereich; Vegetation als `MultiMeshInstance3D`.
- Nur die Sonne wirft Schatten; Gras-Sichtweite ca. 30 m; Welt in Chunks laden und entladen.
- Klänge entstehen zur Laufzeit (`SoundSynth`, `Sound`-Knoten in Main); neue Klänge dort als Rezept ergänzen, keine Audiodateien nötig.
- Grafikstufe im Pausenmenü (`GraphicsSettings`, `user://settings.cfg`): Niedrig/Mittel/Hoch skalieren Grasdichte, Pflanzen-Sichtweite, Schatten und 3D-Auflösung; im Browser startet Mittel.
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
