class_name KillerMoveEffects
extends RefCounted
## Killer Moves (GU_SYSTEM.md, Abschnitt 7) führen ihre Wirkungsschritte aus gu_system.json (killer_moves[].schritte)
## mit EffectSteps aus – ein neuer Killer Move ist nur ein Dateneintrag. Der Gesamtschaden auf ein Ziel ist je Stufe
## gedeckelt (Balance.killer_total_cap), damit lange Zonen oder viele Geschosse nicht ausufern.

const COLOR_BONE: Color = Color(0.95, 0.9, 0.8)
const ANNOUNCE_COLOR: Color = Color(1.0, 0.8, 0.3)
## Ungelenkte Geschosse treffen ein einzelnes Ziel höchstens so oft; Fallen und kreisende Klingen ebenso grob geschätzt.
const UNGUIDED_HITS: int = 3
const TRAP_HITS: int = 2
const ORBIT_SHARE: float = 0.5
const UTILITY_STEPS: Array[String] = ["delay", "armor", "heal", "summon", "buff", "stealth", "teleport", "dash", "cleanse", "unstoppable", "reflect"]

static var _scale_cache: Dictionary = {}


## damage = Grundschaden × Stärke × mult; target = weiches Ziel (darf null sein).
static func execute(move: KillerMoveData, caster: Combatant, damage: float, aim: Vector3, target: Combatant = null, power: float = 1.0) -> void:
	var family: GuFamilyData = DataRegistry.family(move.family_a)
	var color: Color = DataRegistry.gu_system().path_color(family.path) if family != null else ANNOUNCE_COLOR
	var ctx := EffectContext.create(caster, damage * cap_scale(move), aim, color)
	ctx.target = target if is_instance_valid(target) else null
	ctx.power = power
	ctx.path = family.path if family != null else &""
	EffectSteps.run(move.steps, ctx)
	EventBus.floating_text.emit(Loc.t(move.display_name) + "!", caster.aim_point() + Vector3.UP, ANNOUNCE_COLOR)
	EventBus.killer_move_used.emit(move.id)


## Dämpfung (≤ 1), damit damage_mult × Schrittsumme die Obergrenze der Stufe nicht übersteigt.
static func cap_scale(move: KillerMoveData) -> float:
	if _scale_cache.has(move.id):
		return _scale_cache[move.id]
	var caps: Array[float] = Balance.values.killer_total_cap
	var cap: float = caps[clampi(move.min_rank - 1, 0, caps.size() - 1)] if not caps.is_empty() else INF
	var total: float = move.damage_mult * steps_total(move.steps)
	var scale: float = minf(1.0, cap / total) if total > 0.0 else 1.0
	_scale_cache[move.id] = scale
	return scale


## Geschätzter Gesamtschaden der Schritte auf ein Ziel (× Grundschaden).
static func steps_total(steps: Array) -> float:
	var total: float = 0.0
	for raw: Variant in steps:
		if not raw is Dictionary:
			continue
		var step: Dictionary = raw
		var kind: String = str(step.get("t", ""))
		var mult: float = 0.0 if kind in UTILITY_STEPS else float(step.get("mult", 1.0))
		var ticks: float = float(step.get("time", 4.0)) / maxf(float(step.get("tick", EffectSteps.DEFAULT_TICK)), 0.05)
		match kind:
			"zone":
				total += mult * ticks
			"orbit":
				total += mult * ticks * ORBIT_SHARE
			"projectiles":
				var count: int = int(step.get("count", 1))
				total += mult * (count if bool(step.get("homing", false)) else mini(count, UNGUIDED_HITS))
			"trap":
				total += mult * mini(int(step.get("count", 1)), TRAP_HITS)
			_:
				total += mult
		if step.get("then") is Array:
			total += steps_total(step["then"])
	return total
