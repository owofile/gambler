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
	_effects["boost_next_3"] = BoostNextCardEffect.new(3)
	_effects["boost_next_5"] = BoostNextCardEffect.new(5)

func get_effect(effect_id: String) -> IEffectHandler:
	if _effects.has(effect_id):
		return _effects[effect_id]
	return null

func get_all_effect_ids() -> Array:
	return Array(_effects.keys(), TYPE_STRING, "", null)

func get_effects_sorted_by_priority(effect_ids: Array) -> Array:
	var handlers: Array = []
	for eff_id in effect_ids:
		var handler = get_effect(eff_id)
		if handler:
			handlers.append(handler)

	handlers.sort_custom(func(a, b):
		var handler_a: IEffectHandler = a as IEffectHandler
		var handler_b: IEffectHandler = b as IEffectHandler
		if not handler_a or not handler_b:
			return false
		return handler_a.get_priority() < handler_b.get_priority()
	)
	return handlers

func get_effects_by_timing(effect_ids_with_source: Array) -> Dictionary:
	var by_timing: Dictionary = {}

	for item in effect_ids_with_source:
		var eff_id: String = item["effect_id"]
		var source_id: String = item["source_id"]
		var handler = get_effect(eff_id)
		if handler:
			var timing = handler.get_trigger_timing()
			if not by_timing.has(timing):
				by_timing[timing] = []
			by_timing[timing].append({
				"handler": handler,
				"source_id": source_id
			})

	for timing in by_timing.keys():
		var handlers = by_timing[timing]
		handlers.sort_custom(func(a, b):
			return a["handler"].get_priority() < b["handler"].get_priority()
		)

	return by_timing