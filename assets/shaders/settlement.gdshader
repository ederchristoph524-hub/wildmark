// Siedlungen: Vertex-Farben geben die Farbe (im Compatibility-Renderer ohne sRGB-Umrechnung, sonst zu dunkel),
// erzeugte Detailtexturen die Oberfläche – je nach Ausrichtung und Farbe: geneigte Flächen tragen Dachziegel,
// braune Teile Holzmaserung, helle Wände Putz, graue Böden und Mauern Stein. Normal Maps geben den Flächen Relief.
// Markierte Teile (UV2.x = Stärke) leuchten nachts: Fenster warm (UV2.y = 1), Laternen in ihrer Farbe (UV2.y = 0).
shader_type spatial;
render_mode cull_back;

uniform float night_glow : hint_range(0.0, 1.0) = 0.0;
uniform vec3 window_light : source_color = vec3(1.0, 0.6, 0.25);
uniform sampler2D plaster_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D wood_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D tiles_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D plaster_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D wood_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D tiles_nm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_nm : hint_normal, filter_linear_mipmap, repeat_enable;
// Kacheln je Meter.
uniform float plaster_scale = 0.5;
uniform float wood_scale = 0.55;
uniform float tiles_scale = 0.62;
uniform float stone_scale = 0.4;
// 1 = geneigte Flächen sind Dächer (Siedlungen); 0 = Requisiten ohne Dachziegel.
uniform float tiles_on_slopes = 1.0;

varying vec2 glow;
varying vec3 world_pos;
varying vec3 world_normal;

vec3 perturb(vec3 n, vec3 t, vec3 b, vec3 nm, float strength) {
	vec3 d = nm * 2.0 - 1.0;
	return normalize(n + (t * d.x + b * d.y) * strength);
}

void vertex() {
	glow = UV2;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 albedo = COLOR.rgb;
	vec3 n = normalize(world_normal);
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	float near = 1.0 - smoothstep(40.0, 110.0, dist);
	float ay = abs(n.y);
	// Fläche einordnen: Boden, Wand oder Dach; dazu die Textur-Ebene samt Tangenten.
	float roof = smoothstep(0.22, 0.4, ay) * (1.0 - smoothstep(0.88, 0.96, ay)) * tiles_on_slopes;
	float level = smoothstep(0.88, 0.96, ay);
	vec2 uv;
	vec3 t;
	vec3 b;
	if (ay > 0.92) {
		uv = world_pos.xz;
		t = vec3(1.0, 0.0, 0.0);
		b = vec3(0.0, 0.0, 1.0);
	} else if (ay < 0.3) {
		if (abs(n.x) > abs(n.z)) {
			uv = vec2(world_pos.z, -world_pos.y);
			t = vec3(0.0, 0.0, 1.0);
			b = vec3(0.0, -1.0, 0.0);
		} else {
			uv = vec2(world_pos.x, -world_pos.y);
			t = vec3(1.0, 0.0, 0.0);
			b = vec3(0.0, -1.0, 0.0);
		}
	} else {
		// Dach: Ziegelreihen quer zum Gefälle, Ziegel den Hang hinab.
		vec2 down = normalize(n.xz);
		vec2 across = vec2(-down.y, down.x);
		uv = vec2(dot(world_pos.xz, across), dot(world_pos.xz, down) / max(0.2, sqrt(1.0 - ay * ay) + 0.001) * 0.7 - world_pos.y * 0.5);
		t = vec3(across.x, 0.0, across.y);
		b = normalize(cross(n, t));
	}
	// Material aus der Farbe: braun = Holz, grau = Stein, sonst Putz.
	float mx = max(albedo.r, max(albedo.g, albedo.b));
	float mn = min(albedo.r, min(albedo.g, albedo.b));
	float sat = (mx - mn) / max(mx, 0.001);
	// Holz: Brauntöne (Farbton 14–56°, gesättigt, nicht hell) – Laternen (rot) und Putz (hell) bleiben außen vor.
	float hue = 60.0 * (albedo.g - albedo.b) / max(albedo.r - albedo.b, 0.001);
	float brown = smoothstep(14.0, 20.0, hue) * (1.0 - smoothstep(48.0, 56.0, hue)) * step(albedo.b, albedo.g) * smoothstep(0.25, 0.35, sat) * (1.0 - smoothstep(0.72, 0.82, mx));
	float gray = (1.0 - smoothstep(0.08, 0.2, sat)) * (1.0 - smoothstep(0.55, 0.75, mx));
	float wood = brown * (1.0 - roof);
	float stone = gray * (1.0 - roof) * (1.0 - wood);
	float plaster = max(0.0, 1.0 - roof - wood - stone);
	float d = texture(plaster_tex, uv * plaster_scale).r * plaster + texture(wood_tex, uv * wood_scale).r * wood
		+ texture(tiles_tex, uv * tiles_scale).r * roof + texture(stone_tex, uv * stone_scale).r * stone;
	vec3 nm = texture(plaster_nm, uv * plaster_scale).xyz * plaster + texture(wood_nm, uv * wood_scale).xyz * wood
		+ texture(tiles_nm, uv * tiles_scale).xyz * roof + texture(stone_nm, uv * stone_scale).xyz * stone;
	float contrast = 0.35 * plaster + 0.7 * wood + 1.0 * roof + 0.8 * stone;
	float lum = mix(1.0, 1.0 + (d - 0.5) * contrast, near);
	float strength = (0.5 * plaster + 0.8 * wood + 1.4 * roof + 1.0 * stone) * near;
	vec3 n_out = perturb(n, t, b, nm, strength);
	// Dachziegel wirken auf hellen Dächern zu grell: Ziegel leicht abdunkeln.
	albedo *= lum * mix(1.0, 0.92, roof);
	ALBEDO = albedo;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_out, 0.0)).xyz);
	ROUGHNESS = mix(0.95, 0.75, roof + wood * 0.5);
	SPECULAR = 0.12 + 0.1 * roof;
	// Laternen (glow.y = 0) leuchten über Weiß hinaus, damit der Glow-Effekt sie umstrahlt.
	vec3 light = mix(albedo * 2.2, window_light * 1.2, glow.y);
	EMISSION = light * glow.x * night_glow;
}
