// Kultivierungs-Aura: aufsteigende, flackernde Lichtsäule in Rangfarbe (additiv, unbeleuchtet).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 aura_color : source_color = vec4(0.5, 0.9, 0.5, 1.0);
uniform float intensity = 1.0;
uniform float speed = 1.5;

void fragment() {
	// UV.y: 0 oben, 1 unten (CylinderMesh). Unten kräftig, nach oben ausblendend.
	float up = 1.0 - UV.y;
	float fade = smoothstep(0.0, 0.25, UV.y) * (1.0 - smoothstep(0.35, 1.0, up));
	float bands = 0.55 + 0.45 * sin(UV.x * 6.2831 * 7.0 + TIME * speed * 2.0 + up * 9.0);
	float rise = 0.6 + 0.4 * sin(up * 14.0 - TIME * speed * 4.0);
	ALBEDO = aura_color.rgb;
	ALPHA = clamp(intensity * fade * bands * rise * aura_color.a, 0.0, 1.0);
}
