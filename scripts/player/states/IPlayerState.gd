class_name IPlayerState
extends RefCounted

func enter(player: PlayerController) -> void:
	pass

func exit(player: PlayerController) -> void:
	pass

func tick_physics(player: PlayerController, delta: float) -> void:
	pass

func get_next_state(player: PlayerController) -> int:
	return -1
