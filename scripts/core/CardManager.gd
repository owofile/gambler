## Manages card instances in the player's deck.
##
## Responsibility:
## - Create and destroy CardInstance objects
## - Track deck size limits
## - Provide deck snapshots for battles
extends Node

const MAX_DECK_SIZE := 20

var _player_deck: Array = []
var _data_manager: Node = null

func _ready() -> void:
	_data_manager = get_node("/root/DataManager")

## Adds a new card instance to the player's deck.
func add_card(prototype_id: String) -> CardInstance:
	if _data_manager == null:
		push_error("CardManager: DataManager not available")
		return null

	var registry = _data_manager.card_registry
	var prototype = registry.get_prototype(prototype_id)
	if not prototype:
		push_error("CardManager: AddCard failed - prototype %s not found" % prototype_id)
		return null

	if _player_deck.size() >= MAX_DECK_SIZE:
		push_warning("CardManager: AddCard failed - deck is full (max %d)" % MAX_DECK_SIZE)
		return null

	var instance = _create_card_instance(prototype_id)
	_player_deck.append(instance)
	return instance

## Removes a card instance from the player's deck.
func remove_card(instance_id: String) -> bool:
	for i in range(_player_deck.size()):
		var card: CardInstance = _player_deck[i]
		if card.get_card_id() == instance_id:
			if card.is_locked():
				push_warning("CardManager: RemoveCard failed - card %s is locked" % instance_id)
				return false
			_player_deck.remove_at(i)
			return true
	push_warning("CardManager: RemoveCard failed - instance %s not found" % instance_id)
	return false

## Creates a deck snapshot for the selected cards.
func get_deck_snapshot(selected_instance_ids: Array) -> DeckSnapshot:
	var snapshot = DeckSnapshot.new()
	snapshot.set_deck_id(UUID.v4())

	var id_set = {}
	for id in selected_instance_ids:
		id_set[id] = true

	if _data_manager == null:
		push_error("CardManager: DataManager not available")
		return snapshot

	var registry = _data_manager.card_registry
	for card in _player_deck:
		if id_set.has(card.get_card_id()):
			var prototype = registry.get_prototype(card.get_prototype_id())
			if prototype:
				var card_snapshot = CardSnapshot.new()
				card_snapshot.set_card_id(card.get_card_id())
				card_snapshot.set_prototype_id(card.get_prototype_id())
				card_snapshot.set_final_value(prototype.base_value + card.get_delta_value())
				card_snapshot.set_card_class(prototype.card_class)
				for eff_id in prototype.effect_ids:
					card_snapshot.add_effect_id(eff_id)
				card_snapshot.set_cost_id(prototype.cost_id)
				card_snapshot.set_bind_status(card.get_bind_status())
				snapshot.add_card(card_snapshot)

	return snapshot

## Gets all cards in the deck.
func get_all_cards() -> Array:
	return _player_deck.duplicate()

## Gets the current deck size.
func get_deck_size() -> int:
	return _player_deck.size()

## Checks if a card instance is locked.
func is_card_locked(instance_id: String) -> bool:
	for card in _player_deck:
		if card.get_card_id() == instance_id:
			return card.is_locked()
	return false

## Gets a card by instance ID.
func get_card(instance_id: String) -> CardInstance:
	for card in _player_deck:
		if card.get_card_id() == instance_id:
			return card
	return null

## Clears all cards from the deck (used for save/load).
func clear_all_cards() -> void:
	_player_deck.clear()


func _create_card_instance(
	prototype_id: String,
	delta: int = 0,
	bind_status: CardData.CardBindStatus = CardData.CardBindStatus.None
) -> CardInstance:
	return CardInstance.new(
		UUID.v4(),
		prototype_id,
		delta,
		bind_status
	)
