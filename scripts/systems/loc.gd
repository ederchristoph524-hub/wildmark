class_name Loc
extends RefCounted
## Übersetzung für statische Funktionen, in denen tr() nicht verfügbar ist.


static func t(text: String) -> String:
	return String(TranslationServer.translate(text))
