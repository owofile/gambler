## Effect Handler Interface
##
## All effect handlers must implement this interface.
## Effects modify battle state through EffectContext.
class_name IEffectHandler
extends RefCounted

## Get the trigger timing for this effect
func get_trigger_timing() -> int:
	return EffectTriggerTiming.Timing.IMMEDIATE

## Get target card IDs for this effect
## For SEQUENTIAL/DELAYED effects, returns which cards this effect targets
## source_card_id: The card that has this effect
## Returns: Array of card instance IDs that this effect applies to
func get_target_card_ids(context: EffectContext, source_card_id: String) -> Array:
	return [source_card_id]

## Apply the effect to the context
## This is called by the battle system to execute the effect
func apply(context: EffectContext) -> void:
	pass

## Get the execution priority within the same trigger timing
## Lower numbers execute first
func get_priority() -> int:
	return EffectEnums.EffectPriority.Normal

## Get effect description for UI display
func get_description() -> String:
	return ""

## For effects that modify specific cards (not totals)
## context: The effect context
## target_card_id: The card to modify
func apply_to_card(context: EffectContext, target_card_id: String) -> void:
	pass