# settings_manager.gd
extends Node

# 默认配置（用于首次运行或缺失字段）
const DEFAULT_SETTINGS = {
	"audio": {
		"bgm_volume": 40.0,
		"sfx_volume": 70.0
	},
	"input": {
		"controller_device": "keyboard"  # 可选值："keyboard", "controller"
	},
	"graphics": {
		"effects": "high"  # 可选值："low", "medium", "high"
	},
	"system": {
		"language": "en"  # 示例值："en", "zh", "ja" 等
	}
}

# 当前配置变量（通过 getter/setter 访问）
var bgm_volume: float = DEFAULT_SETTINGS.audio.bgm_volume
var sfx_volume: float = DEFAULT_SETTINGS.audio.sfx_volume
var controller_device: String = DEFAULT_SETTINGS.input.controller_device
var effects_quality: String = DEFAULT_SETTINGS.graphics.effects
var language: String = DEFAULT_SETTINGS.system.language

# 文件路径
const CONFIG_PATH = "user://settings.cfg"

# 加载配置
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	
	if err == OK:
		# 音频设置
		bgm_volume = config.get_value("audio", "bgm_volume", DEFAULT_SETTINGS.audio.bgm_volume)
		sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SETTINGS.audio.sfx_volume)
		
		# 输入设备
		controller_device = config.get_value("input", "controller_device", DEFAULT_SETTINGS.input.controller_device)
		
		# 画面效果
		effects_quality = config.get_value("graphics", "effects", DEFAULT_SETTINGS.graphics.effects)
		
		# 语言
		language = config.get_value("system", "language", DEFAULT_SETTINGS.system.language)
		
		print("配置加载成功")
		apply_settings()  # 应用配置到游戏
	else:
		print("使用默认配置，错误码:", err)
		save_settings()  # 创建初始配置文件

# 保存配置
func save_settings() -> void:
	var config = ConfigFile.new()
	
	# 音频
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# 输入设备
	config.set_value("input", "controller_device", controller_device)
	
	# 画面效果
	config.set_value("graphics", "effects", effects_quality)
	
	# 系统
	config.set_value("system", "language", language)
	
	var err = config.save(CONFIG_PATH)
	if err == OK:
		print("配置保存成功")
	else:
		print("保存失败，错误码:", err)

# 将配置应用到游戏（根据你的实际需求完善）
func apply_settings() -> void:
	# 示例：应用音频
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("BGM"), 
		linear_to_db(bgm_volume / 100.0)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), 
		linear_to_db(sfx_volume / 100.0)
	)
	
	# 示例：切换输入设备
	InputMap.load_from_project_settings()  # 确保正确设置 InputMap
	# 这里可以添加控制器/键盘的切换逻辑
	
	# 示例：画面效果（需要实际渲染逻辑）
	match effects_quality:
		"low":
			# 关闭后期处理等
			pass
		"medium":
			# 部分效果
			pass
		"high":
			# 全效果
			pass
	
	# 示例：语言切换（需要国际化支持）
	TranslationServer.set_locale(language)

# 初始化自动加载
func _ready():
	load_settings()
