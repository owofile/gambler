class_name RuleReversalEffect
extends IEffectHandler

func apply(context: EffectContext) -> void:
	var temp: int = context.current_player_total
	context.current_player_total = context.current_enemy_total
	context.current_enemy_total = temp
	print("[RuleReversalEffect] Totals reversed - Player: %d, Enemy: %d" % [context.current_player_total, context.current_enemy_total])

func get_priority() -> int:
	return EffectEnums.EffectPriority.RuleReversal