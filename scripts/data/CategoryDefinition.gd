class_name CategoryDefinition
extends RefCounted

var id: String
var display_name: String
var description: String
var icon: String
var base_value_range: Array = [0, 10]
var special_effect: String
var color: String

func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_description: String = "",
	p_icon: String = "",
	p_value_range: Array = [0, 10],
	p_special_effect: String = "",
	p_color: String = "#FFFFFF"
) -> void:
	id = p_id
	display_name = p_display_name
	description = p_description
	icon = p_icon
	base_value_range = p_value_range.duplicate()
	special_effect = p_special_effect
	color = p_color

static func from_dict(category_id: String, data: Dictionary) -> CategoryDefinition:
	return CategoryDefinition.new(
		category_id,
		data.get("display_name", category_id),
		data.get("description", ""),
		data.get("icon", ""),
		data.get("base_value_range", [0, 10]),
		data.get("special_effect", ""),
		data.get("color", "#FFFFFF")
	)