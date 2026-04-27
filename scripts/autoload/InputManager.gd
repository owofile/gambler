## Manages global input handling and hotkeys.
##
## Responsibility:
## - Detect global key presses across all scenes
## - Trigger appropriate actions via EventBus or direct calls
## - Prevent duplicate triggers within same key press
##
## Usage:
##   F1 / ui_DebugMenu: Toggle debug menu
##
## Note: InputManager is an Autoload singleton.
extends Node

var _debug_menu_open: bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_DebugMenu"):
		_toggle_debug_menu()

func _toggle_debug_menu() -> void:
	if _debug_menu_open:
		return

	_debug_menu_open = true
	var debug_menu_path: String = "res://scenes/Thryzhn/UI_Scenes/debug/debug.tscn"
	var debug_menu_scene = load(debug_menu_path)
	if debug_menu_scene == null:
		push_error("[InputManager] Failed to load debug menu scene!")
		_debug_menu_open = false
		return

	var debug_menu = debug_menu_scene.instantiate()
	if debug_menu == null:
		push_error("[InputManager] Failed to instantiate debug menu!")
		_debug_menu_open = false
		return

	get_tree().root.add_child(debug_menu)
	await debug_menu.tree_exited
	_debug_menu_open = false
