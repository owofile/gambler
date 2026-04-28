## Immutable snapshot of a card at the time of battle selection.
##
## Responsibility:
## - Store card data captured during battle selection
## - Provide read-only access to card information
## - Calculate final battle value
class_name CardSnapshot
extends RefCounted

var _instance_id: String = ""
var _prototype_id: String = ""
var _final_value: int = 0
var _card_class: CardData.CardClass = CardData.CardClass.Artifact
var _effect_ids: Array = []
var _cost_id: String = ""
var _bind_status: CardData.CardBindStatus = CardData.CardBindStatus.None

func _init() -> void:
	_effect_ids = []
	_cost_id = ""

func get_card_id() -> String:
	return _instance_id

func set_card_id(value: String) -> void:
	if value.is_empty():
		push_error("CardSnapshot: Card ID cannot be empty")
		return
	_instance_id = value

func get_prototype_id() -> String:
	return _prototype_id

func set_prototype_id(value: String) -> void:
	if value.is_empty():
		push_error("CardSnapshot: Prototype ID cannot be empty")
		return
	_prototype_id = value

func get_final_value() -> int:
	return _final_value

func set_final_value(value: int) -> void:
	if value < 0:
		push_warning("CardSnapshot: Final value should not be negative, clamping to 0")
		value = 0
	_final_value = value

func get_card_class() -> CardData.CardClass:
	return _card_class

func set_card_class(value: CardData.CardClass) -> void:
	_card_class = value

func get_effect_ids() -> Array:
	return _effect_ids.duplicate()

func add_effect_id(effect_id: String) -> void:
	if not effect_id.is_empty() and not _effect_ids.has(effect_id):
		_effect_ids.append(effect_id)

func get_cost_id() -> String:
	return _cost_id

func set_cost_id(value: String) -> void:
	_cost_id = value

func get_bind_status() -> CardData.CardBindStatus:
	return _bind_status

func set_bind_status(value: CardData.CardBindStatus) -> void:
	_bind_status = value

func has_cost() -> bool:
	return not _cost_id.is_empty()

func has_effect(effect_id: String) -> bool:
	return _effect_ids.has(effect_id)

func add_delta_value(delta: int) -> void:
	_final_value += delta
	if _final_value < 0:
		_final_value = 0

func clone() -> CardSnapshot:
	var new_snapshot = CardSnapshot.new()
	new_snapshot.set_card_id(_instance_id)
	new_snapshot.set_prototype_id(_prototype_id)
	new_snapshot.set_final_value(_final_value)
	new_snapshot.set_card_class(_card_class)
	for eff_id in _effect_ids:
		new_snapshot.add_effect_id(eff_id)
	new_snapshot.set_cost_id(_cost_id)
	new_snapshot.set_bind_status(_bind_status)
	return new_snapshot
