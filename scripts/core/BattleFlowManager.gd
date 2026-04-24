## Manages the battle flow state machine.
##
## Responsibility:
## - Manage battle state transitions
## - Coordinate between player selection, animations, and battle calculation
## - Publish flow events for UI and animation systems
class_name BattleFlowManager
extends Node

signal state_changed(new_state: State)
signal battle_end(result: BattleReport)
signal round_can_select(scores: Array[int])

enum State {
	IDLE,
	PLAYER_SELECTING,
	PLAYER_ANIMATING,
	ENEMY_ANIMATING,
	COMPARE_ANIMATING,
	ROUND_END_ANIMATING,
	BATTLE_END
}

var _current_state: State = State.IDLE
var _player_deck: DeckSnapshot = null
var _enemy: EnemyData = null
var _data_manager: Node = null
var _card_manager: Node = null
var _event_bus: Node = null
var _current_round: int = 0
var _current_score: Array = [0, 0]
var _target_wins: int = 3
var _current_player_snapshot: DeckSnapshot = null
var _current_enemy_card_ids: Array = []
var _current_report: BattleReport = null
var _battle_report: BattleReport = null

## Initializes the battle flow manager with dependencies.
func initialize(
	card_manager: Node,
	data_manager: Node,
	event_bus: Node
) -> void:
	_card_manager = card_manager
	_data_manager = data_manager
	_event_bus = event_bus

## Starts a new battle.
func start_battle(player_deck: DeckSnapshot, enemy: EnemyData) -> void:
	_player_deck = player_deck
	_enemy = enemy

	match enemy.get_tier():
		EnemyData.EnemyTier.Grunt:
			_target_wins = 3
		EnemyData.EnemyTier.Elite:
			_target_wins = 4
		EnemyData.EnemyTier.Boss:
			_target_wins = 5
		_:
			_target_wins = 3

	_current_score = [0, 0]
	_current_round = 0
	_battle_report = null
	_current_report = null

	_set_state(State.PLAYER_SELECTING)
	_publish("Flow_BattleStart", {"enemy": enemy})
	_publish("Flow_PlayerSelecting", null)

## Confirms the player's card selection.
func confirm_selection(card_instance_ids: Array) -> void:
	if _current_state != State.PLAYER_SELECTING:
		push_warning("BattleFlowManager: Cannot confirm selection in state: %d" % _current_state)
		return

	if card_instance_ids.size() == 0:
		push_warning("BattleFlowManager: No cards selected")
		return

	_current_player_snapshot = _card_manager.get_deck_snapshot(card_instance_ids)
	_publish("Flow_PlayerCardAnimStart", {"cards": _current_player_snapshot.get_cards()})

	_set_state(State.PLAYER_ANIMATING)

## Called when an animation completes.
func on_animation_complete(anim_type: String) -> void:
	match _current_state:
		State.PLAYER_ANIMATING:
			if anim_type == "player_card_enter":
				_publish("Flow_PlayerCardAnimEnd", null)
				_trigger_enemy_reveal()
		State.ENEMY_ANIMATING:
			if anim_type == "enemy_card_reveal":
				_trigger_compare()
		State.COMPARE_ANIMATING:
			if anim_type == "compare":
				_trigger_round_end()
		State.ROUND_END_ANIMATING:
			if anim_type == "round_end":
				_check_battle_end()

func get_current_state() -> State:
	return _current_state

func _set_state(new_state: State) -> void:
	_current_state = new_state
	state_changed.emit(_current_state)

func _trigger_enemy_reveal() -> void:
	_set_state(State.ENEMY_ANIMATING)
	_current_round += 1

	_current_enemy_card_ids = _select_enemy_cards()

	if _current_enemy_card_ids.size() > 0:
		var first_card_id = _current_enemy_card_ids[0]
		_publish("Flow_EnemyCardReveal", {"card_id": first_card_id, "all_cards": _current_enemy_card_ids})

func _trigger_compare() -> void:
	_set_state(State.COMPARE_ANIMATING)

	var result = _process_selected_cards_static(
		_current_player_snapshot,
		_enemy,
		_data_manager
	)
	_current_enemy_card_ids = result.get("enemy_card_ids")
	var player_total = result.get("player_total")
	var enemy_total = result.get("enemy_total")
	_current_report = result.get("report")

	if _battle_report == null:
		_battle_report = BattleReport.new()

	for card_id in _current_report.get_cards_to_remove():
		if not _battle_report.get_cards_to_remove().has(card_id):
			_battle_report.add_card_to_remove(card_id)

	var player_card_ids: Array = []
	if _current_player_snapshot:
		for c in _current_player_snapshot.get_cards():
			var card: CardSnapshot = c as CardSnapshot
			if card:
				player_card_ids.append(card.get_prototype_id())

	_publish("Flow_CompareStart", {
		"player_cards": player_card_ids,
		"enemy_cards": _current_enemy_card_ids,
		"player_total": player_total,
		"enemy_total": enemy_total,
		"report": _current_report
	})

func _trigger_round_end() -> void:
	_set_state(State.ROUND_END_ANIMATING)

	var player_total = 0
	var enemy_total = 0
	if _current_report and _current_player_snapshot:
		for c in _current_player_snapshot.get_cards():
			var card: CardSnapshot = c as CardSnapshot
			if card:
				player_total += card.get_final_value()
		for cid in _current_enemy_card_ids:
			var proto = _data_manager.card_registry.get_prototype(cid)
			if proto:
				enemy_total += proto.base_value

	var round_result = "draw"
	if player_total > enemy_total:
		_current_score[0] += 1
		round_result = "player"
	elif player_total < enemy_total:
		_current_score[1] += 1
		round_result = "enemy"

	_publish("Flow_RoundEnd", {
		"winner": round_result,
		"scores": _current_score,
		"player_total": player_total,
		"enemy_total": enemy_total,
		"round": _current_round
	})

func _check_battle_end() -> void:
	if _current_score[0] >= _target_wins:
		_trigger_battle_end(BattleEnums.EBattleResult.Victory)
	elif _current_score[1] >= _target_wins:
		_trigger_battle_end(BattleEnums.EBattleResult.Defeat)
	else:
		if _battle_report == null:
			_battle_report = BattleReport.new()
		if _current_report:
			for card_id in _current_report.get_cards_to_remove():
				if not _battle_report.get_cards_to_remove().has(card_id):
					_battle_report.add_card_to_remove(card_id)
		_set_state(State.PLAYER_SELECTING)
		round_can_select.emit(_current_score)

func _trigger_battle_end(result: BattleEnums.EBattleResult) -> void:
	_set_state(State.BATTLE_END)

	if _battle_report == null:
		_battle_report = BattleReport.new()
	_battle_report.set_result(result)
	_battle_report.set_player_wins(_current_score[0])
	_battle_report.set_enemy_wins(_current_score[1])

	if _current_report:
		for card_id in _current_report.get_cards_to_remove():
			if not _battle_report.get_cards_to_remove().has(card_id):
				_battle_report.add_card_to_remove(card_id)

	_publish("Flow_BattleEnd", {"result": result, "report": _battle_report})
	battle_end.emit(_battle_report)

func _select_enemy_cards() -> Array:
	if _enemy == null:
		return []

	var result: Array = []
	var available = _enemy.get_deck_prototype_ids().duplicate()

	for i in range(mini(3, available.size())):
		if available.size() == 0:
			break
		var idx = randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)

	return result

func _publish(event_type: String, payload) -> void:
	if _event_bus:
		_event_bus.publish(event_type, payload)


static func _process_selected_cards_static(
	player_snapshot: DeckSnapshot,
	enemy: EnemyData,
	data_manager
) -> Dictionary:
	var card_registry = data_manager.card_registry
	var effect_registry = data_manager.effect_registry
	var cost_registry = data_manager.cost_registry

	var report := BattleReport.new()
	var player_cards = player_snapshot.get_cards()
	var context := EffectContext.new(
		player_snapshot,
		null,
		player_cards,
		[],
		0,
		0,
		0,
		0,
		3
	)

	for card in player_cards:
		context.add_player_total(card.get_final_value())

	var enemy_card_ids: Array = _select_random_cards(enemy.get_deck_prototype_ids(), 3)
	var enemy_total: int = _sum_enemy_card_values(enemy_card_ids, card_registry)
	context.set_current_enemy_total(enemy_total)

	var all_effects: Array = []
	for card in player_cards:
		for eff_id in card.get_effect_ids():
			all_effects.append(eff_id)

	var sorted_effects: Array = effect_registry.get_effects_sorted_by_priority(all_effects)
	for effect in sorted_effects:
		effect.apply(context)

	for card in player_cards:
		if card.has_cost():
			var cost_handler: ICostHandler = cost_registry.get_cost(card.get_cost_id())
			if cost_handler:
				var cost_ctx := CostContext.new(context, report, card, "player")
				cost_handler.trigger(cost_ctx)

	return {
		"player_total": context.get_current_player_total(),
		"enemy_total": context.get_current_enemy_total(),
		"enemy_card_ids": enemy_card_ids,
		"report": report
	}

static func _select_random_cards(card_ids: Array, count: int) -> Array:
	if card_ids.size() == 0:
		return []

	var result: Array = []
	var available = card_ids.duplicate()

	for i in range(mini(count, card_ids.size())):
		if available.size() == 0:
			break
		var idx = randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)

	return result

static func _sum_enemy_card_values(card_ids: Array, registry) -> int:
	var total: int = 0
	for card_id in card_ids:
		var proto = registry.get_prototype(card_id)
		if proto:
			total += proto.base_value
	return total
