## 动画接口基类
##
## 所有动画必须实现此接口
class_name IAnimation
extends RefCounted

## 播放动画
## config: Dictionary - 动画参数，如 {duration: 0.5, from: Vector2, to: Vector2}
## on_complete: Callable - 动画完成时调用
func play(config: Dictionary, on_complete: Callable) -> void:
	pass

## 停止动画
func stop() -> void:
	pass

## 是否正在播放
func is_playing() -> bool:
	return false

## 获取动画名称（用于调试）
func get_animation_name() -> String:
	return "IAnimation"
