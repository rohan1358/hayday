shader_type canvas_item;
// Shared, single texture sample. No screen capture or per-frame image processing.
uniform float saturation = 1.10;
uniform float contrast = 1.025;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 c = texture(TEXTURE, UV) * vertex_tint;
	float y = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 vivid = mix(vec3(y), c.rgb, saturation);
	float leaf = smoothstep(0.025, 0.18, c.g - max(c.r, c.b));
	vivid *= mix(vec3(1.0), vec3(0.94, 0.98, 1.03), leaf);
	vivid = (vivid - 0.5) * contrast + 0.5;
	vivid += vec3(0.012, 0.006, 0.0) * smoothstep(0.25, 0.9, y);
	COLOR = vec4(clamp(vivid, vec3(0.0), vec3(1.0)), c.a);
}
