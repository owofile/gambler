class_name BattleEndedPayload
extends RefCounted

var report: BattleReport

func _init(p_report: BattleReport = null) -> void:
	report = p_report