## BodyManager - Manages player's body parts for heartbeat mechanic.
##
## Responsibility:
## - Track body parts state (present/absent)
## - Provide configuration for body parts
## - Support save/load
##
## Usage:
##   BodyMgr.has_part(BodyPart.MOUTH)
##   BodyMgr.remove_part(BodyPart.EYES)
##   BodyMgr.configure_parts([BodyPart.EYES, BodyPart.MOUTH, BodyPart.ARMS])
class_name BodyManager
extends Node

enum BodyPart {
	NONE  # 占位符，无意义
}

var _parts_config: Array[BodyPart] = []
var _current_parts: Array[BodyPart] = []

func _init():
	reset()

func reset() -> void:
	_current_parts.clear()
	_current_parts.assign(_parts_config.duplicate())

func configure_parts(all_parts: Array[BodyPart]) -> void:
	_parts_config.clear()
	_parts_config.assign(all_parts)
	reset()

func get_config() -> Dictionary:
	return {"parts": _parts_config, "count": _parts_config.size()}

func has_part(part: BodyPart) -> bool:
	return _current_parts.has(part)

func remove_part(part: BodyPart) -> bool:
	if not has_part(part):
		return false
	_current_parts.erase(part)
	return true

func add_part(part: BodyPart) -> void:
	if not _current_parts.has(part):
		_current_parts.append(part)

func get_parts() -> Array[BodyPart]:
	return _current_parts.duplicate()

func get_parts_count() -> int:
	return _current_parts.size()

func is_all_parts_lost() -> bool:
	return _current_parts.size() == 0

func get_save_data() -> Dictionary:
	var parts_strings: Array = []
	for part in _current_parts:
		parts_strings.append(str(part))
	return {
		"current_parts": parts_strings,
		"config_parts": _parts_config
	}

func load_save_data(data: Dictionary) -> void:
	_parts_config.clear()
	_current_parts.clear()
	if data.has("config_parts"):
		for p in data["config_parts"]:
			_parts_config.append(int(p))
	if data.has("current_parts"):
		for p in data["current_parts"]:
			_current_parts.append(int(p))