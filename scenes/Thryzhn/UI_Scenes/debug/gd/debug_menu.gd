extends CanvasLayer

const OPTION_SAVE := 0
const OPTION_LOAD := 1
const OPTION_ADD_CARD := 2
const OPTION_SHOW_INVENTORY := 3
const OPTION_BACK := 4
const OPTION_COUNT := 5

const INPUT_DELAY := 0.2

const SELECTED_COLOR := Color(1.0, 0.8, 0.0, 1.0)
const NORMAL_COLOR := Color(0.7, 0.7, 0.7, 1.0)

@onready var save_info_label: Label = $Panel/VBox/SaveInfo
@onready var card_info_label: Label = $Panel/VBox/CardInfo
@onready var option_labels: Array = [
	$Panel/VBox/Options/Option0,
	$Panel/VBox/Options/Option1,
	$Panel/VBox/Options/Option2,
	$Panel/VBox/Options/Option3,
	$Panel/VBox/Options/Option4
]
@onready var inventory_panel: ColorRect = $Panel/InventoryPanel
@onready var inventory_label: Label = $Panel/InventoryPanel/InventoryScroll/InventoryLabel

var _current_selection: int = 0
var _input_cooldown: float = 0.0
var _inventory_visible: bool = false

func _ready() -> void:
	_update_all()
	_update_selection_display()

func _process(delta: float) -> void:
	_input_cooldown = maxf(_input_cooldown - delta, 0.0)
	if _input_cooldown > 0:
		return

	if Input.is_action_just_pressed("ui_DebugMenu_Cancel"):
		_handle_cancel()
		return

	if Input.is_action_just_pressed("ui_DebugMenu_Up"):
		if _current_selection > 0:
			_current_selection -= 1
			_update_selection_display()
		_input_cooldown = INPUT_DELAY
		return

	if Input.is_action_just_pressed("ui_DebugMenu_Down"):
		if _current_selection < OPTION_COUNT - 1:
			_current_selection += 1
			_update_selection_display()
		_input_cooldown = INPUT_DELAY
		return

	if Input.is_action_just_pressed("ui_DebugMenu_Accept"):
		_handle_accept()
		return

func _update_selection_display() -> void:
	for i in range(OPTION_COUNT):
		if i == _current_selection:
			option_labels[i].add_theme_color_override("font_color", SELECTED_COLOR)
			option_labels[i].text = "> " + _get_option_text(i)
		else:
			option_labels[i].add_theme_color_override("font_color", NORMAL_COLOR)
			option_labels[i].text = "  " + _get_option_text(i)

func _get_option_text(index: int) -> String:
	match index:
		OPTION_SAVE:
			return "存档"
		OPTION_LOAD:
			return "读档"
		OPTION_ADD_CARD:
			return "添加随机卡牌"
		OPTION_SHOW_INVENTORY:
			return "显示背包"
		OPTION_BACK:
			return "返回"
	return ""

func _handle_accept() -> void:
	match _current_selection:
		OPTION_SAVE:
			_save_game()
		OPTION_LOAD:
			_load_game()
		OPTION_ADD_CARD:
			_add_random_card()
		OPTION_SHOW_INVENTORY:
			_show_inventory()
		OPTION_BACK:
			_back()

func _save_game() -> void:
	SaveManager.auto_save()
	_update_all()

func _load_game() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
		_update_all()

func _add_random_card() -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager == null:
		return
	var all_ids = data_manager.card_registry.get_all_prototype_ids()
	if all_ids.size() == 0:
		return
	var random_id = all_ids[randi() % all_ids.size()]
	var card = CardMgr.add_card(random_id)
	if card:
		_update_all()

func _show_inventory() -> void:
	_inventory_visible = !_inventory_visible
	inventory_panel.visible = _inventory_visible
	if _inventory_visible:
		_update_inventory_display()

func _update_inventory_display() -> void:
	var text = "卡牌数量: %d / %d\n\n" % [CardMgr.get_deck_size(), CardMgr.MAX_DECK_SIZE]
	var all_cards = CardMgr.get_all_cards()
	if all_cards.size() == 0:
		text += "(空)"
	else:
		for card in all_cards:
			text += "- %s\n" % card.get_prototype_id()
	inventory_label.text = text

func _update_all() -> void:
	var save_info = SaveManager.get_last_save_info()
	var has_save = SaveManager.has_save()

	if has_save:
		save_info_label.text = "存档状态: 存在 (%d张卡)" % save_info.get("card_count", 0)
	else:
		save_info_label.text = "存档状态: 无"

	card_info_label.text = "当前卡牌: %d / %d" % [CardMgr.get_deck_size(), CardMgr.MAX_DECK_SIZE]
	_update_selection_display()

func _handle_cancel() -> void:
	if _inventory_visible:
		_close_inventory()
		return
	_back()

func _close_inventory() -> void:
	_inventory_visible = false
	inventory_panel.visible = false

func _back() -> void:
	queue_free()
