class_name CardSelector
extends Node

const MAX_SELECTION := 3
const MIN_SELECTION := 1

signal selection_changed(selected_ids: Array[String])
signal selection_confirmed(selected_ids: Array[String])

var _available_cards: Array[CardInstance] = []
var _selected_ids: Array[String] = []
var _disabled_ids: Array[String] = []
var _locked: bool = false

func _get_event_bus():
	return get_node("/root/EventBus")

func set_available_cards(cards: Array[CardInstance]) -> void:
	_available_cards = cards.duplicate()
	_selected_ids.clear()
	_notify_selection_changed()

func set_disabled_cards(disabled_ids: Array[String]) -> void:
	_disabled_ids = disabled_ids.duplicate()
	_notify_selection_changed()

func set_locked(locked: bool) -> void:
	_locked = locked

func is_card_disabled(instance_id: String) -> bool:
	return _disabled_ids.has(instance_id)

func select_card(instance_id: String) -> bool:
	if _locked:
		print("[CardSelector] Card selection is locked")
		return false

	if is_card_disabled(instance_id):
		print("[CardSelector] Card %s is disabled" % instance_id)
		return false

	if not _is_card_available(instance_id):
		print("[CardSelector] Card %s not available" % instance_id)
		return false

	if _selected_ids.has(instance_id):
		print("[CardSelector] Card %s already selected" % instance_id)
		return false

	if _selected_ids.size() >= MAX_SELECTION:
		print("[CardSelector] Max selection reached (%d)" % MAX_SELECTION)
		return false

	_selected_ids.append(instance_id)
	_notify_selection_changed()
	return true

func deselect_card(instance_id: String) -> bool:
	if not _selected_ids.has(instance_id):
		return false

	_selected_ids.erase(instance_id)
	_notify_selection_changed()
	return true

func toggle_card(instance_id: String) -> bool:
	if _selected_ids.has(instance_id):
		return deselect_card(instance_id)
	else:
		return select_card(instance_id)

func get_selected_ids() -> Array[String]:
	return _selected_ids.duplicate()

func get_selected_count() -> int:
	return _selected_ids.size()

func can_confirm() -> bool:
	return _selected_ids.size() >= MIN_SELECTION and _selected_ids.size() <= MAX_SELECTION

func confirm() -> void:
	if not can_confirm():
		print("[CardSelector] Cannot confirm: selection count %d" % _selected_ids.size())
		return

	_notify_selection_confirmed()

func clear() -> void:
	_selected_ids.clear()
	_notify_selection_changed()

func _is_card_available(instance_id: String) -> bool:
	for card in _available_cards:
		if card.instance_id == instance_id:
			return true
	return false

func _notify_selection_changed() -> void:
	selection_changed.emit(_selected_ids.duplicate())

	var payload = {"selected_ids": _selected_ids.duplicate()}
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.Publish("CardSel_Changed", payload)

func _notify_selection_confirmed() -> void:
	selection_confirmed.emit(_selected_ids.duplicate())

	var payload = {"selected_ids": _selected_ids.duplicate()}
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.Publish("CardSel_Confirmed", payload)