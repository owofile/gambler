class_name Logger
extends Node

var _log_file: FileAccess = null
var _log_path: String = ""

func _init():
	var project_path = ProjectSettings.globalize_path("res://").replace("\\", "/")
	var date_str = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var logs_dir = project_path + "logs"

	DirAccess.make_dir_recursive_absolute(logs_dir)
	_log_path = logs_dir + "/game_%s.log" % date_str
	_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log_file:
		_write("[Logger] Log started: %s" % date_str)
		_write("[Logger] Log path: %s" % _log_path)

func _write(msg: String) -> void:
	if _log_file:
		_log_file.store_line(msg)
		_log_file.flush()

func info(msg: String) -> void:
	var full_msg = "[INFO] %s" % msg
	print(full_msg)
	_write(full_msg)

func warn(msg: String) -> void:
	var full_msg = "[WARN] %s" % msg
	push_warning(full_msg)
	_write(full_msg)

func error(msg: String) -> void:
	var full_msg = "[ERROR] %s" % msg
	push_error(full_msg)
	_write(full_msg)

func debug(msg: String) -> void:
	var full_msg = "[DEBUG] %s" % msg
	print(full_msg)
	_write(full_msg)

func get_log_path() -> String:
	return _log_path

func _exit_tree():
	if _log_file:
		_log_file.close()
