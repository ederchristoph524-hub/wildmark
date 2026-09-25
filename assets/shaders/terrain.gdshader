// Gelände: Vertex-Farben (Biom, Wege, Plätze) geben die Farbe, erzeugte Detailtexturen (ProceduralTextures) die
// Oberfläche: Grashalme auf Wiesen, Krümel und Kies auf Wegen, geschichteter Fels an Steilhängen (dreiseitig
// projiziert), Steinplatten auf Pflaster. Normal Maps lassen Sonne und Laternen über Halme, Kies und Felsrisse
// streichen. In der Ferne blenden die Details aus (kein Flimmern), großräumige Flecken bleiben.
shader_type spatial;
render_mode cull_back;

uniform sampler2D grass_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D soil_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D soil_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
// Kacheln je Meter.
uniform float grass_scale = 0.45;
uniform float soil_scale = 0.6;
uniform float rock_scale = 0.22;
uniform float detail_strength = 0.9;

varying vec3 world_pos;
varying vec3 v_color;
varying vec3 world_normal;
// Pflaster (Vertex-Alpha 0 = gepflastert), in Städten, Festungen und Sekten.
varying float v_paved;

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

// Normal Map (Tangentenraum) auf eine Weltnormale mit gegebener Tangente/Bitangente anwenden.
vec3 perturb(vec3 n, vec3 t, vec3 b, vec3 nm, float strength) {
	vec3 d = nm * 2.0 - 1.0;
	return normalize(n + (t * d.x + b * d.y) * strength);
}

// Zweifach gesampelt (grob und fein versetzt), damit sich die Kachelung nicht wiederholt.
float detail(sampler2D tex, vec2 uv) {
	return mix(texture(tex, uv).r, texture(tex, uv * 0.37 + vec2(0.3, 0.7)).r, 0.35);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_color = srgb_to_linear(COLOR.rgb);
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_paved = 1.0 - COLOR.a;
}

void fragment() {
	vec3 n = normalize(world_normal);
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	float near = (1.0 - smoothstep(45.0, 140.0, dist)) * detail_strength;
	float variation = value_noise(world_pos.xz * 0.12) * 0.65 + value_noise(world_pos.xz * 0.55) * 0.35;
	vec3 base = v_color * (0.88 + 0.22 * variation);
	// Großräumige Flecken auf Wiesen: trockenere, gelbliche Hänge und sattere, kühle Senken (nur auf Grün).
	float macro = value_noise(world_pos.xz * 0.018) * 0.7 + value_noise(world_pos.xz * 0.05) * 0.3;
	float green = clamp((v_color.g - max(v_color.r, v_color.b)) * 10.0, 0.0, 1.0);
	vec3 dry = base * vec3(1.14, 1.03, 0.7);
	vec3 lush = base * vec3(0.8, 0.94, 0.86);
	base = mix(base, mix(lush, dry, smoothstep(0.3, 0.75, macro)), green * 0.6);
	// Steile Hänge: nackter Fels in der Tönung des Bioms (entsättigt, etwas wärmer).
	float steep = smoothstep(0.2, 0.42, 1.0 - n.y);
	vec3 rock_tint = mix(vec3(dot(base, vec3(0.33))), base, 0.3) * vec3(1.04, 0.98, 0.9);
	base = mix(base, rock_tint, steep * 0.85);

	// Oberflächen-Detail: Gras auf Grün, Erde/Kies auf Wegen und Plätzen, Fels an Hängen (dreiseitig projiziert).
	vec2 uv_flat = world_pos.xz;
	float d_grass = detail(grass_tex, uv_flat * grass_scale);
	float d_soil = detail(soil_tex, uv_flat * soil_scale);
	vec3 nm_flat = mix(texture(soil_nm, uv_flat * soil_scale).xyz, texture(grass_nm, uv_flat * grass_scale).xyz, green);
	float d_ground = mix(d_soil, d_grass, green);
	// Schnee und heller Sand: glatt, nur schwache Körnung.
	float bright = smoothstep(0.55, 0.8, max(v_color.r, max(v_color.g, v_color.b))) * (1.0 - green);
	d_ground = mix(d_ground, 0.5 + (d_ground - 0.5) * 0.35, bright);
	vec3 n_ground = perturb(n, vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), nm_flat, mix(0.5, 0.55, green) * near);
	float lum = mix(1.0, mix(0.7 + 0.6 * d_ground, 0.55 + 0.9 * d_ground, green), near);
	vec3 n_out = n_ground;
	if (steep > 0.01) {
		vec3 w = pow(abs(n), vec3(4.0));
		w /= (w.x + w.y + w.z);
		vec2 uv_x = world_pos.zy * rock_scale;
		vec2 uv_y = world_pos.xz * rock_scale;
		vec2 uv_z = world_pos.xy * rock_scale;
		float d_rock = texture(rock_tex, uv_x).r * w.x + texture(rock_tex, uv_y).r * w.y + texture(rock_tex, uv_z).r * w.z;
		vec3 n_x = perturb(n, vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), texture(rock_nm, uv_x).xyz, 1.3 * near);
		vec3 n_y = perturb(n, vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), texture(rock_nm, uv_y).xyz, 1.3 * near);
		vec3 n_z = perturb(n, vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), texture(rock_nm, uv_z).xyz, 1.3 * near);
		vec3 n_rock = normalize(n_x * w.x + n_y * w.y + n_z * w.z);
		// Waagrechte Schichten wie an Felswänden.
		float strata = 0.85 + 0.3 * value_noise(vec2(world_pos.y * 1.4, (world_pos.x + world_pos.z) * 0.12));
		lum = mix(lum, mix(1.0, (0.5 + 1.0 * d_rock) * strata, max(near, 0.35)), steep);
		n_out = normalize(mix(n_ground, n_rock, steep));
	}
	vec3 albedo = base * lum;
	if (v_paved > 0.01) {
		// Steinplatten im Verband: jede zweite Reihe um eine halbe Platte versetzt, Fugen dunkel, jede Platte etwas anders.
		vec2 cell = world_pos.xz / vec2(0.9, 0.6);
		float row = floor(cell.y);
		vec2 slab = vec2(cell.x + mod(row, 2.0) * 0.5, cell.y);
		vec2 f = fract(slab);
		float edge = min(min(f.x, 1.0 - f.x) * 0.9, min(f.y, 1.0 - f.y) * 0.6);
		float far_fade = 1.0 - smoothstep(20.0, 65.0, dist);
		float groove = (1.0 - smoothstep(0.02, 0.06, edge)) * (0.35 + 0.65 * far_fade);
		float tone = hash(floor(slab));
		float grain = mix(1.0, 0.86 + 0.28 * texture(stone_tex, world_pos.xz * 0.8).r, far_fade);
		vec3 stone = vec3(0.3, 0.29, 0.27) * (0.82 + 0.36 * tone) * (0.9 + 0.2 * variation) * grain;
		stone = mix(stone, stone * 0.45, groove);
		float paved = smoothstep(0.0, 0.6, v_paved);
		albedo = mix(albedo, stone, paved);
		// Platten liegen glatt: die Fuge senkt sich ab, sonst keine Halme.
		vec3 n_slab = perturb(n, vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.5 + (f.x - 0.5) * groove * 0.6, 0.5 + (f.y - 0.5) * groove * 0.6, 1.0), 1.0);
		n_out = normalize(mix(n_out, n_slab, paved));
	}
	// Nässe bei Regen (Weather): dunkler und glänzender, auf Pflaster und in Senken stärker.
	float wet = wetness * (0.7 + 0.3 * v_paved + 0.3 * (1.0 - variation));
	albedo *= 1.0 - 0.28 * wet;
	// Etwas entsättigt: der AgX-Tonemapper und das Himmelslicht machen Wiesen sonst grell.
	ALBEDO = mix(vec3(dot(albedo, vec3(0.3, 0.59, 0.11))), albedo, 0.86);
	NORMAL = normalize((VIEW_MATRIX * vec4(n_out, 0.0)).xyz);
	ROUGHNESS = mix(0.95, 0.35, wet);
	SPECULAR = mix(0.12, 0.45, wet);
}
