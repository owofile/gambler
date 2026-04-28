shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float duration : hint_range(0.1, 2.0) = 0.3;
uniform vec2 shrink_scale = vec2(0.01, 0.01);
uniform float alpha_fade_start : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float p = clamp(progress, 0.0, 1.0);

	vec2 scale = mix(vec2(1.0, 1.0), shrink_scale, smoothstep(0.0, 1.0, p));

	vec2 centered_uv = UV - vec2(0.5);
	centered_uv *= scale;
	centered_uv += vec2(0.5);

	if (centered_uv.x < 0.0 || centered_uv.x > 1.0 || centered_uv.y < 0.0 || centered_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = texture(TEXTURE, centered_uv);
		float alpha_fade = smoothstep(alpha_fade_start, 1.0, p);
		COLOR.a *= (1.0 - alpha_fade);
	}
}