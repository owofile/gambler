## Handles dialogue display and progression.
##
## Responsibility:
## - Show dialogue lines
## - Manage dialogue state
## - Integrate with GameStateManager
##
## Usage:
##   EventBus.publish("StartDialogue", {"lines": ["Hello!", "How are you?"]})
class_name DialogueSystem
extends CanvasLayer

signal dialogue_started
signal dialogue_ended
signal line_finished

@export var dialogue_resource_path: String = ""

var _is_active: bool = false
var _dialogue_lines: Array = []
var _current_line_index: int = 0

func _ready():
	EventBus.subscribe("StartDialogue", _on_start_dialogue)

func _on_start_dialogue(payload: Dictionary) -> void:
	if payload.has("lines"):
		_dialogue_lines = payload["lines"]
	else:
		_dialogue_lines = [payload.get("text", "")]

	_current_line_index = 0
	_start_dialogue()

func _start_dialogue():
	_is_active = true
	GameState.enter_dialogue()
	dialogue_started.emit()
	_show_current_line()

func _show_current_line():
	if _current_line_index < _dialogue_lines.size():
		var line = _dialogue_lines[_current_line_index]
		_show_line(line)
	else:
		_end_dialogue()

func _show_line(line: String):
	print("[DialogueSystem] %s" % line)

func _end_dialogue():
	_is_active = false
	_current_line_index = 0
	GameState.enter_exploration()
	dialogue_ended.emit()
	EventBus.publish("DialogueEnded", {})

func advance():
	if not _is_active:
		return
	_current_line_index += 1
	_show_current_line()
	line_finished.emit()

func is_active() -> bool:
	return _is_active
