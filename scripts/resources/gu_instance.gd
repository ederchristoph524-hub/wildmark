class_name GuInstance
extends Resource
## Laufzeit-Zustand eines Gu im Besitz einer Figur (wird gespeichert).

@export var gu_id: StringName
## ID des Merkmals (TraitData); leer, wenn der Gu keines hat.
@export var trait_id: StringName
@export var satiety: float = 100.0
@export var cooldown_left: float = 0.0
## Sekunden, die der Gu schon ausgehungert ist (Sättigung 0).
@export var starved_time: float = 0.0


static func create(id: StringName, trait_value: StringName = &"", start_satiety: float = 100.0) -> GuInstance:
	var instance := GuInstance.new()
	instance.gu_id = id
	instance.trait_id = trait_value
	instance.satiety = start_satiety
	return instance


func to_dict() -> Dictionary:
	return {"gu_id": String(gu_id), "trait_id": String(trait_id), "satiety": satiety, "starved_time": starved_time}


static func from_dict(d: Dictionary) -> GuInstance:
	var instance := create(StringName(str(d.get("gu_id", ""))), StringName(str(d.get("trait_id", ""))), float(d.get("satiety", 100.0)))
	instance.starved_time = float(d.get("starved_time", 0.0))
	return instance
