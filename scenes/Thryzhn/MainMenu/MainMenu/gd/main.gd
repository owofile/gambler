extends Control

#主菜单
@onready var start = $start
@onready var settings = $settings
@onready var arrow = $arrow

#SFX
@onready var UI_Button_Hover_01 = $UI_Button_Hover_01

# 当前选中的按钮索引
var current_selection: int = 0

#0: 开始游戏
#1: 设置
# 可选按钮的数量
const OPTION_COUNT = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_settings_once()
	update_selection()

func _load_settings_once() -> void:
	var settings_manager = preload("res://scenes/Thryzhn/UI_Scenes/settings/gd/settingsManager.gd").new()
	settings_manager.load_settings()
	settings_manager.apply_settings()
	settings_manager.free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 检测左右键输入
	if Input.is_action_just_pressed("ui_right"):
		# 尝试向右移动
		if current_selection < OPTION_COUNT - 1:
			current_selection += 1
			update_selection()
		await get_tree().create_timer(0.2).timeout  # 防止按键重复触发

	if Input.is_action_just_pressed("ui_left"):
		# 尝试向左移动
		if current_selection > 0:
			current_selection -= 1
			update_selection()
		await get_tree().create_timer(0.2).timeout  # 防止按键重复触发
	# 检测确认
	update_accept()

# 更新选中状态的逻辑
func update_selection() -> void:
	#播放音效
	UI_Button_Hover_01.play()
	print(current_selection)
	# 根据 current_selection 的值更新箭头位置或其他视觉反馈
	match current_selection:
		0:
			# 更新为选中“开始游戏”按钮的逻辑
			arrow.position = Vector2(521,422)
			pass
		1:
			# 更新为选中“设置”按钮的逻辑
			arrow.position = Vector2(657,422)
			pass

func update_accept() -> void:
	if Input.is_action_just_released("ui_accept"):
		print("accept" + "选中了" + str(current_selection))
		if current_selection == 0:
			_start_game()
		if current_selection == 1:
			#进入settings
			SceneChanger.scene_changer("res://scenes/Thryzhn/MainMenu/MainMenu/settings.tscn")
		pass

func _start_game() -> void:
	print("[MainMenu] 开始新游戏")

	WorldState.clear_all_flags()
	CardMgr.clear_all_cards()

	SaveManager.auto_save()
	print("[MainMenu] 存档已创建，卡牌背包已初始化")

	SceneChanger.scene_changer("res://scenes/Thryzhn/TestScenes/cave/cave/cave.tscn")
