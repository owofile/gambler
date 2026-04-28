## 弹跳动画
class_name BounceAnimation
extends BaseAnimation

func _init():
	_animation_name = "Bounce"

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	var target = config.get("target", null)
	var scale_from = config.get("scale_from", Vector2.ONE * 0.8)
	var scale_to = config.get("scale_to", Vector2.ONE * 1.2)
	var duration = config.get("duration", 0.2)
	var loops = config.get("loops", 3)

	if not target:
		_on_complete.call()
		return

	set_target(target)

	var tween = target.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "scale", scale_from, duration)
	tween.tween_property(target, "scale", scale_to, duration)
	tween.set_loops(loops)
	tween.chain().tween_callback(func(): _on_complete.call())

	_is_playing = true
