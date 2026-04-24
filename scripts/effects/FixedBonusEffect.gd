## Adds a fixed bonus to player total.
class_name FixedBonusEffect
extends IEffectHandler

var _bonus_value: int

func _init(value: int = 0) -> void:
	_bonus_value = value

func apply(context: EffectContext) -> void:
	context.add_player_total(_bonus_value)

func get_priority() -> int:
	return EffectEnums.EffectPriority.ValueModifier
