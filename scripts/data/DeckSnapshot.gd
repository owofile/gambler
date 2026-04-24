class_name DeckSnapshot
extends RefCounted

var deck_id: String
var cards: Array[CardSnapshot]

func _init() -> void:
	cards = []