## 卡牌控件 - 可复用的卡牌UI组件
class_name CardWidget
extends PanelContainer

signal card_clicked(card_id: String)
signal card_hovered(card_id: String)
signal card_unhovered(card_id: String)

@export var card_id: String = ""
@export var prototype_id: String = ""
@export var card_value: int = 0

var _is_selected: bool = false
var _is_hovered: bool = false
var _is_enabled: bool = false

var _sprite: Sprite2D = null
var _value_label: Label = null
var _hover_label: Label = null

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func setup(proto_id: String, instance_id: String, value: int) -> void:
	prototype_id = proto_id
	card_id = instance_id
	card_value = value

	_find_nodes()
	_load_texture()
	_update_display()
	_connect_signals()

func _find_nodes() -> void:
	_sprite = get_node_or_null("CardContainer/Sprite") as Sprite2D
	_value_label = get_node_or_null("ValueLabel") as Label
	_hover_label = get_node_or_null("HoverInfo") as Label

	if _sprite:
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _connect_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _load_texture() -> void:
	if _sprite:
		_sprite.texture = load("res://assets/cards/backgrounds/logo_antver.png")

func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_modulate_by_state()

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_modulate_by_state()

func set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	_modulate_by_state()

func _modulate_by_state() -> void:
	if not _sprite:
		return

	if not _is_enabled:
		_sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif _is_selected:
		_sprite.modulate = Color(1.3, 1.0, 0.8, 1.0)
	elif _is_hovered:
		_sprite.modulate = Color(1.1, 1.1, 0.9, 1.0)
	else:
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_display() -> void:
	if _value_label:
		_value_label.text = str(card_value)
	if _hover_label:
		_hover_label.text = prototype_id

func _on_mouse_entered() -> void:
	if not _is_enabled:
		return
	_is_hovered = true
	_modulate_by_state()
	card_hovered.emit(card_id)

func _on_mouse_exited() -> void:
	if not _is_enabled:
		return
	_is_hovered = false
	_modulate_by_state()
	card_unhovered.emit(card_id)

func _on_gui_input(event: InputEvent) -> void:
	if not _is_enabled:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(card_id)
