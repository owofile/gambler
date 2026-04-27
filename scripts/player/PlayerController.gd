## Player controller for exploration and battle modes.
##
## Responsibility:
## - Handle player movement input
## - Manage player state transitions
## - Trigger battle mode when player enters combat
##
## Usage:
##   var player = PlayerController.new()
##   player.enter_battle()
class_name PlayerController
extends CharacterBody2D

signal state_changed(previous: int, new: int)

enum PlayerState {
	IDLE = 0,
	LEFT = 1,
	RIGHT = 2,
	UP = 3,
	DOWN = 4,
	BATTLE_START = 5
}

@export var speed: float = 50.0
@export var max_blur_strength: float = 0.03
@export var blur_speed_factor: float = 0.5

@onready var player_test = $PlayerTest
@onready var animation_player: AnimationPlayer = player_test.get_node("AnimationPlayer")

var moving_direction: float = 0.0
var motion_blur_material: ShaderMaterial
var _state_machine: PlayerStateMachine
var _current_state: int = PlayerState.IDLE

func _ready():
	_init_motion_blur()
	_init_state_machine()
	_state_machine.current_state = IdleState.STATE_ID

func _init_motion_blur():
	if player_test.material is ShaderMaterial:
		motion_blur_material = player_test.material
	else:
		motion_blur_material = ShaderMaterial.new()
		motion_blur_material.shader = preload("res://scenes/Thryzhn/Player/test/shader/motion_blur.gdshader")
		player_test.material = motion_blur_material

func _init_state_machine():
	_state_machine = PlayerStateMachine.new()
	_state_machine.owner = self
	_state_machine.current_state = -1
	add_child(_state_machine)

func _physics_process(delta: float):
	_state_machine.tick_physics(_current_state, delta)

	var next := get_next_state(_current_state)
	if _current_state != next:
		_change_state(next)

func get_next_state(state: int) -> int:
	match state:
		PlayerState.IDLE:
			return _get_idle_next_state()
		PlayerState.LEFT:
			if Input.get_axis("ui_left", "ui_right") == 0:
				return PlayerState.IDLE
		PlayerState.RIGHT:
			if Input.get_axis("ui_left", "ui_right") == 0:
				return PlayerState.IDLE
		PlayerState.UP:
			if Input.get_axis("ui_up", "ui_down") == 0:
				return PlayerState.IDLE
		PlayerState.DOWN:
			if Input.get_axis("ui_up", "ui_down") == 0:
				return PlayerState.IDLE
	return state

func _get_idle_next_state() -> int:
	var direction := Input.get_axis("ui_left", "ui_right")
	var vertical := Input.get_axis("ui_up", "ui_down")
	if direction < 0:
		return PlayerState.LEFT
	if direction > 0:
		return PlayerState.RIGHT
	if vertical < 0:
		return PlayerState.UP
	if vertical > 0:
		return PlayerState.DOWN
	return PlayerState.IDLE

func _change_state(new_state: int):
	var prev := _current_state
	_current_state = new_state
	_transition_state(prev, new_state)
	state_changed.emit(prev, new_state)

func _transition_state(from: int, to: int):
	match to:
		PlayerState.IDLE:
			velocity = Vector2.ZERO
			animation_player.play("Idle", 0.1)
			animation_player.set_speed_scale(0.3)
		PlayerState.LEFT:
			velocity.x = -speed
			if not player_test.is_flipped:
				player_test.scale.x *= -1
				player_test.is_flipped = true
			animation_player.play("Walk", 0.1)
			animation_player.set_speed_scale(6.0)
		PlayerState.RIGHT:
			velocity.x = speed
			if player_test.is_flipped:
				player_test.scale.x *= -1
				player_test.is_flipped = false
			animation_player.play("Walk", 0.1)
			animation_player.set_speed_scale(6.0)
		PlayerState.UP:
			velocity.y = -speed
			animation_player.play("Walk", 0.1)
			animation_player.set_speed_scale(6.0)
		PlayerState.DOWN:
			velocity.y = speed
			animation_player.play("Walk", 0.1)
			animation_player.set_speed_scale(6.0)

func enter_battle():
	_change_state(PlayerState.BATTLE_START)
	EventBus.publish("PlayerEnterBattle", null)

func get_state() -> int:
	return _current_state
