extends Control

#主菜单 图标
@onready var menu = $menu
#Arrow
@onready var arrow = $arrow
#BGM
@onready var BGM_icon = $BGM_icon
@onready var BGM_box = $BGM_box
#SFX
@onready var SFX_icon = $SFX_icon
@onready var SFX_box = $SFX_box
#SwitchDevice
@onready var SwitchDevice_Controller = $SwitchDevice_Controller
@onready var SwitchDevice_Keyboard = $SwitchDevice_Keyboard
#Effects
@onready var Effects = $Effects
#Language
@onready var Language = $Language
#Exit
@onready var Exit = $Exit

#特殊动效 音量电池
#BGM
@onready var BGM_HBoxContainer = $BGM_HBoxContainer
@onready var BGM_Volumebattery = $BGM_HBoxContainer/BGM_Volumebattery
@onready var BGM_Volumebattery2 = $BGM_HBoxContainer/BGM_Volumebattery2
@onready var BGM_Volumebattery3 = $BGM_HBoxContainer/BGM_Volumebattery3
@onready var BGM_Volumebattery4 = $BGM_HBoxContainer/BGM_Volumebattery4
@onready var BGM_Volumebattery5 = $BGM_HBoxContainer/BGM_Volumebattery5
@onready var BGM_Volumebattery6 = $BGM_HBoxContainer/BGM_Volumebattery6
@onready var BGM_Volumebattery7 = $BGM_HBoxContainer/BGM_Volumebattery7
@onready var BGM_Volumebattery8 = $BGM_HBoxContainer/BGM_Volumebattery8
@onready var BGM_Volumebattery9 = $BGM_HBoxContainer/BGM_Volumebattery9
@onready var BGM_Volumebattery10 = $BGM_HBoxContainer/BGM_Volumebattery10
@onready var BGM_Volumebattery11 = $BGM_HBoxContainer/BGM_Volumebattery11
@onready var BGM_Volumebattery12 = $BGM_HBoxContainer/BGM_Volumebattery12
@onready var BGM_Volumebattery13 = $BGM_HBoxContainer/BGM_Volumebattery13
@onready var BGM_Volumebattery14 = $BGM_HBoxContainer/BGM_Volumebattery14
#SFX
@onready var SFX_HBoxContainer = $SFX_HBoxContainer
@onready var SFX_Volumebattery = $SFX_HBoxContainer/SFX_Volumebattery
@onready var SFX_Volumebattery2 = $SFX_HBoxContainer/SFX_Volumebattery2
@onready var SFX_Volumebattery3 = $SFX_HBoxContainer/SFX_Volumebattery3
@onready var SFX_Volumebattery4 = $SFX_HBoxContainer/SFX_Volumebattery4
@onready var SFX_Volumebattery5 = $SFX_HBoxContainer/SFX_Volumebattery5
@onready var SFX_Volumebattery6 = $SFX_HBoxContainer/SFX_Volumebattery6
@onready var SFX_Volumebattery7 = $SFX_HBoxContainer/SFX_Volumebattery7
@onready var SFX_Volumebattery8 = $SFX_HBoxContainer/SFX_Volumebattery8
@onready var SFX_Volumebattery9 = $SFX_HBoxContainer/SFX_Volumebattery9
@onready var SFX_Volumebattery10 = $SFX_HBoxContainer/SFX_Volumebattery10
@onready var SFX_Volumebattery11 = $SFX_HBoxContainer/SFX_Volumebattery11
@onready var SFX_Volumebattery12 = $SFX_HBoxContainer/SFX_Volumebattery12
@onready var SFX_Volumebattery13 = $SFX_HBoxContainer/SFX_Volumebattery13
@onready var SFX_Volumebattery14 = $SFX_HBoxContainer/SFX_Volumebattery14

#音效
@onready var UI_Button_Hover_01 = $UI_Button_Hover_01
@onready var UI_Button_Hover_02 = $UI_Button_Hover_02

#设置控制器

@onready var settingmanger = preload("res://scenes/Thryzhn/UI_Scenes/settings/gd/settingsManager.gd").new()



#BUG
#音效播放和场景切换重叠后音效播放一半会卡

# 当前选中的按钮索引
# current_accept默认大于OPTION_COUNT 这是为了在初始化时不选中任何选项
var current_selection: int = 0
var current_accept: int = 7

#0: 开始游戏
#1: 设置
# 可选按钮的数量
const OPTION_COUNT = 6

# 音量控制变量
var bgm_volume: int = 14
var sfx_volume: int = 14
var bgm_batteries: Array = []
var sfx_batteries: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 初始化电池节点
	initialize_batteries()
	load_settings()  # 新增：加载设置
	update_volume_display()
	update_selection()


# 核心修正1：电池节点初始化与排序
func initialize_batteries():
	# BGM电池排序（处理无数字的根节点）
	bgm_batteries = BGM_HBoxContainer.get_children()
	bgm_batteries.sort_custom(func(a, b):
		# 第一个节点名称是纯"BGM_Volumebattery"视为1号电池
		var a_num = a.name.replace("BGM_Volumebattery", "")
		var b_num = b.name.replace("BGM_Volumebattery", "")
		a_num = "1" if a_num == "" else a_num
		b_num = "1" if b_num == "" else b_num
		return a_num.to_int() < b_num.to_int()
	)
	
	# SFX电池排序（同上逻辑）
	sfx_batteries = SFX_HBoxContainer.get_children()
	sfx_batteries.sort_custom(func(a, b):
		var a_num = a.name.replace("SFX_Volumebattery", "")
		var b_num = b.name.replace("SFX_Volumebattery", "")
		a_num = "1" if a_num == "" else a_num
		b_num = "1" if b_num == "" else b_num
		return a_num.to_int() < b_num.to_int()
	)

# 核心修正2：音量显示同步
func update_volume_display():
	# BGM显示（从左到右对应索引0-13）
	for i in range(bgm_batteries.size()):
		var battery = bgm_batteries[i]
		battery.visible = (i < bgm_volume)  # 音量值直接对应显示数量
	
	# SFX显示（同上逻辑）
	for i in range(sfx_batteries.size()):
		var battery = sfx_batteries[i]
		battery.visible = (i < sfx_volume)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 检测左右键输入
	if Input.is_action_just_pressed("ui_down"):
		# 尝试向右移动
		if current_selection < OPTION_COUNT - 1:
			current_selection += 1
			update_selection()
		await get_tree().create_timer(0.2).timeout  # 防止按键重复触发

	if Input.is_action_just_pressed("ui_up"):
		# 尝试向左移动
		if current_selection > 0:
			current_selection -= 1
			update_selection()
		await get_tree().create_timer(0.2).timeout  # 防止按键重复触发
	# 检测确认
	update_accept()
	update_handle_selection_accept()

# 更新选中状态的逻辑
func update_selection() -> void:
	# 默认将所有图标的透明度降低
	reset_icons_opacity()
	UI_Button_Hover_01.play()
	
	# 根据 current_selection 的值更新箭头位置并高亮选中项
	match current_selection:
		0:
			arrow.position = Vector2(35, 76)
			highlight_icon(BGM_icon)  # 高亮选中的图标
			highlight_icon(BGM_box)
			highlight_icons_in_container(BGM_HBoxContainer)
			pass
		1:
			arrow.position = Vector2(35, 176)
			highlight_icon(SFX_icon)  # 高亮选中的图标
			highlight_icon(SFX_box)
			highlight_icons_in_container(SFX_HBoxContainer)
			pass
		2:
			arrow.position = Vector2(35, 279)
			highlight_icon(SwitchDevice_Controller)  # 高亮选中的图标
			highlight_icon(SwitchDevice_Keyboard)
			pass
		3:
			arrow.position = Vector2(35, 387)
			highlight_icon(Effects)  # 高亮选中的图标
			pass
		4:
			arrow.position = Vector2(35, 483)
			highlight_icon(Language)  # 高亮选中的图标
			pass
		5:
			arrow.position = Vector2(35, 577)
			highlight_icon(Exit)  # 高亮选中的图标
			pass

# 高亮选中图标（透明度恢复）
func highlight_icon(icon: Sprite2D) -> void:
	icon.modulate = Color(1, 1, 1, 1)  # 恢复透明度

# 高亮选中图标（透明度恢复）
func highlight_icons_in_container(container: HBoxContainer) -> void:
	container.modulate = Color(1,1,1,1)

# 重置所有图标的透明度
func reset_icons_opacity() -> void:
	var icons = [BGM_icon,BGM_box,BGM_HBoxContainer, SFX_icon,SFX_box,SFX_HBoxContainer, SwitchDevice_Controller,SwitchDevice_Keyboard, Effects, Language, Exit]
	for icon in icons:
		icon.modulate = Color(1, 1, 1, 0.5)  # 默认透明度降低

# 在Settings场景的脚本中添加
signal settings_closed

func update_accept() -> void:
	if Input.is_action_just_released("ui_accept"):
		print("accept" + "选中了" + str(current_selection))
		UI_Button_Hover_02.play()
		if current_selection == 0:
			current_accept = 0
			#BGM
			pass
		if current_selection == 1:
			current_accept = 1
			#SFX
			pass
		if current_selection == 2:
			current_accept = 2
			#SwitchDevice
			pass
		if current_selection == 3:
			current_accept = 3
			#Effects
			pass
		if current_selection == 4:
			current_accept = 4
			#Language
			pass
		if current_selection == 5:
			current_accept = 3
			#Exit
			emit_signal("settings_closed")
			save_settings()
			SceneChanger.scene_changer("res://scenes/Thryzhn/MainMenu/MainMenu/main.tscn")
			pass
	pass
	
# 处理选中后的操作
func update_handle_selection_accept() -> void:
	match current_accept:
		0:  # 正在调整BGM
			handle_volume_adjustment("bgm")
		1:  # 正在调整SFX
			handle_volume_adjustment("sfx")
		2:  # SwitchDevice
			print("当前在控制2")
		3:  # Effects
			print("当前在控制3")
		4:  # Language
			print("当前在控制4")
		5:  # Exit
			print("当前在控制5")

# 核心修正3：音量调整逻辑
func handle_volume_adjustment(volume_type: String):
	var current_volume = bgm_volume if volume_type == "bgm" else sfx_volume
	var max_volume = 14
	
	# 音量增减处理
	if Input.is_action_just_pressed("ui_right"):
		current_volume = min(current_volume + 1, max_volume)
		UI_Button_Hover_01.play()
	elif Input.is_action_just_pressed("ui_left"):
		current_volume = max(current_volume - 1, 0)
		UI_Button_Hover_01.play()
	
	# 更新对应音量
	if volume_type == "bgm":
		bgm_volume = current_volume
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("BGM"), 
			linear_to_db(current_volume / 14.0)
		)
		print("这是正确的音频获取BGM：" + str(linear_to_db(current_volume / 14.0)))
	else:
		sfx_volume = current_volume
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("SFX"), 
			linear_to_db(current_volume / 14.0)
		)
		print("这是正确的音频获取SFX：" + str(linear_to_db(current_volume / 14.0)))
	
	# 确保每次音量调整后更新电池显示
	update_volume_display()
	print_debug("当前%s音量: %d/14 | 显示电池数: %d" % [
		volume_type.to_upper(), 
		current_volume, 
		current_volume  # 直接等于显示数量
	])

# 新增：电池到百分比的转换函数
func battery_to_percentage(battery_count: int) -> float:
	return (battery_count / 14.0) * 100

func percentage_to_battery(percentage: float) -> int:
	return int((percentage / 100) * 14)

# 新增：加载设置的方法
func load_settings() -> void:
	# 从配置文件中读取百分比值
	settingmanger.load_settings()
	var bgm_percentage = settingmanger.bgm_volume
	var sfx_percentage = settingmanger.sfx_volume
	
	# 将百分比转换为电池数量
	bgm_volume = percentage_to_battery(bgm_percentage)
	sfx_volume = percentage_to_battery(sfx_percentage)
	
	print("Loaded settings: BGM Volume = %d/14 (%.2f%%), SFX Volume = %d/14 (%.2f%%)" % [
		bgm_volume, battery_to_percentage(bgm_volume),
		sfx_volume, battery_to_percentage(sfx_volume)
	])

# 保存设置的函数
func save_settings() -> void:
	# 将电池数量转换为百分比
	var bgm_percentage = battery_to_percentage(bgm_volume)
	var sfx_percentage = battery_to_percentage(sfx_volume)
	
	print("Saving settings: BGM Volume = %d/14 (%.2f%%), SFX Volume = %d/14 (%.2f%%)" % [
		bgm_volume, bgm_percentage,
		sfx_volume, sfx_percentage
	])
	
	# 保存百分比值到配置文件
	settingmanger.bgm_volume = bgm_percentage
	settingmanger.sfx_volume = sfx_percentage
	settingmanger.save_settings()
