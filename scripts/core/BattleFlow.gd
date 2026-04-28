## Manages the battle flow with 6-phase state machine.
##
## Responsibility:
## - Manage 6-phase battle flow (PLAYER_SELECT → ENEMY_REVEAL → SETTLE → CONSUME → ROUND_END → CHECK)
## - Coordinate between player selection, animations, and battle calculation
## - Handle card consumption, cross-turn state, and battle end
## - Provide empty deck protection
##
## 6-Phase Flow:
##   1. PLAYER_SELECT: Player selects cards
##   2. ENEMY_REVEAL: Enemy cards revealed
##   3. SETTLE: Calculate results with effects
##   4. CONSUME: Consume played cards
##   5. ROUND_END: Clean up and prepare next round
##   6. CHECK: Check for battle end
##
## Usage:
##   var flow = BattleFlow.new()
##   flow.initialize(card_manager, data_manager, event_bus)
##   flow.start_battle(player_deck_snapshot, enemy_data, config)
class_name BattleFlow
extends Node

## 6-Phase States
enum Phase {
	INVALID = -1,
	IDLE = 0,
	PLAYER_SELECT = 1,
	ENEMY_REVEAL = 2,
	SETTLE = 3,
	CONSUME = 4,
	ROUND_END = 5,
	BATTLE_END = 99
}

signal phase_changed(new_phase: Phase)
signal battle_end(result: int, report: BattleReport)
signal round_info(scores: Array, round_num: int)

var _current_phase: Phase = Phase.INVALID
var _card_manager: Node = null
var _data_manager: Node = null
var _event_bus: Node = null

var _config: BattleConfig = null
var _player_deck_snapshot: DeckSnapshot = null
var _enemy: EnemyData = null

var _round_number: int = 0
var _scores: Array = [0, 0]
var _consecutive_draws: int = 0
var _battle_report: BattleReport = null

var _selected_card_ids: Array = []
var _enemy_card_ids: Array = []
var _disabled_card_ids: Array = []

var _card_consumer: CardConsumer = null
var _cross_turn_state: CrossTurnState = null

func _init() -> void:
	_card_consumer = CardConsumer.new()
	_cross_turn_state = CrossTurnState.new()

func initialize(card_manager: Node, data_manager: Node, event_bus: Node) -> void:
	_card_manager = card_manager
	_data_manager = data_manager
	_event_bus = event_bus
	_card_consumer.initialize(card_manager, data_manager)
	print("[BattleFlow] Initialized")

func start_battle(player_deck: DeckSnapshot, enemy: EnemyData, config: BattleConfig = null) -> void:
	if not _check_deck_size(config if config else _create_default_config(enemy)):
		push_error("[BattleFlow] Cannot start battle: not enough cards")
		return

	_player_deck_snapshot = player_deck
	_enemy = enemy
	_config = config if config else _create_default_config(enemy)
	_config.reset_deck_pointer()
	_config.enable_card_consumption = false  # 强制禁用消耗，后续实现补牌机制后启用

	_round_number = 0
	_scores = [0, 0]
	_consecutive_draws = 0
	_battle_report = BattleReport.new()
	_battle_report.set_player_wins(0)
	_battle_report.set_enemy_wins(0)

	_cross_turn_state.clear_all()

	_publish("Flow_BattleStart", {"enemy": enemy, "config": _config})
	_set_phase(Phase.PLAYER_SELECT)
	_start_round()

## Check if player has enough cards
func _check_deck_size(config: BattleConfig) -> bool:
	if not _card_manager:
		return false
	var min_size = config.min_deck_size if config else 3
	return _card_manager.get_deck_size() >= min_size

## Create default config from enemy data
func _create_default_config(enemy: EnemyData) -> BattleConfig:
	return BattleConfig.from_enemy_data(enemy)

func _set_phase(new_phase: Phase) -> void:
	if _current_phase == new_phase:
		return
	_current_phase = new_phase
	phase_changed.emit(new_phase)
	print("[BattleFlow] Phase: %s" % _get_phase_name(new_phase))

func _get_phase_name(phase: Phase) -> String:
	match phase:
		Phase.INVALID: return "INVALID"
		Phase.IDLE: return "IDLE"
		Phase.PLAYER_SELECT: return "PLAYER_SELECT"
		Phase.ENEMY_REVEAL: return "ENEMY_REVEAL"
		Phase.SETTLE: return "SETTLE"
		Phase.CONSUME: return "CONSUME"
		Phase.ROUND_END: return "ROUND_END"
		Phase.BATTLE_END: return "BATTLE_END"
	return "UNKNOWN"

## Confirm player's card selection
func confirm_selection(card_instance_ids: Array) -> void:
	if _current_phase != Phase.PLAYER_SELECT:
		push_warning("[BattleFlow] Cannot confirm selection in phase: %s" % _get_phase_name(_current_phase))
		return

	if card_instance_ids.size() != _config.cards_per_round:
		push_warning("[BattleFlow] Must select exactly %d cards, got %d" % [_config.cards_per_round, card_instance_ids.size()])
		return

	_selected_card_ids = card_instance_ids
	print("[BattleFlow] Player selected %d cards" % _selected_card_ids.size())

	_publish("Flow_PlayerSelectionConfirmed", {"cards": _selected_card_ids})
	_set_phase(Phase.ENEMY_REVEAL)
	_execute_enemy_reveal()

## Cancel selection and re-select
func cancel_selection() -> void:
	if _current_phase != Phase.PLAYER_SELECT:
		return
	_selected_card_ids.clear()
	_publish("Flow_PlayerSelectionCancelled", null)

func _start_round() -> void:
	_round_number += 1
	_cross_turn_state.process_round_start()
	print("[BattleFlow] ===== Round %d Start =====" % _round_number)

func _execute_enemy_reveal() -> void:
	_enemy_card_ids = _config.get_enemy_cards(_config.cards_per_round)
	print("[BattleFlow] Enemy reveals: %s" % _enemy_card_ids)

	_publish("Flow_EnemyCardReveal", {
		"cards": _enemy_card_ids,
		"round": _round_number
	})

	_set_phase(Phase.SETTLE)
	_execute_settle()

func _execute_settle() -> void:
	var result = _calculate_round_result()

	var winner: String
	match result:
		0:
			winner = "draw"
			_consecutive_draws += 1
		1:
			winner = "player"
			_scores[0] += 1
			_consecutive_draws = 0
		2:
			winner = "enemy"
			_scores[1] += 1
			_consecutive_draws = 0

	if _consecutive_draws >= _config.draw_break_threshold:
		print("[BattleFlow] Draw break triggered after %d consecutive draws" % _consecutive_draws)
		_scores[0] += 1
		winner = "player"
		_consecutive_draws = 0

	print("[BattleFlow] Round %d: %s wins! Score: %d-%d" % [_round_number, winner, _scores[0], _scores[1]])

	_publish("Flow_RoundSettled", {
		"winner": winner,
		"player_cards": _selected_card_ids,
		"enemy_cards": _enemy_card_ids,
		"scores": _scores
	})

	round_info.emit(_scores, _round_number)

	_set_phase(Phase.CONSUME)
	_execute_consume()

func _calculate_round_result() -> int:
	var player_snapshot = _card_manager.get_deck_snapshot(_selected_card_ids)
	var calc_result = BattleManager.ProcessSelectedCards(
		player_snapshot,
		_enemy,
		_data_manager
	)

	var player_total = calc_result.get("player_total", 0)
	var enemy_total = calc_result.get("enemy_total", 0)

	var report: BattleReport = calc_result.get("report")
	if report:
		for cid in report.get_cards_to_remove():
			_disabled_card_ids.append(cid)

	if player_total > enemy_total:
		return 1
	elif player_total < enemy_total:
		return 2
	return 0

func _execute_consume() -> void:
	print("[BattleFlow] _execute_consume called. enable_card_consumption=", _config.enable_card_consumption)
	if _config.enable_card_consumption:
		var consumed = _card_consumer.consume_played_cards(_selected_card_ids, _disabled_card_ids)
		print("[BattleFlow] Consumed %d cards" % consumed.size())
		for card_id in consumed:
			_battle_report.add_card_to_remove(card_id)

	_publish("Flow_CardsConsumed", {"cards": _selected_card_ids})

	_set_phase(Phase.ROUND_END)
	_execute_round_end()

func _execute_round_end() -> void:
	_selected_card_ids.clear()
	_enemy_card_ids.clear()

	_publish("Flow_RoundEnd", {
		"round": _round_number,
		"scores": _scores
	})

	_set_phase(Phase.BATTLE_END)
	_check_battle_end()

func _check_battle_end() -> void:
	print("[BattleFlow] _check_battle_end: scores=%s target=%d" % [_scores, _config.target_wins])
	if _scores[0] >= _config.target_wins:
		_trigger_battle_end(BattleEnums.EBattleResult.Victory)
	elif _scores[1] >= _config.target_wins:
		_trigger_battle_end(BattleEnums.EBattleResult.Defeat)
	else:
		var deck_size = _card_manager.get_deck_size() if _card_manager else 0
		print("[BattleFlow] deck_size=%d cards_per_round=%d" % [deck_size, _config.cards_per_round])
		if deck_size < _config.cards_per_round:
			push_warning("[BattleFlow] Player has only %d cards, need %d. Forfeiting." % [deck_size, _config.cards_per_round])
			_trigger_battle_end(BattleEnums.EBattleResult.Defeat)
		else:
			_set_phase(Phase.PLAYER_SELECT)
			_start_round()

func _trigger_battle_end(result: BattleEnums.EBattleResult) -> void:
	_cross_turn_state.clear_all()
	_battle_report.set_result(result)
	_battle_report.set_player_wins(_scores[0])
	_battle_report.set_enemy_wins(_scores[1])

	# 清理状态
	_selected_card_ids.clear()
	_enemy_card_ids.clear()
	_disabled_card_ids.clear()

	print("[BattleFlow] ===== Battle End: %s =====" % BattleEnums.battle_result_to_string(result))
	print("[BattleFlow] Final Score: %d-%d (%d rounds)" % [_scores[0], _scores[1], _round_number])

	_publish("Flow_BattleEnd", {"result": result, "report": _battle_report})
	battle_end.emit(result, _battle_report)
	_set_phase(Phase.IDLE)

func get_current_phase() -> Phase:
	return _current_phase

func get_scores() -> Array:
	return _scores.duplicate()

func get_config() -> BattleConfig:
	return _config

func _publish(event_type: String, payload) -> void:
	if _event_bus:
		_event_bus.publish(event_type, payload)
