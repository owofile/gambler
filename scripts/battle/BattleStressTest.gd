## 战斗系统压力测试脚本
##
## 用途: 直接测试BattleCore API，不依赖UI层
## 使用方法: 运行此脚本所在的场景，观察console输出
class_name BattleStressTest
extends Node

var _card_manager: Node = null
var _data_manager: Node = null
var _battle_core: BattleCore = null
var _config: BattleConfig = null

var _test_card_ids: Array = [
	"card_rusty_sword",
	"card_ancient_shield",
	"card_cursed_amulet",
	"card_friendly_spirit",
	"card_justice",
	"card_vengeance"
]

var _enemy_deck: Array = [
	"card_rusty_sword",
	"card_ancient_shield",
	"card_cursed_amulet"
]

var _player_wins: int = 0
var _enemy_wins: int = 0
var _round_count: int = 0

func _ready() -> void:
	print("========================================")
	print("[BattleStressTest] Starting stress test...")
	print("========================================")

	_card_manager = get_node_or_null("/root/CardMgr")
	_data_manager = get_node_or_null("/root/DataManager")

	if not _card_manager:
		push_error("[BattleStressTest] CardMgr not found!")
		return
	if not _data_manager:
		push_error("[BattleStressTest] DataManager not found!")
		return

	_setup_test_deck()
	_setup_battle()

func _setup_test_deck() -> void:
	_card_manager.clear_all_cards()
	for proto_id in _test_card_ids:
		var card = _card_manager.add_card(proto_id)
		if card:
			print("[BattleStressTest] Added card: %s (id: %s)" % [proto_id, card.get_card_id()])
	print("[BattleStressTest] Total cards in deck: %d" % _card_manager.get_deck_size())

func _setup_battle() -> void:
	_battle_core = BattleCore.new()
	_battle_core.initialize(_card_manager, _data_manager, null)
	add_child(_battle_core)

	_battle_core.battle_completed.connect(_on_battle_completed)
	_battle_core.state_changed.connect(_on_state_changed)

	_config = BattleConfig.new()
	_config.target_wins = 3
	_config.cards_per_round = 3
	_config.initial_hand_size = 6
	_config.enemy_deck_order = _enemy_deck.duplicate()
	_config.deck_policy = NoConsumptionPolicy.new()

	print("[BattleStressTest] Starting battle...")
	_battle_core.start_battle(_config)

func _on_state_changed(state_name: String) -> void:
	print("[BattleStressTest] State changed: %s" % state_name)

	match state_name:
		"PlayerSelect":
			_process_player_selection()
		"RoundEnd":
			_process_round_end()
		"Settlement":
			pass
		"EnemyReveal":
			pass

func _process_player_selection() -> void:
	var hand = _battle_core.get_player_hand()
	print("[BattleStressTest] PlayerSelect - hand size: %d" % hand.size())

	if hand.size() < _config.cards_per_round:
		print("[BattleStressTest] ERROR: Not enough cards in hand!")
		return

	var selected_ids: Array = []
	for i in range(_config.cards_per_round):
		var card = hand[i]
		selected_ids.append(card.get_card_id())
		print("[BattleStressTest]   Selected[%d]: %s" % [i, card.get_card_id()])

	print("[BattleStressTest] Calling on_selection_confirmed with %d cards..." % selected_ids.size())
	_battle_core.on_selection_confirmed(selected_ids)

func _process_round_end() -> void:
	_round_count += 1
	var player_hand = _battle_core.get_player_hand()
	print("[BattleStressTest] RoundEnd #%d - remaining cards: %d" % [_round_count, player_hand.size()])
	print("[BattleStressTest]   Score: Player %d vs Enemy %d (target: %d)" % [
		_battle_core._player_wins, _battle_core._enemy_wins, _config.target_wins])

	if _battle_core._player_wins > _player_wins:
		print("[BattleStressTest]   >>> Player won this round!")
		_player_wins = _battle_core._player_wins
	elif _battle_core._enemy_wins > _enemy_wins:
		print("[BattleStressTest]   >>> Enemy won this round!")
		_enemy_wins = _battle_core._enemy_wins
	else:
		print("[BattleStressTest]   >>> Draw!")

func _on_battle_completed(result: int, report: BattleReport) -> void:
	print("========================================")
	print("[BattleStressTest] BATTLE COMPLETED!")
	print("[BattleStressTest] Result: %d (%s)" % [result, "Victory" if result == 0 else "Defeat"])
	print("[BattleStressTest] Final Score - Player: %d, Enemy: %d" % [report.get_player_wins(), report.get_enemy_wins()])
	print("[BattleStressTest] Total Rounds: %d" % _round_count)
	print("========================================")

	await get_tree().create_timer(1.0).timeout
	print("[BattleStressTest] Test complete. Check results above.")
	get_tree().quit()
