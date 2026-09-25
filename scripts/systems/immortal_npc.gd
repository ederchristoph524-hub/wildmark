class_name ImmortalNpc
extends RefCounted
## NPC-Unsterbliche (GuMasterData mit Rang 6–8, docs/UNSTERBLICH.md, 10): Sie würdigen Sterbliche keines Kampfes,
## setzen im Duell ihre unsterblichen Gu mit langer Ausholzeit und Warnkreis ein und lassen als Lohn Essenzsteine und
## mit etwas Glück einen ihrer unsterblichen Gu zurück.

const META_WAIT: StringName = &"immortal_wait"
const WINDUP: float = 1.3
const CAST_INTERVAL: float = 7.0
const CAST_RANGE: float = 14.0
const WARN_RADIUS: float = 4.0
const REWARD_STONES: int = 12
const GU_DROP_CHANCE: float = 0.5
const COLOR: Color = Color(1.0, 0.85, 0.45)


static func is_immortal(master: GuMaster) -> bool:
	return master.data != null and master.data.is_immortal()


## Sterbliche werden abgewiesen (true = Interaktion beendet).
static func refuses(master: GuMaster) -> bool:
	if not is_immortal(master) or GameState.rank >= Immortal.FIRST_RANK:
		return false
	EventBus.message.emit(Loc.t("%s würdigt dich keines Blickes – für einen Unsterblichen bist du eine Ameise.") % master.display_title(), UiTheme.MUTED)
	return true


## Kampf-KI: alle CAST_INTERVAL Sekunden ein unsterblicher Gu mit Warnkreis am Ziel (true = diese Runde genutzt).
static func try_cast(master: GuMaster, foe: Combatant, distance: float) -> bool:
	if not is_immortal(master) or master.data.immortal_gu.is_empty() or distance > CAST_RANGE:
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < float(master.get_meta(META_WAIT, 0.0)):
		return false
	master.set_meta(META_WAIT, now + CAST_INTERVAL)
	var id: StringName = master.data.immortal_gu[randi() % master.data.immortal_gu.size()]
	if not DataRegistry.has_immortal_gu(id):
		return false
	var aim: Vector3 = (foe.global_position - master.global_position).normalized()
	Telegraph.show_disc(master.get_tree(), foe.global_position, WARN_RADIUS, WINDUP)
	EventBus.floating_text.emit(Loc.t(DataRegistry.immortal_gu(id).display_name) + " …", master.aim_point() + Vector3.UP * 1.3, COLOR)
	master.get_tree().create_timer(WINDUP).timeout.connect(_cast.bind(weakref(master), id, aim, weakref(foe)))
	return true


static func _cast(master_ref: WeakRef, id: StringName, aim: Vector3, foe_ref: WeakRef) -> void:
	var master: GuMaster = master_ref.get_ref() as GuMaster
	if master == null or master.is_dead() or not master.is_inside_tree():
		return
	var data: ImmortalGuData = DataRegistry.immortal_gu(id)
	# Der Schadensfaktor des Meisters (base_damage_mult) wirkt über damage_dealt_mult beim Treffer.
	var damage: float = data.base_damage * Immortal.power(data.rank) * Balance.immortal.npc_cast_mult
	var ctx := EffectContext.create(master, damage, aim, DataRegistry.gu_system().path_color(data.path))
	var foe: Combatant = foe_ref.get_ref() as Combatant
	ctx.target = foe if foe != null and not foe.is_dead() else null
	ctx.power = Immortal.power(data.rank)
	ctx.path = data.path
	EffectSteps.run(data.steps, ctx)
	GuVfx.burst(master.get_tree(), master.aim_point(), GuVfx.style_of(data.path, []), 1.5, 1.3)


## Duell-Lohn eines Unsterblichen: Essenzsteine, dazu mit Glück einer seiner unsterblichen Gu, den noch niemand hat.
static func reward(master: GuMaster) -> void:
	if not is_immortal(master):
		return
	var stones: int = REWARD_STONES * (master.rank - Immortal.FIRST_RANK + 1)
	GameState.add_item(ImmortalAperture.STONE_ITEM, stones)
	EventBus.message.emit(Loc.t("%s überlässt dir %d Unsterblichen-Essenzsteine.") % [master.display_title(), stones], COLOR)
	if randf() >= GU_DROP_CHANCE:
		return
	for id: StringName in master.data.immortal_gu:
		if not ImmortalGu.owns(id) and ImmortalGu.grant(id):
			EventBus.message.emit(Loc.t("„Nimm ihn – ein Gu gehört dem, der ihn führen kann.“"), COLOR)
			return
