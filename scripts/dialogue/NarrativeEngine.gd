## NarrativeEngine - Dialogue tree parsing and condition-effect execution.
##
## Responsibility:
## - Parse dialogue trees from JSON configuration
## - Evaluate conditions based on WorldState and other contexts
## - Execute effects (GiveItem, SetFlag, StartBattle, etc.)
## - Publish events for other contexts
##
## Dialogue Tree Format:
## {
##   "nodes": {
##     "start": {
##       "speaker": "NPC Name",
##       "text": "Dialogue text here",
##       "options": [
##         {
##           "text": "Player response",
##           "conditions": [{ "type": "HasFlag", "params": { "flag": "met_npc" } }],
##           "effects": [{ "type": "SetFlag", "params": { "flag": "talked_to_npc", "value": true } }]
##         }
##       ]
##     }
##   }
## }
##
## Condition Types:
##   - HasFlag(flag, value?)     : Check if flag exists and optionally matches value
##   - HasItem(prototype_id)      : Check if player has a specific card
##   - DeckSizeGE(min)           : Check if deck size >= min
##   - NpcAlive(npc_id)          : Check if NPC is alive (flag check)
##   - Comparison(flag, op, value): Compare flag to value (>, <, ==, !=)
##
## Effect Types:
##   - SetFlag(flag, value)      : Set a world state flag
##   - GiveItem(prototype_id)    : Add card to player's deck
##   - RemoveItem(prototype_id)  : Remove card from player's deck
##   - StartBattle(enemy_id)    : Trigger a battle
##   - TriggerDialogue(node_id)  : Jump to another dialogue node
##   - KillNpc(npc_id)          : Mark NPC as dead
class_name NarrativeEngine
extends Node

signal dialogue_started(node_id: String)
signal dialogue_ended(node_id: String)
signal dialogue_node_changed(node_id: String)
signal effect_executed(effect_type: String, params: Dictionary)

var _current_tree: Dictionary = {}
var _current_node_id: String = ""
var _dialogue_history: Array = []

const CONDITION_TYPES: Array = ["HasFlag", "HasItem", "DeckSizeGE", "NpcAlive", "Comparison"]
const EFFECT_TYPES: Array = ["SetFlag", "GiveItem", "RemoveItem", "StartBattle", "TriggerDialogue", "KillNpc", "GiveGold", "TakeGold"]

func _ready() -> void:
	print("[NarrativeEngine] Initialized")

func load_dialogue_tree(tree_data: Dictionary) -> bool:
	if not tree_data.has("nodes"):
		push_error("[NarrativeEngine] Dialogue tree missing 'nodes' key")
		return false
	if not tree_data.has("start"):
		push_error("[NarrativeEngine] Dialogue tree missing 'start' node")
		return false

	_current_tree = tree_data
	_dialogue_history.clear()
	print("[NarrativeEngine] Loaded dialogue tree with %d nodes" % tree_data["nodes"].size())
	return true

func load_dialogue_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("[NarrativeEngine] Dialogue file not found: %s" % path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[NarrativeEngine] Failed to open dialogue file: %s" % path)
		return false

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[NarrativeEngine] Failed to parse dialogue JSON")
		return false

	return load_dialogue_tree(json.data)

func start_dialogue(start_node_id: String = "start") -> void:
	if _current_tree.is_empty():
		push_error("[NarrativeEngine] No dialogue tree loaded")
		return

	if not _current_tree["nodes"].has(start_node_id):
		push_error("[NarrativeEngine] Start node '%s' not found" % start_node_id)
		return

	_current_node_id = start_node_id
	_dialogue_history.append(start_node_id)
	dialogue_started.emit(start_node_id)
	_show_current_node()

func _show_current_node() -> void:
	if _current_node_id.is_empty():
		return

	var node = _current_tree["nodes"][_current_node_id]
	dialogue_node_changed.emit(_current_node_id)

	var available_options = _get_available_options(node)
	if available_options.is_empty():
		_end_dialogue()
	else:
		EventBus.publish("DialogueNodeShown", {
			"node_id": _current_node_id,
			"speaker": node.get("speaker", ""),
			"text": node.get("text", ""),
			"options": available_options
		})

func _get_available_options(node: Dictionary) -> Array:
	var options: Array = node.get("options", [])
	var available: Array = []

	for option in options:
		if _evaluate_conditions(option.get("conditions", [])):
			available.append({
				"text": option.get("text", ""),
				"effects": option.get("effects", []),
				"next": option.get("next", "")
			})

	return available

func _evaluate_conditions(conditions: Array) -> bool:
	if conditions.is_empty():
		return true

	for cond in conditions:
		var cond_type: String = cond.get("type", "")
		var params: Dictionary = cond.get("params", {})

		match cond_type:
			"HasFlag":
				if not WorldState.has_flag(params.get("flag", "")):
					return false
				if params.has("value") and WorldState.get_flag(params["flag"]) != params["value"]:
					return false
			"HasItem":
				var prototype_id: String = params.get("prototype_id", "")
				if not _player_has_item(prototype_id):
					return false
			"DeckSizeGE":
				var min_size: int = params.get("min", 0)
				if CardMgr.get_deck_size() < min_size:
					return false
			"NpcAlive":
				var npc_id: String = params.get("npc_id", "")
				if WorldState.has_flag("npc_dead_" + npc_id):
					return false
			"HasCard":
				var prototype_id: String = params.get("prototype_id", "")
				if not CardMgr.has_card(prototype_id):
					return false
			"Comparison":
				var flag: String = params.get("flag", "")
				var op: String = params.get("op", "==")
				var value: Variant = params.get("value", 0)
				var flag_value: Variant = WorldState.get_flag(flag, 0)
				if not _compare_values(flag_value, op, value):
					return false
			_:
				push_warning("[NarrativeEngine] Unknown condition type: %s" % cond_type)

	return true

func _compare_values(a: Variant, op: String, b: Variant) -> bool:
	match op:
		"==":
			return a == b
		"!=":
			return a != b
		">":
			return a > b
		">=":
			return a >= b
		"<":
			return a < b
		"<=":
			return a <= b
		_:
			push_warning("[NarrativeEngine] Unknown comparison operator: %s" % op)
			return false

func _player_has_item(prototype_id: String) -> bool:
	var all_cards = CardMgr.get_all_cards()
	for card in all_cards:
		if card.prototype_id == prototype_id:
			return true
	return false

func select_option(option_index: int) -> void:
	if _current_node_id.is_empty():
		return

	var node = _current_tree["nodes"][_current_node_id]
	var options = _get_available_options(node)

	if option_index < 0 or option_index >= options.size():
		push_warning("[NarrativeEngine] Invalid option index: %d" % option_index)
		return

	var selected_option = options[option_index]
	_execute_effects(selected_option.get("effects", []))

	EventBus.publish("DialogueOptionSelected", {
		"node_id": _current_node_id,
		"option_index": option_index,
		"option_text": selected_option.get("text", "")
	})

	var next_node: String = selected_option.get("next", "")
	if not next_node.is_empty():
		_current_node_id = next_node
		_dialogue_history.append(next_node)
		_show_current_node()
	else:
		_end_dialogue()

func _execute_effects(effects: Array) -> void:
	for effect in effects:
		var effect_type: String = effect.get("type", "")
		var params: Dictionary = effect.get("params", {})

		match effect_type:
			"SetFlag":
				var flag: String = params.get("flag", "")
				var value: Variant = params.get("value", true)
				WorldState.set_flag(flag, value)
				effect_executed.emit(effect_type, params)

			"GiveItem":
				var prototype_id: String = params.get("prototype_id", "")
				var instance = CardMgr.add_card(prototype_id)
				if instance:
					EventBus.publish("CardAcquired", {"prototype_id": prototype_id, "instance_id": instance.instance_id})
				effect_executed.emit(effect_type, params)

			"RemoveItem":
				var prototype_id: String = params.get("prototype_id", "")
				var all_cards = CardMgr.get_all_cards()
				for card in all_cards:
					if card.prototype_id == prototype_id:
						CardMgr.remove_card(card.instance_id)
						EventBus.publish("CardLost", {"prototype_id": prototype_id, "instance_id": card.instance_id})
						break
				effect_executed.emit(effect_type, params)

			"StartBattle":
				var enemy_id: String = params.get("enemy_id", "")
				EventBus.publish("BattleRequested", {"enemy_id": enemy_id})
				effect_executed.emit(effect_type, params)

			"TriggerDialogue":
				var node_id: String = params.get("node_id", "")
				if _current_tree["nodes"].has(node_id):
					_current_node_id = node_id
					_dialogue_history.append(node_id)
					_show_current_node()
				effect_executed.emit(effect_type, params)

			"KillNpc":
				var npc_id: String = params.get("npc_id", "")
				WorldState.set_flag("npc_dead_" + npc_id, true)
				effect_executed.emit(effect_type, params)

			"GiveGold":
				var amount: int = params.get("amount", 0)
				WorldState.set_flag("gold", WorldState.get_flag_int("gold", 0) + amount)
				effect_executed.emit(effect_type, params)

			"TakeGold":
				var amount: int = params.get("amount", 0)
				WorldState.set_flag("gold", max(0, WorldState.get_flag_int("gold", 0) - amount))
				effect_executed.emit(effect_type, params)

			_:
				push_warning("[NarrativeEngine] Unknown effect type: %s" % effect_type)

func _end_dialogue() -> void:
	var end_node_id = _current_node_id
	_current_node_id = ""
	dialogue_ended.emit(end_node_id)
	EventBus.publish("DialogueEnded", {"last_node": end_node_id, "history": _dialogue_history.duplicate()})

func is_active() -> bool:
	return not _current_node_id.is_empty()

func get_current_node_id() -> String:
	return _current_node_id

func get_dialogue_history() -> Array:
	return _dialogue_history.duplicate()

func jump_to_node(node_id: String) -> void:
	if _current_tree["nodes"].has(node_id):
		_current_node_id = node_id
		_dialogue_history.append(node_id)
		_show_current_node()
