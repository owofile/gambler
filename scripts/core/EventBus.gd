## Global event publishing and subscription system.
##
## Responsibility:
## - Enable decoupled communication between modules
## - Support event idempotency (processed event tracking)
## - Support command+ack pattern for reliable delivery
##
## Usage:
##   EventBus.subscribe("battle_ended", _on_battle_ended)
##   EventBus.publish("battle_ended", payload)
##
##   # With ack support:
##   EventBus.publish_with_ack("BattleEnded", payload)
##   EventBus.subscribe_with_ack("BattleEnded", _on_battle_ended)  # handler must call EventBus.ack(event_id)
##
## Note: EventBus is an Autoload singleton.
extends Node

var _subscribers: Dictionary = {}
var _ack_subscribers: Dictionary = {}
var _processed_event_ids: Array = []
var _pending_acks: Dictionary = {}
var _ack_results: Dictionary = {}

const MAX_PROCESSED_EVENTS: int = 1000
const DEFAULT_ACK_TIMEOUT_MS: int = 5000

func _ready() -> void:
	print("[EventBus] Initialized")

func _generate_event_id() -> String:
	var uuid: String = ""
	var hex: String = "0123456789abcdef"
	for i in range(32):
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid += "-"
		uuid += hex[randi() % 16]
	return uuid

func _is_event_processed(event_id: String) -> bool:
	return _processed_event_ids.has(event_id)

func _mark_event_processed(event_id: String) -> void:
	_processed_event_ids.append(event_id)
	if _processed_event_ids.size() > MAX_PROCESSED_EVENTS:
		_processed_event_ids.pop_front()

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

## Subscribes a handler that must acknowledge event receipt.
## The handler MUST call EventBus.ack(event_id) when processing is complete.
##
## Params:
##   event_type: String - The event to subscribe to
##   handler: Callable - Function that receives payload with event_id, must call ack()
func subscribe_with_ack(event_type: String, handler: Callable) -> void:
	subscribe(event_type, handler)
	if not _ack_subscribers.has(event_type):
		_ack_subscribers[event_type] = []
	if not _ack_subscribers[event_type].has(handler):
		_ack_subscribers[event_type].append(handler)

## Acknowledges that an event has been processed.
## Call this from handlers subscribed with subscribe_with_ack.
##
## Params:
##   event_id: String - The event ID from the payload
func ack(event_id: String) -> void:
	if _pending_acks.has(event_id):
		_pending_acks[event_id].append(true)
		if _ack_results.has(event_id):
			_ack_results[event_id] = true

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

	if _ack_subscribers.has(event_type):
		var ack_handlers: Array = _ack_subscribers[event_type]
		if ack_handlers.has(handler):
			ack_handlers.erase(handler)

## Publishes an event to all subscribers.
## If payload contains "event_id", idempotency check is performed.
##
## Params:
##   event_type: String - The event to publish
##   payload: Variant - Data to pass to handlers
func publish(event_type: String, payload: Variant) -> void:
	if event_type.is_empty():
		push_error("EventBus: Cannot publish empty event type")
		return

	var event_id: String = ""
	if payload is Dictionary and payload.has("event_id"):
		event_id = payload["event_id"]
		if _is_event_processed(event_id):
			print("[EventBus] Skipping duplicate event: ", event_id)
			return

	if not _subscribers.has(event_type):
		return

	for handler in _subscribers[event_type]:
		if handler.is_valid():
			var bound: Callable = handler.bind(payload)
			bound.call()
		else:
			push_warning("EventBus: Skipping invalid handler for event: %s" % event_type)

	if event_id:
		_mark_event_processed(event_id)

## Publishes an event and waits for all ack handlers to acknowledge.
## Returns true if all acks received within timeout, false otherwise.
##
## Params:
##   event_type: String - The event to publish
##   payload: Variant - Data to pass to handlers
##   timeout_ms: int - Milliseconds to wait for acks (default 5000)
##
## Returns:
##   bool - true if all acks received, false if timeout
func publish_with_ack(event_type: String, payload: Variant, timeout_ms: int = DEFAULT_ACK_TIMEOUT_MS) -> bool:
	var event_id: String = _generate_event_id()
	var enhanced_payload: Dictionary = {
		"event_id": event_id,
		"event_type": event_type,
		"data": payload,
		"timestamp": Time.get_unix_time_from_system()
	}

	_pending_acks[event_id] = []
	_ack_results[event_id] = false

	if _ack_subscribers.has(event_type):
		for handler in _ack_subscribers[event_type]:
			if handler.is_valid():
				var bound: Callable = handler.bind(enhanced_payload)
				bound.call()

	publish(event_type, enhanced_payload)

	var waited_ms: int = 0
	var poll_interval: int = 50
	while waited_ms < timeout_ms:
		OS.delay_msec(poll_interval)
		waited_ms += poll_interval
		if _ack_results.get(event_id, false):
			_cleanup_ack(event_id)
			return true

	print("[EventBus] Ack timeout for event: ", event_id)
	_cleanup_ack(event_id)
	return false

func _cleanup_ack(event_id: String) -> void:
	_pending_acks.erase(event_id)
	_ack_results.erase(event_id)

## Clears all subscriptions.
func clear_all() -> void:
	_subscribers.clear()
	_ack_subscribers.clear()
	_processed_event_ids.clear()
	_pending_acks.clear()
	_ack_results.clear()

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
