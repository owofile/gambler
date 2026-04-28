## 回合结束状态
class_name RoundEndState
extends BattleState

var _destroy_card_ids: Array = []
var _add_card_ids: Array = []
var _deck_policy_remove: Array = []
var _deck_policy_add: Array = []

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "RoundEnd"

func enter() -> void:
	_core.notify_state_changed(_state_name)

	_destroy_card_ids = _core.get_settlement_cards_to_remove()
	_add_card_ids = _core.get_settlement_cards_to_add()

	var player_cards = _core.get_current_player_cards()
	var current_deck_size = _core.get_deck_size()

	_deck_policy_remove = _core.get_deck_policy().on_cards_consumed(player_cards, current_deck_size)
	_deck_policy_add = _core.get_deck_policy().on_round_start(
		current_deck_size - _deck_policy_remove.size(),
		_core.get_config().cards_per_round
	)

	print("[RoundEndState] Settlement destroy: %d, add: %d | Deck policy remove: %d, add: %d" % [
		_destroy_card_ids.size(), _add_card_ids.size(),
		_deck_policy_remove.size(), _deck_policy_add.size()
	])

	_core.ui_clear_selection()
	play_animation("round_end")

func exit() -> void:
	pass

func on_animation_complete() -> void:
	call_deferred("_transition_to_next")

func _transition_to_next() -> void:
	var all_destroy = _destroy_card_ids.duplicate()
	for cid in _deck_policy_remove:
		if not all_destroy.has(cid):
			all_destroy.append(cid)

	if all_destroy.is_empty():
		_apply_settlement_and_transition()
	else:
		_core.ui_play_destroy_animation(all_destroy, _on_destroy_complete)

func _on_destroy_complete() -> void:
	_apply_settlement_and_transition()

func _apply_settlement_and_transition() -> void:
	for card_id in _destroy_card_ids:
		_core.remove_card_from_deck(card_id)
		print("[RoundEndState] Destroyed (settlement): %s" % card_id)

	for card_id in _deck_policy_remove:
		_core.remove_card_from_deck(card_id)
		print("[RoundEndState] Destroyed (deck policy): %s" % card_id)

	for proto_id in _add_card_ids:
		_core.add_card_to_deck(proto_id)
		print("[RoundEndState] Added (settlement): %s" % proto_id)

	for proto_id in _deck_policy_add:
		_core.add_card_to_deck(proto_id)
		print("[RoundEndState] Added (deck policy): %s" % proto_id)

	_destroy_card_ids.clear()
	_deck_policy_remove.clear()
	_deck_policy_add.clear()
	_add_card_ids.clear()
	_core.clear_settlement_cards()

	if _core.check_battle_end():
		_core.transition_to(BattleEndState)
	else:
		_core.transition_to(PlayerSelectState)