## Cost that reduces the card's value by a percentage or fixed amount.
class_name ValueReductionCost
extends ICostHandler

var _reduction_amount: int
var _is_percentage: bool

func _init(amount: int = 0, percentage: bool = false) -> void:
	_reduction_amount = amount
	_is_percentage = percentage

func trigger(context: CostContext) -> void:
	if context.get_source_card() == null:
		return

	var card = context.get_source_card()
	var current_value = card.get_final_value()
	var reduction = _reduction_amount

	if _is_percentage:
		reduction = int(current_value * (_reduction_amount / 100.0))

	var new_value = maxi(current_value - reduction, 0)
	card.set_final_value(new_value)
	print("[ValueReductionCost] Card %s reduced by %d (percentage=%s), new value: %d" % [
		card.get_card_id(), reduction, _is_percentage, new_value])