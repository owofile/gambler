## 销毁动画 - 震动消失效果
class_name ShakeDestroyAnimation
extends BaseAnimation

func _init():
	_animation_name = "ShakeDestroy"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	super.play(target, config, on_complete)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var duration = config.get("duration", 0.4)
	var shake_amount = config.get("shake_amount", 3)

	var original_scale = target.scale
	var tween = target.create_tween()
	tween.set_parallel(true)

	for i in range(shake_amount):
		target.scale = original_scale * 1.1
		tween.tween_property(target, "scale", original_scale * 0.9, duration / shake_amount / 2)
		tween.tween_property(target, "scale", original_scale, duration / shake_amount / 2)

	tween.chain().tween_property(target, "modulate:a", 0.0, duration)
	tween.chain().tween_property(target, "scale", Vector2(0.01, 0.01), duration * 0.5)
	tween.chain().tween_callback(_on_complete)
	_is_playing = true