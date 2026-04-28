## 移动动画
class_name MoveAnimation
extends BaseAnimation

func _init():
	_animation_name = "Move"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	super.play(target, config, on_complete)
	var to_pos = config.get("to", target.position + Vector2(0, -50))
	var duration = config.get("duration", 0.3)
	var ease_type = config.get("ease", Tween.EASE_OUT)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var original_pos = target.position

	var tween = target.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "position", to_pos, duration).set_ease(ease_type)
	tween.chain().tween_callback(_on_complete)

	_is_playing = true