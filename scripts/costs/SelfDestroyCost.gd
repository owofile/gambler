## Cost that destroys the card after battle.
class_name SelfDestroyCost
extends ICostHandler

func trigger(context: CostContext) -> void:
	if context.get_source_card() != null and context.get_report() != null:
		context.destroy_source_card()
