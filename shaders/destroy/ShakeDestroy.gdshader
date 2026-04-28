shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float duration : hint_range(0.1, 2.0) = 0.5;
uniform vec2 shake_offset = vec2(5.0, 5.0);
uniform int shake_loops = 3;
uniform float fade_delay : hint_range(0.0, 1.0) = 0.1;
uniform float final_shrink : hint_range(0.0, 1.0) = 0.2;

float shake(float t, float freq, float amp) {
	return sin(t * freq) * amp;
}

void fragment() {
	float p = clamp(progress, 0.0, 1.0);

	float shake_phase = p * float(shake_loops) * 6.28318;
	float shake_x = shake(shake_phase, 20.0, shake_offset.x / 100.0);
	float shake_y = shake(shake_phase + 1.57, 20.0, shake_offset.y / 100.0);

	float shrink = smoothstep(0.0, 0.6, p) * (1.0 - final_shrink) + final_shrink;

	vec2 offset_uv = UV + vec2(shake_x, shake_y);
	vec2 centered_uv = (offset_uv - vec2(0.5)) / shrink + vec2(0.5);

	if (centered_uv.x < 0.0 || centered_uv.x > 1.0 || centered_uv.y < 0.0 || centered_uv.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, centered_uv);
		float fade_start = 0.6;
		float alpha = smoothstep(fade_start, 1.0, p);
		COLOR.a *= (1.0 - alpha);
	}
}