## Consume with auto-draw policy
class_name ConsumeWithDrawPolicy
extends IDeckPolicy

func on_cards_consumed(played: Array, current_deck: int) -> Array:
	return played.duplicate()

func can_continue(current_deck: int, hand_size: int) -> bool:
	return current_deck >= hand_size

func get_name() -> String:
	return "ConsumeWithDraw"
