## HeartbeatManager - Manages heartbeat timer for pain mechanic.
##
## Responsibility:
## - Track heartbeat timer state
## - Trigger pain events periodically
## - Support save/load
##
## Usage:
##   Heartbeat.configure(30.0)
##   Heartbeat.start()
##   Heartbeat.pause()
##   Heartbeat.trigger()  # Manual trigger for testing
class_name HeartTimerManager
extends Node

signal heartbeat_triggered
signal heartbeat_state_changed(is_running: bool)

enum Choice {
	NONE  # 占位符
}

var _interval: float = 60.0
var _is_running: bool = false
var _elapsed: float = 0.0
var _timer: Timer = null

func _ready() -> void:
	_create_timer()

func _create_timer() -> void:
	if _timer:
		_timer.timeout.disconnect(_on_timer_timeout)
		_timer.queue_free()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

func _process(delta: float) -> void:
	if not _is_running:
		return
	_elapsed += delta
	if _elapsed >= _interval:
		_trigger_heartbeat()

func _on_timer_timeout() -> void:
	if _is_running:
		_trigger_heartbeat()

func _trigger_heartbeat() -> void:
	_elapsed = 0.0
	heartbeat_triggered.emit()
	heartbeat_state_changed.emit(_is_running)

func configure(interval: float) -> void:
	_interval = maxi(1.0, interval)
	print("[Heartbeat] Interval configured: %f seconds" % _interval)

func get_interval() -> float:
	return _interval

func start() -> void:
	if _is_running:
		return
	_is_running = true
	_elapsed = 0.0
	print("[Heartbeat] Started with interval: %f seconds" % _interval)
	heartbeat_state_changed.emit(_is_running)

func pause() -> void:
	if not _is_running:
		return
	_is_running = false
	_elapsed = 0.0
	print("[Heartbeat] Paused")
	heartbeat_state_changed.emit(_is_running)

func toggle() -> void:
	if _is_running:
		pause()
	else:
		start()

func trigger() -> void:
	_trigger_heartbeat()

func is_running() -> bool:
	return _is_running

func get_state() -> Dictionary:
	return {
		"interval": _interval,
		"is_running": _is_running,
		"elapsed": _elapsed
	}

func get_save_data() -> Dictionary:
	return {
		"interval": _interval,
		"is_running": _is_running,
		"elapsed": _elapsed
	}

func load_save_data(data: Dictionary) -> void:
	_interval = data.get("interval", 60.0)
	_is_running = data.get("is_running", false)
	_elapsed = data.get("elapsed", 0.0)
	print("[Heartbeat] Loaded state: interval=%f, running=%s" % [_interval, _is_running])
	heartbeat_state_changed.emit(_is_running)