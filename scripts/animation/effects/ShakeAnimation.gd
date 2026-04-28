## 抖动动画
class_name ShakeAnimation
extends BaseAnimation

func _init():
	_animation_name = "Shake"

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	var target = config.get("target", null)
	var offset = config.get("offset", Vector2(5, 5)
	var duration = config.get("duration", 0.1)
	var loops = config.get("loops", 3)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var original_pos = target.position

	var tween = target.create_tween()
	tween.set_parallel(true)

	for i in range(loops):
		tween.tween_property(target, "position", original_pos + Vector2(offset.x, 0), duration)
		tween.tween_property(target, "position", original_pos + Vector2(-offset.x, 0), duration)
		tween.tween_property(target, "position", original_pos + Vector2(0, offset.y), duration)
		tween.tween_property(target, "position", original_pos + Vector2(0, -offset.y), duration)
		tween.tween_property(target, "position", original_pos, duration)

	tween.chain().tween_callback(func(): _on_complete.call())

	_is_playing = true
