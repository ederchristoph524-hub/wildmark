class_name Wanderer
extends GuMaster
## Wandernder Gu-Meister auf den Straßen eines Gebiets (gebiete.json → wanderer, Wanderers). Dämonische Kultivierende
## überfallen dich („Deine Gu oder dein Leben!"), rechtschaffene Patrouillen ziehen vorbei, bis du gesucht wirst;
## Kopfgeldjäger verfolgen Gesuchte. Kein Duell mit Untergrenze: Du kannst sterben. Wer besiegt wird, ergibt sich,
## und du entscheidest: töten (Geldbeutel und seine Gu), ausrauben oder verschonen – mit Folgen für deinen Ruf.

const GROUP: StringName = &"wanderers"
const WALK: float = 0.45
const WAYPOINT_REACH: float = 1.5
const FLEE_TIME: float = 5.0
## Kopfgeldjäger folgen dir bis zu dieser Entfernung auch ohne Sichtkontakt.
const CHASE_RANGE: float = 140.0
const KILL_COLOR: Color = Color(0.75, 0.1, 0.12)

## Wegpunkte (Straße), die er hin und zurück abläuft; leer = bleibt an seinem Platz.
var route: Array[Vector3] = []
var bounty_hunter: bool = false
## Klanfehde (ClanFeud): Fraktion, deren Siedlung er angreift – greift deren Mitglieder an, auch im Dorf.
var raid_target: StringName = &""
var raid_cry: String = ""
var surrendered: bool = false
var fleeing: bool = false
var purse: int = 0
var _route_index: int = 0
var _route_step: int = 1
var _world: World = null


func _ready() -> void:
	super()
	add_to_group(GROUP)
	purse = roundi(Balance.values.wanderer_purse * rank * randf_range(0.7, 1.3))
	_world = get_tree().get_first_node_in_group(World.GROUP_WORLD) as World


func is_demonic() -> bool:
	return data.faction == Renown.DEMONIC


## Greift er den Spieler von sich aus an (Pfad, Ruf, Sekte)?
func is_hostile() -> bool:
	if surrendered or fleeing:
		return false
	if raid_target != &"":
		return SectLife.is_member(raid_target) and not Renown.disguised()
	if bounty_hunter:
		return not Renown.disguised()
	return not Renown.spared_by_demons() if is_demonic() else Renown.hunted_by_righteous()


# --- Wandern ---

func _idle() -> Vector3:
	var player: Player = get_tree().get_first_node_in_group(Player.GROUP_PLAYER) as Player
	if fleeing:
		return _flee(player)
	if surrendered:
		# Lässt du ihn einfach liegen, macht er sich davon.
		if player == null or player.global_position.distance_to(global_position) > Balance.values.wanderer_leash:
			_leave(false)
		return Vector3.ZERO
	if player != null and not player.is_dead() and not Childhood.is_child() and is_hostile():
		var distance: float = player.global_position.distance_to(global_position)
		if distance < Balance.values.wanderer_aggro and (raid_target != &"" or not _in_settlement(player.global_position)):
			ambush(player)
			return Vector3.ZERO
		if bounty_hunter and distance < CHASE_RANGE:
			return _toward(player.global_position, 1.0)
	return _walk_route()


func _walk_route() -> Vector3:
	if route.size() < 2:
		return super._idle()
	var offset: Vector3 = route[_route_index] - global_position
	offset.y = 0.0
	if offset.length() < WAYPOINT_REACH:
		if _route_index + _route_step < 0 or _route_index + _route_step >= route.size():
			_route_step = -_route_step
		_route_index += _route_step
		return Vector3.ZERO
	return offset.normalized() * WALK


func _toward(point: Vector3, speed: float) -> Vector3:
	var offset: Vector3 = point - global_position
	offset.y = 0.0
	return offset.normalized() * speed if offset.length() > 1.0 else Vector3.ZERO


func _flee(player: Player) -> Vector3:
	if _state_time > FLEE_TIME:
		queue_free()
		return Vector3.ZERO
	if player == null:
		return Vector3.ZERO
	return -_toward(player.global_position, 1.0)


func _in_settlement(point: Vector3) -> bool:
	return _world != null and _world.in_settlement(point.x, point.z)


# --- Kampf ---

## Überfall ohne Duellregeln: kurze Vorwarnung, dann Kampf auf Leben und Tod (für dich).
func ambush(foe: Combatant) -> void:
	if duel_state != DuelState.IDLE or surrendered or fleeing:
		return
	opponent = foe
	_enter(DuelState.COUNTDOWN)
	_state_time = maxf(0.0, Balance.values.duel_countdown - Balance.values.wanderer_warning)
	remove_from_group(Player.GROUP_INTERACTABLES)
	EventBus.message.emit(_threat(), Renown.INFAMY_COLOR)
	EventBus.duel_started.emit(self)


func _threat() -> String:
	if raid_target != &"":
		return raid_cry
	if bounty_hunter:
		return tr("%s: „Im Namen der rechtschaffenen Klans – dein Kopf gehört mir!“") % display_title()
	if is_demonic():
		return tr("%s versperrt dir den Weg: „Deine Gu oder dein Leben!“") % display_title()
	if Renown.hunted_by_righteous():
		return tr("%s erkennt dich: „Dämonischer Abschaum! Stirb!“") % display_title()
	return tr("%s zieht seine Gu: „Du wagst es, uns zu überfallen?“") % display_title()


func _opponent_left() -> bool:
	return opponent.is_dead() or opponent.global_position.distance_to(global_position) > Balance.values.wanderer_leash


func _abort() -> void:
	var foe: Combatant = opponent
	if foe != null and foe.is_dead():
		EventBus.message.emit(tr("%s durchwühlt deine Sachen und zieht weiter.") % display_title(), UiTheme.MUTED)
	else:
		EventBus.message.emit(tr("%s lässt von dir ab.") % display_title(), UiTheme.MUTED)
	_reset_after_duel()
	duel_finished.emit(false)


## Besiegt: Er ergibt sich und wartet auf dein Urteil (bleibt verwundet).
func _finish(player_won: bool) -> void:
	if not player_won:
		super(player_won)
		return
	surrendered = true
	if is_demonic() and not bounty_hunter:
		GameState.rogues_defeated += 1
	if opponent != null:
		opponent.status.clear_negative()
	opponent = null
	_enter(DuelState.IDLE)
	_set_fighting(false)
	status.clear_negative()
	reductions.clear()
	_model.set_sitting(true)
	EventBus.message.emit(tr("%s bricht zusammen: „Gnade! Nimm, was du willst …“") % display_title(), Color(0.6, 1.0, 0.6))
	duel_finished.emit(true)
	EventBus.duel_ended.emit(self, true)


# --- Ansprechen und Urteil ---

func interact_label() -> String:
	if surrendered:
		return tr("Urteil über %s") % display_title()
	if is_demonic() or bounty_hunter or raid_target != &"":
		return tr("Angreifen: %s") % display_title()
	return tr("Überfallen: %s (dämonische Tat)") % display_title()


func interact(player: Player) -> void:
	if surrendered:
		offer_choices()
		return
	if Childhood.is_child() or fleeing:
		return
	if not is_demonic() and not bounty_hunter and raid_target == &"":
		Renown.add_infamy(Balance.values.renown_attack, tr("Überfall auf %s") % display_title())
	ambush(player)


func offer_choices() -> void:
	var b: BalanceData = Balance.values
	var text: String
	if raid_target != &"":
		text = tr("Ein Angreifer – Richten bleibt ohne Folgen für deinen Ruf. Töten: sein Geldbeutel und seine Gu · Ausrauben: %d Urstein · Verschonen: Ansehen +%d") % [purse, b.renown_spare]
	elif is_demonic():
		text = tr("Töten: Ansehen +%d, sein Geldbeutel und seine Gu · Ausrauben: %d Urstein · Verschonen: Ansehen +%d") % [b.renown_kill_demonic, purse, b.renown_spare]
	else:
		text = tr("Töten: Berüchtigtheit +%d, sein Geldbeutel und seine Gu · Ausrauben: %d Urstein, Berüchtigtheit +%d · Verschonen: Ansehen +%d") % [b.renown_kill_righteous, purse, b.renown_rob, b.renown_spare]
	var options: Array = [[tr("Töten"), kill], [tr("Ausrauben"), rob], [tr("Verschonen"), spare]]
	EventBus.choice_requested.emit(display_title(), text, options)


## Geldbeutel und mindestens ein Gu; seine übrigen Gu entkommen wild und müssen verfeinert werden.
func kill() -> void:
	if not surrendered or fleeing:
		return
	var b: BalanceData = Balance.values
	_take_purse()
	var order: Array[GuInstance] = []
	order.assign(gu_list)
	order.shuffle()
	var drops: int = mini(order.size(), 2 if randf() < b.wanderer_second_gu else 1)
	for i: int in drops:
		var wild: WildGu = DuelRewards.drop_gu(self, order[i], "wanderer_%s_%d_%d" % [order[i].gu_id, Time.get_ticks_msec(), i])
		if wild != null:
			wild.global_position += Vector3(0.0, 0.0, 1.4 * i)
	if is_demonic() and raid_target == &"":
		Renown.add_fame(b.renown_kill_demonic, tr("%s erschlagen") % display_title())
	elif raid_target == &"":
		Renown.add_infamy(b.renown_kill_righteous, tr("Mord an %s") % display_title())
	Fx.sphere(get_tree(), global_position + Vector3.UP, 1.3, KILL_COLOR, 0.6)
	queue_free()


func rob() -> void:
	if not surrendered or fleeing:
		return
	_take_purse()
	if not is_demonic() and raid_target == &"":
		Renown.add_infamy(Balance.values.renown_rob, tr("%s ausgeraubt") % display_title())
	_leave(true)


func spare() -> void:
	if not surrendered or fleeing:
		return
	Renown.add_fame(Balance.values.renown_spare, tr("%s verschont") % display_title())
	_leave(true)


func _take_purse() -> void:
	if purse <= 0:
		return
	GameState.add_item(DuelRewards.STONE_ITEM, purse)
	EventBus.message.emit(tr("Geldbeutel: +%d %s") % [purse, tr(DataRegistry.item(DuelRewards.STONE_ITEM).display_name)], Color(0.6, 1.0, 0.6))
	purse = 0


## Steht auf und flieht (verschwindet nach FLEE_TIME).
func _leave(announce: bool) -> void:
	surrendered = false
	fleeing = true
	_enter(DuelState.IDLE)
	_model.set_sitting(false)
	remove_from_group(Player.GROUP_INTERACTABLES)
	if announce:
		EventBus.message.emit(tr("%s rafft sich auf und flieht.") % display_title(), UiTheme.MUTED)
