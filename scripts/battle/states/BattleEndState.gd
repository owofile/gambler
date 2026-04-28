## 战斗结束状态
class_name BattleEndState
extends BattleState

var _result: int = 0

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "BattleEnd"

func enter() -> void:
	_core.notify_state_changed(_state_name)
	_result = _core.get_battle_result()
	_core.ui_show_battle_result(_result)
	play_animation("battle_end")

func on_animation_complete() -> void:
	var report = _core.generate_report()
	_core.notify_battle_completed(_result, report)
