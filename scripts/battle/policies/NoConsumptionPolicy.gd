## 无消耗策略 - 卡牌重复使用
class_name NoConsumptionPolicy
extends IDeckPolicy

func on_cards_consumed(played: Array, current_deck: int) -> Array:
	return []

func get_name() -> String:
	return "NoConsumption"

func get_policy_name() -> String:
	return get_name()
