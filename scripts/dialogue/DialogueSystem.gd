## DialogueSystem - Unified dialogue management.
##
## Responsibility:
## - Manage simple line-by-line dialogue
## - Delegate tree-based dialogue to NarrativeEngine
## - Integrate with UI components (DialogueBoxParent, ItemBar)
## - Handle game state transitions
##
## Usage:
##   # Simple dialogue
##   EventBus.publish("StartDialogue", {"lines": ["Hello!", "How are you?"]})
##
##   # Tree-based dialogue
##   EventBus.publish("StartDialogueTree", {
##       "path": "res://dialogues/merchant.json",
##       "start_node": "start"
##   })
##
## Architecture:
##   DialogueSystem (Orchestrator)
##       ├── SimpleDialogueMode: line-by-line with DialogueBoxParent
##       └── NarrativeEngine: tree-based with conditions/effects
class_name DialogueSystem
extends CanvasLayer

signal dialogue_started
signal dialogue_ended
signal line_finished
signal dialogue_node_shown(node_id: String, speaker: String, text: String, options: Array)
signal option_selected(index: int)

enum DialogueMode { NONE, SIMPLE, NARRATIVE }

var _current_mode: DialogueMode = DialogueMode.NONE
var _is_active: bool = false

var _dialogue_box: Control = null
var _item_bar: Control = null
var _narrative_engine: NarrativeEngine = null

var _simple_lines: Array = []
var _simple_current_index: int = 0

func _ready() -> void:
	_setup_components()
	_setup_event_subscriptions()
	print("[DialogueSystem] Initialized")

func _setup_components() -> void:
	_narrative_engine = NarrativeEngine.new()
	add_child(_narrative_engine)
	_narrative_engine.dialogue_ended.connect(_on_narrative_ended)
	_narrative_engine.dialogue_node_changed.connect(_on_narrative_node_changed)
	_narrative_engine.effect_executed.connect(_on_effect_executed)

	if has_node("DialogueBoxParent"):
		_dialogue_box = $DialogueBoxParent
	if has_node("ItemBar"):
		_item_bar = $ItemBar
		if _item_bar.has_signal("on_item_selected"):
			_item_bar.on_item_selected.connect(_on_item_bar_selected)

func _setup_event_subscriptions() -> void:
	EventBus.subscribe("StartDialogue", _on_start_simple_dialogue)
	EventBus.subscribe("StartDialogueTree", _on_start_narrative_dialogue)
	EventBus.subscribe("DialogueNodeShown", _on_dialogue_node_shown)

func _on_start_simple_dialogue(payload: Dictionary) -> void:
	if _is_active:
		_end_current_dialogue()

	_simple_lines = payload.get("lines", [payload.get("text", "")])
	_simple_current_index = 0
	_current_mode = DialogueMode.SIMPLE
	_start_active()

func _on_start_narrative_dialogue(payload: Dictionary) -> void:
	if _is_active:
		_end_current_dialogue()

	var path: String = payload.get("path", "")
	if path.is_empty():
		push_error("[DialogueSystem] Dialogue path is empty")
		return

	if not _narrative_engine.load_dialogue_from_path(path):
		push_error("[DialogueSystem] Failed to load dialogue: %s" % path)
		return

	_current_mode = DialogueMode.NARRATIVE
	var start_node: String = payload.get("start_node", "start")
	_narrative_engine.start_dialogue(start_node)
	_start_active()

func _start_active() -> void:
	_is_active = true
	GameState.enter_dialogue()
	dialogue_started.emit()
	_show_current_content()

func _show_current_content() -> void:
	match _current_mode:
		DialogueMode.SIMPLE:
			_show_simple_line()
		DialogueMode.NARRATIVE:
			pass

func _show_simple_line() -> void:
	if _simple_current_index >= _simple_lines.size():
		_end_dialogue()
		return

	var line: String = _simple_lines[_simple_current_index]
	if _dialogue_box and _dialogue_box.has_method("show_single_dialogue"):
		_dialogue_box.show_single_dialogue(line)
	else:
		print("[DialogueSystem] %s" % line)

func _on_dialogue_node_shown(payload: Dictionary) -> void:
	var node_id: String = payload.get("node_id", "")
	var speaker: String = payload.get("speaker", "")
	var text: String = payload.get("text", "")
	var options: Array = payload.get("options", [])

	dialogue_node_shown.emit(node_id, speaker, text, options)

	if _dialogue_box and _dialogue_box.has_method("show_single_dialogue"):
		_dialogue_box.show_single_dialogue(text)
	if _dialogue_box and _dialogue_box.has_method("set_speaker_name"):
		_dialogue_box.speaker_name = speaker

	_update_option_display(options)

func _update_option_display(options: Array) -> void:
	if not _item_bar:
		return

	if options.is_empty():
		if _item_bar.has_method("hide"):
			_item_bar.hide()
	else:
		if _item_bar.has_method("show"):
			_item_bar.show()
		if _item_bar.has_method("set_option_count"):
			_item_bar.set_option_count(options.size())
		for i in range(min(options.size(), 3)):
			var text = options[i].get("text", "Option %d" % i)
			if _item_bar.has_method("set_option_text"):
				_item_bar.set_option_text(i, text)

func _on_item_bar_selected(index: int) -> void:
	if not _is_active:
		return

	option_selected.emit(index)

	match _current_mode:
		DialogueMode.SIMPLE:
			_on_simple_option_selected(index)
		DialogueMode.NARRATIVE:
			_on_narrative_option_selected(index)

func _on_simple_option_selected(index: int) -> void:
	match index:
		0:
			advance()
		1, 2, 3:
			print("[DialogueSystem] Simple mode - option %d selected" % index)

func _on_narrative_option_selected(index: int) -> void:
	if _narrative_engine and _narrative_engine.is_active():
		_narrative_engine.select_option(index)

func _on_narrative_ended(node_id: String) -> void:
	_end_dialogue()

func _on_narrative_node_changed(node_id: String) -> void:
	pass

func _on_effect_executed(effect_type: String, params: Dictionary) -> void:
	print("[DialogueSystem] Effect executed: %s" % effect_type)

func advance() -> void:
	if not _is_active:
		return

	match _current_mode:
		DialogueMode.SIMPLE:
			_simple_current_index += 1
			_show_simple_line()
			line_finished.emit()
		DialogueMode.NARRATIVE:
			pass

func select_option(option_index: int) -> void:
	if not _is_active:
		return

	match _current_mode:
		DialogueMode.NARRATIVE:
			if _narrative_engine and _narrative_engine.is_active():
				_narrative_engine.select_option(option_index)

func _end_current_dialogue() -> void:
	match _current_mode:
		DialogueMode.SIMPLE:
			_simple_lines.clear()
			_simple_current_index = 0
		DialogueMode.NARRATIVE:
			pass

	_current_mode = DialogueMode.NONE

func _end_dialogue() -> void:
	_is_active = false
	_end_current_dialogue()
	GameState.enter_exploration()
	dialogue_ended.emit()
	EventBus.publish("DialogueEnded", {"mode": _current_mode if _current_mode != DialogueMode.NONE else "simple"})

	if _dialogue_box and _dialogue_box.has_method("hide_dialogue"):
		_dialogue_box.hide_dialogue()
	if _item_bar and _item_bar.has_method("hide"):
		_item_bar.hide()

func is_active() -> bool:
	return _is_active

func get_current_mode() -> DialogueMode:
	return _current_mode

func get_narrative_engine() -> NarrativeEngine:
	return _narrative_engine

func _process(delta: float) -> void:
	if not _is_active:
		return

	if Input.is_action_just_pressed("ui_accept"):
		_on_accept_pressed()
	elif Input.is_action_just_pressed("ui_cancel"):
		_on_cancel_pressed()
	elif Input.is_action_just_pressed("ui_left"):
		_on_left_pressed()
	elif Input.is_action_just_pressed("ui_right"):
		_on_right_pressed()

func _on_accept_pressed() -> void:
	if _current_mode == DialogueMode.SIMPLE:
		advance()

func _on_cancel_pressed() -> void:
	pass

func _on_left_pressed() -> void:
	if _item_bar and "current_index" in _item_bar:
		_item_bar.current_index = max(0, _item_bar.current_index - 1)
		if _item_bar.has_method("update_highlight"):
			_item_bar.update_highlight()

func _on_right_pressed() -> void:
	if _item_bar and "current_index" in _item_bar:
		_item_bar.current_index = min(_item_bar.controls.size() - 1, _item_bar.current_index + 1)
		if _item_bar.has_method("update_highlight"):
			_item_bar.update_highlight()
