class_name BiomeData
extends Resource
## Landschaftstyp eines Gebiets (aus gebiete.json → BIOME): Bodenfarben, Bewuchs, Himmel, Nebel und Wasser.

const NO_SEA: float = -1000.0

@export var id: StringName
@export var display_name: String = ""
## Bodenfarben: gras_dunkel, gras_hell, moos, erde, fels, gipfel, weg, platz, strand (Meer).
@export var colors: Dictionary[StringName, Color] = {}
## Anteile der Baumarten (laubbaum, palme, nadelbaum, bambus, kaktus, totholz …).
@export var vegetation: Dictionary[StringName, float] = {}
@export var trees_per_1000: float = 5.0
@export var bushes_per_1000: float = 4.0
@export var grass_per_1000: float = 30.0
@export var rocks_per_1000: float = 1.5
@export var sky: Color = Color(0.62, 0.83, 0.69)
@export var sky_top: Color = Color(0.36, 0.6, 0.72)
@export var fog: Color = Color(0.62, 0.78, 0.66)
@export var fog_density: float = 0.0065
@export var water: Color = Color(0.17, 0.43, 0.42)
## Meeresspiegel (Östliches Meer): darunter liegt alles unter Wasser; NO_SEA = kein Meer.
@export var sea_level: float = NO_SEA
## Tönung der Pflanzen (Steppe gelblich, Wüste staubig); jede Instanz variiert leicht.
@export var plant_tint: Color = Color.WHITE
## Wetter (Weather): regen, schnee, sand oder leer; Chance je Tag.
@export var weather: StringName = &""
@export var weather_chance: float = 0.0


func color(key: StringName, fallback: Color = Color.MAGENTA) -> Color:
	return colors.get(key, fallback)
