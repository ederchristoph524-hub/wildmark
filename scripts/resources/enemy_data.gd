class_name EnemyData
extends Resource
## Ein Gegnertyp mit Werten, Verhalten und Beute.

@export var id: StringName
@export var display_name: String = ""
@export var max_hp: int = 1
@export var damage: int = 0
@export var speed: float = 1.0
@export var xp: int = 0
@export var radius: float = 0.5
@export var color: Color = Color.WHITE
## Gefahrenzone innerhalb einer Region.
@export var zone: int = 0
## Beute-Würfe; jeder Eintrag wird einzeln gewürfelt (wie im Prototyp).
@export var drops: Array[DropEntry] = []
## Platzhalterform bis zum echten Modell.
@export var shape: StringName
## Verhalten (charge, ranged, heal, boss …); leer = Standard.
@export var behavior: StringName
## Fernkampf-Reichweite; 0 = Nahkampf.
@export var attack_range: float = 0.0
## Gegner-ID, die dieser Gegner beschwört; leer, wenn keiner.
@export var minion: StringName
@export var poison: bool = false
@export var burn: bool = false
@export var flying: bool = false
@export var night_only: bool = false
@export var armored: bool = false
@export var boss: bool = false
## Erscheint nicht von selbst in der Welt (nur als Beschwörung).
@export var no_spawn: bool = false
