## Adds bonus to the next card in selection order.
##
## Example: Card A has effect "boost_next_3", Card B is played after Card A.
## When Card A's effect triggers, Card B's value increases by 3.
class_name BoostNextCardEffect
extends IEffectHandler

var _bonus: int

func _init(bonus: int = 0) -> void:
	_bonus = bonus

func get_trigger_timing() -> int:
	return EffectTriggerTiming.Timing.DELAYED_NEXT

func get_target_card_ids(context: EffectContext, source_card_id: String) -> Array:
	var next_card = context.get_next_card_in_order(source_card_id)
	if not next_card.is_empty():
		return [next_card]
	return []

func apply(context: EffectContext) -> void:
	pass

func apply_to_card(context: EffectContext, target_card_id: String) -> void:
	var card = context.get_card_snapshot_by_id(target_card_id)
	if card:
		card.add_delta_value(_bonus)

func get_priority() -> int:
	return EffectEnums.EffectPriority.ValueModifier

func get_description() -> String:
	return "+%d 点到下一张牌" % _bonus