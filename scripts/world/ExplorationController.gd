class_name ExplorationController
extends Node

@export var world_scene_path: String = ""
@export var player_start_position: Vector2 = Vector2(100, 100)

var _player: PlayerController
var _is_exploration_active: bool = false

func _ready():
	EventBus.subscribe("BattleEnded", _on_battle_ended)
	EventBus.subscribe("WorldLoaded", _on_world_loaded)

func start_exploration(world_path: String) -> void:
	world_scene_path = world_path
	_is_exploration_active = true
	GameState.enter_exploration()
	get_tree().change_scene_to_file(world_path)

func _on_battle_ended(payload: Dictionary) -> void:
	print("[ExplorationController] Battle ended, returning to exploration")
	_is_exploration_active = true

func _on_world_loaded(payload: Dictionary) -> void:
	print("[ExplorationController] World loaded: %s" % payload.get("path", ""))

func is_exploration_active() -> bool:
	return _is_exploration_active

func get_player() -> PlayerController:
	return _player
