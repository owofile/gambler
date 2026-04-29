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
	if not data.has("items"):
		print("[DataManager] No items in prototypes file")
		return

	for key in data["items"]:
		var item_data = ItemData.from_dict(data["items"][key])
		item_registry.register_item(item_data)

	print("[DataManager] Loaded %d item prototypes" % item_registry.get_count())
