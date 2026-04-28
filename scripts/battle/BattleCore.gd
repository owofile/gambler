## 战斗核心 - 状态机管理器
##
## Responsibility:
## - 管理战斗状态转换
## - 协调 UI 和数据管理
## - 处理卡牌消耗/补充
class_name BattleCore
extends Node

signal battle_started()
signal battle_completed(result: int, report: BattleReport)
signal state_changed(state_name: String)
signal animation_requested(anim_name: String)

var _current_state: BattleState = null
var _config: BattleConfig = null
var _card_manager: Node = null
var _data_manager: Node = null
var _ui: CanvasLayer = null

var _player_wins: int = 0
var _enemy_wins: int = 0
var _round_number: int = 0
var _player_cards: Array = []
var _enemy_cards: Array = []
var _battle_report: BattleReport = null
var _settlement_cards_to_remove: Array = []
var _settlement_cards_to_add: Array = []
var _pending_destroy_card_ids: Array = []

func get_settlement_cards_to_remove() -> Array:
	return _settlement_cards_to_remove.duplicate()

func get_settlement_cards_to_add() -> Array:
	return _settlement_cards_to_add.duplicate()

func get_pending_destroy_card_ids() -> Array:
	return _pending_destroy_card_ids.duplicate()

func add_pending_destroy_cards(card_ids: Array) -> void:
	for cid in card_ids:
		if not _pending_destroy_card_ids.has(cid):
			_pending_destroy_card_ids.append(cid)

func clear_pending_destroy_cards() -> void:
	_pending_destroy_card_ids.clear()

func initialize(card_manager: Node, data_manager: Node, ui: CanvasLayer) -> void:
	_card_manager = card_manager
	_data_manager = data_manager
	_ui = ui

	if _ui and _ui.has_signal("animation_finished"):
		_ui.animation_finished.connect(_on_ui_animation_finished)

func _on_ui_animation_finished(anim_name: String) -> void:
	print("[BattleCore] Animation finished: %s" % anim_name)
	on_animation_complete()

func start_battle(config: BattleConfig) -> void:
	_config = config
	_player_wins = 0
	_enemy_wins = 0
	_round_number = 0
	_player_cards.clear()
	_enemy_cards.clear()

	_battle_report = BattleReport.new()
	_battle_report.set_player_wins(0)
	_battle_report.set_enemy_wins(0)

	var initial_hand = _config.deck_policy.on_round_start(
		_card_manager.get_deck_size(),
		_config.initial_hand_size
	)
	for proto_id in initial_hand:
		_card_manager.add_card(proto_id)

	battle_started.emit()
	transition_to(PlayerSelectState)

func transition_to(state_class: GDScript) -> void:
	if _current_state:
		_current_state.exit()
		if not is_instance_valid(_current_state):
			return

	var new_state = state_class.new(self)
	_current_state = new_state
	_current_state.enter()

func get_config() -> BattleConfig:
	return _config

func get_deck_policy() -> IDeckPolicy:
	return _config.deck_policy

func get_player_hand() -> Array:
	return _card_manager.get_all_cards()

func get_deck_size() -> int:
	return _card_manager.get_deck_size()

func get_current_player_cards() -> Array:
	return _player_cards

func get_current_enemy_cards() -> Array:
	return _enemy_cards

func generate_enemy_cards() -> Array:
	var cards = _config.get_enemy_cards(_config.cards_per_round)
	_enemy_cards = cards
	return cards

func calculate_settlement(player_cards: Array, enemy_cards: Array) -> Dictionary:
	var player_snapshot = _card_manager.get_deck_snapshot(player_cards)
	var result = BattleManager.ProcessSelectedCards(
		player_snapshot,
		get_enemy_data(),
		_data_manager
	)
	return result

func get_enemy_data() -> EnemyData:
	return _config.enemy_data

func record_round_result(winner: String) -> void:
	_round_number += 1
	match winner:
		"player":
			_player_wins += 1
		"enemy":
			_enemy_wins += 1

func check_battle_end() -> bool:
	print("[BattleCore] check_battle_end: player_wins=%d/%d, enemy_wins=%d/%d, deck_size=%d, cards_per_round=%d" % [
		_player_wins, _config.target_wins,
		_enemy_wins, _config.target_wins,
		_card_manager.get_deck_size(), _config.cards_per_round
	])
	var result = _player_wins >= _config.target_wins or _enemy_wins >= _config.target_wins or not _config.deck_policy.can_continue(_card_manager.get_deck_size(), _config.cards_per_round)
	print("[BattleCore] check_battle_end result: %s" % result)
	return result

func get_battle_result() -> int:
	if _player_wins >= _config.target_wins:
		return BattleEnums.EBattleResult.Victory
	return BattleEnums.EBattleResult.Defeat

func force_battle_end() -> void:
	transition_to(BattleEndState)

func generate_report() -> BattleReport:
	_battle_report.set_result(get_battle_result())
	_battle_report.set_player_wins(_player_wins)
	_battle_report.set_enemy_wins(_enemy_wins)
	return _battle_report

func record_settlement_cards(cards_to_remove: Array, cards_to_add: Array) -> void:
	_settlement_cards_to_remove = cards_to_remove.duplicate()
	_settlement_cards_to_add = cards_to_add.duplicate()
	print("[BattleCore] Recorded settlement cards to remove: %d, add: %d" % [_settlement_cards_to_remove.size(), _settlement_cards_to_add.size()])

func apply_settlement_cards() -> void:
	for card_id in _settlement_cards_to_remove:
		var removed = _card_manager.remove_card(card_id)
		print("[BattleCore] Settlement card removed: %s (success=%s)" % [card_id, removed])
	for proto_id in _settlement_cards_to_add:
		var added = _card_manager.add_card(proto_id)
		print("[BattleCore] Settlement card added: %s" % proto_id)

func clear_settlement_cards() -> void:
	_settlement_cards_to_remove.clear()
	_settlement_cards_to_add.clear()

func remove_card_from_deck(card_id: String) -> void:
	_card_manager.remove_card(card_id)

func add_card_to_deck(proto_id: String) -> void:
	_card_manager.add_card(proto_id)

func get_card_manager() -> Node:
	return _card_manager

func get_data_manager() -> Node:
	return _data_manager

func request_animation(anim_name: String) -> void:
	animation_requested.emit(anim_name)

func on_animation_complete() -> void:
	if _current_state:
		_current_state.animation_callback()

func on_selection_confirmed(card_ids: Array) -> void:
	if _current_state:
		_player_cards = card_ids
		_current_state.on_player_confirm(card_ids)

func notify_battle_completed(result: int, report: BattleReport) -> void:
	battle_completed.emit(result, report)

func notify_state_changed(state_name: String) -> void:
	state_changed.emit(state_name)

func ui_show_hand(cards: Array) -> void:
	if _ui and _ui.has_method("show_hand"):
		_ui.show_hand(cards)

func ui_enable_selection(enabled: bool) -> void:
	if _ui == null:
		return
	if _ui.has_method("enable_selection"):
		_ui.enable_selection(enabled)

func ui_highlight_card(card_id: String, highlight: bool) -> void:
	if _ui and _ui.has_method("highlight_card"):
		_ui.highlight_card(card_id, highlight)

func ui_show_selection_confirmed(cards: Array) -> void:
	if _ui and _ui.has_method("show_selection_confirmed"):
		_ui.show_selection_confirmed(cards)

func ui_show_enemy_cards(cards: Array) -> void:
	if _ui and _ui.has_method("show_enemy_cards"):
		_ui.show_enemy_cards(cards)

func ui_show_settlement(player_score: int, enemy_score: int, winner: String) -> void:
	if _ui and _ui.has_method("show_settlement"):
		_ui.show_settlement(player_score, enemy_score, winner)

func ui_clear_selection() -> void:
	if _ui and _ui.has_method("clear_selection"):
		_ui.clear_selection()

func ui_show_battle_result(result: int) -> void:
	if _ui and _ui.has_method("show_battle_result"):
		_ui.show_battle_result(result)

signal destroy_animation_requested(cards_to_destroy: Array)

func ui_play_destroy_animation(card_ids: Array, callback: Callable) -> void:
	if _ui and _ui.has_method("play_destroy_animation"):
		_ui.play_destroy_animation(card_ids, callback)
	else:
		callback.call()
		apply_settlement_cards()

func on_destroy_animation_complete() -> void:
	apply_settlement_cards()
