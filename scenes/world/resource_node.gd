class_name ResourceNode
extends StaticBody3D
## Sammelstelle (Beeren, Stein, Urstein, Totholz, Kräuter, Erz, Mondtau, Glutasche, Frostsplitter, Knochen):
## mit Faustschlägen abbauen, wächst nach einer Weile nach. Mondtau gibt es nur nachts.

const HITS_NEEDED: int = 3
const REGROW_TIME: float = 240.0
## Sammelstellen werden erst aus der Nähe gezeichnet (spart Draw Calls am Handy).
const VIEW_DISTANCE: float = 55.0
const NIGHT_ONLY: Array[StringName] = [&"mondtau"]
const HARD_ITEMS: Array[StringName] = [&"stein", &"kristall", &"eisenerz", &"frostsplitter", &"jadeader", &"erdkern", &"blutkoralle", &"urkristall", &"seelenglas", &"sonnengold", &"klingenstahl", &"drachenschuppe"]
const HARD_PITCH: float = 1.5
const SOFT_PITCH: float = 0.7
## Aussehen je Gegenstand: Grundform und Farbe (glow = leuchtet).
const LOOKS: Dictionary[StringName, Dictionary] = {
	&"beeren": {"base": Color(0.2, 0.45, 0.2), "accent": Color(0.55, 0.25, 0.85), "shape": &"bush"},
	&"stein": {"base": Color(0.55, 0.55, 0.52), "accent": Color(0.48, 0.48, 0.45), "shape": &"rock"},
	&"kristall": {"base": Color(0.4, 0.4, 0.42), "accent": Color(0.35, 0.9, 1.0), "shape": &"crystal"},
	&"holz": {"base": Color(0.4, 0.28, 0.18), "accent": Color(0.35, 0.25, 0.15), "shape": &"log"},
	&"gruenkraut": {"base": Color(0.25, 0.6, 0.25), "accent": Color(0.55, 0.9, 0.35), "shape": &"herb"},
	&"eisenerz": {"base": Color(0.33, 0.3, 0.3), "accent": Color(0.62, 0.36, 0.22), "shape": &"ore"},
	&"mondtau": {"base": Color(0.3, 0.5, 0.35), "accent": Color(0.75, 0.9, 1.0), "shape": &"dew"},
	&"glutasche": {"base": Color(0.2, 0.19, 0.18), "accent": Color(1.0, 0.45, 0.15), "shape": &"ash"},
	&"frostsplitter": {"base": Color(0.75, 0.85, 0.9), "accent": Color(0.65, 0.95, 1.0), "shape": &"crystal"},
	&"knochenmehl": {"base": Color(0.88, 0.85, 0.76), "accent": Color(0.8, 0.77, 0.68), "shape": &"bones"},
	&"windfeder": {"base": Color(0.86, 0.88, 0.92), "accent": Color(0.4, 0.6, 0.9), "shape": &"herb"},
	&"sternsand": {"base": Color(0.75, 0.7, 0.55), "accent": Color(1.0, 0.95, 0.6), "shape": &"ash"},
	&"jadeader": {"base": Color(0.42, 0.42, 0.4), "accent": Color(0.25, 0.7, 0.4), "shape": &"ore"},
	&"erdkern": {"base": Color(0.38, 0.3, 0.24), "accent": Color(0.9, 0.5, 0.2), "shape": &"ore"},
	&"giftdrüse": {"base": Color(0.3, 0.4, 0.22), "accent": Color(0.7, 0.3, 0.9), "shape": &"herb"},
	&"blutkoralle": {"base": Color(0.5, 0.15, 0.15), "accent": Color(0.95, 0.25, 0.3), "shape": &"crystal"},
	&"urkristall": {"base": Color(0.35, 0.3, 0.45), "accent": Color(0.75, 0.5, 1.0), "shape": &"crystal"},
	&"tiefseeperle": {"base": Color(0.55, 0.6, 0.62), "accent": Color(0.95, 0.9, 0.95), "shape": &"dew"},
	&"donnerholz": {"base": Color(0.3, 0.26, 0.24), "accent": Color(0.5, 0.7, 1.0), "shape": &"log"},
	&"geisterseide": {"base": Color(0.8, 0.82, 0.86), "accent": Color(0.7, 0.9, 1.0), "shape": &"bush"},
	&"seelenglas": {"base": Color(0.45, 0.5, 0.6), "accent": Color(0.6, 0.85, 1.0), "shape": &"crystal"},
	&"zeitharz": {"base": Color(0.42, 0.3, 0.18), "accent": Color(0.95, 0.7, 0.25), "shape": &"dew"},
	&"sonnengold": {"base": Color(0.45, 0.4, 0.3), "accent": Color(1.0, 0.85, 0.3), "shape": &"ore"},
	&"klingenstahl": {"base": Color(0.4, 0.4, 0.42), "accent": Color(0.8, 0.82, 0.88), "shape": &"ore"},
	&"wuestenrose": {"base": Color(0.55, 0.45, 0.35), "accent": Color(0.9, 0.5, 0.6), "shape": &"herb"},
	&"drachenschuppe": {"base": Color(0.3, 0.35, 0.3), "accent": Color(0.8, 0.3, 0.2), "shape": &"crystal"},
}

var item: StringName = &"beeren"
var amount: int = 2
## Besitzer (Sekten-ID) einer Urstein-Ader; leer = frei.
var owner_sect: StringName = &""
var _hits: int = 0
var _regrow: float = 0.0
var _visual: Node3D = null
var _shape: CollisionShape3D = null


func _init(item_id: StringName, yield_amount: int) -> void:
	item = item_id
	amount = yield_amount
	collision_layer = 1
	collision_mask = 0


func _ready() -> void:
	add_to_group(Player.GROUP_HARVESTABLE)
	_visual = Node3D.new()
	add_child(_visual)
	_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	_shape.shape = sphere
	_shape.position.y = 0.45
	add_child(_shape)
	var look: Dictionary = LOOKS.get(item, LOOKS[&"stein"])
	ResourceNodeLooks.build(self, look["shape"], look["base"], look["accent"])
	if item in NIGHT_ONLY:
		_shape.disabled = true


## Fügt ein Mesh hinzu (glow = leuchtendes Material statt Vertex-Farben).
## material = eigenes Material (z. B. Pflanzen-Shader), sonst Requisiten-Material bzw. Leuchten bei glow.
func add_mesh(mesh: ArrayMesh, glow: Color = Color(0, 0, 0, 0), material: Material = null) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	if material == null and glow.a > 0.0:
		material = WorldMaterials.glowing(glow)
	elif material == null:
		material = WorldMaterials.props()
	node.material_override = material
	node.visibility_range_end = VIEW_DISTANCE
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(node)


func is_available() -> bool:
	if _regrow > 0.0:
		return false
	return item not in NIGHT_ONLY or Formulas.is_night(Balance.values, GameState.time_of_day)


func harvest_hit(_player: Node3D) -> void:
	if not is_available():
		return
	_hits += 1
	# Stein und Erz klingen hell, Holz und Pflanzen dumpf.
	Sound.play(&"hit", global_position, -10.0, HARD_PITCH if item in HARD_ITEMS else SOFT_PITCH)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.12, 0.9, 1.12), 0.06)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.1)
	if _hits < maxi(1, HITS_NEEDED + roundi(PassiveGu.add("harvest_hits"))):
		return
	_hits = 0
	Pickup.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), {item: roundi(amount * PassiveGu.mult("harvest_mult"))})
	if owner_sect != &"":
		_owned_harvest()
	_regrow = REGROW_TIME
	_refresh()


## Ader eines Klans: Mitglieder arbeiten eine Schicht (Verdienst), Fremde stehlen (Berüchtigtheit), verkleidet unerkannt.
func _owned_harvest() -> void:
	var sect: SectData = DataRegistry.sect(owner_sect)
	var sect_name: String = Loc.t(sect.display_name) if sect != null else String(owner_sect)
	if SectLife.is_member(owner_sect):
		SectLife.add_merit(Balance.values.vein_member_merit)
		EventBus.message.emit(Loc.t("Schicht in der Ader – Verdienst +%d") % Balance.values.vein_member_merit, Renown.FAME_COLOR)
	elif Renown.disguised():
		EventBus.message.emit(Loc.t("Unter fremdem Gesicht bleibt der Diebstahl unbemerkt."), Renown.FAME_COLOR)
	else:
		Renown.add_infamy(Balance.values.renown_vein_theft, Loc.t("Urstein aus der Ader von %s gestohlen") % sect_name)


func _process(delta: float) -> void:
	if _regrow > 0.0:
		_regrow -= delta
	_refresh()


func _refresh() -> void:
	var available: bool = is_available()
	if available != is_in_group(Player.GROUP_HARVESTABLE):
		if available:
			add_to_group(Player.GROUP_HARVESTABLE)
		else:
			remove_from_group(Player.GROUP_HARVESTABLE)
		if item not in NIGHT_ONLY and item != &"beeren":
			_shape.set_deferred(&"disabled", not available)
	_visual.visible = available or item == &"beeren"
	if item == &"beeren" and _visual.get_child_count() > 1:
		_visual.get_child(1).visible = available
