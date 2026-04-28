## Shader销毁动画基类 - 使用着色器实现GPU加速的销毁效果
class_name ShaderDestroyAnimation
extends BaseAnimation

var _shader_path: String = ""
var _progress: float = 0.0
var _duration: float = 0.3
var _timer: Timer = null

func _init(shader_path: String = ""):
	_animation_name = "ShaderDestroy"
	_shader_path = shader_path

func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
	if not target:
		on_complete.call()
		return

	set_target(target)
	_duration = config.get("duration", 0.3)

	_apply_shader(target)
	_start_timer()

func _apply_shader(target: Node) -> void:
	if _shader_path.is_empty():
		return

	if target.has_method("set_material"):
		var shader = load(_shader_path)
		if shader:
			var material = ShaderMaterial.new()
			material.shader = shader
			target.set_material(material)

func _start_timer() -> void:
	_clear_timer()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = _duration
	_timer.timeout.connect(_on_timer_complete)
	target.add_child(_timer)
	_timer.start()
	_is_playing = true

func _clear_timer() -> void:
	if _timer:
		_timer.timeout.disconnect(_on_timer_complete)
		if _timer.get_parent() == target:
			_timer.queue_free()
		_timer = null

func _on_timer_complete() -> void:
	_is_playing = false
	_on_complete.call()
	_clear_timer()

func stop() -> void:
	_is_playing = false
	_clear_timer()

func is_playing() -> bool:
	return _is_playing

func get_animation_name() -> String:
	return _animation_name