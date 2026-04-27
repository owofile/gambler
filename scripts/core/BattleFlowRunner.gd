## Orchestrates battles using the new BattleFlow system.
##
## Responsibility:
## - Set up battle environment
## - Create BattleFlow and manage its lifecycle
## - Connect to UI for player interaction
## - Handle battle result and rewards
##
## Usage:
##   var runner = BattleFlowRunner.new()
##   runner.setup(battle_ui, enemy)
##   runner.start_battle()
class_name BattleFlowRunner
extends Node

signal battle_ended(result: int, report: BattleReport)

@export var target_wins: int = 3

var _card_manager: Node = null
var _data_manager: Node = null
var _event_bus: Node = null
var _all_cards: Array = []
var _current_enemy: EnemyData = null
var _battle_ui: Node = null
var _battle_flow: BattleFlow = null
var _config: BattleConfig = null
var _battle_in_progress: bool = false

func _ready() -> void:
	_card_manager = get_node_or_null("/root/CardMgr")
	_data_manager = get_node_or_null("/root/DataManager")
	_event_bus = get_node_or_null("/root/EventBus")

func setup(battle_ui: Node, enemy: EnemyData) -> void:
	_battle_ui = battle_ui
	_current_enemy = enemy

	_battle_flow = BattleFlow.new()
	_battle_flow.initialize(_card_manager, _data_manager, _event_bus)
	_battle_flow.phase_changed.connect(_on_phase_changed)
	_battle_flow.battle_end.connect(_on_battle_end)
	_battle_flow.round_info.connect(_on_round_info)

	add_child(_battle_flow)

	match enemy.get_tier():
		EnemyData.EnemyTier.Grunt:
			target_wins = 3
		EnemyData.EnemyTier.Elite:
			target_wins = 4
		EnemyData.EnemyTier.Boss:
			target_wins = 5
		_:
			target_wins = 3

	print("[BattleFlowRunner] Setup complete with enemy: %s (target: %d wins)" % [enemy.get_enemy_name(), target_wins])

func start_battle() -> void:
	if _battle_in_progress:
		return

	if not _check_deck_size():
		push_error("[BattleFlowRunner] Cannot start battle: not enough cards!")
		_show_error("卡牌不足，无法开始战斗！")
		return

	_battle_in_progress = true
	_all_cards = _card_manager.get_all_cards()

	_config = BattleConfig.from_enemy_data(_current_enemy)
	_config.target_wins = target_wins

	var snapshot = _card_manager.get_deck_snapshot(_get_all_card_ids())
	_battle_flow.start_battle(snapshot, _current_enemy, _config)

	if _battle_ui:
		_battle_ui.setup_battle(_current_enemy)

func _check_deck_size() -> bool:
	if not _card_manager:
		return false
	return _card_manager.get_deck_size() >= _config.cards_per_round

func _get_all_card_ids() -> Array:
	var ids: Array = []
	for card in _all_cards:
		var c: CardInstance = card as CardInstance
		if c:
			ids.append(c.get_card_id())
	return ids

func confirm_selection(card_instance_ids: Array) -> void:
	if _battle_flow and _battle_flow.get_current_phase() == BattleFlow.Phase.PLAYER_SELECT:
		_battle_flow.confirm_selection(card_instance_ids)

func _on_phase_changed(new_phase: BattleFlow.Phase) -> void:
	print("[BattleFlowRunner] Phase changed to: %s" % BattleFlow.Phase.keys()[new_phase])

	match new_phase:
		BattleFlow.Phase.PLAYER_SELECT:
			if _battle_ui:
				_battle_ui.enable_selection(true)
		BattleFlow.Phase.ENEMY_REVEAL:
			if _battle_ui:
				_battle_ui.enable_selection(false)
		BattleFlow.Phase.SETTLE:
			pass
		BattleFlow.Phase.CONSUME:
			pass
		BattleFlow.Phase.ROUND_END:
			pass
		BattleFlow.Phase.BATTLE_END:
			pass

func _on_round_info(scores: Array, round_num: int) -> void:
	print("[BattleFlowRunner] Round %d: Score %d-%d" % [round_num, scores[0], scores[1]])
	if _battle_ui:
		_battle_ui.update_scores(scores)

func _on_battle_end(result: BattleEnums.EBattleResult, report: BattleReport) -> void:
	_battle_in_progress = false
	print("[BattleFlowRunner] Battle ended: %s" % BattleEnums.battle_result_to_string(result))

	if _battle_ui:
		_battle_ui.enable_selection(false)
		_battle_ui.on_battle_complete(report)

	battle_ended.emit(result, report)

	if report and result == BattleEnums.EBattleResult.Victory:
		_apply_loot(report)
	else:
		_apply_defeat_penalty(report)

func _apply_loot(report: BattleReport) -> void:
	var loot = report.get_cards_to_add()
	for prototype_id in loot:
		_card_manager.add_card(prototype_id)
		print("[BattleFlowRunner] Loot added: %s" % prototype_id)

func _apply_defeat_penalty(report: BattleReport) -> void:
	var to_remove = report.get_cards_to_remove()
	for card_id in to_remove:
		_card_manager.remove_card(card_id)
		print("[BattleFlowRunner] Card removed: %s" % card_id)

func _show_error(message: String) -> void:
	print("[BattleFlowRunner] ERROR: %s" % message)

func cleanup() -> void:
	if _battle_flow:
		_battle_flow.queue_free()
		_battle_flow = null
