# Art-Style-Guide – Wildmark

Ziel: ein einheitlicher, wiedererkennbarer Look, der im Handy-Browser flüssig läuft. Einheitlichkeit schlägt Detailgrad. Ein Spiel mit schlichten, aber zusammenpassenden Assets wirkt hochwertiger als eines mit gemischten, detaillierten.

## Stil in einem Satz

Realistisch angehauchtes Low-Poly: einfache Formen, aber echte Oberflächen (Gras, Erde, Fels, Putz, Holz, Ziegel, Rinde, Stoff mit Relief), Laub aus Blattkarten, Wasser mit Wellen und Himmelsspiegelung, Wolken, warmes Laternenlicht und Glow – schön bei Tag, bedrohlich bei Nacht.

## Umsetzung des realistischen Looks (Stand: Realismus-Umbau)

- **Texturen ohne Dateien:** `ProceduralTextures` (mit `ProceduralPatterns`, `ProceduralCards`) erzeugt beim ersten Start nahtlose Detailtexturen und Normal Maps (256 px) und legt sie als PNG in `user://textures/` ab (`VERSION` erhöhen, wenn sich ein Rezept ändert). Die Farbe kommt weiterhin aus Vertex-Farben; die Textur liefert nur Helligkeit und Relief.
- **Gelände** (`terrain.gdshader`): Gras auf Grün, Kies/Erde auf Wegen, dreiseitig projizierter Fels an Steilhängen, Steinplatten auf Pflaster (Vertex-Alpha), Nässe bei Regen. Details blenden ab 45 m aus.
- **Bauten und Requisiten** (`settlement.gdshader`, `WorldMaterials.settlement()`/`props()`): Material nach Farbe und Neigung – geneigte Flächen Dachziegel, Brauntöne (Farbton 14–56°) Holz, helle Töne Putz, graue Stein. Fenster und Laternen leuchten nachts (UV2), dazu `LanternLights` als echte Lichter.
- **Pflanzen** (`vegetation.gdshader`, `WorldMaterials.vegetation()`): Kronen aus Kugeln mit organischem Ausschnitt plus Blattkarten (`MeshBuilder.add_card`, UV in UV2), Gras als Halm-Karten, Rinde an Stämmen, Gestein an Felsen, leichtes Wiegen im Wind.
- **Wasser** (`water.gdshader`): zwei ziehende Wellen-Normal-Maps, dunkle Grundfarbe, Himmelsspiegelung nach Blickwinkel (Farbe aus `DayNight`), Schaum auf Flüssen.
- **Himmel und Licht:** Wolkendecke (`sky_cover`), AgX-Tonemapper, Glow ab Grafikstufe Mittel (`GraphicsSettings.glow()`), Sonne mit Schatten, warmes Umgebungslicht.
- **Dorfleben** (`VillageYards`): Zäune mit Törchen, Gemüsebeete, Steinplattenwege, Schornsteine mit Herdrauch (ein Partikelsystem je Siedlung), Bänke und Schattenbäume am Brunnen, in der Halle und im Garten – damit Dörfer bewohnt wirken statt leerer Wiesen zwischen Häusern.
- **Figuren** (`CharacterMesh`, `character.gdshader`): etwa 6,5 Kopfhöhen, Hals, Hände, Gesicht (Augen, Brauen, Nase, Mund), Faltenwurf; Gewebe-Textur auf Stoff, Haut und Haar glatt.

## Grundregeln

- **Geometrie:** Low-Poly, sichtbare Facetten erlaubt. Charaktere ca. 1.500–4.000 Dreiecke, Bäume 300–1.500, kleine Props unter 300.
- **Texturen:** möglichst keine; Farbe über eine gemeinsame Paletten-Textur (Farbatlas, z. B. 256 × 256), auf die alle Modelle per UV zeigen. So teilen sich viele Modelle ein Material, was Draw Calls spart.
- **Materialien:** ein Standardmaterial für die Welt, eines für Charaktere, eines für Effekte. Kein PBR-Realismus.
- **Licht:** eine Sonne mit Schatten, sonst Umgebungslicht und Nebel. Stimmung entsteht über Nebelfarbe und Himmelsfarbe, die sich mit Tageszeit und Region ändern.
- **Gu-Effekte:** leuchtend und gesättigt vor der gedämpften Welt. Jeder Pfad hat seine Farbe (`PATH_COLOR` in `docs/daten/gu.json`), damit man Fähigkeiten auf einen Blick erkennt. Partikel sparsam, lieber wenige große als viele kleine. Dazu hat jeder Pfad eine eigene Partikel-Handschrift (`GuVfx`): Feuer stiebt aufsteigende Glut, Eis zersplittert in fallende Scherben, Blitz zuckt in kurzen Strichen mit Zickzack-Ästen, Gift blubbert, Wasser und Blut spritzen in Tropfen, Holz lässt Blätter trudeln, Seele steigt als Irrlicht auf, Raum stürzt nach innen, Erde wirft Brocken, Wind wirbelt Striche, Stern funkelt, Klang wirft Ringe, Zeit kreist wie Sand, Glück regnet bunte Funken. Einsatz: beim Wirken (Selbst-Wirkungen kräftiger), bei Treffern (je Ziel gedrosselt), am Aufschlag, als Schweif an Geschossen, als Schwaden über Zonen und doppelt bei Killer Moves. Je Effekt ein `CPUParticles3D` mit geteilten Meshes und Materialien, höchstens 30 zugleich.
- **Lesbarkeit vor Schönheit:** Gegner-Telegraphen und Killer-Move-Kanalisierungen müssen sich immer klar vom Hintergrund abheben (Rot/Orange für Gefahr, reserviert für nichts anderes).

## Paletten pro Region

Die Grundfarbe stammt aus dem Prototyp (`REGIONS`), die übrigen Werte sind Vorschläge für Himmel, Nebel und Akzente.

| Region | Grundfarbe | Himmel Tag | Nebel Nacht | Akzent | Stimmung |
|---|---|---|---|---|---|
| Südliche Grenze | `#3f8a4a` | `#9fd4b0` | `#1c2b24` | `#b5e04a` Giftgrün | feucht, dicht, giftig |
| Nördliche Ebene | `#9ab86a` | `#bcd8ef` | `#262a33` | `#e0a040` Sonnengold | weit, windig, karg |
| Östliches Meer | `#3a8ac9` | `#a8dcf0` | `#132433` | `#f0f0e0` Gischt | offen, salzig, gefährlich tief |
| Westliche Wüste | `#d9b46a` | `#f4d8a0` | `#2e2230` | `#c0482c` Rotfels | heiß, still, uralt |
| Zentralkontinent | `#7ab86a` | `#c8e4f4` | `#232838` | `#e8c23a` Hofgold | reich, geordnet, mächtig |
| Gesegnetes Land | `#5ee1c1` | `#d8fff4` | `#1a3a3a` | `#ffffff` | traumartig, eigenes Licht |

## Charaktere

- Proportionen leicht stilisiert (etwas größere Hände und Köpfe), aber nicht chibi.
- Kleidung nach Fraktion farbcodiert; der Spieler trägt neutrale Erdtöne, damit Gu-Effekte hervorstechen.
- Rang sichtbar machen: dezentes Leuchten der Apertur-Stelle (Bauch) in der Rangfarbe aus `RANKS`.

## Gu

Gu sind im Spiel sichtbar: als kleine leuchtende Wesen, die beim Einsatz kurz um die Spielfigur kreisen, und als wilde Gu in der Welt. Ein Grundmodell pro Gu-Form (Wurm, Käfer, Falter, Schnecke, Kristallwesen) reicht, eingefärbt nach Pfadfarbe. So entstehen 126 Gu aus rund fünf Modellen.

## Assets: kostenlos starten, später gezielt kaufen

**Phase 1 – Platzhalter und frühe Entwicklung (kostenlos, CC0):**
- **Quaternius** (quaternius.com): Low-Poly-Charaktere mit Animationen, Natur, Tiere, Monster. Sehr gut für Wildmark geeignet.
- **Kenney** (kenney.nl): Props, UI-Elemente, Soundeffekte.
- **Mixamo** (mixamo.com, kostenlos mit Adobe-Konto): Animationen für humanoide Figuren.
- **Poly Haven** (polyhaven.com): Himmel-HDRIs, falls ein Himmelsbild gebraucht wird.

CC0 heißt: frei nutzbar, auch kommerziell, ohne Namensnennung. Trotzdem jede Quelle in `assets/LICENSES.md` eintragen.

**Phase 2 – nach M2, wenn das Spiel Spaß macht:**
Ein einheitliches kostenpflichtiges Low-Poly-Paket für Natur, Dorf und Charaktere, z. B. aus der POLYGON-Reihe von Synty. Vor dem Kauf prüfen, dass alle Pakete aus derselben Reihe stammen, damit der Stil zusammenpasst. Die Lizenz erlaubt die Nutzung in eigenen Spielen, aber nicht das Weitergeben der Rohdateien; das Repository deshalb auf privat stellen, sobald gekaufte Assets drin sind. Achtung: GitHub Pages aus einem privaten Repository braucht ein kostenpflichtiges GitHub-Konto. Alternative: Der Build-Workflow veröffentlicht nur den fertigen Web-Export auf Cloudflare Pages, Netlify oder itch.io (dort ist ein privater Testlink möglich). Der fertige Export enthält die Assets nur in kompilierter Form, das ist mit den üblichen Lizenzen vereinbar.

**Audio:** Kenney-Sounds (CC0), das jährliche kostenlose GDC-Audio-Paket von Sonniss (lizenzfrei). Bei freesound.org jede Datei einzeln auf ihre Lizenz prüfen.

**KI-generierte 3D-Modelle** (Meshy, Tripo) nur für einzelne Props und immer an den Stil anpassen (Farbatlas, Polygonzahl reduzieren); nie als Hauptquelle, sonst zerfällt der einheitliche Look.

## Technik für Godot

- Format: glTF (`.glb`), von Godot direkt unterstützt.
- Vegetation als `MultiMeshInstance3D`; Sichtweite für Gras kurz halten (ca. 30 m).
- LOD für Bäume und Felsen über Godots automatische Mesh-LOD.
- Web-Build: Texturen komprimiert exportieren, Gesamtgröße des Downloads unter 50 MB halten, damit das Laden am Handy erträglich bleibt.
