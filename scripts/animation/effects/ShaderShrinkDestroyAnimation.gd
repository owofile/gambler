## 着色器缩小销毁动画
class_name ShaderShrinkDestroyAnimation
extends ShaderDestroyAnimation

var _material: ShaderMaterial = null

func _init():
	super._init("res://shaders/destroy/ShrinkDestroy.gdshader")
	_animation_name = "ShaderShrinkDestroy"

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	if not target:
		on_complete.call()
		return

	set_target(target)
	_duration = config.get("duration", 0.3)

	var shader = load(_shader_path)
	if not shader:
		on_complete.call()
		return

	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("duration", _duration)
	_material.set_shader_parameter("progress", 0.0)

	var sprite = target.get_node_or_null("CardContainer/Sprite")
	if sprite and sprite is Sprite2D:
		sprite.material = _material
	else:
		target.set_material(_material)

	var tween = target.create_tween()
	tween.tween_method(func(p):
		if _material:
			_material.set_shader_parameter("progress", p)
	, 0.0, 1.0, _duration)
	tween.tween_callback(func():
		_on_animation_done()
	)
	_is_playing = true

func _on_animation_done() -> void:
	_is_playing = false
	var cb = _on_complete
	clear()
	cb.call()

func clear() -> void:
	_material = null

func stop() -> void:
	if _is_playing:
		_is_playing = false
		var cb = _on_complete
		clear()
		if cb.is_valid():
			cb.call()