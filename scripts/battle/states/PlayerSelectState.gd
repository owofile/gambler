## 玩家选牌状态
class_name PlayerSelectState
extends BattleState

var _selected_cards: Array = []
var _required_count: int = 3
var _exiting: bool = false

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "PlayerSelect"

func enter() -> void:
	_selected_cards.clear()
	_required_count = _core.get_config().cards_per_round
	_core.notify_state_changed(_state_name)
	_core.ui_show_hand(_core.get_player_hand())
	_core.ui_enable_selection(true)
	play_animation("show_hand")

func exit() -> void:
	if _exiting:
		return
	_exiting = true
	_core.ui_enable_selection(false)
	_exiting = false

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

func on_animation_complete() -> void:
	pass
