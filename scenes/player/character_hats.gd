class_name CharacterHats
extends RefCounted
## Kopfbedeckungen für CharacterMesh nach Art und Stand: Strohhut der Wanderer, Gelehrtenkappe, Fellmütze der
## Steppe, Stirnband, Kapuze der Dämonischen, Turban der Wüste, Haarkrone der Ältesten, Federkranz des Federvolks.
## y = Kopfmitte (Kopfradius CharacterMesh.HEAD_R, oben HEAD_R × HEAD_TALL).

const STRAW: Color = Color(0.78, 0.66, 0.4)
const INK: Color = Color(0.08, 0.08, 0.09)
const FUR: Color = Color(0.42, 0.3, 0.2)
const TURBAN: Color = Color(0.9, 0.86, 0.76)
const GOLD: Color = Color(0.85, 0.7, 0.3)
const FEATHERS: Array[Color] = [Color(0.9, 0.35, 0.2), Color(0.95, 0.8, 0.3), Color(0.25, 0.6, 0.85)]


static func add(b: MeshBuilder, c: Dictionary, y: float) -> void:
	var r: float = CharacterMesh.HEAD_R
	var top: float = y + r * CharacterMesh.HEAD_TALL
	match c.get("hat", &""):
		&"stroh":
			b.add(MeshBuilder.cylinder(0.03, 0.34, 0.15, 12), MeshBuilder.at(Vector3(0.0, top + 0.03, 0.02)), STRAW)
			b.add(MeshBuilder.cylinder(0.34, 0.35, 0.015, 12), MeshBuilder.at(Vector3(0.0, top - 0.04, 0.02)), STRAW.darkened(0.15))
		&"kappe":
			b.add(MeshBuilder.cylinder(0.1, 0.12, 0.11, 8), MeshBuilder.at(Vector3(0.0, top + 0.02, 0.03)), INK)
			b.add(MeshBuilder.box(Vector3(0.36, 0.03, 0.045)), MeshBuilder.at(Vector3(0.0, top + 0.01, 0.12)), INK)
		&"fell":
			b.add(MeshBuilder.cylinder(0.155, 0.16, 0.15, 9), MeshBuilder.at(Vector3(0.0, top - 0.06, 0.02)), FUR)
			b.add(MeshBuilder.sphere(0.155, 8, 4), MeshBuilder.at(Vector3(0.0, top + 0.01, 0.02), Vector3(1.0, 0.45, 1.0)), FUR.lightened(0.12))
		&"band":
			b.add(MeshBuilder.cylinder(0.134, 0.134, 0.04, 12), MeshBuilder.at(Vector3(0.0, y + 0.045, 0.01), Vector3(1.0, 1.0, 1.05)), c["sash"])
			b.add(MeshBuilder.box(Vector3(0.025, 0.14, 0.015)), MeshBuilder.at(Vector3(0.04, y - 0.02, 0.15), Vector3.ONE, Vector3(0.3, 0.0, 0.2)), c["sash"])
		&"kapuze":
			var hood: Color = (c["robe"] as Color).darkened(0.35)
			b.add(MeshBuilder.sphere(r * 1.3, 10, 6), MeshBuilder.at(Vector3(0.0, y + 0.02, 0.06), Vector3(1.0, 1.1, 1.05)), hood)
			b.add(MeshBuilder.cylinder(0.16, 0.24, 0.16, 9), MeshBuilder.at(Vector3(0.0, y - 0.2, 0.04)), hood)
		&"turban":
			b.add(MeshBuilder.sphere(r * 1.25, 10, 5), MeshBuilder.at(Vector3(0.0, y + 0.07, 0.02), Vector3(1.06, 0.72, 1.06)), TURBAN)
			b.add(MeshBuilder.sphere(0.05, 6, 4), MeshBuilder.at(Vector3(0.0, y + 0.1, -0.15)), c["sash"])
		&"krone":
			b.add(MeshBuilder.box(Vector3(0.09, 0.08, 0.15)), MeshBuilder.at(Vector3(0.0, top + 0.03, 0.04)), GOLD)
			b.add(MeshBuilder.cylinder(0.01, 0.01, 0.26, 4), MeshBuilder.at(Vector3(0.0, top + 0.03, 0.04), Vector3.ONE, Vector3(0.0, 0.0, PI * 0.5)), GOLD.lightened(0.2))
		&"feder":
			b.add(MeshBuilder.cylinder(0.134, 0.134, 0.045, 12), MeshBuilder.at(Vector3(0.0, y + 0.045, 0.01), Vector3(1.0, 1.0, 1.05)), c["sash"])
			for i: int in 3:
				var tilt: float = (float(i) - 1.0) * 0.45
				b.add(MeshBuilder.box(Vector3(0.045, 0.3, 0.012)), MeshBuilder.at(Vector3(sin(tilt) * 0.1, top + 0.08, 0.1), Vector3.ONE, Vector3(-0.25, 0.0, -tilt)), FEATHERS[i])
