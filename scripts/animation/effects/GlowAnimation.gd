## 发光动画
class_name GlowAnimation
extends BaseAnimation

func _init():
	_animation_name = "Glow"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	super.play(target, config, on_complete)
	var duration = config.get("duration", 0.3)
	var min_scale = config.get("min_scale", 1.0)
	var max_scale = config.get("max_scale", 1.15)

	if not target:
		_on_complete.call()
		return

	set_target(target)
	var original_modulate = target.modulate

	var tween = target.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "modulate", original_modulate * Color(1.2, 1.2, 0.8), duration * 0.5)
	tween.tween_property(target, "scale", Vector2(max_scale, max_scale), duration * 0.5)
	tween.chain().tween_property(target, "modulate", original_modulate, duration * 0.5)
	tween.chain().tween_property(target, "scale", Vector2(min_scale, min_scale), duration * 0.5)
	tween.chain().tween_callback(func(): _on_complete.call())

	_is_playing = true