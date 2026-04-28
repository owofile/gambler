## 销毁动画 - 淡出效果
class_name FadeDestroyAnimation
extends BaseAnimation

func _init():
	_animation_name = "FadeDestroy"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	super.play(target, config, on_complete)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var duration = config.get("duration", 0.4)
	var scale_small = config.get("scale", 0.1)

	var tween = target.create_tween()
	tween.set_parallel(true)

	tween.tween_property(target, "modulate:a", 0.0, duration)
	tween.tween_property(target, "scale", Vector2(scale_small, scale_small), duration)

	tween.chain().tween_callback(_on_complete)
	_is_playing = true