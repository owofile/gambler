## 顺序播放动画
##
## 依次播放多个动画
class_name SequentialAnimation
extends BaseAnimation

var _animations: Array = []
var _current_index: int = 0

func _init():
	_animation_name = "Sequential"

## 添加动画
func add(anim: IAnimation) -> void:
	_animations.append(anim)

## 清除所有动画
func clear() -> void:
	_animations.clear()
	_current_index = 0

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	_current_index = 0

	if _animations.is_empty():
		_on_complete.call()
		return

	_play_next()

func _play_next() -> void:
	if _current_index >= _animations.size():
		_is_playing = false
		_on_complete.call()
		return

	var anim = _animations[_current_index]
	var anim_config = config.get(str(_current_index), {})
	_current_index += 1
	anim.play(anim_config, _play_next)

func stop() -> void:
	super.stop()
	for anim in _animations:
		anim.stop()

func is_playing() -> bool:
	for anim in _animations:
		if anim.is_playing():
			return true
	return false
