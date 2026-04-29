## Represents an item instance in the player's inventory.
##
## Responsibility:
## - Track individual item state (instance ID, prototype, quantity)
## - Provide metadata storage for extended functionality
class_name ItemInstance
extends RefCounted

var _instance_id: String = ""
var _prototype_id: String = ""
var _quantity: int = 1
var _metadata: Dictionary = {}

func _init(
	p_instance_id: String = "",
	p_prototype_id: String = "",
	p_quantity: int = 1
) -> void:
	_instance_id = p_instance_id
	_prototype_id = p_prototype_id
	_quantity = maxi(1, p_quantity)

func get_instance_id() -> String:
	return _instance_id

func set_instance_id(value: String) -> void:
	if value.is_empty():
		push_error("ItemInstance: Instance ID cannot be empty")
		return
	_instance_id = value

func get_prototype_id() -> String:
	return _prototype_id

func set_prototype_id(value: String) -> void:
	if value.is_empty():
		push_error("ItemInstance: Prototype ID cannot be empty")
		return
	_prototype_id = value

func get_quantity() -> int:
	return _quantity

func set_quantity(value: int) -> void:
	_quantity = maxi(1, value)

func add_quantity(amount: int) -> void:
	_quantity += amount

func remove_quantity(amount: int) -> bool:
	if _quantity < amount:
		return false
	_quantity -= amount
	return true

func get_metadata(key: String, default = null):
	return _metadata.get(key, default)

func set_metadata(key: String, value) -> void:
	_metadata[key] = value

func has_metadata(key: String) -> bool:
	return _metadata.has(key)

func clear_metadata() -> void:
	_metadata.clear()

static func generate_id() -> String:
	return UUID.v4()

func to_dict() -> Dictionary:
	return {
		"instance_id": _instance_id,
		"prototype_id": _prototype_id,
		"quantity": _quantity,
		"metadata": _metadata.duplicate()
	}

static func from_dict(data: Dictionary) -> ItemInstance:
	var instance = ItemInstance.new(
		data.get("instance_id", UUID.v4()),
		data.get("prototype_id", ""),
		data.get("quantity", 1)
	)
	if data.has("metadata"):
		for key in data["metadata"]:
			instance.set_metadata(key, data["metadata"][key])
	return instance