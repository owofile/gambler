extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_door_area_entered(area: Area2D) -> void:
	print(area.name + "进入了门")
	#切换场景
	SceneChanger.scene_changer("res://scenes/Battle_UI_v1.tscn")
	pass # Replace with function body.
