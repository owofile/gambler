extends Node2D

# Shader 路径（需自行填写实际路径）
var shader_path := "res://Shader/Grass_Sway.gdshader"

# Shader 控制参数（可在此处调整）
@export var speed: float = 4.0  # 摆动速度
@export var frequency: float = 2.0  # 波形频率
@export var amplitude: float = 1  # 摆动幅度
@export var wind_direction: Vector2 = Vector2(2.0, 2.0)  # 风向向量

func _ready():
	# 遍历 grass 节点
	for i in range(1, 25):
		var node_name := "grass"
		if i > 1:
			node_name += str(i)
		var node = get_node(node_name)
		if node and node is Sprite2D:
			# 挂载 Shader
			var shader = load(shader_path)
			var shader_material = ShaderMaterial.new()
			shader_material.shader = shader
			
			# 设置 Shader 参数
			shader_material.set_shader_parameter("speed", speed)
			shader_material.set_shader_parameter("frequency", frequency)
			shader_material.set_shader_parameter("amplitude", amplitude)
			shader_material.set_shader_parameter("wind_direction", wind_direction)
			
			# 应用材质
			node.material = shader_material
		else:
			print("节点 grass", i, "不存在")
