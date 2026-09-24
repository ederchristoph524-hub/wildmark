class_name Combatant
extends CharacterBody3D
## Basis für alles, was kämpft (Spieler, Bestien, Gefährten): Team, Lebenspunkte, Zustände, Treffer, Rückstoß.

signal died_signal(combatant: Combatant)

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1
## Welt-Objekte (Hindernisse): werden getroffen, greifen aber nie an und werden von Bestien ignoriert.
const TEAM_WORLD: int = 2
const LAYER_WORLD: int = 1
const LAYER_PLAYER_SIDE: int = 2
const LAYER_ENEMY_SIDE: int = 4
const DAMAGE_COLOR: Color = Color(1.0, 0.95, 0.85)
const PLAYER_DAMAGE_COLOR: Color = Color(1.0, 0.35, 0.35)

var team: int = TEAM_ENEMY
var display_name: String = ""
var body_radius: float = 0.4
var body_height: float = 1.8
var health: HealthComponent = null
var status: StatusComponent = null
## Schadensreduktionen (z. B. Schild): Quelle → Anteil 0–1, werden multiplikativ verrechnet.
var reductions: Dictionary[StringName, float] = {}
var invulnerable_time: float = 0.0
## Fester Zuschlag auf direkten Schaden (Körper-Gu wie Rosa-Eber).
var flat_damage: float = 0.0
## Faktor auf den Umkreis, in dem Bestien diese Figur bemerken (Schleichstein-Gu).
var aggro_mult: float = 1.0
## Ranggabe Eisenhaut: Geschosse prallen zurück, solange > 0.
var reflect_time: float = 0.0
## Bronzehaut: kein Rückstoß, keine Betäubung, solange > 0.
var unstoppable_time: float = 0.0
## Tarnung: Bestien bemerken die Figur nicht; der erste Treffer daraus ist verstärkt.
var stealth_time: float = 0.0
## Stärkungen (Quelle → {damage, speed, time}); multiplikativ.
var buffs: Dictionary[StringName, Dictionary] = {}

var _knockback: Vector3 = Vector3.ZERO
var _dead: bool = false
var _reduction_time: Dictionary[StringName, float] = {}
var _regen_rate: float = 0.0
var _regen_time: float = 0.0


func _init_combatant(new_team: int, max_hp: float, current_hp: float = -1.0) -> void:
	team = new_team
	health = HealthComponent.new()
	health.name = "Health"
	health.setup(max_hp, current_hp)
	add_child(health)
	status = StatusComponent.new(self)
	add_child(status)
	health.died.connect(_on_died)
	add_to_group(Combat.GROUP_COMBATANTS)
	set_team(new_team)


## Wechselt das Team (z. B. gezähmte Bestie) samt Kollisionsebene.
func set_team(new_team: int) -> void:
	team = new_team
	if team == TEAM_WORLD:
		collision_layer = LAYER_WORLD
		collision_mask = 0
		return
	# Verbündete gehen durcheinander hindurch (Gefährten bleiben sonst hinter dem Spieler hängen);
	# Bestien schieben sich weiter gegenseitig weg, damit ein Rudel nicht in einem Punkt steht.
	if team == TEAM_PLAYER:
		collision_layer = LAYER_PLAYER_SIDE
		collision_mask = LAYER_WORLD | LAYER_ENEMY_SIDE
	else:
		collision_layer = LAYER_ENEMY_SIDE
		collision_mask = LAYER_WORLD | LAYER_PLAYER_SIDE | LAYER_ENEMY_SIDE


func is_dead() -> bool:
	return _dead


func aim_point() -> Vector3:
	return global_position + Vector3.UP * body_height * 0.6


## Nacht- und Schattenwesen werden von Licht geblendet (überschreiben).
func fears_light() -> bool:
	return false


func damage_multiplier_taken() -> float:
	var mult: float = 1.0
	for key: StringName in reductions:
		mult *= 1.0 - reductions[key]
	return maxf(mult, 1.0 - Balance.values.max_damage_reduction) * status.damage_taken_mult()


## Faktor auf ausgeteilten Schaden (Stärkungen).
func damage_dealt_mult() -> float:
	var mult: float = 1.0
	for key: StringName in buffs:
		mult *= float(buffs[key]["damage"])
	return mult


func speed_buff_mult() -> float:
	var mult: float = 1.0
	for key: StringName in buffs:
		mult *= float(buffs[key]["speed"])
	return mult


func add_buff(key: StringName, damage: float, speed: float, duration: float) -> void:
	buffs[key] = {"damage": damage, "speed": speed, "time": duration}


## Wie stark Bestien diese Figur bemerken (0 = gar nicht, getarnt).
func aggro_factor() -> float:
	return 0.0 if stealth_time > 0.0 else aggro_mult


## Tarnung: Bestien, die diese Figur jagen, verlieren sie aus den Augen.
func start_stealth(duration: float) -> void:
	stealth_time = maxf(stealth_time, duration)
	for node: Node in get_tree().get_nodes_in_group(Combat.GROUP_COMBATANTS):
		var other: Combatant = node as Combatant
		if other != null and other.team != team and other.get(&"target") == self:
			other.set(&"target", null)
			other.status.blind_time = maxf(other.status.blind_time, Balance.values.stealth_lose_time)
	Fx.sphere(get_tree(), aim_point(), 1.2, Color(0.5, 0.5, 0.6, 0.4), 0.5)


func receive_hit(hit: HitInfo) -> void:
	if _dead:
		return
	if not hit.is_dot and invulnerable_time > 0.0:
		return
	var mult: float = status.process_hit(hit) * damage_multiplier_taken() * _armor_multiplier(hit)
	var attacker: Combatant = hit.source as Combatant if is_instance_valid(hit.source) else null
	if attacker != null and not hit.is_dot:
		mult *= attacker.damage_dealt_mult()
		if attacker.stealth_time > 0.0:
			mult *= Balance.values.stealth_strike_mult
			attacker.stealth_time = 0.0
	if hit.execute_bonus > 0.0 and health.ratio() < EffectSteps.EXECUTE_THRESHOLD:
		mult *= 1.0 + hit.execute_bonus
	var dealt: float = health.apply_damage(hit.damage * mult)
	if hit.knockback != Vector3.ZERO and not status.is_frozen() and unstoppable_time <= 0.0:
		_knockback += hit.knockback
	if hit.stun > 0.0:
		status.stun(hit.stun)
	if hit.lifesteal > 0.0 and attacker != null and not attacker.is_dead() and dealt > 0.0:
		attacker.heal(dealt * hit.lifesteal)
	if dealt >= 0.5:
		var color: Color = PLAYER_DAMAGE_COLOR if team == TEAM_PLAYER else (PhysiqueEffects.CRIT_COLOR if hit.is_crit else DAMAGE_COLOR)
		EventBus.floating_text.emit(str(roundi(dealt)) + ("!" if hit.is_crit else ""), aim_point(), color)
	_after_hit(hit, dealt)


## Heilt unter Berücksichtigung von Zuständen (Gift halbiert Heilung).
func heal(amount: float) -> float:
	return health.heal(amount * status.heal_multiplier())


## Hook für Unterklassen (z. B. Kanalisierung abbrechen, Ziel merken).
func _after_hit(_hit: HitInfo, _dealt: float) -> void:
	pass


## Hook für Rüstung von vorn (Gegner mit beh=armor).
func _armor_multiplier(_hit: HitInfo) -> float:
	return 1.0


## Zeitlich begrenzte Schadensreduktion (z. B. Steinhaut).
func add_timed_reduction(key: StringName, amount: float, duration: float) -> void:
	reductions[key] = amount
	_reduction_time[key] = duration


## Heilung über Zeit (z. B. Lebenskraft-Blatt).
func start_regeneration(total: float, duration: float) -> void:
	_regen_rate = total / maxf(duration, 0.1)
	_regen_time = duration


## Zeitgeber der Basisklasse; Unterklassen rufen das in _physics_process auf.
func tick_combatant(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	reflect_time = maxf(0.0, reflect_time - delta)
	unstoppable_time = maxf(0.0, unstoppable_time - delta)
	stealth_time = maxf(0.0, stealth_time - delta)
	for key: StringName in buffs.keys():
		buffs[key]["time"] = float(buffs[key]["time"]) - delta
		if float(buffs[key]["time"]) <= 0.0:
			buffs.erase(key)
	for key: StringName in _reduction_time.keys():
		_reduction_time[key] -= delta
		if _reduction_time[key] <= 0.0:
			_reduction_time.erase(key)
			reductions.erase(key)
	if _regen_time > 0.0:
		_regen_time -= delta
		heal(_regen_rate * delta)


## Rückstoß abbauen und auf velocity anwenden (in _physics_process aufrufen).
## Gibt gesammelten Rückstoß einmal als Stoß an die Geschwindigkeit weiter (vor move_and_slide aufrufen).
## Früher wurde er über viele Bilder addiert und schleuderte Ziele dutzende Meter weit.
func apply_knockback(_delta: float) -> void:
	if _knockback.length_squared() > 0.01:
		var impulse: Vector3 = _knockback.limit_length(Balance.values.knockback_max_speed)
		velocity.x += impulse.x
		velocity.z += impulse.z
	_knockback = Vector3.ZERO


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	ReactionEffects.spread_on_death(self)
	died_signal.emit(self)
	_die()


## Unterklassen entscheiden, was beim Tod passiert.
func _die() -> void:
	queue_free()
