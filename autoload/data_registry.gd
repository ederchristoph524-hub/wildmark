extends Node
## Lädt beim Start alle Resources aus res://data/ und liefert sie per ID, z. B. DataRegistry.gu(&"mondlicht").

## Kategorie → Ordner mit den vom Datenimport erzeugten .tres-Dateien.
const DATA_DIRS: Dictionary[StringName, String] = {
	&"families": "res://data/gu/families/",
	&"body": "res://data/gu/body/",
	&"support": "res://data/gu/support/",
	&"traits": "res://data/gu/traits/",
	&"statuses": "res://data/combat/statuses/",
	&"reactions": "res://data/combat/reactions/",
	&"killer_moves": "res://data/killer_moves/",
	&"enemies": "res://data/enemies/",
	&"items": "res://data/items/",
	&"regions": "res://data/regions/",
	&"sects": "res://data/sects/",
	&"quests": "res://data/quests/",
}
const GU_SYSTEM_PATH: String = "res://data/gu/gu_system.tres"
const PROGRESSION_PATH: String = "res://data/progression.tres"
const RESOURCE_EXTENSIONS: Array[String] = [".tres", ".res"]

## Kategorie → {ID → Resource}. Regionen sind nach int-ID geschlüsselt, alles andere nach StringName.
var _tables: Dictionary[StringName, Dictionary] = {}
## Mitglieder aller Familien nach ID.
var _gu: Dictionary[StringName, GuData] = {}
var _gu_system: GuSystemData = null
var _progression: ProgressionData = null


func _ready() -> void:
	load_all()


## Lädt alle Daten neu (auch für Tests). Fehler landen im Log, das Spiel läuft weiter.
func load_all() -> void:
	_tables.clear()
	_gu.clear()
	for category: StringName in DATA_DIRS:
		_tables[category] = _load_dir(DATA_DIRS[category])
	for family_data: GuFamilyData in _tables[&"families"].values():
		for member: GuData in family_data.members:
			_gu[member.id] = member
	_gu_system = load(GU_SYSTEM_PATH) as GuSystemData
	if _gu_system == null:
		push_error("DataRegistry: %s fehlt – Datenimport ausführen" % GU_SYSTEM_PATH)
	_progression = load(PROGRESSION_PATH) as ProgressionData
	if _progression == null:
		push_error("DataRegistry: %s fehlt – Datenimport ausführen" % PROGRESSION_PATH)
	print("DataRegistry: %d Einträge geladen (%d Gu)" % [count_all(), _gu.size()])


## Nutzt ResourceLoader.list_directory, damit es auch im Export (umbenannte .remap-Dateien) funktioniert.
func _load_dir(dir: String) -> Dictionary:
	var table: Dictionary = {}
	if not DirAccess.dir_exists_absolute(dir):
		push_error("DataRegistry: Ordner %s fehlt – Datenimport ausführen" % dir)
		return table
	for file_name: String in ResourceLoader.list_directory(dir):
		if not _is_resource_file(file_name):
			continue
		var resource: Resource = load(dir + file_name)
		if resource == null:
			push_error("DataRegistry: %s%s lässt sich nicht laden" % [dir, file_name])
			continue
		table[resource.get("id")] = resource
	return table


func _is_resource_file(file_name: String) -> bool:
	for extension: String in RESOURCE_EXTENSIONS:
		if file_name.ends_with(extension):
			return true
	return false


func _lookup(category: StringName, id: Variant) -> Resource:
	var table: Dictionary = _tables.get(category, {})
	var resource: Resource = table.get(id)
	if resource == null:
		push_error("DataRegistry: unbekannte ID '%s' in %s" % [id, category])
	return resource


# --- Einzelabfragen per ID -------------------------------------------------

## Ein Gu (Familienmitglied) per ID, z. B. &"mondlicht" oder &"feuerlotus".
func gu(id: StringName) -> GuData:
	var result: GuData = _gu.get(id)
	if result == null:
		push_error("DataRegistry: unbekannte Gu-ID '%s'" % id)
	return result


func family(id: StringName) -> GuFamilyData:
	return _lookup(&"families", id) as GuFamilyData


## Die Familie, zu der ein Gu gehört.
func family_of(gu_id: StringName) -> GuFamilyData:
	var member: GuData = gu(gu_id)
	return null if member == null else family(member.family)


func body_gu(id: StringName) -> BodyGuData:
	return _lookup(&"body", id) as BodyGuData


func support_gu(id: StringName) -> SupportGuData:
	return _lookup(&"support", id) as SupportGuData


## Merkmal per ID (`trait` ist in GDScript reserviert).
func trait_data(id: StringName) -> TraitData:
	return _lookup(&"traits", id) as TraitData


func status(id: StringName) -> StatusData:
	return _lookup(&"statuses", id) as StatusData


func reaction(id: StringName) -> ReactionData:
	return _lookup(&"reactions", id) as ReactionData


func killer_move(id: StringName) -> KillerMoveData:
	return _lookup(&"killer_moves", id) as KillerMoveData


func enemy(id: StringName) -> EnemyData:
	return _lookup(&"enemies", id) as EnemyData


func item(id: StringName) -> ItemData:
	return _lookup(&"items", id) as ItemData


func region(id: int) -> RegionData:
	return _lookup(&"regions", id) as RegionData


func sect(id: StringName) -> SectData:
	return _lookup(&"sects", id) as SectData


func quest(id: StringName) -> QuestData:
	return _lookup(&"quests", id) as QuestData


func gu_system() -> GuSystemData:
	return _gu_system


func progression() -> ProgressionData:
	return _progression


# --- Listen und Existenzprüfung ------------------------------------------

## Alle Einträge einer Kategorie aus DATA_DIRS (z. B. &"enemies"), sortiert nach ID.
func all(category: StringName) -> Array[Resource]:
	var result: Array[Resource] = []
	var table: Dictionary = _tables.get(category, {})
	var keys: Array = table.keys()
	keys.sort()
	for key: Variant in keys:
		result.append(table[key])
	return result


## Alle Gu (Familienmitglieder), sortiert nach Familie und Rang.
func all_gu() -> Array[GuData]:
	var result: Array[GuData] = []
	for family_data: Resource in all(&"families"):
		result.append_array((family_data as GuFamilyData).members)
	return result


func has_gu(id: StringName) -> bool:
	return _gu.has(id)


func has(category: StringName, id: Variant) -> bool:
	return (_tables.get(category, {}) as Dictionary).has(id)


func count(category: StringName) -> int:
	return (_tables.get(category, {}) as Dictionary).size()


func count_all() -> int:
	var total: int = 0
	for category: StringName in _tables:
		total += _tables[category].size()
	return total
