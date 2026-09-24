// Wasserfläche (Seen, Quellen): Farbverlauf nach Blickwinkel, sanfte Wellen und Glanz; optional leuchtend (Geisterquelle).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 shallow_color : source_color = vec4(0.25, 0.55, 0.55, 1.0);
uniform vec4 deep_color : source_color = vec4(0.06, 0.2, 0.26, 1.0);
uniform float glow = 0.0;
uniform float alpha = 0.82;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = TIME;
	vec3 wave = vec3(
		sin(p.x * 0.9 + t * 1.1) * 0.5 + sin(p.x * 2.3 + p.y * 1.1 - t * 1.7) * 0.25,
		8.0,
		sin(p.y * 0.8 - t * 1.3) * 0.5 + sin(p.y * 2.1 - p.x * 0.9 + t * 1.5) * 0.25);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(wave), 0.0)).xyz);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 3.0);
	vec3 color = mix(deep_color.rgb, shallow_color.rgb, 0.2 + 0.5 * fresnel);
	ALBEDO = color;
	ROUGHNESS = 0.2;
	SPECULAR = 0.12 + 0.3 * fresnel;
	EMISSION = shallow_color.rgb * glow * (0.7 + 0.3 * sin(t * 2.0 + p.x * 0.5));
	ALPHA = alpha;
}
