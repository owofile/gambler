## 回合结束状态
class_name RoundEndState
extends BattleState

var _destroy_card_ids: Array = []
var _add_card_ids: Array = []

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "RoundEnd"

func enter() -> void:
	_core.notify_state_changed(_state_name)

	# Get cards marked for destruction from settlement (self_destroy, delayed_destroy, etc.)
	# These were recorded by SettlementState.record_settlement_cards()
	_destroy_card_ids = _core.get_settlement_cards_to_remove()
	_add_card_ids = _core.get_settlement_cards_to_add()

	print("[RoundEndState] Settlement destroy: %d cards, add: %d cards" % [_destroy_card_ids.size(), _add_card_ids.size()])

	_core.ui_clear_selection()
	play_animation("round_end")

func exit() -> void:
	pass

func on_animation_complete() -> void:
	call_deferred("_transition_to_next")

func _transition_to_next() -> void:
	if _destroy_card_ids.is_empty():
		_apply_settlement_and_transition()
	else:
		_core.ui_play_destroy_animation(_destroy_card_ids, _on_destroy_complete)

func _on_destroy_complete() -> void:
	_apply_settlement_and_transition()

func _apply_settlement_and_transition() -> void:
	for card_id in _destroy_card_ids:
		_core.remove_card_from_deck(card_id)
		print("[RoundEndState] Destroyed card: %s" % card_id)

	for proto_id in _add_card_ids:
		_core.add_card_to_deck(proto_id)
		print("[RoundEndState] Added card: %s" % proto_id)

	_destroy_card_ids.clear()
	_add_card_ids.clear()

	if _core.check_battle_end():
		_core.transition_to(BattleEndState)
	else:
		_core.transition_to(PlayerSelectState)