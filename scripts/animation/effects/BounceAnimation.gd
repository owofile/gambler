## 弹跳动画
class_name BounceAnimation
extends BaseAnimation

func _init():
	_animation_name = "Bounce"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	super.play(target, config, on_complete)
	var duration = config.get("duration", 0.15)
	var loops = config.get("loops", 2)
	var bounce_height = config.get("bounce_height", 15)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var original_pos = target.position

	var tween = target.create_tween()

	for i in range(loops):
		tween.tween_property(target, "position", original_pos + Vector2(0, -bounce_height), duration)
		tween.tween_property(target, "position", original_pos, duration)

	tween.chain().tween_callback(_on_complete)

	_is_playing = true
