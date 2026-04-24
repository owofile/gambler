## Context passed to cost handlers during battle.
##
## Responsibility:
## - Provide cost handlers with necessary battle context
## - Allow cost handlers to modify the battle report
class_name CostContext
extends RefCounted

var _effect_context: EffectContext = null
var _report: BattleReport = null
var _source_card: CardSnapshot = null
var _owner: String = ""

func _init(
	ctx: EffectContext = null,
	r: BattleReport = null,
	card: CardSnapshot = null,
	o: String = ""
) -> void:
	_effect_context = ctx
	_report = r
	_source_card = card
	_owner = o

func get_effect_context() -> EffectContext:
	return _effect_context

func get_report() -> BattleReport:
	return _report

func get_source_card() -> CardSnapshot:
	return _source_card

func get_owner() -> String:
	return _owner

## Schedules the source card to be destroyed.
func destroy_source_card() -> void:
	if _source_card != null and _report != null:
		var card_id = _source_card.get_card_id()
		if not _report.get_cards_to_remove().has(card_id):
			_report.add_card_to_remove(card_id)
			print("[SelfDestroyCost] Card %s will be destroyed" % card_id)

## Disables the source card for the next turn.
func disable_source_card() -> void:
	if _source_card != null and _report != null:
		_report.add_disabled_instance(_source_card.get_card_id())
