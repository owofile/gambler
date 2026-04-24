class_name EnemyData
extends RefCounted

enum EnemyTier {
	Grunt,
	Elite,
	Boss
}

var enemy_id: String
var enemy_name: String
var tier: EnemyTier
var deck_prototype_ids: Array[String]
var loot_pool_prototype_ids: Array[String]

func _init(
	p_id: String = "",
	p_name: String = "",
	p_tier: EnemyTier = EnemyTier.Grunt,
	p_deck: Array[String] = [],
	p_loot: Array[String] = []
) -> void:
	enemy_id = p_id
	enemy_name = p_name
	tier = p_tier
	deck_prototype_ids = p_deck.duplicate()
	loot_pool_prototype_ids = p_loot.duplicate()

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
		_: pass
	return EnemyTier.Grunt
