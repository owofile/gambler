## Item prototype definition
class_name ItemData
extends RefCounted

var prototype_id: String = ""
var display_name: String = ""
var description: String = ""
var item_type: ItemType.Type = ItemType.Type.None
var max_stack: int = 99
var icon_path: String = ""
var is_droppable: bool = true
var is_discardable: bool = true

func _init(
	p_id: String = "",
	p_name: String = "",
	p_desc: String = "",
	p_type: ItemType.Type = ItemType.Type.None
) -> void:
	prototype_id = p_id
	display_name = p_name
	description = p_desc
	item_type = p_type

func is_consumable() -> bool:
	return item_type == ItemType.Type.Consumable

func is_equipment() -> bool:
	return item_type == ItemType.Type.Equipment

func is_quest_item() -> bool:
	return item_type == ItemType.Type.QuestItem

func is_material() -> bool:
	return item_type == ItemType.Type.Material

func is_key_item() -> bool:
	return item_type == ItemType.Type.KeyItem

func can_stack() -> bool:
	return max_stack > 1

func to_dict() -> Dictionary:
	return {
		"prototype_id": prototype_id,
		"display_name": display_name,
		"description": description,
		"item_type": ItemType.type_to_string(item_type),
		"max_stack": max_stack,
		"icon_path": icon_path,
		"is_droppable": is_droppable,
		"is_discardable": is_discardable
	}

static func from_dict(data: Dictionary) -> ItemData:
	var item = ItemData.new(
		data.get("prototype_id", ""),
		data.get("display_name", ""),
		data.get("description", ""),
		ItemType.string_to_type(data.get("item_type", "None"))
	)
	item.max_stack = data.get("max_stack", 99)
	item.icon_path = data.get("icon_path", "")
	item.is_droppable = data.get("is_droppable", true)
	item.is_discardable = data.get("is_discardable", true)
	return item