## Handles card consumption and destruction after rounds.
##
## Responsibility:
## - Consume (destroy) cards that were played in a round
## - Check for exceptions (cards that survive)
## - Apply invalid/null card protection
##
## Card Lifecycle:
##   Hand (CardMgr) → Played → Consumed → Removed from deck
##   Exception: Cards with "preserve" tag survive
##
## Usage:
##   var consumer = CardConsumer.new()
##   consumer.initialize(card_manager)
##   consumer.consume_played_cards(played_card_ids)
class_name CardConsumer
extends RefCounted

## Card binding status that grants exception from consumption
enum ConsumptionException {
	None = 0,
	Locked = 1,      # Locked cards don't consume
	PreserveTag = 2  # Cards with special preserve effect
}

var _card_manager: Node = null
var _data_manager: Node = null

func initialize(card_manager: Node, data_manager: Node) -> void:
	_card_manager = card_manager
	_data_manager = data_manager

## Main entry point: consume played cards
## Returns array of actually consumed card IDs
func consume_played_cards(
	played_card_ids: Array,
	disabled_card_ids: Array = []
) -> Array:
	if played_card_ids.size() == 0:
		return []

	var consumed: Array = []
	var protected: Array = []

	for card_id in played_card_ids:
		var exception = _check_consumption_exception(card_id)
		if exception != ConsumptionException.None:
			protected.append(card_id)
			print("[CardConsumer] Card %s protected (exception: %d)" % [card_id, exception])
			continue

		var is_disabled = disabled_card_ids.has(card_id)
		if is_disabled:
			print("[CardConsumer] Card %s was disabled, consuming anyway" % card_id)

		var removed = _card_manager.remove_card(card_id)
		if removed:
			consumed.append(card_id)
			print("[CardConsumer] Card %s consumed" % card_id)
		else:
			push_warning("[CardConsumer] Failed to consume card: %s" % card_id)

	print("[CardConsumer] Consumed: %d, Protected: %d" % [consumed.size(), protected.size()])
	return consumed

## Check if a card has consumption exception
func _check_consumption_exception(card_id: String) -> int:
	if not _card_manager:
		return ConsumptionException.None

	var card = _card_manager.get_card(card_id)
	if not card:
		return ConsumptionException.None

	if card.is_locked():
		return ConsumptionException.Locked

	return ConsumptionException.None

## Validate cards before consumption - mark invalid cards
## Invalid cards: null reference, missing prototype, etc.
func validate_cards(card_ids: Array) -> Array:
	var valid: Array = []
	var invalid: Array = []

	for card_id in card_ids:
		if _is_valid_card(card_id):
			valid.append(card_id)
		else:
			invalid.append(card_id)
			push_warning("[CardConsumer] Invalid card filtered: %s" % card_id)

	if invalid.size() > 0:
		print("[CardConsumer] Filtered %d invalid cards" % invalid.size())

	return valid

## Check if card is valid (exists and has valid prototype)
func _is_valid_card(card_id: String) -> bool:
	if not _card_manager:
		return false

	var card = _card_manager.get_card(card_id)
	if not card:
		return false

	var prototype_id = card.get_prototype_id()
	if prototype_id.is_empty():
		return false

	if not _data_manager:
		return true

	var prototype = _data_manager.card_registry.get_prototype(prototype_id)
	return prototype != null

## Check if player has enough cards to play
func check_deck_size(required: int) -> bool:
	if not _card_manager:
		return false
	return _card_manager.get_deck_size() >= required

## Get current deck size
func get_current_deck_size() -> int:
	if not _card_manager:
		return 0
	return _card_manager.get_deck_size()
