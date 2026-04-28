## 基础动画类
##
## 提供通用功能：计时器管理、子节点管理
class_name BaseAnimation
extends IAnimation

var _is_playing: bool = false
var _animation_name: String = "BaseAnimation"
var _timer: Timer = null
var _on_complete: Callable = Callable()
var _target_node: Node = null

func _init():
	pass

func play(config: Dictionary, on_complete: Callable) -> void:
	_is_playing = true
	_on_complete = on_complete

func stop() -> void:
	_is_playing = false
	_clear_timer()

func is_playing() -> bool:
	return _is_playing

func get_animation_name() -> String:
	return _animation_name

func _create_timer(duration: float) -> Timer:
	_clear_timer()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = duration
	add_child(_timer)
	return _timer

func _clear_timer() -> void:
	if _timer:
		_timer.queue_free()
	_timer = null

func _on_timer_complete() -> void:
	_is_playing = false
	if _on_complete.is_valid():
		_on_complete.call()

func set_target(node: Node) -> void:
	_target_node = node

func get_target() -> Node:
	return _target_node
