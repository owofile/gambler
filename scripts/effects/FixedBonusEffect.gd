class_name FixedBonusEffect
extends IEffectHandler

var _bonus_value: int

func _init(value: int = 0) -> void:
	_bonus_value = value

func apply(context: EffectContext) -> void:
	context.current_player_total += _bonus_value
	print("[FixedBonusEffect] Player bonus +%d, now %d" % [_bonus_value, context.current_player_total])

func get_priority() -> int:
	return EffectEnums.EffectPriority.ValueModifier