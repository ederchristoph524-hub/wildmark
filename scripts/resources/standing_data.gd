class_name StandingData
extends Resource
## Herkunft innerhalb des Klans (fraktionen.json → STANDING): Startgeschenk, Talentbonus und Ansehen im
## Heimatklan (wird beim Start als Verdienst im Gu-Yue-Klan angerechnet; 0 = kein Mitglied).

@export var id: StringName
@export var display_name: String = ""
@export var icon: String = ""
@export_multiline var description: String = ""
@export var gift: Dictionary[StringName, int] = {}
@export var home_merit: int = 0
@export var apt_bonus: float = 0.0
