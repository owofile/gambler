## Item type enumeration
class_name ItemType
extends RefCounted

enum Type {
	None = 0,
	Consumable = 1,    # 消耗品（可使用一次或多次）
	Equipment = 2,     # 装备（穿戴后持续有效）
	QuestItem = 3,     # 任务物品（不可使用，用于剧情）
	Material = 4,      # 材料（用于合成/升级）
	KeyItem = 5        # 关键物品（唯一，不可丢弃）
}

static func type_to_string(type: Type) -> String:
	match type:
		Type.Consumable:
			return "Consumable"
		Type.Equipment:
			return "Equipment"
		Type.QuestItem:
			return "QuestItem"
		Type.Material:
			return "Material"
		Type.KeyItem:
			return "KeyItem"
	return "None"

static func string_to_type(s: String) -> Type:
	match s:
		"Consumable":
			return Type.Consumable
		"Equipment":
			return Type.Equipment
		"QuestItem":
			return Type.QuestItem
		"Material":
			return Type.Material
		"KeyItem":
			return Type.KeyItem
	return Type.None