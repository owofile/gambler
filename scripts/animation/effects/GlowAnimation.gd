## 发光动画
##
## 节点发光效果
class_name GlowAnimation
extends BaseAnimation

func _init():
	_animation_name = "Glow"

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	var target = config.get("target", null)
	var duration = config.get("duration", 0.3)
	var color_from = config.get("color_from", Color.WHITE)
	var color_to = config.get("color_to", Color.YELLOW)
	var property = config.get("property", "modulate")

	if not target:
		_on_complete.call()
		return

	set_target(target)

	var tween = target.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, property, color_to, duration / 2)
	tween.tween_property(target, property, color_from, duration / 2)
	tween.chain().tween_callback(func(): _on_complete.call())

	_is_playing = true
