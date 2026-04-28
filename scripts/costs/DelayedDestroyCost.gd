## Cost that marks a card to be destroyed at the end of next round.
## Unlike self_destroy which destroys immediately, this destroys after a full round cycle.
class_name DelayedDestroyCost
extends ICostHandler

func trigger(context: CostContext) -> void:
	if context.get_source_card() == null or context.get_report() == null:
		return

	var card_id = context.get_source_card().get_card_id()
	context.get_report().add_delayed_destroy(card_id)
	print("[DelayedDestroyCost] Card %s marked for delayed destruction" % card_id)