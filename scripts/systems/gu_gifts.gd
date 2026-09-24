class_name GuGifts
extends RefCounted
## Ranggaben als Schalter: Ein Gu erbt die Ranggaben aller Mitglieder seiner Familie bis zu seinem Rang.

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
		var gift: Dictionary = Balance.values.rank_gifts.get(member.id, {})
		for key: Variant in gift:
			var value: Variant = gift[key]
			if value is bool or not result.has(key):
				result[key] = value
			else:
				result[key] = float(result[key]) + float(value)
	_cache[gu.id] = result
	return result


static func number(gu: GuData, key: String) -> float:
	return float(flags(gu).get(key, 0.0))


static func has(gu: GuData, key: String) -> bool:
	return bool(flags(gu).get(key, false))
