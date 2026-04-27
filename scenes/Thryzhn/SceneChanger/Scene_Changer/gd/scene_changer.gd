extends CanvasLayer

@onready var animation:AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	自身隐藏
	self.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func scene_changer(path):
#	自身显示
	self.show()
#	调整层级
	self.set_layer(999)
#	播放切换动画
	animation.play("Gradient")
#	等待动画执行完毕
	await animation.animation_finished
#	跳转对应场景
	call_deferred(func(): get_tree().change_scene_to_file(path))
#	反向播放切换动画
	animation.play_backwards("Gradient")
#	等待动画执行完毕
	await animation.animation_finished
#	调整层级
	self.set_layer(-1)
#	自身隐藏
	self.hide()
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
#	或许可以用这个信号去判断？
	pass # Replace with function body.
