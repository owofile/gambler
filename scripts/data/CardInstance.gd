## Represents a card instance in the player's deck.
##
## Responsibility:
## - Track individual card state (instance ID, delta value, bind status)
## - Calculate total value with prototype
class_name CardInstance
extends RefCounted

var _instance_id: String = ""
var _prototype_id: String = ""
var _delta_value: int = 0
var _bind_status: CardData.CardBindStatus = CardData.CardBindStatus.None

func _init(
	p_instance_id: String = "",
	p_prototype_id: String = "",
	p_delta: int = 0,
	p_bind: CardData.CardBindStatus = CardData.CardBindStatus.None
) -> void:
	_instance_id = p_instance_id
	_prototype_id = p_prototype_id
	_delta_value = p_delta
	_bind_status = p_bind

func get_card_id() -> String:
	return _instance_id

func set_card_id(value: String) -> void:
	if value.is_empty():
		push_error("CardInstance: Card ID cannot be empty")
		return
	_instance_id = value

func get_prototype_id() -> String:
	return _prototype_id

func set_prototype_id(value: String) -> void:
	if value.is_empty():
		push_error("CardInstance: Prototype ID cannot be empty")
		return
	_prototype_id = value

func get_delta_value() -> int:
	return _delta_value

func set_delta_value(value: int) -> void:
	_delta_value = value

func get_bind_status() -> CardData.CardBindStatus:
	return _bind_status

func set_bind_status(value: CardData.CardBindStatus) -> void:
	_bind_status = value

func is_locked() -> bool:
	return _bind_status == CardData.CardBindStatus.Locked

func is_cursed() -> bool:
	return _bind_status == CardData.CardBindStatus.Cursed

func get_total_value(prototype: CardData) -> int:
	return prototype.base_value + _delta_value

func apply_delta(delta: int) -> void:
	_delta_value += delta

static func generate_id() -> String:
	return UUID.v4()

static func bind_status_to_string(status: CardData.CardBindStatus) -> String:
	match status:
		CardData.CardBindStatus.None:
			return "None"
		CardData.CardBindStatus.Locked:
			return "Locked"
		CardData.CardBindStatus.Cursed:
			return "Cursed"
	return "None"

static func string_to_bind_status(s: String) -> CardData.CardBindStatus:
	match s:
		"Locked":
			return CardData.CardBindStatus.Locked
		"Cursed":
			return CardData.CardBindStatus.Cursed
	return CardData.CardBindStatus.None
