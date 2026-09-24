class_name GuFamilyData
extends Resource
## Eine Gu-Familie mit gemeinsamer Wirkform, Futter, Basiswerten auf Rang 1 und ihren Mitgliedern je Rang.

@export var id: StringName
@export var display_name: String = ""
@export var path: StringName
@export var role: String = ""
## Wirkform aus GU_SYSTEM.md (geschoss, strahl, stich, kreis, selbst, bewegung, zaehmen …).
@export var form: StringName
@export var tags: Array[StringName] = []
## Zustand, den ein Treffer auslöst; leer, wenn keiner.
@export var status: StringName
@export var feed_item: StringName
@export var feed_amount: int = 0
## Basiswerte auf Rang 1 (Schlüssel wie in gu_system.json, z. B. schaden, cd, ess, reichweite).
@export var base_r1: Dictionary[StringName, Variant] = {}
@export var members: Array[GuData] = []
## Aufstiegs-Materialien je Zielrang: {2: {&"mondtau": 3}, 3: {…}}.
@export var upgrade_materials: Dictionary[int, Dictionary] = {}
@export_multiline var world_effect: String = ""


## Liefert das Mitglied für einen Rang oder null.
func member_for_rank(target_rank: int) -> GuData:
	for member: GuData in members:
		if member.rank == target_rank:
			return member
	return null
