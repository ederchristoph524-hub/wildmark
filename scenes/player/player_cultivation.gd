class_name PlayerCultivation
extends Node
## Kultivieren des Spielers: ein Knopf für Meditation und Durchbruch, Schneidersitz, Aura in Rangfarbe
## und Lichtstöße bei Stufenaufstieg und Durchbruch.

var player: Player = null
var aura: CultivationAura = null


func _init(owner_player: Player) -> void:
	player = owner_player
	name = "Cultivation"


func _ready() -> void:
	aura = CultivationAura.new()
	player.add_child(aura)
	aura.set_color(_rank_color(GameState.rank))
	player.aperture.meditation_changed.connect(_on_meditation)
	player.aperture.ritual_changed.connect(_on_ritual)
	EventBus.stage_reached.connect(func(_rank: int, _stage: int) -> void: aura.burst(false))
	EventBus.breakthrough_attempted.connect(_on_breakthrough)


## Kultivieren-Knopf: Durchbruch, wenn möglich; sonst Meditation an/aus.
func cultivate() -> void:
	var aperture: ApertureComponent = player.aperture
	if aperture.ritual_left > 0.0:
		return
	if aperture.can_break_through() and player.is_on_floor():
		aperture.set_meditating(true)
		aperture.start_breakthrough()
		return
	if aperture.meditating:
		aperture.set_meditating(false)
	elif player.is_on_floor() and PlayerActions.can_meditate(player):
		aperture.set_meditating(true)
		EventBus.message.emit(tr("Du kultivierst – Uressenz fließt gegen die Aperturwand …"), Color(0.8, 0.9, 1.0))


func _process(_delta: float) -> void:
	player.model.set_glow(Color(aura.color, 0.35 * minf(aura.strength(), 1.5)))


func _on_meditation(active: bool) -> void:
	player.model.set_sitting(active)
	aura.target_strength = 1.0 if active else 0.0


func _on_ritual(active: bool) -> void:
	aura.set_color(_rank_color(GameState.rank + 1) if active else _rank_color(GameState.rank))
	aura.target_strength = 2.0 if active else (1.0 if player.aperture.meditating else 0.0)


func _on_breakthrough(success: bool, rank: int) -> void:
	aura.set_color(_rank_color(rank))
	aura.burst(success)
	if not success:
		Fx.sphere(get_tree(), player.aim_point(), 2.0, Color(1.0, 0.3, 0.3, 0.5), 0.5)
	player.aperture.set_meditating(false)


static func _rank_color(rank: int) -> Color:
	return DataRegistry.progression().rank_color(clampi(rank, 1, 9))
