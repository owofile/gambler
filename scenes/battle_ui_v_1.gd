extends Node2D

signal cards_confirmed(selected_ids: Array)

@onready var user_card_01 = $user_card/user_card_01
@onready var user_card_02 = $user_card/user_card_02
@onready var user_card_03 = $user_card/user_card_03
@onready var user_card_04 = $user_card/user_card_04
@onready var user_card_05 = $user_card/user_card_05
@onready var user_card_06 = $user_card/user_card_06

@onready var playcard_btn = $playcard

@onready var user_card_component = $user_card

var _card_nodes: Array = []
var _selected_indices: Array = []
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
var _current_score: Array = [0, 0]

var _card_info_panel: Control = null
var _card_info_label: RichTextLabel = null
var _card_info_name_label: Label = null

const CARD_INFO_OFFSET_X := -80
const CARD_INFO_OFFSET_Y := 10

const CARD_INFO_PANEL_SIZE_X := 180
const CARD_INFO_PANEL_SIZE_Y := 120

const CARD_INFO_BORDER_WIDTH := 2

const CARD_INFO_CONTENT_OFFSET_X := 10
const CARD_INFO_CONTENT_OFFSET_Y := 10

const INITIAL_CARD_IDS: Array = [
	"card_rusty_sword",
	"card_friendly_spirit",
	"card_justice",
	"card_blood_oath",
	"card_vengeance",
	"card_kings_authority"
]

var _battle_runner: BattleRunner = null

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
	_setup_battle_runner()
	_initialize_deck_if_empty()
	_do_refresh_hand()
	_create_card_info_panel()
	print("[BattleUI_v1] Ready")

func _setup_battle_runner() -> void:
	_battle_runner = BattleRunner.new()
	add_child(_battle_runner)
	_battle_runner.battle_ended.connect(_on_battle_ended)
	print("[BattleUI_v1] BattleRunner initialized")

func _initialize_deck_if_empty() -> void:
	if _card_manager == null:
		push_error("[BattleUI_v1] CardMgr not found!")
		return

	var current_cards = _card_manager.get_all_cards()
	if current_cards.size() == 0:
		print("[BattleUI_v1] No cards found, initializing default deck...")
		for proto_id in INITIAL_CARD_IDS:
			_card_manager.add_card(proto_id)

	if _data_manager == null:
		push_error("[BattleUI_v1] DataManager not found!")
		return

	var default_enemy = _data_manager.enemy_registry.get_enemy("enemy_skeletal_warrior")
	if default_enemy:
		print("[BattleUI_v1] Setting up default enemy: %s" % default_enemy.get_enemy_name())
		_current_enemy = default_enemy
		if _battle_runner:
			_battle_runner.target_wins = _target_wins
			_battle_runner.setup(self, default_enemy)
		setup_battle(default_enemy)

func _create_card_info_panel() -> void:
	_card_info_panel = Control.new()
	_card_info_panel.z_index = 100
	_card_info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(_card_info_panel)

	var panel_bg = ColorRect.new()
	panel_bg.custom_minimum_size = Vector2(CARD_INFO_PANEL_SIZE_X, CARD_INFO_PANEL_SIZE_Y)
	panel_bg.color = Color(0.1, 0.1, 0.15, 0.95)
	_card_info_panel.add_child(panel_bg)

	var border = ColorRect.new()
	border.custom_minimum_size = Vector2(CARD_INFO_PANEL_SIZE_X + CARD_INFO_BORDER_WIDTH * 2, CARD_INFO_PANEL_SIZE_Y + CARD_INFO_BORDER_WIDTH * 2)
	border.position = Vector2(-CARD_INFO_BORDER_WIDTH, -CARD_INFO_BORDER_WIDTH)
	border.color = Color(0.6, 0.5, 0.3, 1.0)
	panel_bg.add_child(border)
	border.z_index = -1

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(CARD_INFO_CONTENT_OFFSET_X, CARD_INFO_CONTENT_OFFSET_Y)
	vbox.custom_minimum_size = Vector2(CARD_INFO_PANEL_SIZE_X - CARD_INFO_CONTENT_OFFSET_X * 2, CARD_INFO_PANEL_SIZE_Y - CARD_INFO_CONTENT_OFFSET_Y * 2)
	panel_bg.add_child(vbox)

	_card_info_name_label = Label.new()
	_card_info_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_info_name_label.add_theme_font_size_override("font_size", 14)
	_card_info_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	vbox.add_child(_card_info_name_label)

	_card_info_label = RichTextLabel.new()
	_card_info_label.custom_minimum_size = Vector2(CARD_INFO_PANEL_SIZE_X - CARD_INFO_CONTENT_OFFSET_X * 2, CARD_INFO_PANEL_SIZE_Y - CARD_INFO_CONTENT_OFFSET_Y * 2 - 20)
	_card_info_label.bbcode_enabled = true
	_card_info_label.fit_content = true
	_card_info_label.scroll_active = false
	vbox.add_child(_card_info_label)

	_card_info_panel.visible = false

func _connect_user_card_signals() -> void:
	if user_card_component:
		user_card_component.card_hovered.connect(_on_card_hovered)
		user_card_component.card_unhovered.connect(_on_card_unhovered)
		user_card_component.card_clicked.connect(_on_card_clicked)
		print("[BattleUI_v1] user_card signals connected")
	else:
		push_error("[BattleUI_v1] user_card_component not found!")

func _on_card_hovered(index: int) -> void:
	if not _selection_enabled:
		return
	_hovered_index = index
	_show_card_info(index)

func _on_card_unhovered(index: int) -> void:
	if _hovered_index == index:
		_hovered_index = -1
		_hide_card_info()

func _show_card_info(index: int) -> void:
	if index < 0 or index >= _all_cards.size() or _card_info_panel == null:
		return

	var card_instance: CardInstance = _all_cards[index] as CardInstance
	if card_instance == null or _data_manager == null:
		return

	var prototype_id = card_instance.get_prototype_id()
	var prototype: CardData = _data_manager.card_registry.get_prototype(prototype_id)
	if prototype == null:
		return

	var card_name = _format_card_name(prototype_id)
	var card_class_str = CardData.class_name_to_string(prototype.card_class)
	var total_value = card_instance.get_total_value(prototype)

	_card_info_name_label.text = card_name

	var info_text = ""
	info_text += "[color=yellow]Type:[/color] [color=white]%s[/color]\n" % card_class_str
	info_text += "[color=yellow]Value:[/color] [color=white]%d[/color]" % total_value

	if prototype.effect_ids.size() > 0:
		info_text += "\n[color=yellow]Effects:[/color]"
		for effect_id in prototype.effect_ids:
			info_text += "\n  [color=cyan]• %s[/color]" % effect_id

	if prototype.cost_id != "":
		info_text += "\n[color=yellow]Cost:[/color] [color=red]%s[/color]" % prototype.cost_id

	if card_instance.get_bind_status() != CardData.CardBindStatus.None:
		info_text += "\n[color=purple]Status:[/color] %s" % CardInstance.bind_status_to_string(card_instance.get_bind_status())

	_card_info_label.text = info_text
	_card_info_panel.visible = true

func _hide_card_info() -> void:
	if _card_info_panel:
		_card_info_panel.visible = false

func _update_card_info_position() -> void:
	if _card_info_panel == null or not _card_info_panel.visible or _hovered_index < 0 or _hovered_index >= _card_nodes.size():
		return

	var card = _card_nodes[_hovered_index]
	if not card.visible:
		return

	var target_pos = _original_positions[card]
	target_pos.y += HOVER_OFFSET_Y

	var wobble_x = sin(_wobble_time * SHAKE_SPEED + _hovered_index * 1.5) * SHAKE_AMPLITUDE
	var wobble_y = cos(_wobble_time * SHAKE_SPEED * 0.7 + _hovered_index * 1.2) * (SHAKE_AMPLITUDE * 0.5)

	var target_with_wobble = target_pos + Vector2(wobble_x, wobble_y)

	_card_info_panel.position = target_with_wobble + Vector2(CARD_INFO_OFFSET_X, CARD_INFO_OFFSET_Y)

func _format_card_name(prototype_id: String) -> String:
	var name = prototype_id.replace("card_", "")
	var words = name.split("_")
	var formatted = ""
	for word in words:
		if word.length() > 0:
			formatted += word.capitalize()
			formatted += " "
	return formatted.strip_edges()

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
	_update_card_info_position()

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

	var selected_ids: Array = []
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
		_hide_card_info()

func update_selection(selected_ids: Array) -> void:
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

func _on_battle_ended(result: int, report: BattleReport) -> void:
	print("[BattleUI_v1] Battle ended with result: %d" % result)
	enable_selection(false)

func get_selected_indices() -> Array:
	return _selected_indices.duplicate()


func _on_user_card_card_hovered(index: int) -> void:
	pass # Replace with function body.


func _on_user_card_card_clicked(index: int) -> void:
	pass # Replace with function body.


func _on_user_card_card_unhovered(index: int) -> void:
	pass # Replace with function body.
