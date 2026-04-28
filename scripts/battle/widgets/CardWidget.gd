## 卡牌控件 - 可复用的卡牌UI组件
class_name CardWidget
extends PanelContainer

signal card_clicked(card_id: String)
signal card_hovered(card_id: String)
signal card_unhovered(card_id: String)

@export var card_id: String = ""
@export var prototype_id: String = ""
@export var card_value: int = 0
@export var card_name: String = ""
@export var card_class: String = ""
@export var card_effects: String = ""
@export var texture_path: String = ""

var _is_selected: bool = false
var _is_hovered: bool = false
var _is_enabled: bool = false

var _sprite: Sprite2D = null
var _value_label: Label = null
var _hover_info: PanelContainer = null
var _hover_name: Label = null
var _hover_value: Label = null
var _hover_class: Label = null
var _hover_effects: Label = null
var _animation_registry: Node = null

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_filter = MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_sprite = get_node_or_null("CardContainer/Sprite")
	_value_label = get_node_or_null("ValueLabel")
	_hover_info = get_node_or_null("HoverInfo")
	_hover_name = get_node_or_null("HoverInfo/VBox/NameLabel")
	_hover_value = get_node_or_null("HoverInfo/VBox/ValueInfoLabel")
	_hover_class = get_node_or_null("HoverInfo/VBox/ClassLabel")
	_hover_effects = get_node_or_null("HoverInfo/VBox/EffectsLabel")
	_is_enabled = true

	_update_display()

	print("[CardWidget] Ready - card_id=%s, prototype_id=%s" % [card_id, prototype_id])

func setup(proto_id: String, instance_id: String, value: int, name: String = "", card_class_name: String = "", effects: String = "", texture: String = "") -> void:
	prototype_id = proto_id
	card_id = instance_id
	card_value = value
	card_name = name
	card_class = card_class_name
	card_effects = effects
	texture_path = texture
	_apply_texture()

	if _value_label != null:
		_update_display()
	else:
		print("[DEBUG] setup called before _ready(), will update later")

	print("[CardWidget] Setup - id=%s, value=%d, name=%s, texture=%s" % [instance_id, value, name, texture])

func _get_animation_registry() -> Node:
	if _animation_registry == null:
		_animation_registry = get_node_or_null("/root/AnimationRegistry")
		if _animation_registry == null:
			_animation_registry = Node.new()
			_animation_registry.set_script(load("res://scripts/battle/AnimationRegistry.gd"))
			_animation_registry.name = "AnimationRegistry"
			get_tree().root.add_child(_animation_registry)
	return _animation_registry

func _apply_texture() -> void:
	if not _sprite:
		_sprite = get_node_or_null("CardContainer/Sprite")
	if not _sprite:
		return

	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		if tex:
			_sprite.texture = tex
			return

	var fallback = "res://assets/cards/textures/default.png"
	if ResourceLoader.exists(fallback):
		_sprite.texture = load(fallback)
	else:
		print("[CardWidget] No texture for %s, no fallback available" % prototype_id)

func play_animation(event_name: String, on_complete: Callable = Callable()) -> void:
	var registry = _get_animation_registry()
	if registry == null:
		if on_complete.is_valid():
			on_complete.call()
		return

	var anim_name = _get_animation_name_for(event_name)
	if anim_name.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return

	var anim = registry.get_animation(anim_name)
	if anim:
		var config = _build_animation_config(event_name)
		anim.play(self, config, on_complete)
	else:
		if on_complete.is_valid():
			on_complete.call()

func _get_animation_name_for(event_name: String) -> String:
	match event_name:
		"hover": return "glow"
		"click": return "bounce"
		"selected": return "move"
		"reveal": return "shake"
		"particle": return "particle"
	return ""

func _build_animation_config(event_name: String) -> Dictionary:
	match event_name:
		"hover":
			return {"duration": 0.3}
		"click":
			return {"duration": 0.15, "loops": 2}
		"selected":
			return {"to": position + Vector2(0, -50), "duration": 0.3}
		"particle":
			return {"particle_count": card_value if card_value > 0 else 10, "spawn_position": global_position, "color": Color.YELLOW}
	return {}

func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_modulate_by_state()

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_modulate_by_state()
	if selected:
		play_animation("selected")

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
		_value_label.text = str(card_value) if card_value > 0 else "-"
	if _hover_name:
		_hover_name.text = card_name if not card_name.is_empty() else prototype_id
	if _hover_value:
		_hover_value.text = "Value: %d" % card_value
	if _hover_class:
		_hover_class.text = "Class: %s" % card_class
	if _hover_effects:
		_hover_effects.text = "Effects: %s" % card_effects if not card_effects.is_empty() else "Effects: None"

func _on_mouse_entered() -> void:
	if not _is_enabled:
		return
	_is_hovered = true
	_modulate_by_state()
	_show_hover_info(true)
	card_hovered.emit(card_id)

func _on_mouse_exited() -> void:
	if not _is_enabled:
		return
	_is_hovered = false
	_modulate_by_state()
	_show_hover_info(false)
	card_unhovered.emit(card_id)

func _show_hover_info(show: bool) -> void:
	if _hover_info:
		_hover_info.visible = show

func _on_gui_input(event: InputEvent) -> void:
	if not _is_enabled:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			play_animation("click")
			card_clicked.emit(card_id)
