## 并行播放动画
##
## 同时播放多个动画，全部完成后触发回调
class_name ParallelAnimation
extends BaseAnimation

var _animations: Array = []
var _pending_count: int = 0

func _init():
	_animation_name = "Parallel"

## 添加动画
func add(anim: IAnimation) -> void:
	_animations.append(anim)

## 清除所有动画
func clear() -> void:
	_animations.clear()
	_pending_count = 0

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	_pending_count = _animations.size()

	if _animations.is_empty():
		_on_complete.call()
		return

	for anim in _animations:
		anim.play(config, _on_child_complete)

	_is_playing = true

func _on_child_complete() -> void:
	_pending_count -= 1
	if _pending_count <= 0:
		_is_playing = false
		_on_complete.call()

func stop() -> void:
	super.stop()
	for anim in _animations:
		anim.stop()

func is_playing() -> bool:
	for anim in _animations:
		if anim.is_playing():
			return true
	return false
