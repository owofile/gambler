## 回合结束状态
class_name RoundEndState
extends BattleState

var _consumed_cards: Array = []
var _added_cards: Array = []

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "RoundEnd"

func enter() -> void:
	_core.notify_state_changed(_state_name)

	_core.apply_settlement_cards()

	var player_cards = _core.get_current_player_cards()
	var current_deck_size = _core.get_deck_size()

	_consumed_cards = _core.get_deck_policy().on_cards_consumed(player_cards, current_deck_size)
	_added_cards = _core.get_deck_policy().on_round_start(
		current_deck_size - _consumed_cards.size(),
		_core.get_config().cards_per_round
	)

	for card_id in _consumed_cards:
		_core.remove_card_from_deck(card_id)

	for proto_id in _added_cards:
		_core.add_card_to_deck(proto_id)

	_core.ui_clear_selection()
	play_animation("round_end")

func exit() -> void:
	pass

func on_animation_complete() -> void:
	call_deferred("_transition_to_next")

func _transition_to_next() -> void:
	if _core.check_battle_end():
		_core.transition_to(BattleEndState)
	else:
		_core.transition_to(PlayerSelectState)
