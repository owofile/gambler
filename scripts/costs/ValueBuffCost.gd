## Cost that buffs the card's value by a fixed amount or percentage.
class_name ValueBuffCost
extends ICostHandler

var _buff_amount: int
var _is_percentage: bool

func _init(amount: int = 0, percentage: bool = false) -> void:
	_buff_amount = amount
	_is_percentage = percentage

func trigger(context: CostContext) -> void:
	if context.get_source_card() == null:
		return

	var card = context.get_source_card()
	var current_value = card.get_final_value()
	var buff = _buff_amount

	if _is_percentage:
		buff = int(current_value * (_buff_amount / 100.0))

	var new_value = current_value + buff
	card.set_final_value(new_value)
	print("[ValueBuffCost] Card %s buffed by %d (percentage=%s), new value: %d" % [
		card.get_card_id(), buff, _is_percentage, new_value])