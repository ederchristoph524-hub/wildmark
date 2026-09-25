class_name GraphicsSettings
extends RefCounted
## Grafikstufe (Niedrig, Mittel, Hoch) für schwächere Handys: Gras- und Pflanzendichte, Sichtweite der Pflanzen,
## Schatten und 3D-Auflösung. Liegt in user://settings.cfg (unabhängig vom Spielstand). Dichte und Sichtweite
## gelten ab dem nächsten Weltaufbau, Schatten und Auflösung sofort.

enum Quality { LOW, MEDIUM, HIGH }

const PATH: String = "user://settings.cfg"
const NAMES: Array[String] = ["Niedrig", "Mittel", "Hoch"]
const GRASS: Array[float] = [0.35, 0.7, 1.0]
const VIEW: Array[float] = [0.6, 0.85, 1.0]
const SCALE_3D: Array[float] = [0.7, 0.85, 1.0]
const SHADOWS: Array[bool] = [false, true, true]

static var _quality: int = -1


static func quality() -> int:
	if _quality < 0:
		var config := ConfigFile.new()
		# Handy-Browser starten auf Mittel, Rechner auf Hoch.
		var fallback: int = Quality.MEDIUM if OS.has_feature("web") or OS.has_feature("mobile") else Quality.HIGH
		_quality = int(config.get_value("grafik", "stufe", fallback)) if config.load(PATH) == OK else fallback
	return _quality


static func set_quality(value: int, viewport: Viewport) -> void:
	_quality = clampi(value, Quality.LOW, Quality.HIGH)
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("grafik", "stufe", _quality)
	config.save(PATH)
	apply(viewport)


## Sofort wirksame Teile (Auflösung); Schatten fragt DayNight selbst ab.
static func apply(viewport: Viewport) -> void:
	if viewport != null:
		viewport.scaling_3d_scale = SCALE_3D[quality()]


static func grass_mult() -> float:
	return GRASS[quality()]


static func view_mult() -> float:
	return VIEW[quality()]


static func shadows() -> bool:
	return SHADOWS[quality()]


static func label() -> String:
	return Loc.t("Grafik: %s") % Loc.t(NAMES[quality()])
