extends Node2D

signal cards_confirmed(selected_ids: Array[String])

@onready var user_card_01 = $user_card/user_card_01
@onready var user_card_02 = $user_card/user_card_02
@onready var user_card_03 = $user_card/user_card_03
@onready var user_card_04 = $user_card/user_card_04
@onready var user_card_05 = $user_card/user_card_05
@onready var user_card_06 = $user_card/user_card_06

@onready var playcard_btn = $playcard

@onready var user_card_component = $user_card

var _card_nodes: Array[Area2D] = []
var _selected_indices: Array[int] = []
var _hovered_index: int = -1
var _selection_enabled: bool = false

const MAX_SELECT := 3
const HOVER_OFFSET_Y := -30.0
const SHAKE_AMPLITUDE := 3.0
const SHAKE_SPEED := 8.0

var _all_cards: Array = []
var _card_manager: Node = null
var _data_manager: Node = null
var _event_bus: Node = null
var _current_enemy: EnemyData = null

var _wobble_time: float = 0.0
var _original_positions: Dictionary = {}
var _target_wins: int = 3
var _current_score: Array[int] = [0, 0]

func _ready() -> void:
	_card_manager = get_node_or_null("/root/CardMgr")
	_data_manager = get_node_or_null("/root/DataManager")
	_event_bus = get_node_or_null("/root/EventBus")

	_card_nodes = [user_card_01, user_card_02, user_card_03, user_card_04, user_card_05, user_card_06]
	for card in _card_nodes:
		_original_positions[card] = card.position

	playcard_btn.pressed.connect(_on_playcard_pressed)
	playcard_btn.disabled = true

	_connect_user_card_signals()
	_subscribe_to_events()
	_do_refresh_hand()
	print("[BattleUI_v1] Ready")

func _connect_user_card_signals() -> void:
	if user_card_component:
		user_card_component.card_hovered.connect(_on_card_hovered)
		user_card_component.card_unhovered.connect(_on_card_unhovered)
		user_card_component.card_clicked.connect(_on_card_clicked)

func _on_card_hovered(index: int) -> void:
	if not _selection_enabled:
		return
	_hovered_index = index

func _on_card_unhovered(index: int) -> void:
	if _hovered_index == index:
		_hovered_index = -1

func _on_card_clicked(index: int) -> void:
	if not _selection_enabled:
		return
	if index < 0 or index >= _card_nodes.size():
		return

	if _selected_indices.has(index):
		_selected_indices.erase(index)
		_set_card_selected(index, false)
		print("[BattleUI_v1] Card %d deselected" % index)
	else:
		if _selected_indices.size() >= MAX_SELECT:
			print("[BattleUI_v1] Max %d cards selected!" % MAX_SELECT)
			return
		_selected_indices.append(index)
		_set_card_selected(index, true)
		print("[BattleUI_v1] Card %d selected" % index)

	playcard_btn.disabled = _selected_indices.size() == 0

func _subscribe_to_events() -> void:
	if _event_bus:
		_event_bus.subscribe("Flow_BattleStart", _on_flow_battle_start)
		_event_bus.subscribe("Flow_PlayerSelecting", _on_flow_player_selecting)
		_event_bus.subscribe("Flow_PlayerCardAnimStart", _on_flow_player_card_anim_start)
		_event_bus.subscribe("Flow_PlayerCardAnimEnd", _on_flow_player_card_anim_end)
		_event_bus.subscribe("Flow_EnemyCardReveal", _on_flow_enemy_card_reveal)
		_event_bus.subscribe("Flow_CompareStart", _on_flow_compare_start)
		_event_bus.subscribe("Flow_RoundEnd", _on_flow_round_end)
		_event_bus.subscribe("Flow_BattleEnd", _on_flow_battle_end)
		_event_bus.subscribe("CardSel_Changed", _on_card_sel_changed)

func setup_battle(enemy: EnemyData) -> void:
	_current_enemy = enemy
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
	print("[BattleUI_v1] setup_battle: %s (target: %d wins)" % [enemy.get_enemy_name(), _target_wins])
	_do_refresh_hand()
	enable_selection(true)

func _do_refresh_hand() -> void:
	if _card_manager:
		_all_cards = _card_manager.get_all_cards()
		_update_card_display()

func refresh_hand() -> void:
	_do_refresh_hand()
	clear_selection()

func _update_card_display() -> void:
	for i in range(_card_nodes.size()):
		if i < _all_cards.size():
			_card_nodes[i].visible = true
		else:
			_card_nodes[i].visible = false

func _process(delta: float) -> void:
	_wobble_time += delta
	_update_card_animations(delta)

func _update_card_animations(delta: float) -> void:
	for i in range(_card_nodes.size()):
		var card = _card_nodes[i]
		if not card.visible:
			continue

		var target_pos = _original_positions[card]

		if i == _hovered_index and _selection_enabled:
			target_pos.y += HOVER_OFFSET_Y
		else:
			target_pos.y = _original_positions[card].y

		var wobble_x = sin(_wobble_time * SHAKE_SPEED + i * 1.5) * SHAKE_AMPLITUDE
		var wobble_y = cos(_wobble_time * SHAKE_SPEED * 0.7 + i * 1.2) * (SHAKE_AMPLITUDE * 0.5)

		var target_with_wobble = target_pos + Vector2(wobble_x, wobble_y)
		card.position = card.position.lerp(target_with_wobble, delta * 10)

func _set_card_selected(index: int, selected: bool) -> void:
	var card = _card_nodes[index]
	var sprite = card.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		if selected:
			sprite.modulate = Color(1.3, 1.0, 0.8, 1.0)
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_playcard_pressed() -> void:
	if _selected_indices.is_empty():
		return

	var selected_ids: Array[String] = []
	for idx in _selected_indices:
		if idx < _all_cards.size():
			var card: CardInstance = _all_cards[idx] as CardInstance
			if card:
				selected_ids.append(card.get_card_id())

	print("[BattleUI_v1] Confirming %d cards: %s" % [selected_ids.size(), selected_ids])
	emit_signal("cards_confirmed", selected_ids)

	enable_selection(false)

func enable_selection(enabled: bool) -> void:
	_selection_enabled = enabled
	if not enabled:
		_hovered_index = -1

func update_selection(selected_ids: Array[String]) -> void:
	_selected_indices.clear()
	for instance_id in selected_ids:
		for i in range(_all_cards.size()):
			var card: CardInstance = _all_cards[i] as CardInstance
			if card and card.get_card_id() == instance_id:
				_selected_indices.append(i)
				break

	for i in range(_card_nodes.size()):
		var is_selected = _selected_indices.has(i)
		_set_card_selected(i, is_selected)

	playcard_btn.disabled = _selected_indices.size() == 0

func clear_selection() -> void:
	for idx in _selected_indices:
		_set_card_selected(idx, false)
	_selected_indices.clear()
	playcard_btn.disabled = true

func _on_flow_battle_start(payload) -> void:
	var enemy = payload.get("enemy", null)
	if enemy:
		setup_battle(enemy)
	print("[BattleUI_v1] Flow: BattleStart")

func _on_flow_player_selecting(payload) -> void:
	enable_selection(true)
	print("[BattleUI_v1] Flow: PlayerSelecting")

func _on_flow_player_card_anim_start(payload) -> void:
	print("[BattleUI_v1] Flow: PlayerCardAnimStart")

func _on_flow_player_card_anim_end(payload) -> void:
	print("[BattleUI_v1] Flow: PlayerCardAnimEnd")

func _on_flow_enemy_card_reveal(payload) -> void:
	var card_id = payload.get("card_id", "")
	print("[BattleUI_v1] Flow: EnemyCardReveal - %s" % card_id)

func _on_flow_compare_start(payload) -> void:
	var player_cards = payload.get("player_cards", [])
	var enemy_cards = payload.get("enemy_cards", [])
	var player_total = payload.get("player_total", 0)
	var enemy_total = payload.get("enemy_total", 0)
	print("[BattleUI_v1] Flow: CompareStart - Player: %s vs Enemy: %s" % [player_cards, enemy_cards])
	print("[BattleUI_v1] Flow: CompareStart - Player: %d vs Enemy: %d" % [player_total, enemy_total])

func _on_flow_round_end(payload) -> void:
	var winner = payload.get("winner", "draw")
	var scores_arr: Array = payload.get("scores", [0, 0])
	var score0 = scores_arr[0] if scores_arr.size() > 0 else 0
	var score1 = scores_arr[1] if scores_arr.size() > 1 else 0
	print("[BattleUI_v1] Flow: RoundEnd - %s wins! Score: %d-%d" % [winner, score0, score1])
	_current_score[0] = score0
	_current_score[1] = score1
	clear_selection()

func _on_flow_battle_end(payload) -> void:
	var result = payload.get("result", 0)
	var result_str = "Victory" if result == 1 else "Defeat"
	print("[BattleUI_v1] Flow: BattleEnd - %s" % result_str)
	print("Battle ended: %s" % result_str)

func on_battle_complete(report: BattleReport) -> void:
	var result_str = "Victory" if report.is_victory() else "Defeat"
	print("==========")
	print("BATTLE ENDED: %s" % result_str)
	print("Final Score: Player %d - %d Enemy" % [report.get_player_wins(), report.get_enemy_wins()])
	print("Rounds played: %d" % report.get_total_rounds())
	print("==========")

func _on_card_sel_changed(payload) -> void:
	var selected_ids = payload.get("selected_ids", [])
	update_selection(selected_ids)

func get_selected_indices() -> Array[int]:
	return _selected_indices.duplicate()


func _on_user_card_card_hovered(index: int) -> void:
	pass # Replace with function body.


func _on_user_card_card_clicked(index: int) -> void:
	pass # Replace with function body.


func _on_user_card_card_unhovered(index: int) -> void:
	pass # Replace with function body.
