## 动画注册表
##
## 管理所有动画实例，提供获取和注册功能
class_name AnimationRegistry
extends Node

var _presets: Dictionary = {}
var _custom_animations: Dictionary = {}

func _ready() -> void:
	_init_presets()
	print("[AnimationRegistry] Initialized with %d presets" % _presets.size())

func _init_presets() -> void:
	_presets["glow"] = GlowAnimation.new()
	_presets["bounce"] = BounceAnimation.new()
	_presets["shake"] = ShakeAnimation.new()
	_presets["move"] = MoveAnimation.new()
	_presets["particle"] = ParticleAnimation.new()
	_presets["sequential"] = SequentialAnimation.new()
	_presets["parallel"] = ParallelAnimation.new()

## 获取动画实例
func get_animation(name: String) -> Variant:
	if _custom_animations.has(name):
		return _custom_animations[name]

	if _presets.has(name):
		return _presets[name]

	push_warning("[AnimationRegistry] Animation not found: %s" % name)
	return null

## 注册自定义动画
func register(name: String, anim: IAnimation) -> void:
	_custom_animations[name] = anim
	print("[AnimationRegistry] Registered: %s" % name)

## 检查动画是否存在
func has_animation(name: String) -> bool:
	return _custom_animations.has(name) or _presets.has(name)

## 获取所有动画名称
func get_animation_names() -> Array:
	var names: Array = []
	names.assign(_custom_animations.keys())
	names.append_array(_presets.keys())
	return names
