// Pflanzen und Felsen (MultiMesh): Vertex-Farben geben die Farbe, erzeugte Texturen die Oberfläche. Grüne und rosa
// Flächen sind Laub: eine Blattkarte schneidet die Kugelkronen zu unregelmäßigen Blattbüscheln aus (cutout) und gibt
// ihnen Blattrelief; braune Flächen sind Rinde mit senkrechten Rissen; Felsen (kind = 1) bekommen Gestein mit Kanten.
// Alles wiegt sich leicht im Wind (oben mehr als unten).
shader_type spatial;
render_mode cull_disabled;

uniform float kind = 0.0;
uniform float cutout = 0.0;
uniform float sway = 0.1;
uniform float sway_height = 6.0;
uniform sampler2D card_tex : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D leaves_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaves_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D bark_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D bark_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float leaf_scale = 0.35;
uniform float bark_scale = 0.9;
uniform float rock_scale = 0.5;

varying vec3 local_pos;
varying vec3 local_normal;
varying vec3 world_pos;
varying vec2 card_uv;

vec3 perturb(vec3 n, vec3 t, vec3 b, vec3 nm, float strength) {
	vec3 d = nm * 2.0 - 1.0;
	return normalize(n + (t * d.x + b * d.y) * strength);
}

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	card_uv = UV2;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float lift = clamp(VERTEX.y / sway_height, 0.0, 1.0);
	float phase = TIME * 1.3 + wp.x * 0.25 + wp.z * 0.2;
	vec3 offset = vec3(sin(phase) + 0.4 * sin(phase * 2.7), 0.0, cos(phase * 0.8)) * sway * lift * lift;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
	world_pos = wp + offset;
}

void fragment() {
	vec3 color = COLOR.rgb;
	vec3 n = normalize(local_normal);
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	float near = 1.0 - smoothstep(35.0, 100.0, dist);
	float green = smoothstep(0.01, 0.06, color.g - max(color.r, color.b));
	float pink = smoothstep(0.02, 0.08, (color.r + color.b) * 0.5 - color.g);
	float leafy = max(green, pink) * (1.0 - kind);
	// Rinde: Brauntöne (Farbton 14–56°, gesättigt, nicht hell) – nicht Blüten oder Blumen.
	float mx = max(color.r, max(color.g, color.b));
	float mn = min(color.r, min(color.g, color.b));
	float sat = (mx - mn) / max(mx, 0.001);
	float hue = 60.0 * (color.g - color.b) / max(color.r - color.b, 0.001);
	float brown = smoothstep(14.0, 20.0, hue) * (1.0 - smoothstep(48.0, 56.0, hue)) * step(color.b, color.g) * smoothstep(0.25, 0.35, sat) * (1.0 - leafy) * (1.0 - kind);
	// Textur-Ebene nach Hauptachse der Normale (Objektraum, damit die Blätter am Baum kleben).
	vec3 an = abs(n);
	vec2 uv;
	vec3 t;
	vec3 b;
	if (an.y >= an.x && an.y >= an.z) {
		uv = local_pos.xz;
		t = vec3(1.0, 0.0, 0.0);
		b = vec3(0.0, 0.0, 1.0);
	} else if (an.x >= an.z) {
		uv = vec2(local_pos.z, -local_pos.y);
		t = vec3(0.0, 0.0, 1.0);
		b = vec3(0.0, -1.0, 0.0);
	} else {
		uv = vec2(local_pos.x, -local_pos.y);
		t = vec3(1.0, 0.0, 0.0);
		b = vec3(0.0, -1.0, 0.0);
	}
	vec3 n_out = n;
	float lum = 1.0;
	float alpha = 1.0;
	if (card_uv.x >= 1.5) {
		// Karte (Blatt- oder Grasbüschel): Form aus dem Alpha der Kartentextur, in der Ferne ein voller Fleck.
		vec4 card = texture(card_tex, card_uv - vec2(2.0));
		alpha = mix(card.a, smoothstep(0.02, 0.2, card.a), smoothstep(45.0, 90.0, dist));
		lum = 0.55 + 0.9 * card.r;
		// Blätter zeigen im Mittel nach oben: so bleibt Laub von allen Seiten gleichmäßig hell.
		n_out = normalize(mix(n, vec3(0.0, 1.0, 0.0), 0.6));
		leafy = 0.0;
		brown = 0.0;
	} else if (leafy > 0.01) {
		vec4 leaf = texture(leaves_tex, uv * leaf_scale);
		lum = mix(lum, 0.6 + 0.9 * leaf.r, leafy * near);
		n_out = perturb(n, t, b, texture(leaves_nm, uv * leaf_scale).xyz, 0.7 * leafy * near);
		// Ausschnitt: Kronen zerfallen in Blattbüschel, in der Ferne wieder geschlossen (kein Flimmern).
		alpha = mix(1.0, mix(leaf.a, 1.0, smoothstep(50.0, 90.0, dist)), cutout * leafy);
	}
	if (brown > 0.01) {
		vec2 uv_bark = vec2(local_pos.x + local_pos.z, local_pos.y * 0.6) * bark_scale;
		float bark = texture(bark_tex, uv_bark).r;
		lum = mix(lum, 0.55 + 0.9 * bark, brown * near);
		n_out = perturb(n_out, normalize(vec3(n.z, 0.0, -n.x) + vec3(0.001)), vec3(0.0, 1.0, 0.0), texture(bark_nm, uv_bark).xyz, 1.0 * brown * near);
	}
	if (kind > 0.5) {
		float rock = texture(rock_tex, uv * rock_scale).r;
		lum = mix(1.0, 0.6 + 0.8 * rock, near);
		n_out = perturb(n, t, b, texture(rock_nm, uv * rock_scale).xyz, 1.2 * near);
	}
	ALBEDO = color * lum;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = alpha;
	// Rückseiten der ausgeschnittenen Kronen: Normale zum Betrachter drehen, sonst sind sie schwarz.
	vec3 n_view = normalize((MODEL_NORMAL_MATRIX * n_out));
	NORMAL = FRONT_FACING ? n_view : -n_view;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
}
