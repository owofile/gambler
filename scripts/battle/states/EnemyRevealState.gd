## 敌方出牌状态
class_name EnemyRevealState
extends BattleState

var _enemy_cards: Array = []

func _init(core: BattleCore) -> void:
	super._init(core)
	_state_name = "EnemyReveal"

func enter() -> void:
	_core.notify_state_changed(_state_name)
	_enemy_cards = _core.generate_enemy_cards()
	_core.ui_show_enemy_cards(_enemy_cards)
	play_animation("enemy_reveal")

func exit() -> void:
	pass

func on_animation_complete() -> void:
	call_deferred("_transition_to_next")

func _transition_to_next() -> void:
	_core.transition_to(SettlementState)
