## 结算状态
class_name SettlementState
extends BattleState

var _player_cards: Array = []
var _enemy_cards: Array = []
var _player_score: int = 0
var _enemy_score: int = 0
var _round_winner: String = ""

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "Settlement"

func enter() -> void:
	_core.notify_state_changed(_state_name)
	_player_cards = _core.get_current_player_cards()
	_enemy_cards = _core.get_current_enemy_cards()

	var result = _core.calculate_settlement(_player_cards, _enemy_cards)
	_player_score = result.get("player_total", 0)
	_enemy_score = result.get("enemy_total", 0)

	if _player_score > _enemy_score:
		_round_winner = "player"
	elif _player_score < _enemy_score:
		_round_winner = "enemy"
	else:
		_round_winner = "draw"

	_core.ui_show_settlement(_player_score, _enemy_score, _round_winner)
	play_animation("settlement")

func exit() -> void:
	pass

func on_animation_complete() -> void:
	call_deferred("_transition_to_next")

func _transition_to_next() -> void:
	_core.record_round_result(_round_winner)
	_core.transition_to(RoundEndState)
