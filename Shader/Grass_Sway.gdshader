shader_type canvas_item;

// 控制参数（可通过编辑器调节）
uniform float speed = 1.0;       // 摆动速度
uniform float frequency = 2.0;   // 波形频率
uniform float amplitude = 0.1;   // 摆动幅度
uniform vec2 wind_direction = vec2(1.0, 0.5); // 风向向量

void vertex() {
    // 基础摆动公式：正弦波
    float wave = sin(TIME * speed + VERTEX.x * frequency) * amplitude;
    
    // 根据UV的Y坐标增加顶部摆动幅度（假设顶部在UV坐标顶部）
    float vertical_factor = 1.0 - UV.y; // 调整这里
    
    // 组合偏移量（加入随机噪声让运动更自然）
    vec2 offset = vec2(
        wave * wind_direction.x,
        wave * wind_direction.y * 0.5
    ) * vertical_factor;
    
    // 应用顶点偏移
    VERTEX += offset;
}

// 可选：添加颜色变化（例如顶部颜色随摆动变化）
void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    float color_variation = sin(TIME * 2.0 + UV.x * 5.0) * 0.1;
    COLOR = base_color * vec4(1.0, 1.0 + color_variation, 1.0, 1.0);
}