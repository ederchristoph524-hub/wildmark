extends Node
## Stellt alle Balancing-Konstanten aus docs/FORMELN.md bereit, gelesen aus einem Balance-Resource in res://data/.

## Optional: im Editor angelegtes Resource mit angepassten Werten; sonst gelten die Standardwerte aus BalanceData.
const OVERRIDE_PATH: String = "res://data/balance.tres"

var values: BalanceData = BalanceData.new()


func _enter_tree() -> void:
	if ResourceLoader.exists(OVERRIDE_PATH):
		var loaded: BalanceData = load(OVERRIDE_PATH) as BalanceData
		if loaded != null:
			values = loaded
