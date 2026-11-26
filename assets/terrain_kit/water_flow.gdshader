shader_type canvas_item;
render_mode unshaded;
uniform vec2 flow_direction = vec2(0.035, 0.07);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.12;

void fragment() {
	vec2 drift = UV + TIME * flow_direction;
	vec4 water = texture(TEXTURE, drift);
	float ripple = pow(max(0.0, sin(drift.x * 65.0 + sin(drift.y * 31.0))), 18.0);
	water.rgb = mix(water.rgb, vec3(0.88, 1.0, 1.0), ripple * foam_amount);
	COLOR = water * COLOR;
}
