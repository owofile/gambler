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
var _animation_registry: Node = null

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_mouse_filter = MOUSE_FILTER_STOP

	_sprite = get_node_or_null("CardContainer/Sprite")
	_value_label = get_node_or_null("ValueLabel")
	_hover_label = get_node_or_null("HoverInfo")
	_is_enabled = true

func setup(proto_id: String, instance_id: String, value: int) -> void:
	prototype_id = proto_id
	card_id = instance_id
	card_value = value
	_update_display()

func _get_animation_registry() -> Node:
	if _animation_registry == null:
		_animation_registry = get_node_or_null("/root/AnimationRegistry")
		if _animation_registry == null:
			_animation_registry = Node.new()
			_animation_registry.set_script(load("res://scripts/battle/AnimationRegistry.gd"))
			_animation_registry.name = "AnimationRegistry"
			get_tree().root.add_child(_animation_registry)
	return _animation_registry

func play_animation(event_name: String, on_complete: Callable = Callable()) -> void:
	var registry = _get_animation_registry()
	if registry == null:
		on_complete.call()
		return

	var anim_name = _get_animation_name_for(event_name)
	if anim_name.is_empty():
		on_complete.call()
		return

	var anim = registry.get_animation(anim_name)
	if anim:
		var config = _build_animation_config(event_name)
		anim.play(config, on_complete)
	else:
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
			return {"target": self, "duration": 0.3}
		"click":
			return {"target": self, "duration": 0.15, "loops": 2}
		"selected":
			return {"target": self, "to": position + Vector2(0, -50), "duration": 0.3}
		"particle":
			return {"particle_count": card_value, "spawn_position": global_position, "color": Color.YELLOW}
	return {"target": self}

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
		_value_label.text = str(card_value)
	if _hover_label:
		_hover_label.text = prototype_id

func _on_mouse_entered() -> void:
	if not _is_enabled:
		return
	_is_hovered = true
	_modulate_by_state()
	play_animation("hover")
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
			play_animation("click")
			card_clicked.emit(card_id)
