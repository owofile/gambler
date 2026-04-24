class_name RoundDetail
extends RefCounted

var round_number: int
var player_card_ids: Array[String]
var enemy_card_ids: Array[String]
var player_total_value: int
var enemy_total_value: int
var result: BattleEnums.ERoundResult

func _init() -> void:
	player_card_ids = []
	enemy_card_ids = []