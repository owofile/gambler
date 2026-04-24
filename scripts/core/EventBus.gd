extends Node

var _subscribers: Dictionary = {}

func _ready() -> void:
	print("[EventBus] Initialized")

func Subscribe(event_type: String, handler: Callable) -> void:
	if not _subscribers.has(event_type):
		_subscribers[event_type] = []
	if not _subscribers[event_type].has(handler):
		_subscribers[event_type].append(handler)
	print("[EventBus] Subscribed to: %s" % event_type)

func Unsubscribe(event_type: String, handler: Callable) -> void:
	if _subscribers.has(event_type):
		var handlers: Array = _subscribers[event_type]
		if handlers.has(handler):
			handlers.erase(handler)
			print("[EventBus] Unsubscribed from: %s" % event_type)

func Publish(event_type: String, payload: Variant) -> void:
	print("[EventBus] Publishing: %s" % event_type)
	if _subscribers.has(event_type):
		for handler in _subscribers[event_type]:
			if handler.is_valid():
				var bound: Callable = handler.bind(payload)
				bound.call()

func ClearAll() -> void:
	_subscribers.clear()
	print("[EventBus] All subscriptions cleared")