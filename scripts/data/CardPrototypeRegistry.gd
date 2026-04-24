class_name CardPrototypeRegistry
extends Resource

const REGISTRY_PATH := "res://resources/card_prototypes.json"

var _prototypes: Dictionary = {}

func _init() -> void:
	_load_registry()

func _get_prototype(p_id: String) -> CardData:
	if _prototypes.has(p_id):
		return _prototypes[p_id]
	return null

func get_prototype(p_id: String) -> CardData:
	return _get_prototype(p_id)

func has_prototype(p_id: String) -> bool:
	return _prototypes.has(p_id)

func _load_registry() -> void:
	if FileAccess.file_exists(REGISTRY_PATH):
		var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
		if file:
			var json_str := file.get_as_text()
			file.close()
			var json := JSON.new()
			if json.parse(json_str) == OK:
				var data: Variant = json.data
				if data is Dictionary:
					_parse_prototypes(data)
					return
	_setup_default_prototypes()

func _parse_prototypes(data: Dictionary) -> void:
	_prototypes.clear()
	for key in data.keys():
		var proto_dict: Dictionary = data[key]
		var card_class: CardData.CardClass = CardData.string_to_class_name(proto_dict.get("card_class", "Artifact"))
		var effects: Variant = proto_dict.get("effect_ids", [])
		var effects_str: Array[String] = []
		if effects is Array:
			for e in effects:
				effects_str.append(str(e))
		var proto := CardData.new(
			key,
			card_class,
			proto_dict.get("base_value", 0),
			effects_str,
			proto_dict.get("cost_id", ""),
			proto_dict.get("is_lockable", true)
		)
		_prototypes[key] = proto

func _setup_default_prototypes() -> void:
	var empty_effects: Array[String] = []
	_prototypes["card_rusty_sword"] = CardData.new("card_rusty_sword", CardData.CardClass.Artifact, 7, empty_effects, "", true)
	_prototypes["card_ancient_shield"] = CardData.new("card_ancient_shield", CardData.CardClass.Artifact, 5, empty_effects, "", true)
	_prototypes["card_cursed_amulet"] = CardData.new("card_cursed_amulet", CardData.CardClass.Artifact, 9, empty_effects, "", false)

	_prototypes["card_friendly_spirit"] = CardData.new("card_friendly_spirit", CardData.CardClass.Creature, 4, empty_effects, "", true)
	_prototypes["card_wild_beast"] = CardData.new("card_wild_beast", CardData.CardClass.Creature, 6, empty_effects, "", true)
	_prototypes["card_minion"] = CardData.new("card_minion", CardData.CardClass.Creature, 3, empty_effects, "", true)

	_prototypes["card_justice"] = CardData.new("card_justice", CardData.CardClass.Concept, 5, empty_effects, "", true)
	_prototypes["card_freedom"] = CardData.new("card_freedom", CardData.CardClass.Concept, 2, empty_effects, "", true)
	_prototypes["card_hope"] = CardData.new("card_hope", CardData.CardClass.Concept, 7, empty_effects, "", true)

	_prototypes["card_blood_oath"] = CardData.new("card_blood_oath", CardData.CardClass.Bond, 3, empty_effects, "", true)
	_prototypes["card_familial_bond"] = CardData.new("card_familial_bond", CardData.CardClass.Bond, 4, empty_effects, "", true)
	_prototypes["card_sworn_enemy"] = CardData.new("card_sworn_enemy", CardData.CardClass.Bond, 2, empty_effects, "", true)

	_prototypes["card_vengeance"] = CardData.new("card_vengeance", CardData.CardClass.Sin, 8, empty_effects, "self_destroy", true)
	_prototypes["card_gluttony"] = CardData.new("card_gluttony", CardData.CardClass.Sin, 6, empty_effects, "", true)
	_prototypes["card_greed"] = CardData.new("card_greed", CardData.CardClass.Sin, 10, empty_effects, "", true)

	_prototypes["card_kings_authority"] = CardData.new("card_kings_authority", CardData.CardClass.Authority, 8, empty_effects, "", true)
	_prototypes["card_judgment"] = CardData.new("card_judgment", CardData.CardClass.Authority, 5, empty_effects, "", true)
	_prototypes["card_decree"] = CardData.new("card_decree", CardData.CardClass.Authority, 4, empty_effects, "", true)

func get_all_prototype_ids() -> Array:
	return Array(_prototypes.keys(), TYPE_STRING, "", null)

func get_prototypes_by_class(card_class: CardData.CardClass) -> Array:
	var result: Array = []
	for proto in _prototypes.values():
		if proto.card_class == card_class:
			result.append(proto)
	return result
