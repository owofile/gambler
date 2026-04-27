extends Node

var _initial_cards: Array = [
	"card_rusty_sword",
	"card_friendly_spirit",
	"card_justice",
	"card_blood_oath",
	"card_vengeance",
	"card_kings_authority"
]

func _ready() -> void:
	print("[GameRunner] Starting game...")
	_start_game()

func _get_card_manager():
	return get_node("/root/CardMgr")

func _get_data_manager():
	return get_node("/root/DataManager")

func _get_event_bus():
	return get_node("/root/EventBus")

func _start_game() -> void:
	var card_mgr = _get_card_manager()
	var data_mgr = _get_data_manager()
	var event_bus = _get_event_bus()

	for i in range(_initial_cards.size()):
		var proto_id: String = _initial_cards[i]
		var card: CardInstance = card_mgr.AddCard(proto_id)
		if card == null:
			print("[GameRunner] Failed to add card: %s" % proto_id)

	print("[GameRunner] Initial deck size: %d" % card_mgr.GetDeckSize())

	var enemy: EnemyData = data_mgr.enemy_registry.get_enemy("enemy_skeletal_warrior")
	if not enemy:
		print("[GameRunner] Failed to load enemy")
		return

	print("[GameRunner] Enemy loaded: %s" % enemy.get_enemy_name())

	var all_cards = card_mgr.GetAllCards()
	var sorted_cards = all_cards.duplicate()
	sorted_cards.sort_custom(func(a, b):
		var card_a: CardInstance = a as CardInstance
		var card_b: CardInstance = b as CardInstance
		if not card_a or not card_b:
			return false
		var proto_a: CardData = data_mgr.card_registry.get_prototype(card_a.get_prototype_id())
		var proto_b: CardData = data_mgr.card_registry.get_prototype(card_b.get_prototype_id())
		var val_a: int = proto_a.base_value + card_a.get_delta_value() if proto_a else 0
		var val_b: int = proto_b.base_value + card_b.get_delta_value() if proto_b else 0
		return val_a > val_b
	)

	var selected_ids: Array = []
	var top_count := mini(3, sorted_cards.size())
	for i in range(top_count):
		var c = sorted_cards[i]
		var card: CardInstance = c as CardInstance
		if card:
			selected_ids.append(card.get_card_id())

	var snapshot = card_mgr.GetDeckSnapshot(selected_ids)

	print("[GameRunner] Starting battle with %d cards in snapshot" % snapshot.cards.size())

	var report: BattleReport = BattleManager.StartBattle(snapshot, enemy, data_mgr)

	print("[GameRunner] Battle result: %s (Player: %d, Enemy: %d)" % [
		"Victory" if report.result == BattleEnums.EBattleResult.Victory else "Defeat",
		report.player_wins,
		report.enemy_wins
	])

	for proto_id in report.cards_to_add:
		var new_card: CardInstance = card_mgr.AddCard(proto_id)
		if new_card:
			event_bus.Publish("CardAcquired", CardAcquiredPayload.new(proto_id, new_card.get_card_id()))

	for instance_id in report.cards_to_remove:
		var removed: bool = card_mgr.RemoveCard(instance_id)
		if removed:
			var all_cards_now = card_mgr.GetAllCards()
			var proto_id_removed: String = ""
			for c in all_cards_now:
				var card: CardInstance = c as CardInstance
				if card and card.get_card_id() == instance_id:
					proto_id_removed = card.get_prototype_id()
					break
			event_bus.Publish("CardLost", CardLostPayload.new(instance_id, proto_id_removed))

	event_bus.Publish("BattleEnded", BattleEndedPayload.new(report))

	print("[GameRunner] Final deck size: %d" % card_mgr.GetDeckSize())

	_setup_event_listeners()

func _setup_event_listeners() -> void:
	var event_bus = _get_event_bus()
	event_bus.subscribe("BattleEnded", _on_battle_ended)
	event_bus.subscribe("CardAcquired", _on_card_acquired)
	event_bus.subscribe("CardLost", _on_card_lost)

func _on_battle_ended(payload: BattleEndedPayload) -> void:
	print("[GameRunner] [Event] BattleEnded received - Result: %s" % (
		"Victory" if payload.report.result == BattleEnums.EBattleResult.Victory else "Defeat"
	))

func _on_card_acquired(payload: CardAcquiredPayload) -> void:
	print("[GameRunner] [Event] CardAcquired: %s (instance: %s)" % [payload.prototype_id, payload.instance_id])

func _on_card_lost(payload: CardLostPayload) -> void:
	print("[GameRunner] [Event] CardLost: %s (instance: %s)" % [payload.prototype_id, payload.instance_id])
