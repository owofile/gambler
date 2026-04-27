## Main menu controller for the game.
##
## Responsibility:
## - Handle main menu navigation
## - Start new game or continue
## - Access settings
class_name MainMenuController
extends Control

const OPTION_START := 0
const OPTION_SETTINGS := 1
const OPTION_COUNT := 2

@onready var arrow: Sprite2D = $arrow
@onready var ui_sfx: AudioStreamPlayer = $UI_Button_Hover_01

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
	if ui_sfx and ui_sfx.stream:
		ui_sfx.play()

	match _current_selection:
		OPTION_START:
			arrow.position = Vector2(521, 422)
		OPTION_SETTINGS:
			arrow.position = Vector2(657, 422)

func _handle_accept() -> void:
	print("[MainMenu] Selected: %d" % _current_selection)
	match _current_selection:
		OPTION_START:
			_start_game()
		OPTION_SETTINGS:
			_open_settings()

func _start_game() -> void:
	print("[MainMenu] Starting game")
	get_tree().change_scene_to_file("res://scenes/Thryzhn/TestScenes/cave/cave.tscn")

func _open_settings() -> void:
	print("[MainMenu] Opening settings")
