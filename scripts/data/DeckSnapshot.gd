## Immutable snapshot of the player's deck at battle start.
class_name DeckSnapshot
extends RefCounted

var _deck_id: String = ""
var _cards: Array = []

func _init() -> void:
	_cards = []

func get_deck_id() -> String:
	return _deck_id

func set_deck_id(value: String) -> void:
	if value.is_empty():
		push_error("DeckSnapshot: Deck ID cannot be empty")
		return
	_deck_id = value

func get_cards() -> Array:
	return _cards.duplicate()

func get_card_count() -> int:
	return _cards.size()

func add_card(card: CardSnapshot) -> void:
	if card != null:
		_cards.append(card)

func get_card_at(index: int) -> CardSnapshot:
	if index >= 0 and index < _cards.size():
		return _cards[index]
	return null

func has_card(instance_id: String) -> bool:
	for i in range(_cards.size()):
		var c = _cards[i]
		if _safe_instance_id_match(c, instance_id):
			return true
	return false

func _safe_instance_id_match(c: CardSnapshot, instance_id: String) -> bool:
	if c != null:
		return c.get_card_id() == instance_id
	return false

func clone() -> DeckSnapshot:
	var new_snapshot = DeckSnapshot.new()
	new_snapshot.set_deck_id(_deck_id)
	for i in range(_cards.size()):
		var c = _cards[i]
		if c is CardSnapshot:
			new_snapshot.add_card(c.clone())
	return new_snapshot
