## Standalone battle orchestrator for BattleUI.
##
## Responsibility:
## - Initialize deck if empty
## - Handle card selection and battle flow
## - Calculate battle results and manage score
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

const INITIAL_CARD_IDS: Array = [
	"card_rusty_sword",
	"card_friendly_spirit",
	"card_justice",
	"card_blood_oath",
	"card_vengeance",
	"card_kings_authority"
]

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
		_battle_ui.setup_battle(enemy)
	print("[BattleRunner] Setup complete with enemy: %s" % enemy.get_enemy_name())

func _on_cards_confirmed(selected_ids: Array) -> void:
	if _battle_in_progress:
		return
	if selected_ids.size() == 0:
		return

	_battle_in_progress = true
	print("[BattleRunner] Cards confirmed: %d" % selected_ids.size())

	var player_snapshot = _card_manager.get_deck_snapshot(selected_ids)
	var result = BattleManager.ProcessSelectedCards(player_snapshot, _current_enemy, _data_manager)

	var player_total = result.get("player_total", 0)
	var enemy_total = result.get("enemy_total", 0)
	var enemy_card_ids = result.get("enemy_card_ids", [])

	print("[BattleRunner] Round result - Player: %d vs Enemy: %d" % [player_total, enemy_total])

	var round_result: int
	if player_total > enemy_total:
		round_result = 1
		_player_score += 1
		print("[BattleRunner] Player wins round!")
	elif player_total < enemy_total:
		round_result = 2
		_enemy_score += 1
		print("[BattleRunner] Enemy wins round!")
	else:
		round_result = 0
		print("[BattleRunner] Draw!")

	_show_round_result(player_total, enemy_total, enemy_card_ids, round_result)

	if _player_score >= target_wins:
		_end_battle(1)
	elif _enemy_score >= target_wins:
		_end_battle(2)
	else:
		_battle_in_progress = false
		if _battle_ui:
			_battle_ui.clear_selection()

func _show_round_result(player_total: int, enemy_total: int, enemy_card_ids: Array, result: int) -> void:
	var result_text = "平局" if result == 0 else ("玩家胜利" if result == 1 else "敌人胜利")
	print("[BattleRunner] === 回合结果 ===")
	print("[BattleRunner] 玩家点数: %d vs 敌人点数: %d" % [player_total, enemy_total])
	print("[BattleRunner] 敌人出牌: " + str(enemy_card_ids))
	print("[BattleRunner] 当前比分: %d - %d" % [_player_score, _enemy_score])
	print("[BattleRunner] ====================")

func _end_battle(result: int) -> void:
	_battle_in_progress = false
	print("[BattleRunner] ===== 战斗结束 =====")
	print("[BattleRunner] 最终比分: %d - %d" % [_player_score, _enemy_score])
	print("[BattleRunner] 结果: %s" % ("玩家胜利" if result == 1 else "敌人胜利"))
	print("[BattleRunner] ======================")

	if _battle_ui:
		_battle_ui.enable_selection(false)
	battle_ended.emit(result, null)
