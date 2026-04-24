class_name EffectRegistry
extends RefCounted

var _effects: Dictionary = {}

func _init() -> void:
	_register_all_effects()

func _register_all_effects() -> void:
	_effects["fixed_bonus_2"] = FixedBonusEffect.new(2)
	_effects["fixed_bonus_3"] = FixedBonusEffect.new(3)
	_effects["fixed_bonus_5"] = FixedBonusEffect.new(5)
	_effects["rule_reversal"] = RuleReversalEffect.new()

func get_effect(effect_id: String) -> IEffectHandler:
	if _effects.has(effect_id):
		return _effects[effect_id]
	return null

func get_all_effect_ids() -> Array[String]:
	return Array(_effects.keys(), TYPE_STRING, "", null)

func get_effects_sorted_by_priority(effect_ids: Array[String]) -> Array[IEffectHandler]:
	var handlers: Array[IEffectHandler] = []
	for eff_id in effect_ids:
		var handler = get_effect(eff_id)
		if handler:
			handlers.append(handler)

	handlers.sort_custom(func(a, b): return a.get_priority() < b.get_priority())
	return handlers