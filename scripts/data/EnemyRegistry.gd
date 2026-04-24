class_name EnemyRegistry
extends Resource

const REGISTRY_PATH := "res://resources/enemy_registry.json"

var _enemies: Dictionary = {}

func _init() -> void:
	_load_registry()

func _get_enemy(e_id: String) -> EnemyData:
	if _enemies.has(e_id):
		return _enemies[e_id]
	return null

func get_enemy(e_id: String) -> EnemyData:
	return _get_enemy(e_id)

func has_enemy(e_id: String) -> bool:
	return _enemies.has(e_id)

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
					_parse_enemies(data)
					return
	_setup_default_enemies()

func _parse_enemies(data: Dictionary) -> void:
	_enemies.clear()
	for key in data.keys():
		var enemy_dict: Dictionary = data[key]
		var tier: EnemyData.EnemyTier = EnemyData.string_to_tier(enemy_dict.get("tier", "Grunt"))
		var deck: Array = enemy_dict.get("deck_prototype_ids", [])
		var deck_str: Array = []
		for d in deck:
			deck_str.append(str(d))
		var loot: Array = enemy_dict.get("loot_pool_prototype_ids", [])
		var loot_str: Array = []
		for l in loot:
			loot_str.append(str(l))
		var enemy := EnemyData.new(
			key,
			enemy_dict.get("enemy_name", key),
			tier,
			deck_str,
			loot_str
		)
		_enemies[key] = enemy

func _setup_default_enemies() -> void:
	var grunt_deck: Array = [
		"card_rusty_sword",
		"card_ancient_shield",
		"card_cursed_amulet"
	]
	var grunt_loot: Array = ["card_rusty_sword", "card_ancient_shield"]

	_enemies["enemy_skeletal_warrior"] = EnemyData.new(
		"enemy_skeletal_warrior",
		"Skeletal Warrior",
		EnemyData.EnemyTier.Grunt,
		grunt_deck,
		grunt_loot
	)

	var elite_deck: Array = [
		"card_friendly_spirit",
		"card_justice",
		"card_vengeance",
		"card_kings_authority",
		"card_blood_oath"
	]
	var elite_loot: Array = ["card_friendly_spirit", "card_justice", "card_vengeance"]

	_enemies["enemy_shadow_assassin"] = EnemyData.new(
		"enemy_shadow_assassin",
		"Shadow Assassin",
		EnemyData.EnemyTier.Elite,
		elite_deck,
		elite_loot
	)

func get_all_enemy_ids() -> Array:
	return Array(_enemies.keys(), TYPE_STRING, "", null)

func get_enemies_by_tier(tier: EnemyData.EnemyTier) -> Array:
	var result: Array = []
	for enemy in _enemies.values():
		if enemy.get_tier() == tier:
			result.append(enemy)
	return result
