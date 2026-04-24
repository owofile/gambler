class_name BattleReport
extends RefCounted

var result: BattleEnums.EBattleResult
var player_wins: int
var enemy_wins: int
var rounds: Array[RoundDetail]
var cards_to_add: Array[String]
var cards_to_remove: Array[String]
var disabled_instance_ids: Array[String]

func _init() -> void:
	rounds = []
	cards_to_add = []
	cards_to_remove = []
	disabled_instance_ids = []