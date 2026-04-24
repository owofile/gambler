extends Control

signal cards_confirmed(selected_ids: Array[String])

@onready var _hand_list: VBoxContainer = $MainArea/HandPanel/HandList
@onready var _selected_container: VBoxContainer = $MainArea/BattlePanel/SelectedCards
@onready var _confirm_button: Button = $MainArea/BattlePanel/ConfirmButton
@onready var _round_result_label: Label = $MainArea/BattlePanel/RoundResult
@onready var _log_text: RichTextLabel = $BottomPanel/LogScroll/LogText
@onready var _enemy_name_label: Label = $TopPanel/VBox/EnemyInfo/EnemyName
@onready var _enemy_tier_label: Label = $TopPanel/VBox/EnemyInfo/EnemyTier
@onready var _player_score_label: Label = $TopPanel/VBox/ScoreBoard/PlayerScoreLabel
@onready var _enemy_score_label: Label = $TopPanel/VBox/ScoreBoard/EnemyScoreLabel
@onready var _win_progress: ProgressBar = $TopPanel/VBox/WinProgress

const MAX_SELECT := 3
const MAX_LOG_LINES := 50

var _selected_indices: Array[int] = []
var _all_cards: Array[CardInstance] = []
var _current_enemy: EnemyData = null
var _current_score: Array[int] = [0, 0]
var _round_number: int = 0
var _target_wins: int = 3
var _selection_enabled: bool = false
var _all_cards_by_id: Dictionary = {}

func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_subscribe_to_events()
	_log("[BattleUI] Ready")

func _subscribe_to_events() -> void:
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.Subscribe("Flow_BattleStart", _on_flow_battle_start)
		event_bus.Subscribe("Flow_PlayerSelecting", _on_flow_player_selecting)
		event_bus.Subscribe("Flow_PlayerCardAnimStart", _on_flow_player_card_anim_start)
		event_bus.Subscribe("Flow_PlayerCardAnimEnd", _on_flow_player_card_anim_end)
		event_bus.Subscribe("Flow_EnemyCardReveal", _on_flow_enemy_card_reveal)
		event_bus.Subscribe("Flow_CompareStart", _on_flow_compare_start)
		event_bus.Subscribe("Flow_RoundEnd", _on_flow_round_end)
		event_bus.Subscribe("Flow_BattleEnd", _on_flow_battle_end)
		event_bus.Subscribe("CardSel_Changed", _on_card_sel_changed)

func _get_card_manager():
	return get_node("/root/CardManager")

func _get_data_manager():
	return get_node("/root/DataManager")

func _get_event_bus():
	return get_node("/root/EventBus")

func setup_battle(enemy: EnemyData) -> void:
	_current_enemy = enemy
	match enemy.tier:
		EnemyData.EnemyTier.Grunt: _target_wins = 3
		EnemyData.EnemyTier.Elite: _target_wins = 4
		EnemyData.EnemyTier.Boss: _target_wins = 5
		_: _target_wins = 3

	_win_progress.max_value = _target_wins
	_win_progress.value = 0

	_enemy_name_label.text = "Enemy: %s" % enemy.enemy_name
	_enemy_tier_label.text = "[%s]" % EnemyData.tier_to_string(enemy.tier)

	_update_score_display()
	refresh_hand()
	enable_selection(true)

func refresh_hand() -> void:
	var card_mgr = _get_card_manager()
	_all_cards = card_mgr.GetAllCards()
	_build_card_index()
	_refresh_hand_display()

func _build_card_index() -> void:
	_all_cards_by_id.clear()
	for i in range(_all_cards.size()):
		var card = _all_cards[i]
		_all_cards_by_id[card.instance_id] = i

func _refresh_hand_display() -> void:
	_clear_hand()

	for i in range(_all_cards.size()):
		var card: CardInstance = _all_cards[i]
		var data_mgr = _get_data_manager()
		var proto: CardData = data_mgr.card_registry.get_prototype(card.prototype_id)
		if not proto:
			continue

		var final_value: int = proto.base_value + card.delta_value
		var display_text: String = "%s [%d]" % [proto.prototype_id, final_value]

		var card_btn := Button.new()
		card_btn.text = display_text
		card_btn.custom_minimum_size.y = 40

		var card_instance_id = card.instance_id
		card_btn.pressed.connect(func(): _on_card_clicked_by_id(card_instance_id))
		_hand_list.add_child(card_btn)

func _clear_hand() -> void:
	for child in _hand_list.get_children():
		_hand_list.remove_child(child)
		child.queue_free()

func _on_card_clicked_by_id(instance_id: String) -> void:
	if not _selection_enabled:
		return

	if _all_cards_by_id.has(instance_id):
		var index = _all_cards_by_id[instance_id]
		_on_card_clicked(index)

func _on_card_clicked(index: int) -> void:
	if index in _selected_indices:
		_selected_indices.erase(index)
		_log("[BattleUI] Deselected card %d" % index)
	else:
		if _selected_indices.size() >= MAX_SELECT:
			_log("[BattleUI] Max %d cards selected!" % MAX_SELECT)
			return
		_selected_indices.append(index)
		_log("[BattleUI] Selected card %d" % index)

	_update_selected_display()

func _update_selected_display() -> void:
	for child in _selected_container.get_children():
		_selected_container.remove_child(child)
		child.queue_free()

	var data_mgr = _get_data_manager()
	for idx in _selected_indices:
		if idx >= 0 and idx < _all_cards.size():
			var card: CardInstance = _all_cards[idx]
			var proto: CardData = data_mgr.card_registry.get_prototype(card.prototype_id)
			if proto:
				var value: int = proto.base_value + card.delta_value
				var label := Label.new()
				label.text = "  %s [%d]" % [proto.prototype_id, value]
				_selected_container.add_child(label)

	_confirm_button.disabled = _selected_indices.size() == 0

func _on_confirm_pressed() -> void:
	if not _selection_enabled or _selected_indices.is_empty():
		return

	var selected_ids: Array[String] = []
	for idx in _selected_indices:
		if idx >= 0 and idx < _all_cards.size():
			selected_ids.append(_all_cards[idx].instance_id)

	_log("[BattleUI] Confirming %d cards..." % selected_ids.size())
	emit_signal("cards_confirmed", selected_ids)

func update_selection(selected_ids: Array[String]) -> void:
	_selected_indices.clear()
	for instance_id in selected_ids:
		if _all_cards_by_id.has(instance_id):
			_selected_indices.append(_all_cards_by_id[instance_id])
	_update_selected_display()

func enable_selection(enabled: bool) -> void:
	_selection_enabled = enabled
	_confirm_button.disabled = not enabled or _selected_indices.size() == 0

func on_round_complete(round_detail: RoundDetail) -> void:
	_round_number = round_detail.round_number
	_round_result_label.text = "Round %d: %s" % [_round_number, BattleEnums.round_result_to_string(round_detail.result)]

	var player_total: int = round_detail.player_total_value
	var enemy_total: int = round_detail.enemy_total_value
	_log("[Round %d] Your cards: %s = %d" % [_round_number, round_detail.player_card_ids, player_total])
	_log("[Round %d] Enemy cards: %s = %d" % [_round_number, round_detail.enemy_card_ids, enemy_total])

	match round_detail.result:
		BattleEnums.ERoundResult.PlayerWin:
			_current_score[0] += 1
			_log("[Round %d] YOU WIN!" % _round_number)
		BattleEnums.ERoundResult.EnemyWin:
			_current_score[1] += 1
			_log("[Round %d] ENEMY WIN" % _round_number)
		BattleEnums.ERoundResult.Draw:
			_log("[Round %d] DRAW" % _round_number)

	_update_score_display()
	_selected_indices.clear()
	_update_selected_display()

func _update_score_display() -> void:
	_player_score_label.text = "Player: %d" % _current_score[0]
	_enemy_score_label.text = "%d :Enemy" % _current_score[1]
	_win_progress.value = _current_score[0]

func on_battle_complete(report: BattleReport) -> void:
	_log("==========")
	_log("BATTLE ENDED: %s" % BattleEnums.battle_result_to_string(report.result))
	_log("Final Score: Player %d - %d Enemy" % [report.player_wins, report.enemy_wins])
	_log("Rounds played: %d" % report.rounds.size())
	_log("==========")
	enable_selection(false)

func _on_flow_battle_start(payload) -> void:
	var enemy = payload.get("enemy", null)
	if enemy:
		setup_battle(enemy)
	_log("[BattleUI] Flow: BattleStart")

func _on_flow_player_selecting(payload) -> void:
	enable_selection(true)
	_log("[BattleUI] Flow: PlayerSelecting")

func _on_flow_player_card_anim_start(payload) -> void:
	_log("[BattleUI] Flow: PlayerCardAnimStart - %s" % payload)

func _on_flow_player_card_anim_end(payload) -> void:
	_log("[BattleUI] Flow: PlayerCardAnimEnd")

func _on_flow_enemy_card_reveal(payload) -> void:
	var card_id = payload.get("card_id", "")
	_log("[BattleUI] Flow: EnemyCardReveal - %s" % card_id)

func _on_flow_compare_start(payload) -> void:
	var player_cards = payload.get("player_cards", [])
	var enemy_cards = payload.get("enemy_cards", [])
	var player_total = payload.get("player_total", 0)
	var enemy_total = payload.get("enemy_total", 0)
	_log("[BattleUI] Flow: CompareStart - Player: %s vs Enemy: %s" % [player_cards, enemy_cards])
	_log("[BattleUI] Flow: CompareStart - Player: %d vs Enemy: %d" % [player_total, enemy_total])

func _on_flow_round_end(payload) -> void:
	var winner = payload.get("winner", "draw")
	var scores = payload.get("scores", [0, 0])
	_log("[BattleUI] Flow: RoundEnd - %s wins! Score: %d-%d" % [winner, scores[0], scores[1]])

func _on_flow_battle_end(payload) -> void:
	var result = payload.get("result", BattleEnums.EBattleResult.Defeat)
	_log("[BattleUI] Flow: BattleEnd - %s" % (
		"Victory" if result == BattleEnums.EBattleResult.Victory else "Defeat"))

func _on_card_sel_changed(payload) -> void:
	var selected_ids = payload.get("selected_ids", [])
	update_selection(selected_ids)

func _log(message: String) -> void:
	_log_text.append_text(message + "\n")
	var full_text := _log_text.text
	var lines := full_text.split("\n")
	if lines.size() > MAX_LOG_LINES:
		var start_idx := lines.size() - MAX_LOG_LINES
		var truncated := lines.slice(start_idx)
		_log_text.text = "\n".join(truncated)

func reset() -> void:
	_selected_indices.clear()
	_current_score = [0, 0]
	_round_number = 0
	_log_text.clear()
	_clear_hand()
	_update_selected_display()
	_round_result_label.text = "Round: --"
	_update_score_display()
	_win_progress.value = 0
