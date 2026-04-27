class_name WalkState
extends IPlayerState

const STATE_LEFT := 1
const STATE_RIGHT := 2
const STATE_UP := 3
const STATE_DOWN := 4

func enter(player: PlayerController) -> void:
	pass

func exit(player: PlayerController) -> void:
	pass

func tick_physics(player: PlayerController, delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var vertical := Input.get_axis("ui_up", "ui_down")

	if direction != 0:
		player.moving_direction = direction
		player.velocity.x = direction * player.speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.speed)

	player.velocity.y = vertical * player.speed * 2
	player.move_and_slide()

	if player.get_last_slide_collision():
		player.velocity = Vector2.ZERO

func get_next_state(player: PlayerController) -> int:
	var direction := Input.get_axis("ui_left", "ui_right")
	var vertical := Input.get_axis("ui_up", "ui_down")

	if direction == 0 and vertical == 0:
		return IdleState.STATE_ID

	return -1
