## Standalone battle orchestrator for BattleUI.
##
## Responsibility:
## - Handle card selection and battle flow
## - Calculate battle results and manage score
## - Use new BattleFlow for 6-phase state machine
class_name BattleRunner
extends Node

signal battle_ended(result: int, report: BattleReport)

@export var target_wins: int = 3

var _card_manager: Node = null
var _data_manager: Node = null
var _all_cards: Array = []
var _current_enemy: EnemyData = null
var _player_score: int = 0
var _enemy_score: int = 0
var _battle_ui: Node = null
var _battle_in_progress: bool = false
var _battle_flow: BattleFlow = null

func _ready() -> void:
	_card_manager = get_node_or_null("/root/CardMgr")
	_data_manager = get_node_or_null("/root/DataManager")

func setup(battle_ui: Node, enemy: EnemyData) -> void:
	_battle_ui = battle_ui
	_current_enemy = enemy
	_player_score = 0
	_enemy_score = 0
	_battle_in_progress = false

	if _battle_ui:
		_battle_ui.cards_confirmed.connect(_on_cards_confirmed)

	_setup_battle_flow()
	_start_battle()
	print("[BattleRunner] Setup complete with enemy: %s" % enemy.get_enemy_name())

func _start_battle() -> void:
	if not _card_manager:
		push_error("[BattleRunner] CardMgr not available!")
		return

	var all_card_ids: Array = []
	for card in _card_manager.get_all_cards():
		var c: CardInstance = card as CardInstance
		if c:
			all_card_ids.append(c.get_card_id())

	if all_card_ids.size() == 0:
		push_error("[BattleRunner] No cards in deck! Cannot start battle.")
		return

	var snapshot = _card_manager.get_deck_snapshot(all_card_ids)
	var config = BattleConfig.from_enemy_data(_current_enemy)
	config.target_wins = target_wins
	config.enable_card_consumption = false  # 暂时禁用消耗，后续添加补牌机制后启用

	if _battle_flow:
		_battle_flow.start_battle(snapshot, _current_enemy, config)

func _setup_battle_flow() -> void:
	_battle_flow = BattleFlow.new()
	_battle_flow.initialize(_card_manager, _data_manager, get_node_or_null("/root/EventBus"))
	_battle_flow.battle_end.connect(_on_battle_end)
	_battle_flow.round_info.connect(_on_round_info)
	add_child(_battle_flow)

func _on_cards_confirmed(selected_ids: Array) -> void:
	if _battle_in_progress:
		return
	if selected_ids.size() == 0:
		return

	_battle_in_progress = true
	print("[BattleRunner] Cards confirmed: %d" % selected_ids.size())

	if _battle_flow:
		_battle_flow.confirm_selection(selected_ids)

func _on_round_info(scores: Array, round_num: int) -> void:
	if scores.size() >= 2:
		_player_score = scores[0]
		_enemy_score = scores[1]
		print("[BattleRunner] Round %d: Player %d vs Enemy %d" % [round_num, _player_score, _enemy_score])

func _on_battle_end(result: BattleEnums.EBattleResult, report: BattleReport) -> void:
	_battle_in_progress = false
	print("[BattleRunner] Battle ended: %s" % BattleEnums.battle_result_to_string(result))

	if _battle_ui:
		_battle_ui.enable_selection(false)

	battle_ended.emit(result, report)

	print("[BattleRunner] Returning to exploration...")
	get_tree().change_scene_to_file("res://scenes/Thryzhn/TestScenes/cave/cave/cave.tscn")

func get_battle_flow() -> BattleFlow:
	return _battle_flow
