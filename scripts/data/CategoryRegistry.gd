## CategoryRegistry - Manages card category definitions
##
## Responsibility:
## - Load category definitions from JSON
## - Provide lookup for category metadata
## - Support adding new categories without code changes
##
## Usage:
##   CategoryRegistry.get_category("Bird")
##   CategoryRegistry.get_display_name("Artifact")
##   CategoryRegistry.get_all_category_ids()
##
## Note: CategoryRegistry is NOT an Autoload. Use via DataManager.card_category_registry
class_name CategoryRegistry
extends RefCounted

const DEFAULT_PATH := "res://resources/card_categories.json"

var _categories: Dictionary = {}

func _init() -> void:
	load_categories()

func load_categories(path: String = DEFAULT_PATH) -> bool:
	_categories.clear()
	
	if not FileAccess.file_exists(path):
		push_warning("[CategoryRegistry] Category file not found: %s" % path)
		_setup_default_categories()
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[CategoryRegistry] Failed to open file: %s" % path)
		_setup_default_categories()
		return false
	
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("[CategoryRegistry] Failed to parse JSON")
		_setup_default_categories()
		return false
	
	var data: Variant = json.data
	if data is Dictionary:
		for category_id in data.keys():
			var cat_data: Dictionary = data[category_id]
			var category := CategoryDefinition.from_dict(category_id, cat_data)
			_categories[category_id] = category
		print("[CategoryRegistry] Loaded %d categories" % _categories.size())
		return true
	
	_setup_default_categories()
	return false

func _setup_default_categories() -> void:
	_categories["Artifact"] = CategoryDefinition.new("Artifact", "器物", "武器、护具、工具等装备类卡牌", "", [5, 9], "", "#8B4513")
	_categories["Bond"] = CategoryDefinition.new("Bond", "羁绊", "人际关系、情感纽带类卡牌", "", [2, 4], "", "#9370DB")
	_categories["Creature"] = CategoryDefinition.new("Creature", "生灵", "生物、怪物、灵体类卡牌", "", [3, 6], "", "#228B22")
	_categories["Concept"] = CategoryDefinition.new("Concept", "概念", "抽象概念、情感、理念类卡牌", "", [2, 7], "", "#4169E1")
	_categories["Sin"] = CategoryDefinition.new("Sin", "罪孽", "负面、危险、高风险类卡牌", "", [6, 10], "high_risk", "#8B0000")
	_categories["Authority"] = CategoryDefinition.new("Authority", "权能", "权力、命令、审判类卡牌", "", [4, 8], "", "#FFD700")

func get_category(category_id: String) -> CategoryDefinition:
	if _categories.has(category_id):
		return _categories[category_id]
	push_warning("[CategoryRegistry] Category not found: %s" % category_id)
	return null

func has_category(category_id: String) -> bool:
	return _categories.has(category_id)

func get_display_name(category_id: String) -> String:
	var cat := get_category(category_id)
	return cat.display_name if cat else category_id

func get_description(category_id: String) -> String:
	var cat := get_category(category_id)
	return cat.description if cat else ""

func get_icon(category_id: String) -> String:
	var cat := get_category(category_id)
	return cat.icon if cat else ""

func get_color(category_id: String) -> String:
	var cat := get_category(category_id)
	return cat.color if cat else "#FFFFFF"

func get_value_range(category_id: String) -> Array:
	var cat := get_category(category_id)
	return cat.base_value_range.duplicate() if cat else [0, 10]

func get_all_category_ids() -> Array:
	return Array(_categories.keys(), TYPE_STRING, "", null)

func get_all_categories() -> Array:
	return Array(_categories.values(), TYPE_OBJECT, "CategoryDefinition", null)

func add_category(category_id: String, definition: CategoryDefinition) -> void:
	_categories[category_id] = definition
	print("[CategoryRegistry] Added category: %s" % category_id)

func is_valid_value_for_category(category_id: String, value: int) -> bool:
	var range_arr: Array = get_value_range(category_id)
	if range_arr.size() >= 2:
		return value >= range_arr[0] and value <= range_arr[1]
	return true