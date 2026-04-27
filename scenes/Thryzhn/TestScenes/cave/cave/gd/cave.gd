extends Node2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_door_area_entered(area: Area2D) -> void:
	print(area.name + "进入了门")
	SceneChanger.scene_changer("res://scenes/Battle_UI_v1.tscn")
