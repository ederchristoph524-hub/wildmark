class_name ImportUtil
extends RefCounted
## Hilfsfunktionen, um JSON-Werte sicher in typisierte Resource-Felder umzuwandeln.

const FN_PREFIX := "[fn]"


## Liefert die ID als StringName; null wird zu &"".
static func sn(value: Variant) -> StringName:
	if value == null:
		return &""
	return StringName(str(value))


## Liefert Text; null wird zu "". Referenzlogik ([fn]) wird nie übernommen.
static func text(value: Variant) -> String:
	if value == null:
		return ""
	var result: String = str(value)
	if result.begins_with(FN_PREFIX):
		return ""
	return result


static func to_int(value: Variant, fallback: int = 0) -> int:
	if value is float or value is int:
		return int(value)
	return fallback


static func to_float(value: Variant, fallback: float = 0.0) -> float:
	if value is float or value is int:
		return float(value)
	return fallback


## JSON kennt Flags als 1/0 oder true/false.
static func flag(data: Dictionary, key: String) -> bool:
	var value: Variant = data.get(key, false)
	if value is bool:
		return value
	return to_float(value) != 0.0


static func names(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for entry: Variant in value:
			result.append(sn(entry))
	return result


## Prüft Pflichtfelder und meldet fehlende mit Kontext.
static func require(data: Dictionary, keys: Array[String], context: String, report: ImportReport) -> bool:
	var ok: bool = true
	for key: String in keys:
		if not data.has(key) or data[key] == null:
			report.error("%s: Pflichtfeld '%s' fehlt" % [context, key])
			ok = false
	return ok


static func color(value: Variant, context: String, report: ImportReport) -> Color:
	var hex: String = text(value)
	if hex.is_empty():
		return Color.WHITE
	if not Color.html_is_valid(hex):
		report.error("%s: ungültige Farbe '%s'" % [context, hex])
		return Color.WHITE
	return Color.html(hex)


## JSON-Objekt als Dictionary (Kopie); alles andere → leer.
static func plain_dict(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


## JSON-Liste als Array (Kopie); alles andere → leer.
static func plain_list(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []
