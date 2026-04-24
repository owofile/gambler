## Main scene orchestrator for the battle system.
##
## Responsibility:
## - Initialize all game modules
## - Coordinate battle flow
## - Handle UI events and state updates
##
## This is the entry point that wires together CardManager, BattleFlowManager,
## CardSelector, and BattleUI.
class_name SceneRunnerV2
extends Node

const INITIAL_CARD_IDS: Array[String] = [
	"card_rusty_sword",
	"card_friendly_spirit",
	"card_justice",
	"card_blood_oath",
	"card_vengeance",
	"card_kings_authority"
]

var _battle_ui: Node = null
var _current_enemy: EnemyData = null
var _data_manager: Node = null
var _card_manager: Node = null
var _card_selector: Node = null
var _battle_flow: Node = null
var _all_cards: Array = []
var _battle_in_progress: bool = false
var _logger: Logger = null

func _ready() -> void:
	_logger = Logger.new()
	_setup_ui()
	_setup_modules()
	_start_game()

func _setup_modules() -> void:
	_card_manager = get_node("/root/CardMgr")
	_data_manager = get_node("/root/DataManager")
	var event_bus = get_node("/root/EventBus")

	_card_selector = CardSelector.new()
	add_child(_card_selector)
	_card_selector.selection_changed.connect(_on_selection_changed)

	_battle_flow = BattleFlowManager.new()
	add_child(_battle_flow)
	_battle_flow.initialize(_card_manager, _data_manager, event_bus)
	_battle_flow.state_changed.connect(_on_flow_state_changed)
	_battle_flow.battle_end.connect(_on_battle_end)
	_battle_flow.round_can_select.connect(_on_round_can_select)

	_logger.info("Modules setup complete")

func _setup_ui() -> void:
	var scene = load("res://scenes/Battle_UI_v1.tscn")
	if scene:
		_battle_ui = scene.instantiate()
		add_child(_battle_ui)
		_battle_ui.cards_confirmed.connect(_on_cards_confirmed)
		_logger.info("BattleUI loaded")
	else:
		_logger.error("Failed to load Battle_UI_v1.tscn")

func _start_game() -> void:
	for proto_id in INITIAL_CARD_IDS:
		var card = _card_manager.add_card(proto_id)
		if card:
			_all_cards.append(card)

	_logger.info("Initial deck size: %d" % _all_cards.size())

	_current_enemy = _data_manager.enemy_registry.get_enemy("enemy_skeletal_warrior")
	if _current_enemy:
		_logger.info("Enemy loaded: %s" % _current_enemy.get_enemy_name())
		_card_selector.set_available_cards(_all_cards)
		if _battle_ui:
			_battle_ui.setup_battle(_current_enemy)
		_start_battle_flow()
	else:
		_logger.error("Failed to load enemy!")

func _start_battle_flow() -> void:
	var all_instance_ids: Array[String] = []
	for c in _all_cards:
		var card: CardInstance = c as CardInstance
		if card:
			all_instance_ids.append(card.get_card_id())

	var snapshot = _card_manager.get_deck_snapshot(all_instance_ids)
	_logger.info("Starting battle flow")
	_battle_flow.start_battle(snapshot, _current_enemy)

func _on_selection_changed(selected_ids: Array[String]) -> void:
	if _battle_ui:
		_battle_ui.update_selection(selected_ids)

func _on_cards_confirmed(selected_ids: Array[String]) -> void:
	if _battle_in_progress:
		_logger.warn("Battle in progress, ignoring confirmation")
		return
	if selected_ids.size() == 0:
		_logger.warn("No cards selected")
		return

	_battle_in_progress = true
	_logger.info("Cards confirmed: %d" % selected_ids.size())
	_battle_flow.confirm_selection(selected_ids)

func _on_flow_state_changed(state: int) -> void:
	var state_name = BattleFlowManager.State.keys()[state] if state < BattleFlowManager.State.size() else str(state)
	_logger.info("Flow state changed: %s" % state_name)

	match state:
		BattleFlowManager.State.PLAYER_SELECTING:
			if _battle_ui:
				_battle_ui.enable_selection(true)
			_logger.info("Waiting for player selection")
		BattleFlowManager.State.PLAYER_ANIMATING:
			if _battle_ui:
				_battle_ui.enable_selection(false)
			_logger.info("Player cards animating, will complete after delay")
			await _wait_and_complete("player_card_enter")
			_logger.info("Player animation wait done")
		BattleFlowManager.State.ENEMY_ANIMATING:
			_logger.info("Enemy revealing cards, will complete after delay")
			await _wait_and_complete("enemy_card_reveal")
			_logger.info("Enemy animation wait done")
		BattleFlowManager.State.COMPARE_ANIMATING:
			_logger.info("Comparing cards, will complete after delay")
			await _wait_and_complete("compare")
			_logger.info("Compare wait done")
		BattleFlowManager.State.ROUND_END_ANIMATING:
			_logger.info("Round ending, will complete after delay")
			await _wait_and_complete("round_end")
			_logger.info("Round end animation wait done")
		BattleFlowManager.State.BATTLE_END:
			_logger.info("Battle ended")
			_battle_in_progress = false

func _on_round_can_select(scores: Array) -> void:
	_logger.info("Round ended, player can select again. Score: %d - %d" % [scores[0], scores[1]])
	_battle_in_progress = false
	_logger.info("Battle in progress reset to false")

func _wait_and_complete(anim_type: String) -> void:
	await get_tree().create_timer(0.5).timeout
	_battle_flow.on_animation_complete(anim_type)

func _on_battle_end(report: BattleReport) -> void:
	var result_str = "Victory" if report.is_victory() else "Defeat"
	_logger.info("Battle ended: %s" % result_str)
	_apply_results(report)

func _apply_results(report: BattleReport) -> void:
	_logger.info("Applying battle results")
	var cards_to_remove: Array = report.get_cards_to_remove()
	var cards_to_add: Array = report.get_cards_to_add()
	_logger.info("Report cards_to_remove count: %d" % cards_to_remove.size())
	_logger.info("Report cards_to_add count: %d" % cards_to_add.size())

	for instance_id in report.get_cards_to_remove():
		var removed = _card_manager.remove_card(instance_id)
		if removed:
			_logger.info("Card removed: %s" % instance_id)
			for c in _all_cards:
				var card: CardInstance = c as CardInstance
				if card and card.get_card_id() == instance_id:
					_all_cards.erase(card)
					break

	for proto_id in report.get_cards_to_add():
		var new_card = _card_manager.add_card(proto_id)
		if new_card:
			_all_cards.append(new_card)
			_logger.info("Card added: %s" % proto_id)

	_logger.info("Final deck size: %d" % _all_cards.size())

	if _battle_ui:
		_battle_ui.refresh_hand()
		_battle_ui.on_battle_complete(report)

	_card_selector.set_available_cards(_all_cards)

	_logger.info("Log file: %s" % _logger.get_log_path())
