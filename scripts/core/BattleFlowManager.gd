class_name BattleFlowManager
extends Node

enum State {
	IDLE,
	PLAYER_SELECTING,
	PLAYER_ANIMATING,
	ENEMY_ANIMATING,
	COMPARE_ANIMATING,
	ROUND_END_ANIMATING,
	BATTLE_END
}

signal state_changed(new_state: State)
signal battle_end(result: BattleReport)
signal round_can_select(scores: Array[int])

var _current_state: State = State.IDLE
var _player_deck: DeckSnapshot = null
var _enemy: EnemyData = null
var _data_manager = null
var _current_round: int = 0
var _current_score: Array[int] = [0, 0]
var _target_wins: int = 3
var _current_player_snapshot: DeckSnapshot = null
var _current_enemy_card_ids: Array[String] = []
var _current_report: BattleReport = null
var _battle_report: BattleReport = null

func _get_card_manager():
	return get_node("/root/CardManager")

func _get_data_manager():
	return get_node("/root/DataManager")

func _get_event_bus():
	return get_node("/root/EventBus")

func start_battle(player_deck: DeckSnapshot, enemy: EnemyData) -> void:
	_player_deck = player_deck
	_enemy = enemy
	_data_manager = _get_data_manager()

	match enemy.tier:
		EnemyData.EnemyTier.Grunt: _target_wins = 3
		EnemyData.EnemyTier.Elite: _target_wins = 4
		EnemyData.EnemyTier.Boss: _target_wins = 5
		_: _target_wins = 3

	_current_score = [0, 0]
	_current_round = 0

	_set_state(State.PLAYER_SELECTING)
	_publish("Flow_BattleStart", {"enemy": enemy})
	_publish("Flow_PlayerSelecting", null)

func confirm_selection(card_instance_ids: Array[String]) -> void:
	if _current_state != State.PLAYER_SELECTING:
		print("[BattleFlowManager] Cannot confirm selection in state: %d" % _current_state)
		return

	if card_instance_ids.size() == 0:
		print("[BattleFlowManager] No cards selected")
		return

	var card_mgr = _get_card_manager()
	_current_player_snapshot = card_mgr.GetDeckSnapshot(card_instance_ids)
	_publish("Flow_PlayerCardAnimStart", {"cards": _current_player_snapshot.cards})

	_set_state(State.PLAYER_ANIMATING)

func on_animation_complete(anim_type: String) -> void:
	match _current_state:
		State.PLAYER_ANIMATING:
			if anim_type == "player_card_enter":
				_publish("Flow_PlayerCardAnimEnd", null)
				_trigger_enemy_reveal()
		State.ENEMY_ANIMATING:
			if anim_type == "enemy_card_reveal":
				_trigger_compare()
		State.COMPARE_ANIMATING:
			if anim_type == "compare":
				_trigger_round_end()
		State.ROUND_END_ANIMATING:
			if anim_type == "round_end":
				_check_battle_end()

func get_current_state() -> State:
	return _current_state

func _set_state(new_state: State) -> void:
	_current_state = new_state
	state_changed.emit(_current_state)
	print("[BattleFlowManager] State: %d" % _current_state)

func _trigger_enemy_reveal() -> void:
	_set_state(State.ENEMY_ANIMATING)
	_current_round += 1

	_current_enemy_card_ids = _select_enemy_cards()

	if _current_enemy_card_ids.size() > 0:
		var first_card_id = _current_enemy_card_ids[0]
		_publish("Flow_EnemyCardReveal", {"card_id": first_card_id, "all_cards": _current_enemy_card_ids})

func _trigger_compare() -> void:
	_set_state(State.COMPARE_ANIMATING)

	print("[BattleFlowManager] _trigger_compare called, calling ProcessSelectedCards")
	var result = BattleManager.ProcessSelectedCards(_current_player_snapshot, _enemy, _data_manager)
	print("[BattleFlowManager] ProcessSelectedCards returned: player_total=%d, enemy_total=%d" % [result.player_total, result.enemy_total])
	_current_enemy_card_ids = result.enemy_card_ids
	var player_total = result.player_total
	var enemy_total = result.enemy_total
	_current_report = result.report

	if _battle_report == null:
		_battle_report = BattleReport.new()
	for card_id in _current_report.cards_to_remove:
		if not _battle_report.cards_to_remove.has(card_id):
			_battle_report.cards_to_remove.append(card_id)

	var player_card_ids: Array[String] = []
	if _current_player_snapshot:
		for card in _current_player_snapshot.cards:
			player_card_ids.append(card.prototype_id)

	_publish("Flow_CompareStart", {
		"player_cards": player_card_ids,
		"enemy_cards": _current_enemy_card_ids,
		"player_total": player_total,
		"enemy_total": enemy_total,
		"report": _current_report
	})

func _trigger_round_end() -> void:
	_set_state(State.ROUND_END_ANIMATING)

	var player_total = 0
	var enemy_total = 0
	if _current_report:
		for card in _current_player_snapshot.cards:
			player_total += card.final_value
		for cid in _current_enemy_card_ids:
			var proto = _data_manager.card_registry.get_prototype(cid)
			if proto:
				enemy_total += proto.base_value
	else:
		player_total = _sum_player_values()
		enemy_total = _sum_enemy_values()

	var round_result: String = "draw"
	if player_total > enemy_total:
		_current_score[0] += 1
		round_result = "player"
	elif player_total < enemy_total:
		_current_score[1] += 1
		round_result = "enemy"

	_publish("Flow_RoundEnd", {
		"winner": round_result,
		"scores": _current_score,
		"player_total": player_total,
		"enemy_total": enemy_total,
		"round": _current_round
	})

func _check_battle_end() -> void:
	if _current_score[0] >= _target_wins:
		_trigger_battle_end(BattleEnums.EBattleResult.Victory)
	elif _current_score[1] >= _target_wins:
		_trigger_battle_end(BattleEnums.EBattleResult.Defeat)
	else:
		print("[BattleFlowManager] Round %d complete, accumulating costs..." % _current_round)
		if _current_report == null:
			print("[BattleFlowManager] WARNING: _current_report is null!")
		else:
			print("[BattleFlowManager] _current_report.cards_to_remove: %s" % _current_report.cards_to_remove)
		if _battle_report == null:
			_battle_report = BattleReport.new()
		if _current_report:
			for card_id in _current_report.cards_to_remove:
				if not _battle_report.cards_to_remove.has(card_id):
					_battle_report.cards_to_remove.append(card_id)
					print("[BattleFlowManager] Added %s to _battle_report.cards_to_remove" % card_id)
		print("[BattleFlowManager] _battle_report.cards_to_remove now: %s" % _battle_report.cards_to_remove)
		_set_state(State.PLAYER_SELECTING)
		round_can_select.emit(_current_score)

func _trigger_battle_end(result: BattleEnums.EBattleResult) -> void:
	_set_state(State.BATTLE_END)

	if _battle_report == null:
		_battle_report = BattleReport.new()
	_battle_report.result = result
	_battle_report.player_wins = _current_score[0]
	_battle_report.enemy_wins = _current_score[1]

	# Accumulate costs one final time before battle ends
	if _current_report:
		for card_id in _current_report.cards_to_remove:
			if not _battle_report.cards_to_remove.has(card_id):
				_battle_report.cards_to_remove.append(card_id)
				print("[BattleFlowManager] Final cost added: %s" % card_id)

	print("[BattleFlowManager] Battle ENDED: %s, scores: %d-%d, cards_to_remove: %s" % [
		result, _current_score[0], _current_score[1], _battle_report.cards_to_remove])

	_publish("Flow_BattleEnd", {"result": result, "report": _battle_report})
	battle_end.emit(_battle_report)

func _create_battle_report(result: BattleEnums.EBattleResult) -> BattleReport:
	var report = BattleReport.new()
	report.result = result
	report.player_wins = _current_score[0]
	report.enemy_wins = _current_score[1]
	report.rounds = []
	report.cards_to_add = []
	report.cards_to_remove = []
	report.disabled_instance_ids = []
	return report

func _select_enemy_cards() -> Array[String]:
	if _enemy == null:
		return []

	var result: Array[String] = []
	var available = _enemy.deck_prototype_ids.duplicate()

	for i in range(mini(3, available.size())):
		if available.size() == 0:
			break
		var idx = randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)

	return result

func _sum_player_values() -> int:
	var total = 0
	if _current_player_snapshot:
		for card in _current_player_snapshot.cards:
			total += card.final_value
	return total

func _sum_enemy_values() -> int:
	var total = 0
	var registry = _data_manager.card_registry
	for card_id in _current_enemy_card_ids:
		var proto = registry.get_prototype(card_id)
		if proto:
			total += proto.base_value
	return total

func _publish(event_type: String, payload) -> void:
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.Publish(event_type, payload)
