// Gelände: Vertex-Farben (Biom, Wege, Plätze), Normalen aus dem Höhenraster und weiche Farbvariation aus
// Weltkoordinaten, damit große Flächen nicht flach wirken.
shader_type spatial;
render_mode cull_back;

varying vec3 world_pos;
varying vec3 v_color;
varying vec3 world_normal;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_color = srgb_to_linear(COLOR.rgb);
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float variation = value_noise(world_pos.xz * 0.12) * 0.65 + value_noise(world_pos.xz * 0.55) * 0.35;
	// Feine Körnung (Erdkrümel, Grasbüschel) nur in der Nähe, damit der Boden aus der Nähe nicht glatt wirkt.
	float near = 1.0 - smoothstep(6.0, 35.0, length(world_pos - CAMERA_POSITION_WORLD));
	float grain = value_noise(world_pos.xz * 2.3) * 0.6 + value_noise(world_pos.xz * 6.1) * 0.4;
	vec3 base = v_color * (0.88 + 0.22 * variation);
	// Großräumige Flecken auf Wiesen: trockenere, gelbliche Hänge und sattere, kühle Senken (nur auf Grün).
	float macro = value_noise(world_pos.xz * 0.018) * 0.7 + value_noise(world_pos.xz * 0.05) * 0.3;
	float green = clamp((v_color.g - max(v_color.r, v_color.b)) * 10.0, 0.0, 1.0);
	vec3 dry = base * vec3(1.14, 1.03, 0.7);
	vec3 lush = base * vec3(0.8, 0.94, 0.86);
	base = mix(base, mix(lush, dry, smoothstep(0.3, 0.75, macro)), green * 0.6);
	// Steile Hänge: nackter Fels mit waagrechten Schichten, in der Tönung des Bioms (entsättigt, etwas wärmer).
	float steep = smoothstep(0.2, 0.42, 1.0 - normalize(world_normal).y);
	float strata = value_noise(vec2(world_pos.y * 1.4, (world_pos.x + world_pos.z) * 0.12)) * 0.7 + variation * 0.3;
	vec3 rock = mix(vec3(dot(base, vec3(0.33))), base, 0.3) * vec3(1.04, 0.98, 0.9) * (0.62 + 0.4 * strata);
	base = mix(base, rock, steep * 0.85);
	// Helle Körner wärmer (trockenes Gras, Sand), dunkle kühler (Moos, Schatten zwischen Halmen).
	vec3 warm = base * vec3(1.12, 1.08, 0.86);
	vec3 cool = base * vec3(0.8, 0.88, 0.86);
	vec3 albedo = mix(base, grain > 0.5 ? warm : cool, abs(grain - 0.5) * 1.6 * near);
	// Etwas entsättigt: der AgX-Tonemapper und das Himmelslicht machen Wiesen sonst grell.
	ALBEDO = mix(vec3(dot(albedo, vec3(0.3, 0.59, 0.11))), albedo, 0.86);
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
