## Manages world exploration and battle triggers.
##
## Responsibility:
## - Load and manage world scenes
## - Handle battle trigger events
## - Coordinate with GameStateManager
class_name WorldManager
extends Node

signal player_discovered_area(area_id: String)
signal battle_triggered(enemy_id: String)

var _current_world: String = ""

func _ready():
	EventBus.subscribe("PlayerEnterBattle", _on_player_enter_battle)

func load_world(world_path: String) -> void:
	_current_world = world_path
	get_tree().change_scene_to_file(world_path)
	EventBus.publish("WorldLoaded", {"path": world_path})

func trigger_battle(enemy_id: String) -> void:
	battle_triggered.emit(enemy_id)
	GameState.enter_battle()

func _on_player_enter_battle(_payload):
	print("[WorldManager] Player entering battle")
