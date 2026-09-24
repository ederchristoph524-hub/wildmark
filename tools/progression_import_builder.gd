class_name ProgressionImportBuilder
extends RefCounted
## Baut aus fortschritt.json die ProgressionData (Ränge, Stufen, Talentgrade).

var _report: ImportReport


func _init(report: ImportReport) -> void:
	_report = report


func build(src: Dictionary) -> ProgressionData:
	var data := ProgressionData.new()
	for key: String in ["RANKS", "STAGES", "SUCCESS", "RANKCAP", "APT_FLAVOR", "APT_COLOR"]:
		if not src.has(key):
			_report.error("fortschritt.json: Abschnitt '%s' fehlt" % key)
			return data
	_fill_ranks(data, src["RANKS"])
	for stage: Variant in src["STAGES"]:
		data.stage_names.append(ImportUtil.text(stage))
	for grade: Variant in src["SUCCESS"]:
		data.breakthrough_chance[StringName(str(grade))] = ImportUtil.to_float(src["SUCCESS"][grade])
	for grade: Variant in src["RANKCAP"]:
		data.rank_cap[StringName(str(grade))] = ImportUtil.to_int(src["RANKCAP"][grade])
	for grade: Variant in src["APT_FLAVOR"]:
		data.talent_flavor[StringName(str(grade))] = ImportUtil.text(src["APT_FLAVOR"][grade])
	for grade: Variant in src["APT_COLOR"]:
		data.talent_colors[StringName(str(grade))] = ImportUtil.color(src["APT_COLOR"][grade], "Talentfarbe " + str(grade), _report)
	data.awaken_age = ImportUtil.to_int(src.get("AWAKEN_AGE"), data.awaken_age)
	_check(data)
	return data


## RANKS[0] ist leer (Ränge beginnen bei 1).
func _fill_ranks(data: ProgressionData, ranks: Variant) -> void:
	if not ranks is Array:
		_report.error("fortschritt.json: RANKS ist keine Liste")
		return
	for entry: Variant in ranks:
		if entry is Dictionary:
			var rank: Dictionary = entry
			data.rank_names.append(ImportUtil.text(rank.get("n")))
			data.rank_colors.append(ImportUtil.color(rank.get("c"), "Rangfarbe", _report))
			data.rank_essence_names.append(ImportUtil.text(rank.get("ess")))
		else:
			data.rank_names.append("")
			data.rank_colors.append(Color.WHITE)
			data.rank_essence_names.append("")


func _check(data: ProgressionData) -> void:
	for grade: StringName in data.breakthrough_chance:
		if not data.rank_cap.has(grade):
			_report.error("fortschritt.json: Talentgrad '%s' fehlt in RANKCAP" % grade)
	if data.stage_names.is_empty():
		_report.error("fortschritt.json: keine Stufen")
