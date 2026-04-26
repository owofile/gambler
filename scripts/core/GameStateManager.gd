## Manages game-wide state (exploration, dialogue, battle).
##
## Responsibility:
## - Track current game mode
## - Handle mode transitions
## - Emit signals for mode changes
##
## Usage:
##   GameState.enter_battle()  # Direct static access to singleton
##   if GameState.is_exploration():
##       pass
extends Node

enum GameMode {
	EXPLORATION,
	DIALOGUE,
	BATTLE
}

signal mode_changed(from: GameMode, to: GameMode)

var _current_mode: GameMode = GameMode.EXPLORATION
var _previous_mode: GameMode = GameMode.EXPLORATION

func _ready():
	print("[GameState] Initialized at: %s" % get_path())

func get_mode() -> GameMode:
	return _current_mode

func is_exploration() -> bool:
	return _current_mode == GameMode.EXPLORATION

func is_dialogue() -> bool:
	return _current_mode == GameMode.DIALOGUE

func is_battle() -> bool:
	return _current_mode == GameMode.BATTLE

func enter_exploration():
	_change_mode(GameMode.EXPLORATION)

func enter_dialogue():
	_change_mode(GameMode.DIALOGUE)

func enter_battle():
	_change_mode(GameMode.BATTLE)

func _change_mode(new_mode: GameMode):
	if _current_mode == new_mode:
		return
	_previous_mode = _current_mode
	var old := _current_mode
	_current_mode = new_mode
	EventBus.publish("GameModeChanged", {"from": old, "to": new_mode})
	mode_changed.emit(old, new_mode)
	print("[GameState] Mode: %s -> %s" % [old, new_mode])
