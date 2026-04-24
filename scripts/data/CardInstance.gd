class_name CardInstance
extends RefCounted

var instance_id: String
var prototype_id: String
var delta_value: int
var bind_status: CardData.CardBindStatus

func _init(
	p_instance_id: String = "",
	p_prototype_id: String = "",
	p_delta: int = 0,
	p_bind: CardData.CardBindStatus = CardData.CardBindStatus.None
) -> void:
	instance_id = p_instance_id
	prototype_id = p_prototype_id
	delta_value = p_delta
	bind_status = p_bind

func get_total_value(prototype: CardData) -> int:
	return prototype.base_value + delta_value

static func generate_id() -> String:
	return UUID.v4()

static func bind_status_to_string(status: CardData.CardBindStatus) -> String:
	match status:
		CardData.CardBindStatus.None: return "None"
		CardData.CardBindStatus.Locked: return "Locked"
		CardData.CardBindStatus.Cursed: return "Cursed"
	return "None"

static func string_to_bind_status(s: String) -> CardData.CardBindStatus:
	match s:
		"Locked": return CardData.CardBindStatus.Locked
		"Cursed": return CardData.CardBindStatus.Cursed
	return CardData.CardBindStatus.None
