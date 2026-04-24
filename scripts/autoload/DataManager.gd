extends Node

var card_registry: CardPrototypeRegistry
var enemy_registry: EnemyRegistry
var effect_registry: EffectRegistry
var cost_registry: CostRegistry

func _ready() -> void:
	card_registry = CardPrototypeRegistry.new()
	enemy_registry = EnemyRegistry.new()
	effect_registry = EffectRegistry.new()
	cost_registry = CostRegistry.new()
	print("[DataManager] Initialized")
