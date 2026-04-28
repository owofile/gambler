## 销毁动画 - 缩小消失效果
class_name ShrinkDestroyAnimation
extends BaseAnimation

func _init():
	_animation_name = "ShrinkDestroy"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	super.play(target, config, on_complete)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var duration = config.get("duration", 0.3)

	var tween = target.create_tween()
	tween.set_parallel(true)

	tween.tween_property(target, "scale", Vector2(0.01, 0.01), duration)
	tween.tween_property(target, "modulate:a", 0.0, duration)

	tween.chain().tween_callback(_on_complete)
	_is_playing = true