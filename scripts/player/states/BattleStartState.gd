class_name BattleStartState
extends IPlayerState

const STATE_ID := 5

func enter(player: PlayerController) -> void:
	player.velocity = Vector2.ZERO
	player.animation_player.play("Idle", 0.1)

func exit(player: PlayerController) -> void:
	pass

func tick_physics(player: PlayerController, delta: float) -> void:
	pass

func get_next_state(player: PlayerController) -> int:
	return STATE_ID
