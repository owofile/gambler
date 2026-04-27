## SaveManager - Handles game persistence.
##
## Responsibility:
## - Save/load game state to JSON files
## - Coordinate with WorldState, CardMgr, and other contexts
## - Handle version migration
## - Provide auto-save functionality
##
## Save Data Structure:
## {
##   "version": 1,
##   "timestamp": 1234567890,
##   "current_zone": "res://scenes/World/zone_01.tscn",
##   "player_position": {"x": 100, "y": 200},
##   "world_state": { "flag1": value1, ... },
##   "card_instances": [ {"prototype_id": "xxx", "delta_value": 0, "bind_status": 0}, ... ]
## }
##
## Note: SaveManager is an Autoload singleton.
extends Node

const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves/"
const AUTO_SAVE_PATH: String = "user://saves/autosave.json"
const MAX_AUTO_SAVES: int = 3

var _save_path: String = ""
var _is_loading: bool = false

func _ready() -> void:
	print("[SaveManager] Initialized")
	_dir_init()

func _dir_init() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(path: String = "") -> bool:
	if _is_loading:
		push_error("[SaveManager] Cannot save while loading")
		return false

	_save_path = path if not path.is_empty() else AUTO_SAVE_PATH

	var save_data: Dictionary = _collect_save_data()
	var json_str: String = JSON.stringify(save_data, "\t")

	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to open file for writing: %s" % _save_path)
		return false

	file.store_string(json_str)
	file.close()

	print("[SaveManager] Game saved to: %s" % _save_path)
	EventBus.publish("GameSaved", {"path": _save_path, "timestamp": save_data.get("timestamp", 0)})
	return true

func load_game(path: String = "") -> bool:
	_save_path = path if not path.is_empty() else AUTO_SAVE_PATH

	if not FileAccess.file_exists(_save_path):
		push_error("[SaveManager] Save file not found: %s" % _save_path)
		return false

	_is_loading = true

	var file = FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Failed to open file for reading: %s" % _save_path)
		_is_loading = false
		return false

	var json_str: String = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[SaveManager] Failed to parse save file JSON")
		_is_loading = false
		return false

	var save_data: Dictionary = json.data
	if not save_data.has("version"):
		push_error("[SaveManager] Save file missing version")
		_is_loading = false
		return false

	var version: int = save_data["version"]
	if version != SAVE_VERSION:
		print("[SaveManager] Save version mismatch: %d vs %d" % [version, SAVE_VERSION])
		save_data = _migrate_save_data(save_data, version)

	_apply_save_data(save_data)

	_is_loading = false
	print("[SaveManager] Game loaded from: %s" % _save_path)
	EventBus.publish("GameLoaded", {"path": _save_path})
	return true

func _collect_save_data() -> Dictionary:
	var timestamp: int = Time.get_unix_time_from_system()

	var card_data: Array = []
	if CardMgr:
		var all_cards = CardMgr.get_all_cards()
		for card in all_cards:
			card_data.append({
				"prototype_id": card.prototype_id,
				"delta_value": card.delta_value,
				"bind_status": card.bind_status
			})

	var world_data: Dictionary = {}
	if WorldState:
		world_data = WorldState.get_save_data()

	return {
		"version": SAVE_VERSION,
		"timestamp": timestamp,
		"current_zone": _get_current_zone_path(),
		"player_position": _get_player_position(),
		"world_state": world_data.get("world_state", {}),
		"card_instances": card_data
	}

func _apply_save_data(data: Dictionary) -> void:
	if data.has("world_state") and WorldState:
		WorldState.load_save_data({"version": data.get("version", 1), "world_state": data["world_state"]})

	if data.has("card_instances") and CardMgr:
		CardMgr.clear_all_cards()
		for card_data in data["card_instances"]:
			var instance = CardMgr.add_card(card_data["prototype_id"])
			if instance and card_data.has("delta_value"):
				instance.delta_value = card_data.get("delta_value", 0)
			if instance and card_data.has("bind_status"):
				instance.bind_status = card_data.get("bind_status", 0)

	if data.has("current_zone"):
		_pending_zone = data["current_zone"]

	if data.has("player_position"):
		_pending_player_pos = data["player_position"]

var _pending_zone: String = ""
var _pending_player_pos: Dictionary = {}

func _get_current_zone_path() -> String:
	var root = get_tree().root
	if root and root.has_node("SampleWorld"):
		return root.get_node("SampleWorld").scene_file_path
	return ""

func _get_player_position() -> Dictionary:
	var player = _find_player()
	if player and player is Node2D:
		return {"x": player.global_position.x, "y": player.global_position.y}
	return {"x": 0, "y": 0}

func _find_player() -> Node:
	var root = get_tree().root
	if root.has_node("SampleWorld/Player"):
		return root.get_node("SampleWorld/Player")
	if root.has_node("Player"):
		return root.get_node("Player")
	return null

func _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
	match from_version:
		1:
			print("[SaveManager] No migration needed from v1")
		_:
			push_warning("[SaveManager] Unknown save version: %d" % from_version)
	return data

func delete_save(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var err = DirAccess.remove_absolute(path)
	if err != OK:
		push_error("[SaveManager] Failed to delete save: %s" % path)
		return false

	print("[SaveManager] Save deleted: %s" % path)
	return true

func list_saves() -> Array:
	var result: Array = []

	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return result

	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			result.append(SAVE_DIR + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	result.sort()
	return result

func has_save(path: String = "") -> bool:
	var check_path = path if not path.is_empty() else AUTO_SAVE_PATH
	return FileAccess.file_exists(check_path)

func get_last_save_info(path: String = "") -> Dictionary:
	var check_path = path if not path.is_empty() else AUTO_SAVE_PATH

	if not FileAccess.file_exists(check_path):
		return {}

	var file = FileAccess.open(check_path, FileAccess.READ)
	if file == null:
		return {}

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_str) != OK:
		return {}

	var data = json.data
	return {
		"timestamp": data.get("timestamp", 0),
		"version": data.get("version", 0),
		"current_zone": data.get("current_zone", ""),
		"card_count": data.get("card_instances", []).size() if data.has("card_instances") else 0
	}

func auto_save() -> bool:
	return save_game(AUTO_SAVE_PATH)

func get_auto_save_path() -> String:
	return AUTO_SAVE_PATH
