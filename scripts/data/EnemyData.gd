## Data for an enemy in battle.
class_name EnemyData
extends RefCounted

enum EnemyTier {
	Grunt,
	Elite,
	Boss
}

var _enemy_id: String = ""
var _enemy_name: String = ""
var _tier: EnemyTier = EnemyTier.Grunt
var _deck_prototype_ids: Array = []
var _loot_pool_prototype_ids: Array = []

func _init(
	p_id: String = "",
	p_name: String = "",
	p_tier: EnemyTier = EnemyTier.Grunt,
	p_deck: Array = [],
	p_loot: Array = []
) -> void:
	_enemy_id = p_id
	_enemy_name = p_name
	_tier = p_tier
	_deck_prototype_ids = p_deck.duplicate() if p_deck else []
	_loot_pool_prototype_ids = p_loot.duplicate() if p_loot else []

func get_enemy_id() -> String:
	return _enemy_id

func get_enemy_name() -> String:
	return _enemy_name

func get_tier() -> EnemyTier:
	return _tier

func get_deck_prototype_ids() -> Array:
	return _deck_prototype_ids.duplicate()

func get_loot_pool_prototype_ids() -> Array:
	return _loot_pool_prototype_ids.duplicate()

static func tier_to_string(tier: EnemyTier) -> String:
	match tier:
		EnemyTier.Grunt: return "Grunt"
		EnemyTier.Elite: return "Elite"
		EnemyTier.Boss: return "Boss"
	return "Grunt"

static func string_to_tier(s: String) -> EnemyTier:
	match s:
		"Elite": return EnemyTier.Elite
		"Boss": return EnemyTier.Boss
	return EnemyTier.Grunt
