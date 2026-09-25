class_name LandSpirit
extends Node3D
## Landgeist einer Unsterblichen-Apertur (docs/UNSTERBLICH.md, 5): in der eigenen Apertur verwahrt er die Erträge,
## verdichtet Essenzsteine zu Perlen und kennt die nächste Kalamität; in Gesegneten Ländern der Geschichte
## (Hu-Unsterblichen-Land, Lang Ya …) spricht er für das Land und erlaubt die Annexion.

const COLOR: Color = Color(0.37, 0.88, 0.76)
const BOB_SPEED: float = 1.6
const BOB_HEIGHT: float = 0.25
const FLOAT_HEIGHT: float = 1.6

var own: bool = true
var area: AreaData = null
var spirit_name: String = ""
var lines: Array = []
var _orb: MeshInstance3D = null
var _time: float = 0.0


static func create(owner_area: AreaData, is_own: bool) -> LandSpirit:
	var spirit := LandSpirit.new()
	spirit.area = owner_area
	spirit.own = is_own
	var info: Dictionary = owner_area.immortal.get("spirit", {})
	if is_own:
		info = DataRegistry.immortal().land_spirit
		spirit.spirit_name = String(info.get("n", "Dein Landgeist"))
	else:
		spirit.spirit_name = String(info.get("name", "Landgeist"))
	spirit.lines = info.get("lines", [])
	return spirit


func _ready() -> void:
	add_to_group(Player.GROUP_INTERACTABLES)
	_orb = MeshInstance3D.new()
	_orb.mesh = MeshBuilder.sphere(0.45, 12, 8)
	_orb.material_override = Fx.material(COLOR)
	_orb.position.y = FLOAT_HEIGHT
	add_child(_orb)
	var light := OmniLight3D.new()
	light.light_color = COLOR
	light.omni_range = 7.0
	light.light_energy = 1.4
	light.position.y = FLOAT_HEIGHT
	add_child(light)
	var label := Label3D.new()
	label.text = Loc.t(spirit_name)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.pixel_size = 0.01
	label.outline_size = 10
	label.position.y = FLOAT_HEIGHT + 1.0
	add_child(label)
	GuVfx.zone(self, GuVfx.style_of(&"seele", []), 2.5)


func _process(delta: float) -> void:
	_time += delta
	_orb.position.y = FLOAT_HEIGHT + sin(_time * BOB_SPEED) * BOB_HEIGHT


func interact_label() -> String:
	return Loc.t("Sprechen mit %s") % Loc.t(spirit_name)


func interact(_player: Player) -> void:
	var line: String = Loc.t(String(lines[randi() % lines.size()])) if not lines.is_empty() else ""
	if own:
		EventBus.choice_requested.emit(Loc.t(spirit_name), line + "\n\n" + _status(), _own_options())
	else:
		EventBus.choice_requested.emit(Loc.t(spirit_name), line, _foreign_options())


func _status() -> String:
	var state: ImmortalState = GameState.immortal
	var parts: PackedStringArray = [
		Loc.t("%s · %.0f m Kantenlänge · Zeitfluss 1 : %d") % [ImmortalAperture.title(), ImmortalAperture.size(), roundi(float(Immortal.land_grade().get("time_flow", 1.0)))],
		Loc.t("Perlen: %.1f %s · Essenzsteine im Gepäck: %d") % [state.beads_for(GameState.rank), Loc.t(Immortal.essence_name(GameState.rank)), GameState.item_count(ImmortalAperture.STONE_ITEM)],
	]
	var stored: int = int(state.land_store.get(ImmortalAperture.STONE_ITEM, 0))
	if stored > 0:
		parts.append(Loc.t("Ich verwahre %d Essenzsteine und weitere Erträge für dich.") % stored)
	if state.pending_calamity != &"":
		parts.append(Loc.t("%s naht – heute Nacht!") % Loc.t(String(DataRegistry.immortal().calamity(state.pending_calamity).get("name", ""))))
	elif state.next_calamity_day >= 0:
		parts.append(Loc.t("Die nächste Kalamität spüre ich an Tag %d.") % state.next_calamity_day)
	return "\n".join(parts)


func _own_options() -> Array:
	var per_bead: int = ImmortalAperture.stones_per_bead()
	return [
		[Loc.t("Erträge einsammeln"), func() -> void: EventBus.message.emit(ImmortalAperture.collect(), COLOR)],
		[Loc.t("Essenzsteine zu Perlen verdichten (%d Steine je Perle)") % per_bead, _condense],
		[Loc.t("Apertur verlassen"), ImmortalAperture.leave],
		[Loc.t("Nichts"), func() -> void: pass],
	]


func _condense() -> void:
	var made: int = ImmortalAperture.condense()
	if made > 0:
		EventBus.message.emit(Loc.t("Der Landgeist verdichtet %d Perlen %s.") % [made, Loc.t(Immortal.essence_name(GameState.rank))], Immortal.essence_color(GameState.rank))
	else:
		EventBus.message.emit(Loc.t("Nicht genug Essenzsteine."), UiTheme.MUTED)


func _foreign_options() -> Array:
	var options: Array = []
	var annex: Dictionary = area.immortal.get("annex", {})
	if not annex.is_empty() and area.id not in GameState.immortal.annexed:
		options.append([Loc.t("Dieses Land in deine Apertur eingliedern"), _try_annex])
	options.append([Loc.t("Gehen"), func() -> void: pass])
	return options


## Annexion: nur Unsterbliche, und erst wenn das Erbe dieses Landes geöffnet ist.
func _try_annex() -> void:
	if not Immortal.is_immortal():
		EventBus.message.emit(Loc.t("Nur ein Unsterblicher mit eigener Apertur kann ein Land in sich aufnehmen."), UiTheme.DANGER)
		return
	for place: Dictionary in area.places:
		if place.get("type") == &"erbe" and StringName(place.get("id", "")) not in GameState.inheritances:
			EventBus.message.emit(Loc.t("Erst wenn du das Erbe dieses Landes (%s) geöffnet hast, folgt es dir.") % Loc.t(String(place.get("name", ""))), UiTheme.MUTED)
			return
	ImmortalAperture.annex(area)
