extends Node

var _initial_cards: Array[String] = [
	"card_rusty_sword",
	"card_friendly_spirit",
	"card_justice",
	"card_blood_oath",
	"card_vengeance",
	"card_kings_authority"
]

var _battle_ui = null
var _current_enemy: EnemyData = null
var _data_manager = null

func _ready() -> void:
	_setup_ui()
	_setup_event_listeners()
	start_game()

func _get_data_manager():
	return get_node("/root/DataManager")

func _get_card_manager():
	return get_node("/root/CardMgr")

func _get_event_bus():
	return get_node("/root/EventBus")

func _setup_ui() -> void:
	var scene = load("res://scenes/BattleUI.tscn")
	if scene:
		_battle_ui = scene.instantiate()
		add_child(_battle_ui)
		_battle_ui.connect("cards_confirmed", Callable(_on_cards_confirmed))
		_log("[SceneRunner] BattleUI loaded")
	else:
		_log("[SceneRunner] Failed to load BattleUI.tscn")

func _setup_event_listeners() -> void:
	var event_bus = _get_event_bus()
	event_bus.Subscribe("BattleEnded", _on_battle_ended_listener)

func start_game() -> void:
	var card_mgr = _get_card_manager()
	_data_manager = _get_data_manager()

	for proto_id in _initial_cards:
		var card = card_mgr.AddCard(proto_id)
		if card:
			_log("[SceneRunner] Added: %s" % proto_id)

	_log("[SceneRunner] Initial deck size: %d" % card_mgr.GetDeckSize())

	_current_enemy = _data_manager.enemy_registry.get_enemy("enemy_skeletal_warrior")
	if _current_enemy:
		_log("[SceneRunner] Enemy loaded: %s" % _current_enemy.get_enemy_name())
		if _battle_ui:
			_battle_ui.setup_battle(_current_enemy)
			_battle_ui.refresh_hand()
	else:
		_log("[SceneRunner] Failed to load enemy!")

func _on_cards_confirmed(selected_ids: Array[String]) -> void:
	_log("[SceneRunner] Cards confirmed: %s" % selected_ids)

	var card_mgr = _get_card_manager()
	var snapshot = card_mgr.GetDeckSnapshot(selected_ids)

	_log("[SceneRunner] Snapshot created with %d cards" % snapshot.cards.size())

	if snapshot.cards.size() > 0:
		var player_total: int = 0
		for cs in snapshot.cards:
			player_total += cs.final_value
		_log("[SceneRunner] Player total value: %d" % player_total)

	var report: BattleReport = BattleManager.StartBattle(snapshot, _current_enemy, _data_manager)

	if _battle_ui:
		for round_detail in report.rounds:
			_battle_ui.on_round_complete(round_detail)
		_battle_ui.on_battle_complete(report)

	_apply_battle_results(report, card_mgr)

	var event_bus = _get_event_bus()
	event_bus.Publish("BattleEnded", BattleEndedPayload.new(report))

func _on_battle_ended_listener(payload: BattleEndedPayload) -> void:
	_log("[SceneRunner] BattleEnded event - Result: %s" % (
		"Victory" if payload.report.result == BattleEnums.EBattleResult.Victory else "Defeat"
	))

func _apply_battle_results(report: BattleReport, card_mgr) -> void:
	for instance_id in report.cards_to_remove:
		var removed = card_mgr.RemoveCard(instance_id)
		if removed:
			_log("[SceneRunner] Card removed from deck: %s" % instance_id)
		else:
			_log("[SceneRunner] Failed to remove card: %s" % instance_id)

	for proto_id in report.cards_to_add:
		var new_card = card_mgr.AddCard(proto_id)
		if new_card:
			_log("[SceneRunner] Card added to deck: %s (%s)" % [proto_id, new_card.get_card_id()])

	_log("[SceneRunner] Final deck size: %d" % card_mgr.GetDeckSize())

	if _battle_ui:
		_battle_ui.refresh_hand()

func _log(msg: String) -> void:
	print(msg)
	if _battle_ui and "LogText" in _battle_ui:
		var log_label = _battle_ui.get_node_or_null("BottomPanel/LogScroll/LogText")
		if log_label and log_label.has_method("append_text"):
			log_label.append_text(msg + "\n")
