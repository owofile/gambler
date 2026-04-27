extends CharacterBody2D

#BUG
#在正式使用的时候可以通过遍历将PlayerTest下的所有spite翻转来实现另一方向移动，而不是直接翻转动画整个节点

# 定义状态
enum State {
	IDLE,
	LEFT,
	RIGHT,
	UP,
	DOWN
}

# 移动参数
@export var SPEED = 50.0
const JUMP_VELOCITY = -400.0
const STEP_DURATION = 0.15

# 节点引用
@onready var playerTest = $PlayerTest
@onready var animation_player: AnimationPlayer = playerTest.get_node("AnimationPlayer")

# 运动模糊控制参数
@export var max_blur_strength: float = 0.03    # 最大模糊强度
@export var blur_speed_factor: float = 0.5     # 速度对模糊的影响系数

# 状态变量
var moving_direction = 0
var step_timer = 0.0
var motion_blur_material: ShaderMaterial       # 着色器材质引用
@export var current_state: State = State.IDLE          # 当前状态

func _ready():
	# 初始化运动模糊材质
	if playerTest.material is ShaderMaterial:
		#print(playerTest.material)
		motion_blur_material = playerTest.material
	else:
		# 自动创建材质如果未设置
		motion_blur_material = ShaderMaterial.new()
		motion_blur_material.shader = preload("res://scenes/Thryzhn/Player/test/shader/motion_blur.gdshader")
		playerTest.material = motion_blur_material

func _physics_process(delta: float) -> void:
	# 处理输入
	var direction = Input.get_axis("ui_left", "ui_right")
	var vertical_direction = Input.get_axis("ui_up", "ui_down")

	# 获取下一个状态
	var next_state = get_next_state(current_state)

	# 如果状态发生变化，则更新状态并打印
	if current_state != next_state:
		current_state = next_state
		print_current_state()

	# 水平移动逻辑
	if direction != 0:
		moving_direction = direction
		step_timer -= delta
		if step_timer <= 0.0:
			velocity.x = direction * SPEED
			step_timer = STEP_DURATION
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		moving_direction = 0

	# 垂直移动
	velocity.y = vertical_direction * SPEED * 2

	# 执行移动
	move_and_slide()

	# 防穿透逻辑
	if get_last_slide_collision():
		velocity = Vector2.ZERO

	# 更新动画和模糊效果
	_update_animation()
	_update_motion_blur()

func _update_animation() -> void:
	pass

func _update_motion_blur():
	if not motion_blur_material:
		return

	# 计算当前速度强度
	var speed_factor = clamp(abs(velocity.x) / SPEED, 0.0, 1.0)
	
	if moving_direction != 0 && speed_factor > 0.1:
		# 设置模糊参数
		var blur_intensity = speed_factor * max_blur_strength
		var blur_dir = Vector2(moving_direction * blur_speed_factor, 0.0)
		
		motion_blur_material.set_shader_parameter("blur_strength", blur_intensity)
		motion_blur_material.set_shader_parameter("blur_direction", blur_dir)
	else:
		# 静止时禁用模糊
		motion_blur_material.set_shader_parameter("blur_strength", 0.0)

func get_next_state(state: State) -> State:
	var direction = Input.get_axis("ui_left", "ui_right")
	var vertical_direction = Input.get_axis("ui_up", "ui_down")
	
	match state:
		State.IDLE:
			if direction < 0:
				return State.LEFT
			elif direction > 0:
				return State.RIGHT
			elif vertical_direction < 0:
				return State.UP
			elif vertical_direction > 0:
				return State.DOWN
		State.LEFT:
			if direction == 0:
				return State.IDLE
		State.RIGHT:
			if direction == 0:
				return State.IDLE
		State.UP:
			if vertical_direction == 0:
				return State.IDLE
		State.DOWN:
			if vertical_direction == 0:
				return State.IDLE
	
	return state

func transition_state(from: State, to: State) -> void:
	match to:
		State.IDLE:
			velocity = Vector2.ZERO
			animation_player.play("hello/Idle", 0.1)
			animation_player.set_speed_scale(0.3)
		State.LEFT:
			velocity.x = -SPEED
			if not playerTest.is_flipped:  # 检查是否已经翻转
				playerTest.scale.x *= -1  # 翻转整个节点的 X 轴
				playerTest.is_flipped = true  # 更新翻转状态
			animation_player.play("hello/walk", 0.1)
			animation_player.set_speed_scale(6.0)
			
		State.RIGHT:
			velocity.x = SPEED
			if playerTest.is_flipped:
				playerTest.scale.x *= -1
				playerTest.is_flipped = false
			animation_player.play("hello/walk", 0.1)
			animation_player.set_speed_scale(6.0)
		State.UP:
			velocity.y = -SPEED
			animation_player.play("hello/walk", 0.1)
			animation_player.set_speed_scale(6.0)
		State.DOWN:
			velocity.y = SPEED
			animation_player.play("hello/walk", 0.1)
			animation_player.set_speed_scale(6.0)

func tick_physics(state: State, delta: float) -> void:
	pass

func print_current_state() -> void:
	print(get_current_state_str())

func get_current_state_str() -> String:
	return "当前状态: %s" % [State.keys()[current_state]]
