## Manages card selection for battles.
##
## Responsibility:
## - Track available and selected cards
## - Enforce selection constraints (min/max)
## - Emit signals on selection changes
class_name CardSelector
extends Node

const MAX_SELECTION := 3
const MIN_SELECTION := 1

signal selection_changed(selected_ids: Array[String])
signal selection_confirmed(selected_ids: Array[String])

var _available_cards: Array = []
var _selected_ids: Array[String] = []
var _disabled_ids: Array[String] = []
var _locked: bool = false
var _event_bus: Node = null

func _ready() -> void:
	_event_bus = get_node_or_null("/root/EventBus")

## Sets the available cards for selection.
##
## Params:
##   cards: Array - Cards that can be selected
func set_available_cards(cards: Array) -> void:
	_available_cards = Array(cards.duplicate())
	_selected_ids.clear()
	_notify_selection_changed()

## Sets cards that cannot be selected.
##
## Params:
##   disabled_ids: Array - Instance IDs to disable
func set_disabled_cards(disabled_ids: Array) -> void:
	_disabled_ids = disabled_ids.duplicate()
	_notify_selection_changed()

## Locks the selector, preventing selection changes.
##
## Params:
##   locked: bool - Whether to lock
func set_locked(locked: bool) -> void:
	_locked = locked

## Checks if a card is disabled.
##
## Params:
##   instance_id: String - The card instance ID
##
## Returns:
##   bool - true if disabled
func is_card_disabled(instance_id: String) -> bool:
	return _disabled_ids.has(instance_id)

## Selects a card.
##
## Params:
##   instance_id: String - The card instance ID to select
##
## Returns:
##   bool - true if selection succeeded
func select_card(instance_id: String) -> bool:
	if _locked:
		push_warning("CardSelector: Selection is locked")
		return false

	if is_card_disabled(instance_id):
		push_warning("CardSelector: Card %s is disabled" % instance_id)
		return false

	if not _is_card_available(instance_id):
		push_warning("CardSelector: Card %s not available" % instance_id)
		return false

	if _selected_ids.has(instance_id):
		push_warning("CardSelector: Card %s already selected" % instance_id)
		return false

	if _selected_ids.size() >= MAX_SELECTION:
		push_warning("CardSelector: Max selection reached (%d)" % MAX_SELECTION)
		return false

	_selected_ids.append(instance_id)
	_notify_selection_changed()
	return true

## Deselects a card.
##
## Params:
##   instance_id: String - The card instance ID to deselect
##
## Returns:
##   bool - true if deselection succeeded
func deselect_card(instance_id: String) -> bool:
	if not _selected_ids.has(instance_id):
		return false

	_selected_ids.erase(instance_id)
	_notify_selection_changed()
	return true

## Toggles card selection.
##
## Params:
##   instance_id: String - The card instance ID to toggle
##
## Returns:
##   bool - true if selection state changed
func toggle_card(instance_id: String) -> bool:
	if _selected_ids.has(instance_id):
		return deselect_card(instance_id)
	else:
		return select_card(instance_id)

## Gets the currently selected card IDs.
##
## Returns:
##   Array[String] - Copy of selected IDs
func get_selected_ids() -> Array[String]:
	return _selected_ids.duplicate()

## Gets the number of selected cards.
##
## Returns:
##   int - Selection count
func get_selected_count() -> int:
	return _selected_ids.size()

## Checks if selection can be confirmed.
##
## Returns:
##   bool - true if valid selection exists
func can_confirm() -> bool:
	return _selected_ids.size() >= MIN_SELECTION and _selected_ids.size() <= MAX_SELECTION

## Confirms the current selection.
func confirm() -> void:
	if not can_confirm():
		push_warning("CardSelector: Cannot confirm - selection count %d" % _selected_ids.size())
		return

	_notify_selection_confirmed()

## Clears all selections.
func clear() -> void:
	_selected_ids.clear()
	_notify_selection_changed()

func _is_card_available(instance_id: String) -> bool:
	for c in _available_cards:
		var card: CardInstance = c as CardInstance
		if card and card.get_card_id() == instance_id:
			return true
	return false

func _notify_selection_changed() -> void:
	selection_changed.emit(_selected_ids.duplicate())

	if _event_bus:
		var payload = {"selected_ids": _selected_ids.duplicate()}
		_event_bus.publish("CardSel_Changed", payload)

func _notify_selection_confirmed() -> void:
	selection_confirmed.emit(_selected_ids.duplicate())

	if _event_bus:
		var payload = {"selected_ids": _selected_ids.duplicate()}
		_event_bus.publish("CardSel_Confirmed", payload)
