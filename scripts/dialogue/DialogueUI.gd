## DialogueUI - Connects NarrativeEngine to the dialogue UI components.
##
## Responsibility:
## - Listen to NarrativeEngine events
## - Update DialogueBoxParent with speaker/text
## - Update ItemBar with available options
## - Handle option selection and advance dialogue
## - Manage dialogue input (keyboard/gamepad)
##
## Architecture:
##   NarrativeEngine (logic)
##        ↓ DialogueNodeShown event
##   DialogueUI (controller)
##        ↓ updates
##   DialogueBoxParent + ItemBar (view)
##
## Note: This is a Controller in MVC pattern, not a view.
class_name DialogueUI
extends CanvasLayer

signal dialogue_option_selected(index: int)
signal dialogue_advance_requested

@export var enable_input: bool = true

var _dialogue_box: Control = null
var _item_bar: Control = null
var _narrative_engine: NarrativeEngine = null
var _current_options: Array = []
var _is_active: bool = false

func _ready() -> void:
	_setup_ui_references()
	_setup_event_subscriptions()
	print("[DialogueUI] Initialized")

func _setup_ui_references() -> void:
	if has_node("DialogueBoxParent"):
		_dialogue_box = $DialogueBoxParent
	if has_node("ItemBar"):
		_item_bar = $ItemBar
		if _item_bar.has_signal("on_item_selected"):
			_item_bar.on_item_selected.connect(_on_item_selected)

func _setup_event_subscriptions() -> void:
	EventBus.subscribe("DialogueNodeShown", _on_dialogue_node_shown)
	EventBus.subscribe("DialogueEnded", _on_dialogue_ended)
	EventBus.subscribe("StartDialogue", _on_start_simple_dialogue)

func _on_dialogue_node_shown(payload: Dictionary) -> void:
	if not _dialogue_box:
		return

	var speaker: String = payload.get("speaker", "")
	var text: String = payload.get("text", "")
	var options: Array = payload.get("options", [])

	_current_options = options
	_is_active = true

	if _dialogue_box.has_method("show_single_dialogue"):
		_dialogue_box.show_single_dialogue(text)
	if _dialogue_box.has_method("set_speaker_name"):
		_dialogue_box.speaker_name = speaker

	_update_option_display(options)

func _update_option_display(options: Array) -> void:
	if not _item_bar:
		return

	if options.is_empty():
		_hide_item_bar()
	else:
		_show_item_bar_with_options(options)

func _show_item_bar_with_options(options: Array) -> void:
	if _item_bar.has_method("show_options"):
		_item_bar.show_options(options)
	elif _item_bar.has_method("set_option_count"):
		_item_bar.set_option_count(options.size())
	_update_option_texts(options)

func _update_option_texts(options: Array) -> void:
	if not _item_bar or not _item_bar.has_method("set_option_text"):
		return

	for i in range(min(options.size(), 3)):
		var text = options[i].get("text", "Option %d" % i)
		_item_bar.set_option_text(i, text)

func _hide_item_bar() -> void:
	if _item_bar and _item_bar.has_method("hide"):
		_item_bar.hide()

func _on_item_selected(index: int) -> void:
	if not _is_active:
		return

	print("[DialogueUI] Option selected: %d" % index)

	if _narrative_engine and _narrative_engine.is_active():
		_narrative_engine.select_option(index)
	elif not _current_options.is_empty() and index < _current_options.size():
		execute_option_effects(_current_options[index])

	dialogue_option_selected.emit(index)

func execute_option_effects(option: Dictionary) -> void:
	var effects: Array = option.get("effects", [])
	for effect in effects:
		var effect_type: String = effect.get("type", "")
		var params: Dictionary = effect.get("params", {})

		match effect_type:
			"SetFlag":
				WorldState.set_flag(params.get("flag", ""), params.get("value", true))
			"GiveItem":
				var prototype_id = params.get("prototype_id", "")
				if not prototype_id.is_empty():
					CardMgr.add_card(prototype_id)
			"StartBattle":
				EventBus.publish("BattleRequested", {"enemy_id": params.get("enemy_id", "")})
			"TriggerDialogue":
				var node_id = params.get("node_id", "")
				if _narrative_engine and not node_id.is_empty():
					_narrative_engine.jump_to_node(node_id)

func _on_dialogue_ended(payload: Dictionary) -> void:
	_is_active = false
	_current_options.clear()
	_hide_dialogue_box()

func _on_start_simple_dialogue(payload: Dictionary) -> void:
	if not _dialogue_box:
		return

	var lines: Array = payload.get("lines", [payload.get("text", "")])
	var segments: Array = []
	for line in lines:
		segments.append({"text": line, "avatar": ""})

	if _dialogue_box.has_method("queue_dialogue_segments"):
		_dialogue_box.queue_dialogue_segments(segments)
		_is_active = true

func _hide_dialogue_box() -> void:
	if _dialogue_box and _dialogue_box.has_method("hide_dialogue"):
		_dialogue_box.hide_dialogue()

func _process(delta: float) -> void:
	if not enable_input or not _is_active:
		return

	if Input.is_action_just_pressed("ui_accept"):
		_on_accept_pressed()
	elif Input.is_action_just_pressed("ui_cancel"):
		_on_cancel_pressed()

func _on_accept_pressed() -> void:
	if _item_bar and _item_bar.has_signal("on_item_selected"):
		var current_idx = _item_bar.current_index if "current_index" in _item_bar else 0
		_on_item_selected(current_idx)

func _on_cancel_pressed() -> void:
	pass

func set_narrative_engine(engine: NarrativeEngine) -> void:
	if _narrative_engine:
		_narrative_engine.dialogue_ended.disconnect(_on_narrative_ended)
	_narrative_engine = engine
	if _narrative_engine:
		_narrative_engine.dialogue_ended.connect(_on_narrative_ended)

func _on_narrative_ended(node_id: String) -> void:
	_is_active = false
	_current_options.clear()

func show_dialogue_box() -> void:
	if _dialogue_box:
		_dialogue_box.visible = true

func hide_dialogue_box() -> void:
	if _dialogue_box:
		_dialogue_box.visible = false

func is_dialogue_active() -> bool:
	return _is_active
