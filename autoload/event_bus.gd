extends Node
## Zentraler Signal-Bus: Systeme kommunizieren nur über diese Signale statt über direkte Referenzen. Enthält keine Logik.
# Die Signale werden von anderen Skripten gesendet, nicht von dieser Klasse selbst.
@warning_ignore_start("unused_signal")

## Kurze Meldung für den Spieler (Toast im HUD).
signal message(text: String, color: Color)
## Schwebender Text in der Welt (Schaden, Reaktionen).
signal floating_text(text: String, world_position: Vector3, color: Color)

signal new_game_requested(options: Dictionary)
signal continue_requested
signal game_started
signal return_to_menu_requested

signal player_died
signal player_respawned
signal enemy_killed(enemy_id: StringName, world_position: Vector3)

signal reaction_triggered(reaction_id: StringName, world_position: Vector3)
signal killer_move_learned(move_id: StringName)
signal killer_move_used(move_id: StringName)
signal gu_obtained(gu_id: StringName)
signal gu_died(gu_id: StringName)
signal item_changed(item_id: StringName, amount: int)

signal stage_reached(rank: int, stage: int)
signal breakthrough_attempted(success: bool, rank: int)
signal night_changed(is_night: bool)

## Ein NPC möchte ein Gespräch öffnen (Npc).
signal dialog_requested(npc: Node3D)

## Kamera drehen per Wischen (Pixel-Delta vom Touch-Bereich).
signal camera_look(delta: Vector2)

## Menüs öffnen und schließen (Gu-Menü, Pause).
signal menu_toggled(menu_name: StringName)
signal saved
