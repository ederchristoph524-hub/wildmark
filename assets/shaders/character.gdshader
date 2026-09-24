// Figuren (Spieler, Dorfbewohner, Gu-Meister): Vertex-Farben, Arme und Beine schwingen beim Laufen.
// UV2.x = Schwunggewicht (+ links / − rechts, 0 = starr), UV2.y = Drehpunkt-Höhe (Hüfte bzw. Schulter).
shader_type spatial;
render_mode cull_back;

uniform float walk_phase = 0.0;
uniform float walk_amount = 0.0;
uniform vec4 glow_color : source_color = vec4(0.0);

varying vec3 v_color;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	float w = UV2.x;
	if (abs(w) > 0.001) {
		float angle = sin(walk_phase) * walk_amount * w;
		float c = cos(angle);
		float s = sin(angle);
		vec3 p = VERTEX - vec3(0.0, UV2.y, 0.0);
		VERTEX = vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c) + vec3(0.0, UV2.y, 0.0);
		NORMAL = vec3(NORMAL.x, NORMAL.y * c - NORMAL.z * s, NORMAL.y * s + NORMAL.z * c);
	}
	v_color = srgb_to_linear(COLOR.rgb);
}

void fragment() {
	ALBEDO = v_color;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	// Leichte Kante, damit Figuren sich vom Dschungel abheben; Aura färbt sie beim Kultivieren ein.
	RIM = 0.35;
	RIM_TINT = 0.5;
	EMISSION = glow_color.rgb * glow_color.a;
}
