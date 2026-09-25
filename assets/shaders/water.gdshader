// Wasserfläche (Seen, Quellen, Flüsse, Meer): zwei gegenläufig ziehende Wellen-Normal-Maps (ProceduralTextures),
// Himmelsspiegelung nach Blickwinkel (sky_color setzt DayNight), Sonnenglanz, Tiefenfarbe; optional leuchtend
// (Geisterquelle). Flüsse (flow > 0, UV.x quer, UV.y längs in Metern / 4): ziehende Schaumflecken und Gischt am Ufer.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 shallow_color : source_color = vec4(0.25, 0.55, 0.55, 1.0);
uniform vec4 deep_color : source_color = vec4(0.06, 0.2, 0.26, 1.0);
uniform vec3 sky_color : source_color = vec3(0.6, 0.75, 0.85);
uniform float glow = 0.0;
uniform float alpha = 0.82;
uniform float flow = 0.0;
uniform sampler2D waves_nm : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 world_pos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = TIME;
	// Flüsse: Wellen ziehen mit dem Wasser; Seen: zwei Richtungen gegeneinander.
	vec2 drift = flow > 0.0 ? vec2(0.0, -flow * 0.12) : vec2(0.02, 0.014);
	vec2 uv_a = (flow > 0.0 ? UV * vec2(3.0, 1.0) : p * 0.07) + t * drift;
	vec2 uv_b = (flow > 0.0 ? UV * vec2(5.0, 1.7) + vec2(0.3, 0.0) : p * 0.16) + t * (flow > 0.0 ? drift * 1.6 : vec2(-0.017, 0.024));
	vec3 na = texture(waves_nm, uv_a).xyz * 2.0 - 1.0;
	vec3 nb = texture(waves_nm, uv_b).xyz * 2.0 - 1.0;
	float dist = length(world_pos - CAMERA_POSITION_WORLD);
	float calm = mix(1.0, 0.25, smoothstep(30.0, 200.0, dist));
	vec3 nw = normalize(vec3((na.x + nb.x * 0.6) * 0.28 * calm, 1.0, (na.y + nb.y * 0.6) * 0.28 * calm));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 3.0);
	// Wasser selbst ist dunkel; was hell wirkt, ist der gespiegelte Himmel (flach am stärksten).
	vec3 color = mix(deep_color.rgb, shallow_color.rgb, 0.05 + 0.2 * fresnel);
	color = mix(color, sky_color, 0.4 * fresnel);
	if (flow > 0.0) {
		float along = UV.y - t * flow;
		float n = noise2(vec2(UV.x * 5.0, along * 0.9)) * 0.65 + noise2(vec2(UV.x * 11.0 + 3.0, along * 2.1)) * 0.35;
		float streak = smoothstep(0.62, 0.9, n) * 0.45;
		float edge = 1.0 - smoothstep(0.0, 0.12, min(UV.x, 1.0 - UV.x));
		color = mix(color, vec3(0.86, 0.84, 0.78), clamp(streak + edge * 0.5, 0.0, 0.6));
	}
	ALBEDO = color;
	ROUGHNESS = 0.18;
	SPECULAR = 0.5;
	EMISSION = shallow_color.rgb * glow * (0.7 + 0.3 * sin(t * 2.0 + p.x * 0.5));
	ALPHA = mix(alpha, 0.97, fresnel);
}
