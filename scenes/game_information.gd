extends Node2D

@onready var round_label: RichTextLabel = $round

var _total_rounds: int = 0
var _player_wins: int = 0
var _enemy_wins: int = 0
var _target_wins: int = 3
var _enemy_name: String = "Enemy"
var _event_bus: Node = null

func _ready() -> void:
	_event_bus = get_node_or_null("/root/EventBus")
	_subscribe_to_events()
	_update_display()

func _subscribe_to_events() -> void:
	if _event_bus:
		_event_bus.subscribe("Flow_BattleStart", _on_flow_battle_start)
		_event_bus.subscribe("Flow_RoundEnd", _on_flow_round_end)
		_event_bus.subscribe("Flow_BattleEnd", _on_flow_battle_end)

func _on_flow_battle_start(payload) -> void:
	_total_rounds = 0
	_player_wins = 0
	_enemy_wins = 0

	var enemy = payload.get("enemy", null)
	if enemy:
		_enemy_name = enemy.get_enemy_name()
		match enemy.get_tier():
			EnemyData.EnemyTier.Grunt:
				_target_wins = 3
			EnemyData.EnemyTier.Elite:
				_target_wins = 4
			EnemyData.EnemyTier.Boss:
				_target_wins = 5
			_:
				_target_wins = 3
	else:
		_target_wins = 3

	_update_display()

func _on_flow_round_end(payload) -> void:
	_total_rounds += 1

	var scores: Array = payload.get("scores", [0, 0])
	if scores.size() >= 2:
		_player_wins = scores[0]
		_enemy_wins = scores[1]

	_update_display()

func _on_flow_battle_end(payload) -> void:
	var result = payload.get("result", 0)
	var result_str = "Victory" if result == 1 else "Defeat"
	_update_display_with_result(result_str)

func _update_display() -> void:
	if not round_label:
		return

	var info_text = ""
	info_text += "==================\n"
	info_text += "   BATTLE INFO\n"
	info_text += "==================\n"
	info_text += "\n"
	info_text += "Enemy: %s\n" % _enemy_name
	info_text += "Target: First to %d wins\n" % _target_wins
	info_text += "\n"
	info_text += "------------------\n"
	info_text += "Round: %d\n" % _total_rounds
	info_text += "\n"
	info_text += "Player: %d\n" % _player_wins
	info_text += "Enemy:  %d\n" % _enemy_wins
	info_text += "\n"
	info_text += "------------------\n"
	info_text += "Goal: %d more wins\n" % (_target_wins - _player_wins) if _player_wins < _target_wins else "You won!\n"
	info_text += "==================\n"

	round_label.text = info_text

func _update_display_with_result(result_str: String) -> void:
	if not round_label:
		return

	var info_text = ""
	info_text += "==================\n"
	info_text += "   BATTLE END\n"
	info_text += "==================\n"
	info_text += "\n"
	info_text += "Enemy: %s\n" % _enemy_name
	info_text += "\n"
	info_text += "------------------\n"
	info_text += "Total Rounds: %d\n" % _total_rounds
	info_text += "\n"
	info_text += "Final Score:\n"
	info_text += "Player: %d\n" % _player_wins
	info_text += "Enemy:  %d\n" % _enemy_wins
	info_text += "\n"
	info_text += "==================\n"
	info_text += "   %s\n" % result_str
	info_text += "==================\n"

	round_label.text = info_text

func reset() -> void:
	_total_rounds = 0
	_player_wins = 0
	_enemy_wins = 0
	_target_wins = 3
	_enemy_name = "Enemy"
	_update_display()
