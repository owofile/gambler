class_name IEffectHandler
extends RefCounted

func apply(context: EffectContext) -> void:
	pass

func get_priority() -> int:
	return EffectEnums.EffectPriority.BuffDebuff