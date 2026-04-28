## 卡组策略接口
class_name IDeckPolicy
extends RefCounted

func on_battle_start(deck_size: int, hand_size: int) -> bool:
	return true

func on_round_start(current_deck: int, hand_size: int) -> Array:
	return []

func on_cards_consumed(played: Array, current_deck: int) -> Array:
	return []

func can_continue(current_deck: int, hand_size: int) -> bool:
	return current_deck >= hand_size

func get_name() -> String:
	return "IDeckPolicy"
