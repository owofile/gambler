class_name IdleState
extends IPlayerState

const STATE_ID := 0

func enter(player: PlayerController) -> void:
	player.velocity = Vector2.ZERO
	player.animation_player.play("Idle", 0.1)
	player.animation_player.set_speed_scale(0.3)

func exit(player: PlayerController) -> void:
	pass

func get_next_state(player: PlayerController) -> int:
	var direction := Input.get_axis("ui_left", "ui_right")
	var vertical := Input.get_axis("ui_up", "ui_down")

	if direction < 0:
		return WalkState.STATE_LEFT
	if direction > 0:
		return WalkState.STATE_RIGHT
	if vertical < 0:
		return WalkState.STATE_UP
	if vertical > 0:
		return WalkState.STATE_DOWN

	return STATE_ID
