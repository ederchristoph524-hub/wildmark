class_name KillerMoveEffects
extends RefCounted
## Killer Moves (GU_SYSTEM.md, Abschnitt 7) führen ihre Wirkungsschritte aus gu_system.json (killer_moves[].schritte)
## mit EffectSteps aus – ein neuer Killer Move ist nur ein Dateneintrag.

const COLOR_BONE: Color = Color(0.95, 0.9, 0.8)
const ANNOUNCE_COLOR: Color = Color(1.0, 0.8, 0.3)


## damage = Grundschaden × Stärke × mult; target = weiches Ziel (darf null sein).
static func execute(move: KillerMoveData, caster: Combatant, damage: float, aim: Vector3, target: Combatant = null, power: float = 1.0) -> void:
	var family: GuFamilyData = DataRegistry.family(move.family_a)
	var color: Color = DataRegistry.gu_system().path_color(family.path) if family != null else ANNOUNCE_COLOR
	var ctx := EffectContext.create(caster, damage, aim, color)
	ctx.target = target
	ctx.power = power
	ctx.path = family.path if family != null else &""
	EffectSteps.run(move.steps, ctx)
	EventBus.floating_text.emit(Loc.t(move.display_name) + "!", caster.aim_point() + Vector3.UP, ANNOUNCE_COLOR)
	EventBus.killer_move_used.emit(move.id)
