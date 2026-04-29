## Manages item prototype registry.
##
## Responsibility:
## - Register and retrieve item prototypes
## - Provide prototype validation
class_name ItemPrototypeRegistry
extends RefCounted

var _prototypes: Dictionary = {}

func register_item(data: ItemData) -> void:
	if data.prototype_id.is_empty():
		push_error("ItemPrototypeRegistry: Cannot register item with empty ID")
		return
	_prototypes[data.prototype_id] = data
	print("[ItemPrototypeRegistry] Registered item: %s" % data.prototype_id)

func get_prototype(prototype_id: String) -> ItemData:
	if _prototypes.has(prototype_id):
		return _prototypes[prototype_id]
	push_warning("[ItemPrototypeRegistry] Prototype not found: %s" % prototype_id)
	return null

func has_prototype(prototype_id: String) -> bool:
	return _prototypes.has(prototype_id)

func unregister_item(prototype_id: String) -> void:
	if _prototypes.has(prototype_id):
		_prototypes.erase(prototype_id)
		print("[ItemPrototypeRegistry] Unregistered item: %s" % prototype_id)

func get_all_prototypes() -> Array:
	var result: Array = []
	result.assign(_prototypes.values())
	return result

func get_prototype_ids() -> Array:
	var result: Array = []
	result.assign(_prototypes.keys())
	return result

func clear() -> void:
	_prototypes.clear()
	print("[ItemPrototypeRegistry] Cleared all prototypes")

func get_count() -> int:
	return _prototypes.size()