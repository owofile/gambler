extends Node

const MAX_DECK_SIZE := 20

var _player_deck: Array[CardInstance] = []

func _ready() -> void:
	pass

func _get_data_manager():
	return get_node("/root/DataManager")

func AddCard(prototype_id: String) -> CardInstance:
	var dm = _get_data_manager()
	var registry = dm.card_registry
	var prototype = registry.get_prototype(prototype_id)
	if not prototype:
		print("[CardManager] AddCard failed: prototype %s not found" % prototype_id)
		return null

	if _player_deck.size() >= MAX_DECK_SIZE:
		print("[CardManager] AddCard failed: deck is full (max %d)" % MAX_DECK_SIZE)
		return null

	var instance = CardInstance.new(
		UUID.v4(),
		prototype_id,
		0,
		CardData.CardBindStatus.None
	)
	_player_deck.append(instance)
	print("[CardManager] AddCard: %s (%s)" % [instance.instance_id, prototype_id])
	return instance

func RemoveCard(instance_id: String) -> bool:
	for i in range(_player_deck.size()):
		var card: CardInstance = _player_deck[i]
		if card.instance_id == instance_id:
			if card.bind_status == CardData.CardBindStatus.Locked:
				print("[CardManager] RemoveCard failed: %s is locked" % instance_id)
				return false
			_player_deck.remove_at(i)
			print("[CardManager] RemoveCard: %s" % instance_id)
			return true
	print("[CardManager] RemoveCard: instance %s not found" % instance_id)
	return false

func GetDeckSnapshot(selected_instance_ids: Array[String]) -> DeckSnapshot:
	var snapshot = DeckSnapshot.new()
	snapshot.deck_id = UUID.v4()

	var id_set = {}
	for id in selected_instance_ids:
		id_set[id] = true

	var dm = _get_data_manager()
	for card in _player_deck:
		if id_set.has(card.instance_id):
			var registry = dm.card_registry
			var prototype = registry.get_prototype(card.prototype_id)
			if prototype:
				var card_snapshot = CardSnapshot.new()
				card_snapshot.instance_id = card.instance_id
				card_snapshot.prototype_id = card.prototype_id
				card_snapshot.final_value = prototype.base_value + card.delta_value
				card_snapshot.card_class = prototype.card_class
				card_snapshot.effect_ids = prototype.effect_ids.duplicate()
				card_snapshot.bind_status = card.bind_status
				snapshot.cards.append(card_snapshot)
	print("[CardManager] GetDeckSnapshot: created snapshot %s with %d cards" % [snapshot.deck_id, snapshot.cards.size()])
	return snapshot

func GetAllCards() -> Array[CardInstance]:
	return _player_deck.duplicate()

func GetDeckSize() -> int:
	return _player_deck.size()
