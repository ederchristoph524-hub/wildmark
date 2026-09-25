// Figuren (Spieler, Dorfbewohner, Gu-Meister): Vertex-Farben geben die Farbe, erzeugte Texturen die Oberfläche –
// Gewebe auf Stoff (Robe, Hose, Schärpe), leichtes Relief; Haut und Haar bleiben glatt (Haut etwas weicher glänzend).
// Arme und Beine schwingen beim Laufen: UV2.x = Schwunggewicht (+ links / − rechts, 0 = starr), UV2.y = Drehpunkt-Höhe.
shader_type spatial;
render_mode cull_back;

uniform float walk_phase = 0.0;
uniform float walk_amount = 0.0;
uniform vec4 glow_color : source_color = vec4(0.0);
uniform vec4 skin_color : source_color = vec4(0.86, 0.7, 0.55, 1.0);
uniform vec4 hair_color : source_color = vec4(0.12, 0.1, 0.09, 1.0);
uniform sampler2D fabric_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D fabric_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float fabric_scale = 6.0;

varying vec3 v_color;
varying vec3 local_pos;
varying vec3 local_normal;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 perturb(vec3 n, vec3 t, vec3 b, vec3 nm, float strength) {
	vec3 d = nm * 2.0 - 1.0;
	return normalize(n + (t * d.x + b * d.y) * strength);
}

void vertex() {
	float w = UV2.x;
	vec3 vertex = VERTEX;
	vec3 normal = NORMAL;
	if (abs(w) > 0.001) {
		float angle = sin(walk_phase) * walk_amount * w;
		float c = cos(angle);
		float s = sin(angle);
		vec3 p = VERTEX - vec3(0.0, UV2.y, 0.0);
		vertex = vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c) + vec3(0.0, UV2.y, 0.0);
		normal = vec3(NORMAL.x, NORMAL.y * c - NORMAL.z * s, NORMAL.y * s + NORMAL.z * c);
	}
	VERTEX = vertex;
	NORMAL = normal;
	local_pos = VERTEX;
	local_normal = normal;
	v_color = srgb_to_linear(COLOR.rgb);
}

void fragment() {
	vec3 n = normalize(local_normal);
	// Haut und Haar erkennen (kein Gewebe): Farbabstand zur Haut- bzw. Haarfarbe der Figur.
	vec3 skin = srgb_to_linear(skin_color.rgb);
	vec3 hair = srgb_to_linear(hair_color.rgb);
	float is_skin = 1.0 - smoothstep(0.01, 0.06, distance(v_color, skin));
	float is_hair = 1.0 - smoothstep(0.005, 0.03, distance(v_color, hair));
	float cloth = clamp(1.0 - is_skin - is_hair, 0.0, 1.0);
	vec3 an = abs(n);
	vec2 uv = an.y > max(an.x, an.z) ? local_pos.xz : (an.x > an.z ? local_pos.zy : local_pos.xy);
	vec3 t = an.y > max(an.x, an.z) ? vec3(1.0, 0.0, 0.0) : (an.x > an.z ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0));
	vec3 b = normalize(cross(n, t));
	float near = 1.0 - smoothstep(12.0, 40.0, length((MODEL_MATRIX * vec4(local_pos, 1.0)).xyz - CAMERA_POSITION_WORLD));
	float weave = texture(fabric_tex, uv * fabric_scale).r;
	float lum = 1.0 + (weave - 0.5) * 0.35 * cloth * near;
	vec3 n_out = perturb(n, t, b, texture(fabric_nm, uv * fabric_scale).xyz, 0.5 * cloth * near);
	ALBEDO = v_color * lum;
	NORMAL = normalize((MODEL_NORMAL_MATRIX * n_out));
	ROUGHNESS = mix(0.55, 0.9, cloth) - 0.25 * is_hair;
	SPECULAR = mix(0.35, 0.2, cloth);
	// Leichte Kante, damit Figuren sich vom Dschungel abheben; Aura färbt sie beim Kultivieren ein.
	RIM = 0.25;
	RIM_TINT = 0.6;
	EMISSION = glow_color.rgb * glow_color.a;
}
