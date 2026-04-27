## QuestManager - Quest tracking and objective management.
##
## Responsibility:
## - Load quest definitions from JSON
## - Track quest progress
## - Evaluate objective completion
## - Trigger quest rewards and events
##
## Quest Definition Format:
## {
##   "quests": {
##     "quest_find_sword": {
##       "name": "Find the Rusty Sword",
##       "description": "The merchant mentioned a sword in the old ruins.",
##       "category": "main",
##       "objectives": [
##         {
##           "id": "obj_1",
##           "type": "ExploreZone",
##           "params": { "zone_id": "zone_ruins" },
##           "description": "Explore the Ancient Ruins"
##         },
##         {
##           "id": "obj_2",
##           "type": "DefeatEnemy",
##           "params": { "enemy_id": "shadow_assassin" },
##           "description": "Defeat the Shadow Assassin"
##         },
##         {
##           "id": "obj_3",
##           "type": "HasItem",
##           "params": { "prototype_id": "card_ancient_sword" },
##           "description": "Acquire the Ancient Sword"
##         }
##       ],
##       "rewards": [
##         { "type": "GiveItem", "params": { "prototype_id": "card_treasure_map" } },
##         { "type": "SetFlag", "params": { "flag": "quest_find_sword_complete", "value": true } }
##       ],
##       "next_quests": ["quest_treasure_hunt"]
##     }
##   }
## }
##
## Objective Types:
##   - ExploreZone(zone_id)       : Enter and stay in zone
##   - DefeatEnemy(enemy_id)      : Win battle against enemy
##   - HasItem(prototype_id)      : Have specific card in deck
##   - HasFlag(flag, value?)      : World flag is set
##   - TalkToNpc(npc_id)          : Dialogue with NPC completed
##   - Custom(condition, params)  : Custom condition check
##
## Note: QuestManager is an Autoload singleton.
extends Node

const DEFAULT_QUEST_CONFIG: String = "res://config/quests.json"

var _quest_definitions: Dictionary = {}
var _active_quests: Array = []
var _completed_quests: Array = []
var _quest_progress: Dictionary = {}

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String, progress: float)
signal quest_reward_claimed(quest_id: String)

func _ready() -> void:
	print("[QuestManager] Initialized")
	_setup_event_subscriptions()

func _setup_event_subscriptions() -> void:
	EventBus.subscribe("BattleEnded", _on_battle_ended)
	EventBus.subscribe("CardAcquired", _on_card_acquired)
	EventBus.subscribe("WorldFlagChanged", _on_flag_changed)
	EventBus.subscribe("DialogueEnded", _on_dialogue_ended)
	EventBus.subscribe("ZoneLoaded", _on_zone_loaded)

func load_quest_config(path: String = DEFAULT_QUEST_CONFIG) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("[QuestManager] Quest config not found: %s" % path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[QuestManager] Failed to open quest config: %s" % path)
		return false

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[QuestManager] Failed to parse quest config JSON")
		return false

	_quest_definitions = json.data.get("quests", {})
	print("[QuestManager] Loaded %d quest definitions" % _quest_definitions.size())
	return true

func get_quest_definition(quest_id: String) -> Dictionary:
	return _quest_definitions.get(quest_id, {})

func get_all_quest_ids() -> Array:
	return _quest_definitions.keys()

func start_quest(quest_id: String) -> bool:
	if not _quest_definitions.has(quest_id):
		push_error("[QuestManager] Unknown quest: %s" % quest_id)
		return false

	if is_quest_active(quest_id) or is_quest_completed(quest_id):
		print("[QuestManager] Quest already active or completed: %s" % quest_id)
		return false

	var quest_def = _quest_definitions[quest_id]
	var required_prev_quests = quest_def.get("previous_quests", [])
	for prev_quest in required_prev_quests:
		if not is_quest_completed(prev_quest):
			print("[QuestManager] Previous quest not completed: %s" % prev_quest)
			return false

	_active_quests.append(quest_id)
	_init_quest_progress(quest_id)

	print("[QuestManager] Quest started: %s" % quest_id)
	quest_started.emit(quest_id)
	EventBus.publish("QuestStarted", {"quest_id": quest_id})
	return true

func _init_quest_progress(quest_id: String) -> void:
	var quest_def = _quest_definitions[quest_id]
	var objectives = quest_def.get("objectives", [])

	_quest_progress[quest_id] = {
		"objectives": {},
		"completed_objectives": []
	}

	for obj in objectives:
		var obj_id = obj.get("id", "")
		_quest_progress[quest_id]["objectives"][obj_id] = {
			"progress": 0.0,
			"completed": false,
			"target": _get_objective_target(obj)
		}

func _get_objective_target(objective: Dictionary) -> float:
	var obj_type = objective.get("type", "")
	match obj_type:
		"ExploreZone":
			return 1.0
		"DefeatEnemy":
			return 1.0
		"HasItem":
			return 1.0
		"HasFlag":
			return 1.0
		"TalkToNpc":
			return 1.0
		"CollectItems":
			return float(objective.get("params", {}).get("count", 1))
		_:
			return 1.0

func is_quest_active(quest_id: String) -> bool:
	return _active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return _completed_quests.has(quest_id)

func get_active_quests() -> Array:
	return _active_quests.duplicate()

func get_completed_quests() -> Array:
	return _completed_quests.duplicate()

func get_quest_progress(quest_id: String) -> Dictionary:
	return _quest_progress.get(quest_id, {})

func _update_objective_progress(quest_id: String, objective_id: String, progress_delta: float) -> void:
	if not _quest_progress.has(quest_id):
		return
	if not _quest_progress[quest_id]["objectives"].has(objective_id):
		return

	var obj_data = _quest_progress[quest_id]["objectives"][objective_id]
	if obj_data["completed"]:
		return

	obj_data["progress"] += progress_delta
	var target = obj_data["target"]

	if obj_data["progress"] >= target:
		obj_data["progress"] = target
		obj_data["completed"] = true
		_quest_progress[quest_id]["completed_objectives"].append(objective_id)

	print("[QuestManager] Quest %s objective %s: %.1f/%.1f" % [quest_id, objective_id, obj_data["progress"], target])
	quest_objective_updated.emit(quest_id, objective_id, obj_data["progress"] / target)

	_check_quest_completion(quest_id)

func _check_quest_completion(quest_id: String) -> void:
	if not _quest_progress.has(quest_id):
		return

	var completed_objs = _quest_progress[quest_id]["completed_objectives"]
	var total_objs = _quest_progress[quest_id]["objectives"].size()

	if completed_objs.size() >= total_objs:
		_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	if is_quest_completed(quest_id):
		return

	_active_quests.erase(quest_id)
	_completed_quests.append(quest_id)

	print("[QuestManager] Quest completed: %s" % quest_id)
	quest_completed.emit(quest_id)
	EventBus.publish("QuestCompleted", {"quest_id": quest_id})

	_claim_rewards(quest_id)

	var quest_def = _quest_definitions[quest_id]
	var next_quests = quest_def.get("next_quests", [])
	for next_q in next_quests:
		start_quest(next_q)

func _claim_rewards(quest_id: String) -> void:
	var quest_def = _quest_definitions[quest_id]
	var rewards = quest_def.get("rewards", [])

	for reward in rewards:
		var reward_type = reward.get("type", "")
		var params = reward.get("params", {})

		match reward_type:
			"GiveItem":
				var prototype_id = params.get("prototype_id", "")
				if not prototype_id.is_empty():
					CardMgr.add_card(prototype_id)
					print("[QuestManager] Reward given: %s" % prototype_id)

			"SetFlag":
				var flag = params.get("flag", "")
				var value = params.get("value", true)
				if not flag.is_empty():
					WorldState.set_flag(flag, value)

			"GiveGold":
				var amount = params.get("amount", 0)
				WorldState.set_flag("gold", WorldState.get_flag_int("gold", 0) + amount)

	quest_reward_claimed.emit(quest_id)

func _on_battle_ended(payload: Dictionary) -> void:
	var report = payload.get("report", {})
	var result = report.get("result", "")

	if result == "Victory":
		var enemy_id = payload.get("enemy_id", "")
		for quest_id in _active_quests:
			var quest_def = _quest_definitions.get(quest_id, {})
			var objectives = quest_def.get("objectives", [])

			for obj in objectives:
				if obj.get("type") == "DefeatEnemy":
					var params = obj.get("params", {})
					if params.get("enemy_id") == enemy_id:
						_update_objective_progress(quest_id, obj.get("id"), 1.0)

func _on_card_acquired(payload: Dictionary) -> void:
	var prototype_id = payload.get("prototype_id", "")

	for quest_id in _active_quests:
		var quest_def = _quest_definitions.get(quest_id, {})
		var objectives = quest_def.get("objectives", [])

		for obj in objectives:
			if obj.get("type") == "HasItem":
				var params = obj.get("params", {})
				if params.get("prototype_id") == prototype_id:
					_update_objective_progress(quest_id, obj.get("id"), 1.0)

func _on_flag_changed(payload: Dictionary) -> void:
	var flag_name = payload.get("flag_name", "")

	for quest_id in _active_quests:
		var quest_def = _quest_definitions.get(quest_id, {})
		var objectives = quest_def.get("objectives", [])

		for obj in objectives:
			if obj.get("type") == "HasFlag":
				var params = obj.get("params", {})
				if params.get("flag") == flag_name:
					_update_objective_progress(quest_id, obj.get("id"), 1.0)

func _on_dialogue_ended(payload: Dictionary) -> void:
	var last_node = payload.get("last_node", "")

	for quest_id in _active_quests:
		var quest_def = _quest_definitions.get(quest_id, {})
		var objectives = quest_def.get("objectives", [])

		for obj in objectives:
			if obj.get("type") == "TalkToNpc":
				var params = obj.get("params", {})
				if params.get("node_id") == last_node or params.get("npc_id"):
					_update_objective_progress(quest_id, obj.get("id"), 1.0)

func _on_zone_loaded(payload: Dictionary) -> void:
	var zone_id = payload.get("zone_id", "")

	for quest_id in _active_quests:
		var quest_def = _quest_definitions.get(quest_id, {})
		var objectives = quest_def.get("objectives", [])

		for obj in objectives:
			if obj.get("type") == "ExploreZone":
				var params = obj.get("params", {})
				if params.get("zone_id") == zone_id:
					_update_objective_progress(quest_id, obj.get("id"), 1.0)

func get_quests_by_category(category: String) -> Array:
	var result: Array = []
	for quest_id in _quest_definitions.keys():
		var quest_def = _quest_definitions[quest_id]
		if quest_def.get("category") == category:
			result.append(quest_id)
	return result

func get_quest_status(quest_id: String) -> String:
	if is_quest_completed(quest_id):
		return "completed"
	if is_quest_active(quest_id):
		return "active"
	return "available"

func get_quest_info(quest_id: String) -> Dictionary:
	if not _quest_definitions.has(quest_id):
		return {}

	var quest_def = _quest_definitions[quest_id]
	var status = get_quest_status(quest_id)

	var info = {
		"id": quest_id,
		"name": quest_def.get("name", quest_id),
		"description": quest_def.get("description", ""),
		"category": quest_def.get("category", ""),
		"status": status,
		"objectives": []
	}

	if _quest_progress.has(quest_id):
		info["progress"] = _quest_progress[quest_id]

	return info

func get_save_data() -> Dictionary:
	return {
		"active_quests": _active_quests.duplicate(),
		"completed_quests": _completed_quests.duplicate(),
		"quest_progress": _quest_progress.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("active_quests"):
		_active_quests = data["active_quests"].duplicate()
	if data.has("completed_quests"):
		_completed_quests = data["completed_quests"].duplicate()
	if data.has("quest_progress"):
		_quest_progress = data["quest_progress"].duplicate(true)

func reset_all_quests() -> void:
	_active_quests.clear()
	_completed_quests.clear()
	_quest_progress.clear()
