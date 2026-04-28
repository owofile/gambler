## 战斗UI V2 - 实现 IBattleUI 接口
class_name BattleUI_V2
extends CanvasLayer

signal card_selected(card_id: String)
signal card_deselected(card_id: String)
signal selection_confirmed(card_ids: Array)
signal animation_finished(anim_name: String)

var _core: BattleCore = null
var _card_manager: Node = null
var _data_manager: Node = null

var _card_widgets: Array = []
var _selected_indices: Array = []
var _selection_enabled: bool = false

const MAX_SELECT: int = 3

var _all_cards: Array = []
var _all_card_ids: Array = []

var _score_label: Label = null
var _state_label: Label = null
var _playcard_btn: Button = null
var _instruction_label: Label = null
var _enemy_cards_label: Label = null

@export var card_spacing: int = 120
@export var card_start_x: int = 100
@export var card_start_y: int = 350

@export var enemy_card_spacing: int = 120
@export var enemy_card_start_x: int = 100
@export var enemy_card_start_y: int = 80

var _screen_size: Vector2 = Vector2(800, 600)

func _ready() -> void:
	_card_manager = get_node_or_null("/root/CardMgr")
	_data_manager = get_node_or_null("/root/DataManager")
	_setup_ui_elements()

func initialize(core: BattleCore) -> void:
	_core = core
	print("[BattleUI_V2] Initialized with BattleCore")

	if _core and _core.has_signal("animation_requested"):
		_core.animation_requested.connect(_on_animation_requested)

func _setup_ui_elements() -> void:
	_screen_size = get_viewport().get_visible_rect().size

	var panel = ColorRect.new()
	panel.color = Color(0.1, 0.1, 0.2, 0.9)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	_state_label = Label.new()
	_state_label.text = "Battle"
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.position = Vector2((_screen_size.x - 200) / 2, 20)
	_state_label.size = Vector2(200, 40)
	add_child(_state_label)

	_score_label = Label.new()
	_score_label.text = "Player: 0 | Enemy: 0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.position = Vector2((_screen_size.x - 200) / 2, 70)
	_score_label.size = Vector2(200, 30)
	add_child(_score_label)

	_instruction_label = Label.new()
	_instruction_label.text = "Select %d cards" % MAX_SELECT
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.position = Vector2((_screen_size.x - 300) / 2, 150)
	_instruction_label.size = Vector2(300, 30)
	add_child(_instruction_label)

	_playcard_btn = Button.new()
	_playcard_btn.text = "出牌"
	_playcard_btn.position = Vector2((_screen_size.x - 100) / 2, 480)
	_playcard_btn.size = Vector2(100, 50)
	_playcard_btn.disabled = true
	_playcard_btn.pressed.connect(_on_playcard_pressed)
	add_child(_playcard_btn)

	_enemy_cards_label = Label.new()
	_enemy_cards_label.text = "Enemy: "
	_enemy_cards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_cards_label.position = Vector2((_screen_size.x - 300) / 2, 200)
	_enemy_cards_label.size = Vector2(300, 30)
	add_child(_enemy_cards_label)

func _on_animation_requested(anim_name: String) -> void:
	print("[BattleUI_V2] Animation requested: %s" % anim_name)
	match anim_name:
		"enemy_reveal":
			await get_tree().create_timer(0.5).timeout
			animation_finished.emit("enemy_reveal")
		"settlement":
			await get_tree().create_timer(0.5).timeout
			animation_finished.emit("settlement")
		_:
			animation_finished.emit(anim_name)

func show_hand(cards: Array) -> void:
	_all_cards = cards
	_all_card_ids.clear()
	for card in cards:
		var c = card as CardInstance
		if c:
			_all_card_ids.append(c.get_card_id())

	_clear_card_widgets()
	_create_card_widgets()
	print("[BattleUI_V2] Showing %d cards" % cards.size())

func _create_card_widgets() -> void:
	var scene = load("res://scenes/battle/widgets/CardWidget.tscn")
	if not scene:
		push_error("[BattleUI_V2] CardWidget.tscn not found!")
		return

	var card_count = mini(_all_cards.size(), 6)
	var total_width = (card_count - 1) * card_spacing
	var start_x = (_screen_size.x - total_width) / 2

	for i in range(card_count):
		var card: CardInstance = _all_cards[i] as CardInstance
		if not card:
			continue

		var widget = scene.instantiate()
		widget.position = Vector2(start_x + i * card_spacing, card_start_y)

		var card_info = _get_card_full_info(card)
		widget.setup(
			card.get_prototype_id(),
			card.get_card_id(),
			card_info.value,
			card_info.display_name,
			card_info.card_class,
			card_info.effects,
			card_info.texture
		)
		widget.card_clicked.connect(_on_card_widget_clicked.bind(i))
		widget.card_hovered.connect(_on_card_hovered)
		widget.card_unhovered.connect(_on_card_unhovered)
		widget.set_enabled(true)

		add_child(widget)
		_card_widgets.append(widget)

func _get_card_full_info(card: CardInstance) -> Dictionary:
	var info = {"value": 0, "name": "", "card_class": "", "effects": "", "texture": "", "display_name": ""}

	if not _data_manager:
		print("[DEBUG] _data_manager is null")
		return info

	var prototype = _data_manager.card_registry.get_prototype(card.get_prototype_id())
	if not prototype:
		print("[DEBUG] prototype is null for: ", card.get_prototype_id())
		return info

	info.value = card.get_total_value(prototype)
	info.name = prototype.prototype_id
	info.display_name = prototype.display_name if not prototype.display_name.is_empty() else prototype.prototype_id
	info.card_class = CardData.class_name_to_string(prototype.card_class)
	info.effects = ", ".join(prototype.effect_ids) if not prototype.effect_ids.is_empty() else ""
	info.texture = prototype.texture_path

	print("[DEBUG] card info - value=%d, name=%s, display_name=%s, texture=%s" % [info.value, info.name, info.display_name, info.texture])
	return info

func _clear_card_widgets() -> void:
	for widget in _card_widgets:
		widget.queue_free()
	_card_widgets.clear()

func highlight_card(card_id: String, highlight: bool) -> void:
	for i in range(_all_card_ids.size()):
		if _all_card_ids[i] == card_id:
			if i < _card_widgets.size():
				_card_widgets[i].set_selected(highlight)
			break

func show_selection_confirmed(cards: Array) -> void:
	print("[BattleUI_V2] Selection confirmed: %d cards" % cards.size())

func show_enemy_cards(cards: Array) -> void:
	var text = "Enemy: "
	for card_id in cards:
		text += str(card_id) + " "
	_enemy_cards_label.text = text
	print("[BattleUI_V2] Enemy shows %d cards" % cards.size())

func show_settlement(player_score: int, enemy_score: int, winner: String) -> void:
	_score_label.text = "Player: %d | Enemy: %d | Winner: %s" % [player_score, enemy_score, winner]
	print("[BattleUI_V2] Settlement: %s wins! %d vs %d" % [winner, player_score, enemy_score])

func clear_selection() -> void:
	_selected_indices.clear()
	for widget in _card_widgets:
		widget.set_selected(false)
	_playcard_btn.disabled = true

func show_battle_result(result: int) -> void:
	var result_str = "Victory" if result == 1 else "Defeat"
	_state_label.text = "BATTLE END: %s" % result_str
	print("[BattleUI_V2] Battle result: %s" % result_str)

func enable_selection(enabled: bool) -> void:
	_selection_enabled = enabled
	for widget in _card_widgets:
		widget.set_enabled(enabled)
	_instruction_label.text = "Select %d cards" % MAX_SELECT if enabled else ""
	print("[BattleUI_V2] Selection enabled: %s" % enabled)

func update_score_display(player_wins: int, enemy_wins: int, target: int) -> void:
	_score_label.text = "Player: %d/%d | Enemy: %d/%d" % [player_wins, target, enemy_wins, target]

func _on_card_widget_clicked(card_id: String, index: int) -> void:
	if not _selection_enabled:
		return

	if _selected_indices.has(index):
		_selected_indices.erase(index)
		card_deselected.emit(card_id)
		highlight_card(card_id, false)
	else:
		if _selected_indices.size() < MAX_SELECT:
			_selected_indices.append(index)
			card_selected.emit(card_id)
			highlight_card(card_id, true)

	_playcard_btn.disabled = _selected_indices.size() != MAX_SELECT

func _on_card_hovered(card_id: String) -> void:
	pass

func _on_card_unhovered(card_id: String) -> void:
	pass

func _on_playcard_pressed() -> void:
	if not _selection_enabled:
		return
	if _selected_indices.size() != MAX_SELECT:
		return

	var selected_ids: Array = []
	for idx in _selected_indices:
		if idx < _all_card_ids.size():
			selected_ids.append(_all_card_ids[idx])

	if selected_ids.size() == MAX_SELECT:
		selection_confirmed.emit(selected_ids)
