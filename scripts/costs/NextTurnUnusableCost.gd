class_name NextTurnUnusableCost
extends ICostHandler

func trigger(context: CostContext) -> void:
	if context.source_card and context.report:
		if not "disabled_instance_ids" in context.report:
			context.report.disabled_instance_ids = []
		context.report.disabled_instance_ids.append(context.source_card.instance_id)
		print("[NextTurnUnusableCost] Card %s disabled for next turn" % context.source_card.instance_id)