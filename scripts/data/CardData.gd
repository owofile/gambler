class_name CardData
extends RefCounted

enum CardClass {
	Artifact,
	Bond,
	Creature,
	Concept,
	Sin,
	Authority
}

enum CardBindStatus {
	None,
	Locked,
	Cursed
}

var prototype_id: String
var card_class: CardClass
var base_value: int
var effect_ids: Array = []
var cost_id: String
var is_lockable: bool
var texture_path: String
var display_name: String
var destroy_animation: String = "fade_destroy"
var animation_config: Dictionary = {
	"hover": "glow",
	"click": "bounce",
	"selected": "move",
	"reveal": "shake",
	"particle": "spark"
}

func _init(
	p_id: String = "",
	p_class: CardClass = CardClass.Artifact,
	p_value: int = 0,
	p_effects: Array = [],
	p_cost: String = "",
	p_lockable: bool = true,
	p_texture_path: String = "",
	p_display_name: String = "",
	p_destroy_animation: String = "fade_destroy"
) -> void:
	prototype_id = p_id
	card_class = p_class
	base_value = p_value
	effect_ids = p_effects.duplicate()
	cost_id = p_cost
	is_lockable = p_lockable
	texture_path = p_texture_path
	display_name = p_display_name
	destroy_animation = p_destroy_animation

static func class_name_to_string(class_type: CardClass) -> String:
	match class_type:
		CardClass.Artifact: return "Artifact"
		CardClass.Bond: return "Bond"
		CardClass.Creature: return "Creature"
		CardClass.Concept: return "Concept"
		CardClass.Sin: return "Sin"
		CardClass.Authority: return "Authority"
	return "Unknown"

static func string_to_class_name(s: String) -> CardClass:
	match s:
		"Artifact": return CardClass.Artifact
		"Bond": return CardClass.Bond
		"Creature": return CardClass.Creature
		"Concept": return CardClass.Concept
		"Sin": return CardClass.Sin
		"Authority": return CardClass.Authority
	return CardClass.Artifact
