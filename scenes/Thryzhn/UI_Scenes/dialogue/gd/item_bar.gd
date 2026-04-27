extends Control

@onready var controls = [
	$Left_Arrow,    # 索引0 → 1号
	$ItemSlot1,     # 索引1 → 2号
	$ItemSlot2,     # 索引2 → 3号 
	$ItemSlot3,     # 索引3 → 4号
	$Right_Arrow    # 索引4 → 5号
]

var current_index = 2  # 默认选中中间项（数组索引2对应3号）

#待修改
#实现多页现实和高度自定义

func _ready() -> void:
	update_highlight()
	print("初始位置：", current_index + 1)

# 视觉更新方法（在这里添加你的效果逻辑）
func update_highlight():
	for i in range(controls.size()):
		var control = controls[i]
		if i == current_index:
			# 在此添加选中状态的视觉效果
			# 示例：修改透明度
			control.modulate.a = 1.0
			# 或者使用动画（需先定义动画）
			# $AnimationPlayer.play("selected_effect") 
		else:
			# 在此添加非选中状态的视觉效果
			control.modulate.a = 0.6

# 定义信号
signal on_item_selected(index: int)

func _process(delta: float) -> void:
	# 左右切换
	if Input.is_action_just_pressed("ui_left"):
		current_index = max(0, current_index - 1)
		print("切换到：", current_index + 1)
		update_highlight()
	
	if Input.is_action_just_pressed("ui_right"):
		current_index = min(controls.size() - 1, current_index + 1)
		print("切换到：", current_index + 1)
		update_highlight()
	
	# 确认功能
	if Input.is_action_just_pressed("ui_accept"):
		match current_index + 1:
			1: 
				print("[Left_Arrow] 执行功能")
				emit_signal("on_item_selected", 1)
			2: 
				print("[ItemSlot1] 执行功能")
				emit_signal("on_item_selected", 2)
			3: print("[ItemSlot2] 执行功能")
			4: print("[ItemSlot3] 执行功能")
			5: print("[Right_Arrow] 执行功能")
