class_name SceneManager
extends CanvasLayer

const CHANGE_SCENE := "scene_changed"
const READY_SCENE := "scene_ready"

var _current_scene_path: String = ""
var _animation_player: AnimationPlayer
var _is_changing: bool = false

func _ready():
	_ready_animation()
	self.hide()

func _ready_animation():
	_animation_player = $AnimationPlayer

func change_scene(path: String) -> void:
	if _is_changing:
		return
	_is_changing = true

	self.show()
	self.set_layer(999)
	_animation_player.play("Gradient")
	await _animation_player.animation_finished

	get_tree().change_scene_to_file(path)
	_current_scene_path = path
	EventBus.publish(CHANGE_SCENE, {"path": path})

	_animation_player.play_backwards("Gradient")
	await _animation_player.animation_finished

	self.set_layer(-1)
	self.hide()
	_is_changing = false

func get_current_scene_path() -> String:
	return _current_scene_path

func scene_changer(path: String) -> void:
	change_scene(path)
