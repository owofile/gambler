## Shader销毁动画基类 - 使用着色器实现GPU加速的销毁效果
class_name ShaderDestroyAnimation
extends BaseAnimation

var _shader_path: String = ""
var _material: ShaderMaterial = null

func _init(shader_path: String = ""):
	super._init()
	_shader_path = shader_path

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	if not target:
		on_complete.call()
		return

	set_target(target)
	var duration: float = config.get("duration", 0.3)
	_on_complete = on_complete

	var shader = load(_shader_path)
	if not shader:
		_is_playing = false
		on_complete.call()
		return

	_material = ShaderMaterial.new()
	_material.shader = shader
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
	, 0.0, 1.0, duration)
	tween.tween_callback(_on_animation_done)
	_is_playing = true

func _on_animation_done() -> void:
	_is_playing = false
	clear()
	if _on_complete.is_valid():
		_on_complete.call()

func clear() -> void:
	_material = null

func stop() -> void:
	if _is_playing:
		_is_playing = false
		clear()
		if _on_complete.is_valid():
			_on_complete.call()