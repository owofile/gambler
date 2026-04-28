## 战斗UI接口
class_name IBattleUI
extends CanvasLayer

func show_hand(cards: Array) -> void:
	pass

func highlight_card(card_id: String, highlight: bool) -> void:
	pass

func show_selection_confirmed(cards: Array) -> void:
	pass

func show_enemy_cards(cards: Array) -> void:
	pass

func show_settlement(player_score: int, enemy_score: int, winner: String) -> void:
	pass

func clear_selection() -> void:
	pass

func show_battle_result(result: int) -> void:
	pass

func enable_selection(enabled: bool) -> void:
	pass
