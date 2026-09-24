class_name GuGifts
extends RefCounted
## Ranggaben als Schalter (gu_system.json → mitglieder[].gaben): Ein Gu erbt die Ranggaben aller Mitglieder
## seiner Familie bis zu seinem Rang. Listen und Objekte (Wirkungsschritte) ersetzt der höhere Rang.

## Zahlen, die ein höherer Rang ersetzt statt addiert (sonst summieren sich Zahlen über die Ränge).
const OVERRIDE_KEYS: Array[String] = ["fan_angle", "as_circle", "teleport", "chain_radius", "width_mult", "orbit_speed", "cd_mult"]

static var _cache: Dictionary = {}


## Alle Schalter eines Gu (z. B. {"pierce": 1, "pierce_armor": true}); Zahlen addieren sich.
static func flags(gu: GuData) -> Dictionary:
	if gu == null:
		return {}
	if _cache.has(gu.id):
		return _cache[gu.id]
	var result: Dictionary = {}
	var family: GuFamilyData = DataRegistry.family(gu.family)
	for member: GuData in family.members:
		if member.rank > gu.rank:
			continue
		var gift: Dictionary = member.gifts
		for key: Variant in gift:
			var value: Variant = gift[key]
			if value is bool or value is Dictionary or value is Array or not result.has(key) or String(key) in OVERRIDE_KEYS:
				result[key] = value
			else:
				result[key] = float(result[key]) + float(value)
	_cache[gu.id] = result
	return result


static func number(gu: GuData, key: String) -> float:
	return float(flags(gu).get(key, 0.0))


static func has(gu: GuData, key: String) -> bool:
	return bool(flags(gu).get(key, false))
