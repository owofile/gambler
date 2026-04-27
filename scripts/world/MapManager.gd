## MapManager - Zone configuration and unlock management.
##
## Responsibility:
## - Load zone configurations from JSON
## - Track zone unlock state
## - Manage teleport points
## - Trigger zone transitions
##
## Zone Config Format:
## {
##   "zones": {
##     "zone_01": {
##       "name": "Starting Village",
##       "scene_path": "res://scenes/World/SampleWorld.tscn",
##       "unlock_flag": "zone_01_unlocked",
##       "required_flags": [],
##       "teleport_points": [
##         { "id": "tp_01", "position": {"x": 100, "y": 200}, "target_zone": "zone_02", "target_tp": "tp_02" }
##       ],
##       "connections": [
##         { "to_zone": "zone_02", "unlock_flag": "path_east_opened" }
##       ]
##     }
##   }
## }
##
## Note: MapManager is an Autoload singleton.
extends Node

const DEFAULT_ZONE_CONFIG: String = "res://config/zones.json"

var _zone_configs: Dictionary = {}
var _current_zone_id: String = ""
var _teleport_points: Dictionary = {}

signal zone_loaded(zone_id: String)
signal zone_changed(from_zone: String, to_zone: String)
signal zone_unlocked(zone_id: String)
signal teleport_requested(from_tp: String, to_zone: String, to_tp: String)

func _ready() -> void:
	print("[MapManager] Initialized")

func load_zone_config(path: String = DEFAULT_ZONE_CONFIG) -> bool:
	if not FileAccess.file_exists(path):
		push_error("[MapManager] Zone config not found: %s" % path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[MapManager] Failed to open zone config: %s" % path)
		return false

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[MapManager] Failed to parse zone config JSON")
		return false

	_zone_configs = json.data.get("zones", {})
	print("[MapManager] Loaded %d zone configurations" % _zone_configs.size())
	return true

func get_zone_config(zone_id: String) -> Dictionary:
	return _zone_configs.get(zone_id, {})

func get_all_zone_ids() -> Array:
	return _zone_configs.keys()

func is_zone_unlocked(zone_id: String) -> bool:
	var config = _zone_configs.get(zone_id, {})
	var unlock_flag = config.get("unlock_flag", "")
	if unlock_flag.is_empty():
		return true
	return WorldState.has_flag(unlock_flag) and WorldState.get_flag(unlock_flag, false)

func unlock_zone(zone_id: String) -> bool:
	if not _zone_configs.has(zone_id):
		push_error("[MapManager] Unknown zone: %s" % zone_id)
		return false

	var config = _zone_configs[zone_id]
	var unlock_flag = config.get("unlock_flag", "")
	if not unlock_flag.is_empty():
		WorldState.set_flag(unlock_flag, true)

	zone_unlocked.emit(zone_id)
	print("[MapManager] Zone unlocked: %s" % zone_id)
	return true

func can_access_zone(zone_id: String) -> bool:
	var config = _zone_configs.get(zone_id, {})
	var required_flags = config.get("required_flags", [])

	for req_flag in required_flags:
		if not WorldState.has_flag(req_flag):
			return false
		if WorldState.get_flag(req_flag, false) != true:
			return false

	return true

func get_zone_display_name(zone_id: String) -> String:
	var config = _zone_configs.get(zone_id, {})
	return config.get("name", zone_id)

func get_zone_scene_path(zone_id: String) -> String:
	var config = _zone_configs.get(zone_id, {})
	return config.get("scene_path", "")

func get_zone_teleport_points(zone_id: String) -> Array:
	var config = _zone_configs.get(zone_id, {})
	return config.get("teleport_points", [])

func register_teleport_point(tp_id: String, position: Vector2, target_zone: String, target_tp: String) -> void:
	_teleport_points[tp_id] = {
		"position": position,
		"target_zone": target_zone,
		"target_tp": target_tp
	}

func get_teleport_target(tp_id: String) -> Dictionary:
	return _teleport_points.get(tp_id, {})

func has_teleport_point(tp_id: String) -> bool:
	return _teleport_points.has(tp_id)

func set_current_zone(zone_id: String) -> void:
	var old_zone = _current_zone_id
	_current_zone_id = zone_id
	WorldState.set_flag("current_zone", zone_id)
	if not old_zone.is_empty() and old_zone != zone_id:
		zone_changed.emit(old_zone, zone_id)

func get_current_zone() -> String:
	return _current_zone_id

func load_zone(zone_id: String) -> bool:
	if not _zone_configs.has(zone_id):
		push_error("[MapManager] Zone not found: %s" % zone_id)
		return false

	if not is_zone_unlocked(zone_id):
		push_error("[MapManager] Zone is locked: %s" % zone_id)
		return false

	var scene_path = get_zone_scene_path(zone_id)
	if scene_path.is_empty():
		push_error("[MapManager] Zone has no scene path: %s" % zone_id)
		return false

	print("[MapManager] Loading zone: %s (%s)" % [zone_id, scene_path])

	if get_tree().change_scene_to_file(scene_path) != OK:
		push_error("[MapManager] Failed to change scene to: %s" % scene_path)
		return false

	set_current_zone(zone_id)
	zone_loaded.emit(zone_id)

	var teleport_points = get_zone_teleport_points(zone_id)
	_teleport_points.clear()
	for tp in teleport_points:
		var tp_id = tp.get("id", "")
		var pos = Vector2(tp.get("position", {}).get("x", 0), tp.get("position", {}).get("y", 0))
		var target_zone = tp.get("target_zone", "")
		var target_tp = tp.get("target_tp", "")
		if not tp_id.is_empty():
			register_teleport_point(tp_id, pos, target_zone, target_tp)

	return true

func teleport_to(tp_id: String) -> bool:
	if not _teleport_points.has(tp_id):
		push_warning("[MapManager] Unknown teleport point: %s" % tp_id)
		return false

	var tp_data = _teleport_points[tp_id]
	var target_zone = tp_data.get("target_zone", "")
	var target_tp = tp_data.get("target_tp", "")

	teleport_requested.emit(tp_id, target_zone, target_tp)

	if not target_zone.is_empty() and target_zone != _current_zone_id:
		return load_zone(target_zone)
	else:
		EventBus.publish("TeleportPlayer", {"tp_id": tp_id, "position": tp_data.get("position", Vector2.ZERO)})
		return true

func get_zone_connections(zone_id: String) -> Array:
	var config = _zone_configs.get(zone_id, {})
	return config.get("connections", [])

func is_connection_unlocked(zone_id: String, connection_index: int) -> bool:
	var connections = get_zone_connections(zone_id)
	if connection_index < 0 or connection_index >= connections.size():
		return false

	var connection = connections[connection_index]
	var unlock_flag = connection.get("unlock_flag", "")
	if unlock_flag.is_empty():
		return true

	return WorldState.has_flag(unlock_flag) and WorldState.get_flag(unlock_flag, false)

func unlock_connection(zone_id: String, connection_index: int) -> bool:
	var connections = get_zone_connections(zone_id)
	if connection_index < 0 or connection_index >= connections.size():
		push_error("[MapManager] Invalid connection index: %d" % connection_index)
		return false

	var connection = connections[connection_index]
	var unlock_flag = connection.get("unlock_flag", "")
	if not unlock_flag.is_empty():
		WorldState.set_flag(unlock_flag, true)
		print("[MapManager] Connection unlocked: %s -> %s" % [zone_id, connection.get("to_zone", "")])
	return true

func get_accessible_zones() -> Array:
	var accessible: Array = []
	for zone_id in _zone_configs.keys():
		if is_zone_unlocked(zone_id) and can_access_zone(zone_id):
			accessible.append(zone_id)
	return accessible

func get_save_data() -> Dictionary:
	return {
		"current_zone": _current_zone_id,
		"unlocked_zones": _get_unlocked_zone_ids(),
		"teleport_points": _teleport_points.duplicate(true)
	}

func _get_unlocked_zone_ids() -> Array:
	var unlocked: Array = []
	for zone_id in _zone_configs.keys():
		var config = _zone_configs[zone_id]
		var unlock_flag = config.get("unlock_flag", "")
		if not unlock_flag.is_empty() and WorldState.get_flag(unlock_flag, false):
			unlocked.append(zone_id)
	return unlocked

func load_save_data(data: Dictionary) -> void:
	if data.has("current_zone"):
		_current_zone_id = data["current_zone"]

	if data.has("teleport_points"):
		_teleport_points = data["teleport_points"].duplicate(true)

	if data.has("unlocked_zones"):
		for zone_id in data["unlocked_zones"]:
			var config = _zone_configs.get(zone_id, {})
			var unlock_flag = config.get("unlock_flag", "")
			if not unlock_flag.is_empty():
				WorldState.set_flag(unlock_flag, true)
