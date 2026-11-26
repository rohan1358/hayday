shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	// Select blue water only; the banks, flowers and trees stay still.
	float water = smoothstep(0.04, 0.20, base.b - base.r)
		* smoothstep(0.02, 0.16, base.g - base.r) * base.a;
	vec2 drift = vec2(sin(UV.y * 100.0 - TIME * 3.0),
		cos(UV.x * 130.0 + TIME * 4.0)) * 0.0018 * water;
	vec4 moving = texture(TEXTURE, UV + drift);
	float still_water = smoothstep(0.04, 0.20, moving.b - moving.r)
		* smoothstep(0.02, 0.16, moving.g - moving.r);
	vec3 rgb = mix(base.rgb, moving.rgb, water * still_water * 0.65);
	// Traveling foam follows the river downhill from upper right to lower left.
	float stream = pow(max(0.0, sin((UV.x - UV.y) * 170.0 + TIME * 4.5)), 16.0);
	float spray = pow(max(0.0, sin(UV.x * 267.0 + UV.y * 193.0 - TIME * 6.0)), 28.0);
	rgb = mix(rgb, vec3(0.90, 1.0, 1.0), water * (stream * 0.22 + spray * 0.16));
	COLOR = vec4(rgb, base.a) * COLOR;
}
