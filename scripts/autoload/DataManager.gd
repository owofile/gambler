extends Node

var card_registry: CardPrototypeRegistry
var enemy_registry: EnemyRegistry

func _ready() -> void:
	card_registry = CardPrototypeRegistry.new()
	enemy_registry = EnemyRegistry.new()
	print("[DataManager] Initialized")
