## Reverses player and enemy totals.
class_name RuleReversalEffect
extends IEffectHandler

func apply(context: EffectContext) -> void:
	var temp: int = context.get_current_player_total()
	context.set_current_player_total(context.get_current_enemy_total())
	context.set_current_enemy_total(temp)

func get_priority() -> int:
	return EffectEnums.EffectPriority.RuleReversal
