## Report generated after a battle concludes.
##
## Responsibility:
## - Store battle result and statistics
## - Track cards to add/remove after battle
## - Track disabled cards
class_name BattleReport
extends RefCounted

var _result: BattleEnums.EBattleResult = BattleEnums.EBattleResult.Defeat
var _player_wins: int = 0
var _enemy_wins: int = 0
var _rounds: Array = []
var _cards_to_add: Array = []
var _cards_to_remove: Array = []
var _disabled_instance_ids: Array = []
var _delayed_destroy_ids: Array = []

func _init() -> void:
	_rounds = []
	_cards_to_add = []
	_cards_to_remove = []
	_disabled_instance_ids = []
	_delayed_destroy_ids = []

func get_result() -> BattleEnums.EBattleResult:
	return _result

func set_result(value: BattleEnums.EBattleResult) -> void:
	_result = value

func get_player_wins() -> int:
	return _player_wins

func set_player_wins(value: int) -> void:
	if value < 0:
		push_warning("BattleReport: Player wins cannot be negative")
		value = 0
	_player_wins = value

func get_enemy_wins() -> int:
	return _enemy_wins

func set_enemy_wins(value: int) -> void:
	if value < 0:
		push_warning("BattleReport: Enemy wins cannot be negative")
		value = 0
	_enemy_wins = value

func get_rounds() -> Array:
	return _rounds.duplicate()

func add_round(round_detail: RoundDetail) -> void:
	if round_detail != null:
		_rounds.append(round_detail)

func get_cards_to_add() -> Array:
	return _cards_to_add.duplicate()

func add_card_to_add(prototype_id: String) -> void:
	if not prototype_id.is_empty() and not _cards_to_add.has(prototype_id):
		_cards_to_add.append(prototype_id)

func get_cards_to_remove() -> Array:
	return _cards_to_remove.duplicate()

func add_card_to_remove(instance_id: String) -> void:
	if not instance_id.is_empty() and not _cards_to_remove.has(instance_id):
		_cards_to_remove.append(instance_id)

func get_disabled_instance_ids() -> Array:
	return _disabled_instance_ids.duplicate()

func add_disabled_instance(instance_id: String) -> void:
	if not instance_id.is_empty() and not _disabled_instance_ids.has(instance_id):
		_disabled_instance_ids.append(instance_id)

func get_delayed_destroy_ids() -> Array:
	return _delayed_destroy_ids.duplicate()

func add_delayed_destroy(instance_id: String) -> void:
	if not instance_id.is_empty() and not _delayed_destroy_ids.has(instance_id):
		_delayed_destroy_ids.append(instance_id)

func is_card_disabled(instance_id: String) -> bool:
	return _disabled_instance_ids.has(instance_id)

func is_victory() -> bool:
	return _result == BattleEnums.EBattleResult.Victory

func is_defeat() -> bool:
	return _result == BattleEnums.EBattleResult.Defeat

func get_total_rounds() -> int:
	return _rounds.size()
