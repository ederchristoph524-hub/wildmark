// Bestien: Vertex-Farben geben die Farbe, eine erzeugte Textur die Haut – Fell (Strähnen, kind 0), glatte, feuchte
// Haut für Schleime und Geister (kind 1), Gestein für Golems (kind 2), Schuppen und Panzer (kind 3). Dreiseitig
// projiziert im Objektraum, mit Relief; in der Ferne blendet das Detail aus.
shader_type spatial;
render_mode cull_back;

uniform float kind = 0.0;
uniform sampler2D skin_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D skin_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float skin_scale = 1.4;

varying vec3 local_pos;
varying vec3 local_normal;
varying vec3 world_pos;

vec3 perturb(vec3 n, vec3 t, vec3 b, vec3 nm, float strength) {
	vec3 d = nm * 2.0 - 1.0;
	return normalize(n + (t * d.x + b * d.y) * strength);
}

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(local_normal);
	float near = 1.0 - smoothstep(20.0, 60.0, length(world_pos - CAMERA_POSITION_WORLD));
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec2 uv_x = local_pos.zy * skin_scale;
	vec2 uv_y = local_pos.xz * skin_scale;
	vec2 uv_z = local_pos.xy * skin_scale;
	float d = texture(skin_tex, uv_x).r * w.x + texture(skin_tex, uv_y).r * w.y + texture(skin_tex, uv_z).r * w.z;
	vec3 n_x = perturb(n, vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), texture(skin_nm, uv_x).xyz, 1.0);
	vec3 n_y = perturb(n, vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), texture(skin_nm, uv_y).xyz, 1.0);
	vec3 n_z = perturb(n, vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), texture(skin_nm, uv_z).xyz, 1.0);
	vec3 n_tex = normalize(n_x * w.x + n_y * w.y + n_z * w.z);
	float smooth_skin = step(0.5, kind) * step(kind, 1.5);
	float contrast = mix(0.7, 0.15, smooth_skin);
	float lum = mix(1.0, 0.6 + 0.8 * d, near * (1.0 - smooth_skin * 0.7));
	vec3 n_out = normalize(mix(n, n_tex, near * mix(0.8, 0.15, smooth_skin)));
	ALBEDO = COLOR.rgb * lum;
	NORMAL = normalize((MODEL_NORMAL_MATRIX * n_out));
	ROUGHNESS = mix(0.85, 0.3, smooth_skin);
	SPECULAR = mix(0.2, 0.5, smooth_skin);
	RIM = 0.3 * smooth_skin;
	RIM_TINT = 0.5;
}
