## 移动动画
class_name MoveAnimation
extends BaseAnimation

func _init():
	_animation_name = "Move"

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	var target = config.get("target", null)
	var to = config.get("to", Vector2.ZERO)
	var duration = config.get("duration", 0.5)
	var easing = config.get("easing", Tween.EASE_IN_OUT)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var from = target.position

	var tween = target.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "position", to, duration).set_ease(easing)
	tween.chain().tween_callback(func(): _on_complete.call())

	_is_playing = true
