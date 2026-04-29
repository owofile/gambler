## Manages item instances in the player's inventory.
##
## Responsibility:
## - Add/remove items from inventory
## - Query inventory state
## - Provide save/load integration
class_name InventorySystem
extends Node

const MAX_SIZE: int = 99

var _items: Array[ItemInstance] = []
var _data_manager: Node = null

func _ready() -> void:
	_data_manager = get_node_or_null("/root/DataManager")

func add_item(prototype_id: String, quantity: int = 1) -> ItemInstance:
	if _items.size() >= MAX_SIZE:
		push_warning("InventorySystem: AddItem failed - inventory is full (max %d)" % MAX_SIZE)
		return null

	var existing = _find_by_prototype(prototype_id)
	if existing:
		var prototype = _get_prototype(prototype_id)
		var max_stack = prototype.max_stack if prototype else 99
		var can_add = mini(quantity, max_stack - existing.get_quantity())
		if can_add > 0:
			existing.add_quantity(can_add)
			print("[InventorySystem] Added %d to existing stack: %s (now %d)" % [can_add, prototype_id, existing.get_quantity()])
			return existing
		else:
			push_warning("InventorySystem: AddItem failed - stack is full for %s" % prototype_id)
			return null

	var instance = _create_item_instance(prototype_id, quantity)
	_items.append(instance)
	print("[InventorySystem] Added new item: %s (qty: %d)" % [prototype_id, quantity])
	return instance

func remove_item(instance_id: String, quantity: int = 1) -> bool:
	for i in range(_items.size()):
		if _items[i].get_id() == instance_id:
			if quantity <= 0:
				_items.remove_at(i)
				print("[InventorySystem] Removed item: %s" % instance_id)
				return true
			var success = _items[i].remove_quantity(quantity)
			if success:
				if _items[i].get_quantity() <= 0:
					_items.remove_at(i)
					print("[InventorySystem] Removed item (all): %s" % instance_id)
				else:
					print("[InventorySystem] Reduced item: %s (now %d)" % [instance_id, _items[i].get_quantity()])
				return true
			return false
	push_warning("InventorySystem: RemoveItem failed - instance %s not found" % instance_id)
	return false

func remove_item_by_prototype(prototype_id: String, quantity: int = 1) -> bool:
	var instance = _find_by_prototype(prototype_id)
	if not instance:
		push_warning("InventorySystem: RemoveItemByPrototype failed - no item with prototype %s" % prototype_id)
		return false
	return remove_item(instance.get_id(), quantity)

func has_item(prototype_id: String) -> bool:
	return _find_by_prototype(prototype_id) != null

func get_item_count(prototype_id: String) -> int:
	var item = _find_by_prototype(prototype_id)
	return item.get_quantity() if item else 0

func get_item(instance_id: String) -> ItemInstance:
	for item in _items:
		if item.get_id() == instance_id:
			return item
	return null

func get_all_items() -> Array[ItemInstance]:
	return _items.duplicate()

func get_inventory_size() -> int:
	return _items.size()

func is_full() -> bool:
	return _items.size() >= MAX_SIZE

func clear_all_items() -> void:
	_items.clear()
	print("[InventorySystem] Inventory cleared")

func _find_by_prototype(prototype_id: String) -> ItemInstance:
	for item in _items:
		if item.get_prototype_id() == prototype_id:
			return item
	return null

func _get_prototype(prototype_id: String) -> ItemData:
	if _data_manager == null:
		return null
	var registry = _data_manager.item_registry
	if registry == null:
		return null
	return registry.get_prototype(prototype_id)

func _create_item_instance(prototype_id: String, quantity: int = 1) -> ItemInstance:
	return ItemInstance.new(
		ItemInstance.generate_id(),
		prototype_id,
		quantity
	)

func get_save_data() -> Dictionary:
	var item_list: Array = []
	for item in _items:
		item_list.append(item.to_dict())
	return {
		"items": item_list,
		"version": 1
	}

func load_save_data(data: Dictionary) -> void:
	_items.clear()
	if not data.has("items"):
		print("[InventorySystem] No items to load")
		return

	for item_data in data["items"]:
		var item = ItemInstance.from_dict(item_data)
		_items.append(item)

	print("[InventorySystem] Loaded %d items" % _items.size())

func _get_item_prototype_data(prototype_id: String) -> Dictionary:
	var prototype = _get_prototype(prototype_id)
	if prototype:
		return prototype.to_dict()
	return {}