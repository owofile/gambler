class_name PlayerStateMachine
extends Node

var owner: PlayerController
var current_state: int = -1:
	set(v):
		owner.transition_state(current_state, v)
		current_state = v

func _ready():
	await owner._ready()
	current_state = 0

func tick_physics(state: int, delta: float):
	var next := owner.get_next_state(state)
	if current_state == next:
		return
	current_state = next
