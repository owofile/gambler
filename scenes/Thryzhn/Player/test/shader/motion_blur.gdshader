shader_type canvas_item;

uniform float blur_strength : hint_range(0, 1.0) = 0.0;
uniform vec2 blur_direction = vec2(1.0, 0.0);

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // 增加采样次数和动态步长
    int samples = 8; // 采样次数从5提升到8
    float step = 1.0 / float(samples);

    for(int i = 1; i <= samples; i++){
        float weight = 1.0 - (float(i)/float(samples)); // 线性衰减权重
        vec2 offset = blur_direction * blur_strength * float(i);

        color += texture(TEXTURE, UV + offset) * weight;
        color += texture(TEXTURE, UV - offset) * weight;
    }

    // 动态归一化（根据实际采样次数调整）
    color /= float(samples * 2 + 1);
    COLOR = color;
}