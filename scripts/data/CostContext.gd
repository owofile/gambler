class_name CostContext
extends RefCounted

var effect_context: EffectContext
var report: BattleReport
var source_card: CardSnapshot
var owner: String

func _init(
	ctx: EffectContext = null,
	r: BattleReport = null,
	card: CardSnapshot = null,
	o: String = ""
) -> void:
	effect_context = ctx
	report = r
	source_card = card
	owner = o