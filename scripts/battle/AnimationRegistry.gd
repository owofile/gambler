## 动画注册表
##
## 管理所有动画实例，提供获取和注册功能
class_name AnimationRegistry
extends Node

const PRESETS: Dictionary = {
	"glow": preload("res://scripts/animation/effects/GlowAnimation.gd").new(),
	"bounce": preload("res://scripts/animation/effects/BounceAnimation.gd").new(),
	"shake": preload("res://scripts/animation/effects/ShakeAnimation.gd").new(),
	"move": preload("res://scripts/animation/effects/MoveAnimation.gd").new(),
	"particle": preload("res://scripts/animation/particles/ParticleAnimation.gd").new(),
	"sequential": preload("res://scripts/animation/base/SequentialAnimation.gd").new(),
	"parallel": preload("res://scripts/animation/base/ParallelAnimation.gd").new()
}

var _custom_animations: Dictionary = {}

func _ready() -> void:
	print("[AnimationRegistry] Initialized with %d presets" % PRESETS.size())

## 获取动画实例
func get_animation(name: String) -> IAnimation:
	if _custom_animations.has(name):
		return _custom_animations[name]

	if PRESETS.has(name):
		return PRESETS[name]

	push_warning("[AnimationRegistry] Animation not found: %s" % name)
	return null

## 注册自定义动画
func register(name: String, anim: IAnimation) -> void:
	_custom_animations[name] = anim
	print("[AnimationRegistry] Registered: %s" % name)

## 检查动画是否存在
func has_animation(name: String) -> bool:
	return _custom_animations.has(name) or PRESETS.has(name)

## 获取所有动画名称
func get_animation_names() -> Array:
	var names: Array = []
	names.assign(_custom_animations.keys())
	names.assign(PRESETS.keys())
	return names
