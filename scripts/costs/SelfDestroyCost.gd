class_name SelfDestroyCost
extends ICostHandler

func trigger(context: CostContext) -> void:
	if context.source_card and context.report:
		if not context.source_card.instance_id in context.report.cards_to_remove:
			context.report.cards_to_remove.append(context.source_card.instance_id)
			print("[SelfDestroyCost] Card %s will be destroyed" % context.source_card.instance_id)