class_name CardSnapshot
extends RefCounted

var instance_id: String
var prototype_id: String
var final_value: int
var card_class: CardData.CardClass
var effect_ids: Array[String]
var bind_status: CardData.CardBindStatus

func _init() -> void:
	effect_ids = []