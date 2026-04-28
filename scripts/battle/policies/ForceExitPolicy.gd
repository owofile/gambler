## Force exit policy - battle ends when deck too small
class_name ForceExitPolicy
extends IDeckPolicy

func on_cards_consumed(played: Array, current_deck: int) -> Array:
	return played.duplicate()

func can_continue(current_deck: int, hand_size: int) -> bool:
	return current_deck >= hand_size

func get_name() -> String:
	return "ForceExit"

func get_policy_name() -> String:
	return get_name()
