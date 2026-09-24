// Gelände: Vertex-Farben (Biom, Wege, Plätze), Normalen aus dem Höhenraster und weiche Farbvariation aus
// Weltkoordinaten, damit große Flächen nicht flach wirken.
shader_type spatial;
render_mode cull_back;

varying vec3 world_pos;
varying vec3 v_color;

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
}

void fragment() {
	float variation = value_noise(world_pos.xz * 0.12) * 0.65 + value_noise(world_pos.xz * 0.55) * 0.35;
	ALBEDO = v_color * (0.88 + 0.22 * variation);
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
