## Global event publishing and subscription system.
##
## Responsibility:
## - Enable decoupled communication between modules
## - Manage event subscriptions
##
## Usage:
##   EventBus.subscribe("battle_ended", _on_battle_ended)
##   EventBus.publish("battle_ended", payload)
##
## Note: EventBus is an Autoload singleton.
extends Node

var _subscribers: Dictionary = {}

func _ready() -> void:
	print("[EventBus] Initialized")

## Subscribes a handler to an event.
##
## Params:
##   event_type: String - The event to subscribe to
##   handler: Callable - The function to call when event fires
func subscribe(event_type: String, handler: Callable) -> void:
	if event_type.is_empty():
		push_error("EventBus: Cannot subscribe to empty event type")
		return
	if not handler.is_valid():
		push_error("EventBus: Cannot subscribe with invalid handler")
		return

	if not _subscribers.has(event_type):
		_subscribers[event_type] = []

	if not _subscribers[event_type].has(handler):
		_subscribers[event_type].append(handler)

## Unsubscribes a handler from an event.
##
## Params:
##   event_type: String - The event to unsubscribe from
##   handler: Callable - The handler to remove
func unsubscribe(event_type: String, handler: Callable) -> void:
	if not _subscribers.has(event_type):
		return

	var handlers: Array = _subscribers[event_type]
	if handlers.has(handler):
		handlers.erase(handler)

	if handlers.is_empty():
		_subscribers.erase(event_type)

## Publishes an event to all subscribers.
##
## Params:
##   event_type: String - The event to publish
##   payload: Variant - Data to pass to handlers
func publish(event_type: String, payload: Variant) -> void:
	if event_type.is_empty():
		push_error("EventBus: Cannot publish empty event type")
		return

	if not _subscribers.has(event_type):
		return

	for handler in _subscribers[event_type]:
		if handler.is_valid():
			var bound: Callable = handler.bind(payload)
			bound.call()
		else:
			push_warning("EventBus: Skipping invalid handler for event: %s" % event_type)

## Clears all subscriptions.
func clear_all() -> void:
	_subscribers.clear()

## Gets the number of subscribers for an event.
##
## Params:
##   event_type: String - The event to check
##
## Returns:
##   int - Number of subscribers
func get_subscriber_count(event_type: String) -> int:
	if _subscribers.has(event_type):
		return _subscribers[event_type].size()
	return 0
