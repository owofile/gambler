## Manages cross-turn state (buffs, debuffs, delayed effects).
##
## Responsibility:
## - Store temporary states that persist across rounds
## - Apply/remove buffs at round boundaries
## - Auto-expire effects after duration
##
## Usage:
##   var state = CrossTurnState.new()
##   state.add_buff("damage_up", 2, 3)  # +2 damage for 3 rounds
##   state.process_round_start()
class_name CrossTurnState
extends RefCounted

## Buff/debuff entry
class BuffEntry:
	var buff_id: String
	var value: int
	var remaining_rounds: int

	func _init(p_id: String, p_value: int, p_rounds: int) -> void:
		buff_id = p_id
		value = p_value
		remaining_rounds = p_rounds

	func is_expired() -> bool:
		return remaining_rounds <= 0

## All active buffs/debuffs
var _buffs: Dictionary = {}

## Add a buff/debuff
func add_buff(buff_id: String, value: int, duration_rounds: int) -> void:
	if _buffs.has(buff_id):
		var existing: BuffEntry = _buffs[buff_id]
		existing.value += value
		existing.remaining_rounds = maxi(existing.remaining_rounds, duration_rounds)
		print("[CrossTurnState] Buff %s updated: value=%d, rounds=%d" % [buff_id, existing.value, existing.remaining_rounds])
	else:
		var entry := BuffEntry.new(buff_id, value, duration_rounds)
		_buffs[buff_id] = entry
		print("[CrossTurnState] Buff %s added: value=%d, rounds=%d" % [buff_id, value, duration_rounds])

## Remove a buff
func remove_buff(buff_id: String) -> void:
	if _buffs.has(buff_id):
		_buffs.erase(buff_id)
		print("[CrossTurnState] Buff %s removed" % buff_id)

## Get buff value (returns 0 if not found)
func get_buff_value(buff_id: String) -> int:
	if not _buffs.has(buff_id):
		return 0
	var entry: BuffEntry = _buffs[buff_id]
	return entry.value

## Check if buff exists
func has_buff(buff_id: String) -> bool:
	return _buffs.has(buff_id)

## Get all active buff IDs
func get_active_buff_ids() -> Array:
	var result: Array = []
	for buff_id in _buffs.keys():
		result.append(buff_id)
	return result

## Process round start: decrement durations and remove expired
func process_round_start() -> Array:
	var expired: Array = []
	var still_active: Array = []

	for buff_id in _buffs.keys():
		var entry: BuffEntry = _buffs[buff_id]
		entry.remaining_rounds -= 1

		if entry.is_expired():
			expired.append(buff_id)
		else:
			still_active.append(buff_id)

	for buff_id in expired:
		_buffs.erase(buff_id)
		print("[CrossTurnState] Buff %s expired" % buff_id)

	if expired.size() > 0:
		print("[CrossTurnState] Round start: %d buffs expired, %d remain" % [expired.size(), still_active.size()])

	return expired

## Clear all buffs (battle end)
func clear_all() -> void:
	var count = _buffs.size()
	_buffs.clear()
	print("[CrossTurnState] Cleared all buffs (%d removed)" % count)

## Get all buffs as dictionary (for debugging)
func get_all_buffs_debug() -> Dictionary:
	var result: Dictionary = {}
	for buff_id in _buffs.keys():
		var entry: BuffEntry = _buffs[buff_id]
		result[buff_id] = {"value": entry.value, "rounds": entry.remaining_rounds}
	return result
