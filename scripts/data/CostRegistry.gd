class_name CostRegistry
extends RefCounted

var _costs: Dictionary = {}

func _init() -> void:
	_register_all_costs()

func _register_all_costs() -> void:
	_costs["next_turn_unusable"] = NextTurnUnusableCost.new()
	_costs["self_destroy"] = SelfDestroyCost.new()
	_costs["delayed_destroy"] = DelayedDestroyCost.new()
	_costs["value_buff_2"] = ValueBuffCost.new(2)
	_costs["value_buff_3"] = ValueBuffCost.new(3)
	_costs["value_reduction_2"] = ValueReductionCost.new(2)

func get_cost(cost_id: String) -> ICostHandler:
	if _costs.has(cost_id):
		return _costs[cost_id]
	return null

func get_all_cost_ids() -> Array:
	return Array(_costs.keys(), TYPE_STRING, "", null)