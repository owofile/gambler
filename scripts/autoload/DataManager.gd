extends Node

var card_registry: CardPrototypeRegistry
var enemy_registry: EnemyRegistry
var effect_registry: EffectRegistry
var cost_registry: CostRegistry
var item_registry: ItemPrototypeRegistry

func _ready() -> void:
	card_registry = CardPrototypeRegistry.new()
	enemy_registry = EnemyRegistry.new()
	effect_registry = EffectRegistry.new()
	cost_registry = CostRegistry.new()
	item_registry = ItemPrototypeRegistry.new()
	_load_item_prototypes()
	print("[DataManager] Initialized")

func _load_item_prototypes() -> void:
	var path = "res://resources/item_prototypes.json"
	if not ResourceLoader.exists(path):
		print("[DataManager] No item prototypes file found at: %s" % path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[DataManager] Failed to open item prototypes: %s" % path)
		return

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("[DataManager] Failed to parse item prototypes JSON")
		return

	var data = json.data
	if not data is Dictionary:
		push_error("[DataManager] Item prototypes JSON root is not a dictionary")
		return

	var prototypes_dict = data.get("items", null)
	if prototypes_dict == null:
		prototypes_dict = data

	if not prototypes_dict is Dictionary:
		push_error("[DataManager] Item prototypes data is not a dictionary")
		return

	var count = 0
	for key in prototypes_dict:
		var item_data = ItemData.from_dict(prototypes_dict[key])
		if item_data.prototype_id.is_empty():
			item_data.prototype_id = key
		item_registry.register_item(item_data)
		count += 1

	print("[DataManager] Loaded %d item prototypes" % count)
