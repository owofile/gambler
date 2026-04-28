## 战斗状态基类
class_name BattleState
extends RefCounted

var _core: BattleCore = null
var _state_name: String = "BattleState"
var _animation_pending: bool = false
var _animation_skip: bool = true  # 默认跳过动画

func _init(core: BattleCore) -> void:
	_core = core

func get_name() -> String:
	return _state_name

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func on_animation_complete() -> void:
	pass

func on_player_card_selected(card_id: String) -> void:
	pass

func on_player_card_deselected(card_id: String) -> void:
	pass

func on_player_confirm(cards: Array) -> void:
	pass

func play_animation(anim_name: String) -> void:
	if _animation_skip:
		call_deferred("animation_callback")
		return

	_animation_pending = true
	_core.request_animation(anim_name)

func animation_callback() -> void:
	_animation_pending = false
	on_animation_complete()
