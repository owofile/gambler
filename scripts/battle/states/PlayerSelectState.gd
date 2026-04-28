## 玩家选牌状态
class_name PlayerSelectState
extends BattleState

var _selected_cards: Array = []
var _required_count: int = 3
var _pending_destroy_callback: Callable = Callable()

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "PlayerSelect"

func enter() -> void:
	_selected_cards.clear()
	_required_count = _core.get_config().cards_per_round
	_core.notify_state_changed(_state_name)

	var pending_destroy = _core.get_pending_destroy_card_ids()
	if not pending_destroy.is_empty():
		print("[PlayerSelectState] Has pending destroy cards: %d" % pending_destroy.size())
		_show_hand_with_pending_destroy(pending_destroy)
	else:
		_show_hand_normal()

func _show_hand_normal() -> void:
	_core.ui_show_hand(_core.get_player_hand())
	_core.ui_enable_selection(true)

func _show_hand_with_pending_destroy(pending_ids: Array) -> void:
	_core.ui_show_hand(_core.get_player_hand())

	var self_destroy_ids = _filter_self_destroy_cards(pending_ids)
	if self_destroy_ids.is_empty():
		_core.ui_enable_selection(true)
		_core.clear_pending_destroy_cards()
		return

	print("[PlayerSelectState] Playing destroy animation for self-destroy cards: %d" % self_destroy_ids.size())

	_pending_destroy_callback = func():
		_core.clear_pending_destroy_cards()
		_core.ui_enable_selection(true)
		_core.ui_show_hand(_core.get_player_hand())

	_core.ui_play_destroy_animation(self_destroy_ids, _pending_destroy_callback)

func _filter_self_destroy_cards(card_ids: Array) -> Array:
	var result: Array = []
	var card_manager = _core.get_card_manager()
	for card_id in card_ids:
		var card = card_manager.get_card(card_id)
		if card:
			var prototype_id = card.get_prototype_id()
			var data_manager = _core.get_data_manager()
			var prototype = data_manager.card_registry.get_prototype(prototype_id)
			if prototype and prototype.cost_id == "self_destroy":
				result.append(card_id)
	return result

func exit() -> void:
	pass

func on_player_card_selected(card_id: String) -> void:
	if _selected_cards.size() < _required_count:
		_selected_cards.append(card_id)
		_core.ui_highlight_card(card_id, true)

func on_player_card_deselected(card_id: String) -> void:
	_selected_cards.erase(card_id)
	_core.ui_highlight_card(card_id, false)

func on_player_confirm(cards: Array) -> void:
	if cards.size() == _required_count:
		_core.ui_show_selection_confirmed(cards)
		_core.transition_to(EnemyRevealState)