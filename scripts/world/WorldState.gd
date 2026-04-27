## WorldState - Key-value state management for the World Context.
##
## Responsibility:
## - Store all game progress as key-value pairs
## - Support flag-based storytelling (NPC alive/dead, quest progress, etc.)
## - Provide snapshot for save/load
## - Publish WorldFlagChanged events for other contexts
##
## Usage:
##   WorldState.set_flag("npc_merchant_dead", true)
##   WorldState.set_flag("quest_main_progress", 3)
##   if WorldState.get_flag("npc_merchant_dead", false):
##       ...
##
## Note: WorldState is an Autoload singleton.
extends Node

const SAVE_VERSION: int = 1

var _flags: Dictionary = {}

func _ready() -> void:
	print("[WorldState] Initialized")

func _init() -> void:
	_flags = {}

func set_flag(key: String, value: Variant) -> void:
	if key.is_empty():
		push_error("[WorldState] Cannot set empty flag key")
		return

	var old_value: Variant = _flags.get(key)
	_flags[key] = value

	print("[WorldState] Flag changed: %s = %s (was: %s)" % [key, str(value), str(old_value)])
	EventBus.publish("WorldFlagChanged", {
		"flag_name": key,
		"new_value": value,
		"old_value": old_value
	})

func get_flag(key: String, default: Variant = null) -> Variant:
	return _flags.get(key, default)

func has_flag(key: String) -> bool:
	return _flags.has(key)

func remove_flag(key: String) -> void:
	if _flags.has(key):
		_flags.erase(key)
		EventBus.publish("WorldFlagChanged", {
			"flag_name": key,
			"new_value": null,
			"old_value": null
		})

func get_all_flags() -> Dictionary:
	return _flags.duplicate(true)

func clear_all_flags() -> void:
	_flags.clear()

func set_flags_from_dict(data: Dictionary) -> void:
	_flags = data.duplicate(true)

func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"world_state": _flags.duplicate(true)
	}

func load_save_data(data: Dictionary) -> bool:
	if not data.has("version"):
		push_error("[WorldState] Save data missing version")
		return false

	if not data.has("world_state"):
		push_error("[WorldState] Save data missing world_state")
		return false

	var version: int = data["version"]
	if version != SAVE_VERSION:
		print("[WorldState] Save version mismatch: %d vs %d, attempting migration" % [version, SAVE_VERSION])
		_migrate_data(data, version)
		return true

	_flags = data["world_state"].duplicate(true)
	print("[WorldState] Loaded %d flags" % _flags.size())
	return true

func _migrate_data(data: Dictionary, from_version: int) -> void:
	match from_version:
		1:
			print("[WorldState] Migration from v1 not needed")
		_:
			push_warning("[WorldState] Unknown save version: %d" % from_version)

func has_flag_prefix(prefix: String) -> Array:
	var result: Array = []
	for key in _flags.keys():
		if key.begins_with(prefix):
			result.append(key)
	return result

func get_flag_int(key: String, default: int = 0) -> int:
	var val = get_flag(key, default)
	if val is int:
		return val
	return default

func get_flag_bool(key: String, default: bool = false) -> bool:
	var val = get_flag(key, default)
	if val is bool:
		return val
	return default

func get_flag_string(key: String, default: String = "") -> String:
	var val = get_flag(key, default)
	if val is String:
		return val
	return default
