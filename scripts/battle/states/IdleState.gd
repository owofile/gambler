## 空闲状态 - 等待战斗开始
class_name IdleState
extends BattleState

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "Idle"

func enter() -> void:
	_core.notify_state_changed(_state_name)

func exit() -> void:
	pass
