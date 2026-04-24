## Cost that disables the card for the next turn.
class_name NextTurnUnusableCost
extends ICostHandler

func trigger(context: CostContext) -> void:
	if context.get_source_card() != null and context.get_report() != null:
		context.disable_source_card()
