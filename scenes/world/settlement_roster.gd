class_name SettlementRoster
extends RefCounted
## Besetzungslisten der Siedlungen (reine Daten, ohne Autoload-Bezug, damit auch Import-Werkzeuge sie lesen können):
## Bewohner je Gruppe und Klan-Gu-Meister. Aufgestellt werden sie von SettlementPeople.

## Je Bewohner-Gruppe: NPC-Art, Titel (leer = Name aus den Daten), Aufgabe, Tausch, Anker, Versatz (x, z).
const RESIDENTS: Dictionary[StringName, Array] = {
	&"gu_yue": [
		[&"klan", "Dorfältester", &"bau", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Klanwächter", &"j10", false, &"gate", Vector2(0.0, 0.0)],
		[&"klan", "Wachhauptmann", &"klanfehde", false, &"gate", Vector2(3.5, 0.5)],
		[&"klan", "Holzfäller", &"holz", false, &"back_gate", Vector2(0.0, 0.0)],
		[&"klan", "Späherin", &"ero", false, &"tower", Vector2(0.0, 0.0)],
		[&"klan", "Akademie-Lehrerin", &"akademie", false, &"academy", Vector2(0.0, 0.0)],
		[&"klan", "Onkel", &"onkel", false, &"well", Vector2(1.5, 0.0)],
		[&"klan", "Tante", &"tante_kraeuter", false, &"well", Vector2(-1.5, 1.2)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"daemon", "", &"", true, &"gate_outside", Vector2(0.0, 0.0)],
	],
	&"bai": [
		[&"klan", "Bai-Ältester", &"blumenwein_suche", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Bai-Wächter", &"bai_daemonen", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"xiong": [
		[&"klan", "Xiong-Ältester", &"xiong_duelle", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Xiong-Jäger", &"dk_woelfe", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"shang": [
		[&"klan", "Shang-Verwalter", &"shang_jade", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Stadtwache", &"shang_wege", false, &"gate", Vector2(0.0, 0.0)],
		[&"shang_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"shang_schmied", "", &"", true, &"market", Vector2(-4.0, 2.0)],
		[&"auktionator", "", &"", true, &"well", Vector2(2.0, 2.0)],
		[&"daemon", "", &"", true, &"gate_outside", Vector2(0.0, 0.0)],
	],
	&"steppe": [
		[&"stamm", "Häuptling", &"steppe_fell", false, &"hall", Vector2(0.0, 0.0)],
		[&"stamm", "", &"", true, &"gate", Vector2(0.0, 0.0)],
		[&"steppen_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"lang_ya": [
		[&"klan", "Lang-Ya-Hüter", &"reise_welt", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Lang-Ya-Schreiber", &"gu_sammler", false, &"hall", Vector2(3.0, 1.5)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"wueste": [
		[&"klan", "Tempelhüter", &"oase_rose", false, &"hall", Vector2(0.0, 0.0)],
		[&"klan", "Oasenwache", &"oase_raeuber", false, &"gate", Vector2(0.0, 0.0)],
		[&"haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"wuesten_haendler", "", &"", true, &"market", Vector2(-3.0, 3.0)],
	],
	&"karawane": [
		[&"daemon", "Karawanenältester", &"karawane_wolle", false, &"hall", Vector2(-3.0, 1.0)],
		[&"daemon", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"wuesten_haendler", "", &"", true, &"gate", Vector2(0.0, 0.0)],
	],
	&"wu": [
		[&"klan", "Wu-Verwalter", &"wu_wuerdig", false, &"hall", Vector2(-3.0, 1.0)],
		[&"klan", "Festungswache", &"wu_schuppe", false, &"gate", Vector2(0.0, 0.0)],
		[&"wu_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"auktionator_hoch", "", &"", true, &"market", Vector2(-4.0, 2.0)],
	],
	&"insel": [
		[&"seemann", "", &"", true, &"gate", Vector2(0.0, 0.0)],
		[&"perlentaucher", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"klan", "Inselältester", &"insel_perle", false, &"hall", Vector2(0.0, 0.0)],
	],
	&"meereszombie": [
		[&"daemon", "Zombie-Kapitän", &"zombie_perlen", false, &"hall", Vector2(0.0, 0.0)],
		[&"daemon", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"schatten": [
		[&"klan", "Schattenältester", &"", false, &"hall", Vector2(-3.0, 1.0)],
		[&"daemon", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"klan", "Schattenwächter", &"schatten_blut", false, &"gate", Vector2(0.0, 0.0)],
	],
	&"huang_jin": [
		[&"stamm", "Huang-Jin-Ältester", &"huang_jin_ehre", false, &"hall", Vector2(0.0, 0.0)],
		[&"steppen_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"blutfluegel": [
		[&"klan", "Blutflügel-Ältester", &"", false, &"hall", Vector2(-3.0, 1.0)],
		[&"daemon", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"klan", "Blutwächter", &"blut_pruefung", false, &"gate", Vector2(0.0, 0.0)],
	],
	&"wu_spaeher": [
		[&"klan", "Wu-Späherführer", &"wu_spaeher_auftrag", false, &"hall", Vector2(0.0, 0.0)],
		[&"wu_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"yi_tian": [
		[&"klan", "Yi-Tian-Ältester", &"dao_pilger", false, &"hall", Vector2(-3.0, 1.0)],
		[&"klan", "Yi-Tian-Torwächter", &"yi_tian_pruefung", false, &"gate", Vector2(0.0, 0.0)],
		[&"sekten_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"ge": [
		[&"stamm", "Ge-Häuptling", &"ge_woelfe", false, &"hall", Vector2(0.0, 0.0)],
		[&"steppen_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"federvolk": [
		[&"stamm", "Federältester", &"federn_rat", false, &"hall", Vector2(0.0, 0.0)],
		[&"wuesten_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"piraten": [
		[&"daemon", "Piratenkapitän", &"piraten_beute", false, &"hall", Vector2(-3.0, 1.0)],
		[&"seemann", "", &"", true, &"market", Vector2(0.0, 0.0)],
	],
	&"kranich": [
		[&"klan", "Kranich-Ältester", &"dao_meister", false, &"hall", Vector2(-3.0, 1.0)],
		[&"klan", "Kranich-Torwächter", &"kranich_pruefung", false, &"gate", Vector2(0.0, 0.0)],
		[&"sekten_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"auktionator_hoch", "", &"", true, &"market", Vector2(-4.0, 2.0)],
	],
	&"sekte": [
		[&"klan", "Torwächter", &"sekte_herz", false, &"gate", Vector2(0.0, 0.0)],
		[&"klan", "Bibliothekar", &"sekte_bibliothek", false, &"academy", Vector2(0.0, 0.0)],
		[&"klan", "Sektenwächter", &"sekte_fehde", false, &"gate", Vector2(3.5, 0.5)],
		[&"sekten_haendler", "", &"", true, &"market", Vector2(0.0, 0.0)],
		[&"sekten_schatzmeister", "", &"", true, &"hall", Vector2(-3.0, 1.0)],
	],
}
## Gu-Meister je Bewohner-Gruppe: [Daten-ID, Titel, Anker] (Rang aus gegner.json → GUMASTER).
const MASTERS: Dictionary[StringName, Array] = {
	# Duell-Rangleiter im Gu-Yue-Dorf: Klanlehrer, die Vorsteher der Chi- und Mo-Familie, der Klanführer.
	&"gu_yue": [[&"gu_yue", "Klanlehrer", &"training"], [&"gu_yue_chi", "", &"academy"], [&"gu_yue_mo", "", &"tower"],
		[&"gu_yue_bo", "", &"hall"]],
	&"xiong": [[&"xiong_jaeger", "Xiong-Jagdmeister", &"gate"], [&"xiong_aeltester", "", &"hall"]],
	&"bai": [[&"bai_waechter", "Bai-Klanwächter", &"gate"], [&"bai_aeltester", "", &"hall"]],
	&"shang": [[&"shang_arena", "Arenameister", &"arena"], [&"blutfluegel", "Fremder Dämon", &"gate_outside"]],
	&"steppe": [[&"wilde_horde", "Hordenkrieger", &"training"]],
	&"lang_ya": [[&"yi_tian", "Lang-Ya-Gelehrter", &"training"]],
	&"wueste": [[&"wuestentempel", "Tempelwächter", &"training"]],
	&"karawane": [[&"karawane", "Karawanenführer", &"hall"]],
	&"wu": [[&"wu_general", "Wu-General", &"training"], [&"wu_aeltester", "Wu-Ältester", &"hall"]],
	&"insel": [[&"ostmeer", "Inselwächter", &"training"]],
	&"meereszombie": [[&"meereszombie", "Untoter Seefahrer", &"training"]],
	&"schatten": [[&"schattensekte", "Schattenschüler", &"training"]],
	&"huang_jin": [[&"huang_jin", "Huang-Jin-Krieger", &"training"]],
	&"sekte": [[&"zehn_extreme", "Sektenmeister", &"training"], [&"himmelshof", "Gast des Himmlischen Hofes", &"tower"]],
	&"blutfluegel": [[&"blutfluegel", "Blutflügel-Dämon", &"training"], [&"blutaeltester", "", &"tower"]],
	&"wu_spaeher": [[&"wu_general", "Wu-Späher", &"training"]],
	&"yi_tian": [[&"yi_tian", "Yi-Tian-Schüler", &"training"], [&"yi_tian_aeltester", "", &"tower"]],
	&"ge": [[&"ge_krieger", "", &"training"]],
	&"federvolk": [[&"federkrieger", "", &"training"]],
	&"piraten": [[&"seeraeuber", "", &"training"]],
	&"kranich": [[&"kranich_meister", "", &"training"], [&"himmelshof", "Gesandter des Himmlischen Hofes", &"tower"]],
}
