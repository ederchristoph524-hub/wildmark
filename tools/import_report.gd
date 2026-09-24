class_name ImportReport
extends RefCounted
## Sammelt Fehler und Warnungen eines Datenimports und gibt sie gesammelt aus.

var errors: PackedStringArray = []
var warnings: PackedStringArray = []


func error(message: String) -> void:
	errors.append(message)


func warn(message: String) -> void:
	warnings.append(message)


func has_errors() -> bool:
	return not errors.is_empty()


func print_messages() -> void:
	for message: String in warnings:
		print("  WARNUNG: ", message)
	for message: String in errors:
		printerr("  FEHLER: ", message)
