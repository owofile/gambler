## 战斗系统启动器
class_name BattleStarter
extends Node

@export var enemy_id: String = "enemy_skeletal_warrior"
@export var target_wins: int = 3

var _battle_core: BattleCore = null
var _battle_ui: CanvasLayer = null
var _card_manager: Node = null
var _data_manager: Node = null

func _ready() -> void:
	_card_manager = get_node_or_null("/root/CardMgr")
	_data_manager = get_node_or_null("/root/DataManager")

	if not _card_manager or not _data_manager:
		push_error("[BattleStarter] CardMgr or DataManager not found!")
		return

	print("[BattleStarter] Setting up test cards...")
	_setup_test_cards()
	print("[BattleStarter] Setting up battle...")
	_setup_battle_ui()
	_setup_battle_core()

func _setup_test_cards() -> void:
	var test_cards = [
		"card_booster_alpha",
		"card_booster_beta",
		"card_self_destruct",
		"card_delayed_death",
		"card_next_turn_ban",
		"card_power_sacrifice"
	]
	for proto_id in test_cards:
		_card_manager.add_card(proto_id)
	print("[BattleStarter] Added %d test cards" % test_cards.size())

func _setup_battle_ui() -> void:
	var scene = load("res://scenes/battle/BattleUI_V2.tscn")
	if scene:
		_battle_ui = scene.instantiate()
		add_child(_battle_ui)
		print("[BattleStarter] BattleUI loaded")
	else:
		push_error("[BattleStarter] Failed to load BattleUI_V2.tscn!")

func _setup_battle_core() -> void:
	_battle_core = BattleCore.new()
	_battle_core.initialize(_card_manager, _data_manager, _battle_ui)
	add_child(_battle_core)

	_battle_core.battle_completed.connect(_on_battle_completed)
	_battle_core.state_changed.connect(_on_state_changed)

	if _battle_ui and _battle_ui.has_signal("selection_confirmed"):
		_battle_ui.selection_confirmed.connect(_on_selection_confirmed)

	var enemy = _data_manager.enemy_registry.get_enemy(enemy_id)
	if not enemy:
		push_error("[BattleStarter] Enemy not found: %s" % enemy_id)
		return

	var config = BattleConfig.from_enemy_data(enemy)
	config.target_wins = target_wins
	config.deck_policy = NoConsumptionPolicy.new()

	print("[BattleStarter] Starting battle with %s" % enemy.get_enemy_name())
	_battle_core.start_battle(config)

func _on_state_changed(state_name: String) -> void:
	print("[BattleStarter] State: %s" % state_name)
	if _battle_ui and _battle_ui.has_method("update_score_display"):
		_battle_ui.update_score_display(
			_battle_core._player_wins,
			_battle_core._enemy_wins,
			target_wins
		)

func _on_selection_confirmed(card_ids: Array) -> void:
	print("[BattleStarter] Selection confirmed: %d cards" % card_ids.size())
	if _battle_core:
		_battle_core.on_selection_confirmed(card_ids)

func _on_battle_completed(result: int, report: BattleReport) -> void:
	print("[BattleStarter] Battle completed: %d" % result)
	print("[BattleStarter] Final: Player %d - Enemy %d" % [report.get_player_wins(), report.get_enemy_wins()])
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/Thryzhn/TestScenes/cave/cave/cave.tscn")
