class_name RoundDetail
extends RefCounted

var round_number: int = 0
var player_card_ids: Array = []
var enemy_card_ids: Array = []
var player_total_value: int = 0
var enemy_total_value: int = 0
var result: BattleEnums.ERoundResult = BattleEnums.ERoundResult.Draw

func _init() -> void:
	player_card_ids = []
	enemy_card_ids = []
