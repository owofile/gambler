## Main menu controller for the game.
##
## Responsibility:
## - Handle main menu navigation
## - Start new game or continue
## - Access settings
class_name MainMenuController
extends Control

@export var start_scene_path: String = "res://scenes/World/SampleWorld.tscn"

@onready var arrow: Control = $arrow

const OPTION_COUNT := 2

var _current_selection: int = 0

func _ready():
	update_selection()

func _process(delta: float):
	if Input.is_action_just_pressed("ui_right"):
		if _current_selection < OPTION_COUNT - 1:
			_current_selection += 1
			update_selection()
		await get_tree().create_timer(0.2).timeout

	if Input.is_action_just_pressed("ui_left"):
		if _current_selection > 0:
			_current_selection -= 1
			update_selection()
		await get_tree().create_timer(0.2).timeout

	if Input.is_action_just_released("ui_accept"):
		_handle_accept()

func update_selection() -> void:
	print("[MainMenu] Selection: %d" % _current_selection)
	match _current_selection:
		0:
			arrow.position = Vector2(521, 422)
		1:
			arrow.position = Vector2(657, 422)

func _handle_accept() -> void:
	print("[MainMenu] Accept: %d" % _current_selection)
	match _current_selection:
		0:
			_start_game()
		1:
			_open_settings()

func _start_game() -> void:
	if start_scene_path.is_empty():
		push_error("[MainMenu] start_scene_path not set!")
		return
	get_tree().change_scene_to_file(start_scene_path)

func _open_settings() -> void:
	print("[MainMenu] Open settings")
