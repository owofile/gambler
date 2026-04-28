## 战斗系统压力测试脚本
##
## 用途: 直接测试BattleCore API，不依赖UI层
## 使用方法: 运行此脚本所在的场景，观察console输出
##
## ========== 配置说明 ==========
## 修改以下变量以调整测试行为:
##   _random_player_cards: 玩家是否随机选牌
##   _max_rounds: 最大回合数限制
##   _test_card_ids: 玩家手牌配置
##   _enemy_deck: 敌方卡组配置
##   enemy_deck_random: 敌方是否随机选牌
## ================================
class_name BattleStressTest
extends Node

## ===== 依赖节点 =====
var _card_manager: Node = null
var _data_manager: Node = null
var _battle_core: BattleCore = null
var _config: BattleConfig = null

## ===== 测试配置 =====
## 玩家使用的卡牌 prototype_id 列表
var _test_card_ids: Array = [
	"card_rusty_sword",      # 7点
	"card_ancient_shield",  # 8点
	"card_cursed_amulet",   # 8点
	"card_friendly_spirit",  # 5点
	"card_justice",         # 7点
	"card_vengeance"        # 8点 (代价: self_destroy)
]

## 敌方卡组 prototype_id 列表
var _enemy_deck: Array = [
	"card_rusty_sword",
	"card_ancient_shield",
	"card_cursed_amulet"
]

## 敌方数据
var _enemy_data: EnemyData = null

## ===== 测试参数 =====
## 是否随机选择玩家手牌
var _random_player_cards: bool = true

## 最大回合数限制 (防止无限循环)
var _max_rounds: int = 20

## ===== 状态跟踪 =====
var _player_wins: int = 0
var _enemy_wins: int = 0
var _round_count: int = 0

## ===== 生命周期 =====

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

## ===== 设置方法 =====

## 初始化玩家卡组
func _setup_test_deck() -> void:
	_card_manager.clear_all_cards()
	for proto_id in _test_card_ids:
		var card = _card_manager.add_card(proto_id)
		if card:
			print("[BattleStressTest] Added card: %s (id: %s)" % [proto_id, card.get_card_id()])
	print("[BattleStressTest] Total cards in deck: %d" % _card_manager.get_deck_size())

## 初始化战斗配置并启动
func _setup_battle() -> void:
	_battle_core = BattleCore.new()
	_battle_core.initialize(_card_manager, _data_manager, null)
	add_child(_battle_core)

	_battle_core.battle_completed.connect(_on_battle_completed)
	_battle_core.state_changed.connect(_on_state_changed)

	## 创建敌方数据
	_enemy_data = EnemyData.new(
		"enemy_skeletal_warrior",
		"Skeletal Warrior",
		EnemyData.EnemyTier.Grunt,
		_enemy_deck.duplicate(),
		[]
	)

	## 配置战斗参数
	_config = BattleConfig.new()
	_config.target_wins = 3              # 先赢3回合
	_config.cards_per_round = 3         # 每回合出3张牌
	_config.initial_hand_size = 6        # 初始手牌6张
	_config.enemy_data = _enemy_data
	_config.enemy_deck_order = _enemy_deck.duplicate()
	_config.enemy_deck_random = true     # 敌方随机选牌
	_config.deck_policy = NoConsumptionPolicy.new()  # 卡牌不消耗

	print("[BattleStressTest] Starting battle...")
	_battle_core.start_battle(_config)

## ===== 状态回调 =====

func _on_state_changed(state_name: String) -> void:
	print("[BattleStressTest] State changed: %s" % state_name)

	match state_name:
		"PlayerSelect":
			_process_player_selection()
		"RoundEnd":
			_process_round_end()
		"EnemyReveal":
			_process_enemy_reveal()
		"Settlement":
			_process_settlement()
		"BattleEnd":
			pass

## ===== 选牌逻辑 =====

## 处理玩家选牌
## 根据 _random_player_cards 选择随机或固定选牌
func _process_player_selection() -> void:
	var hand = _battle_core.get_player_hand()
	print("[BattleStressTest] PlayerSelect - hand size: %d" % hand.size())

	if hand.size() < _config.cards_per_round:
		print("[BattleStressTest] ERROR: Not enough cards in hand!")
		return

	var selected_ids: Array = []
	if _random_player_cards:
		## 随机选择: 洗牌后取前N张
		var available_indices: Array = []
		for i in range(hand.size()):
			available_indices.append(i)
		available_indices.shuffle()
		for i in range(_config.cards_per_round):
			var idx = available_indices[i]
			var card = hand[idx]
			selected_ids.append(card.get_card_id())
			print("[BattleStressTest]   Selected[%d]: %s (random)" % [i, card.get_card_id()])
	else:
		## 固定选择: 总是前N张
		for i in range(_config.cards_per_round):
			var card = hand[i]
			selected_ids.append(card.get_card_id())
			print("[BattleStressTest]   Selected[%d]: %s" % [i, card.get_card_id()])

	print("[BattleStressTest] Calling on_selection_confirmed with %d cards..." % selected_ids.size())
	_battle_core.on_selection_confirmed(selected_ids)

## 处理敌方卡牌显示
func _process_enemy_reveal() -> void:
	var enemy_cards = _battle_core.get_current_enemy_cards()
	print("[BattleStressTest] EnemyReveal - enemy cards: %s" % str(enemy_cards))

## 处理结算状态
func _process_settlement() -> void:
	print("[BattleStressTest] Settlement - waiting for round result...")

## 处理回合结束
func _process_round_end() -> void:
	_round_count += 1
	var player_hand = _battle_core.get_player_hand()
	var old_player_wins = _player_wins
	var old_enemy_wins = _enemy_wins
	_player_wins = _battle_core._player_wins
	_enemy_wins = _battle_core._enemy_wins

	print("[BattleStressTest] RoundEnd #%d - remaining cards: %d" % [_round_count, player_hand.size()])
	print("[BattleStressTest]   Score: Player %d vs Enemy %d (target: %d)" % [
		_player_wins, _enemy_wins, _config.target_wins])

	if _player_wins > old_player_wins:
		print("[BattleStressTest]   >>> Player won this round!")
	elif _enemy_wins > old_enemy_wins:
		print("[BattleStressTest]   >>> Enemy won this round!")
	else:
		print("[BattleStressTest]   >>> Draw!")

	## 检查最大回合数限制
	if _round_count >= _max_rounds:
		print("[BattleStressTest] MAX ROUNDS (%d) REACHED, forcing battle end!" % _max_rounds)
		_battle_core.force_battle_end()

## ===== 战斗结束 =====

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

## ===== 扩展指南 =====
## 1. 添加更多测试卡牌: 修改 _test_card_ids
## 2. 改变敌方策略: 修改 enemy_deck_random
## 3. 改变卡牌消耗规则: 替换 NoConsumptionPolicy
## 4. 添加AI对战: 在 _process_player_selection 中实现AI逻辑
## 5. 测试特定卡牌效果: 添加对应 prototype_id 到 _test_card_ids
