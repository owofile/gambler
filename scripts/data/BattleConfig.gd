## Configuration for a single battle instance.
##
## Responsibility:
## - Store all tunable parameters for a battle
## - Provide defaults for simple battles
## - Support extended config for bosses/elites
##
## Usage:
##   var config = BattleConfig.new()
##   config.target_wins = 3
##   config.cards_per_round = 3
##
## Note: BattleConfig is a Resource, can be created via .tres file or code.
class_name BattleConfig
extends Resource

## Default values for basic battles
const DEFAULT_TARGET_WINS := 3
const DEFAULT_CARDS_PER_ROUND := 3
const DEFAULT_DRAW_BREAK_THRESHOLD := 2
const DEFAULT_MIN_DECK_SIZE := 3

## Target wins to complete the battle
@export var target_wins: int = DEFAULT_TARGET_WINS

## How many cards player must select per round
@export var cards_per_round: int = DEFAULT_CARDS_PER_ROUND

## How many cards to draw at battle start
@export var initial_hand_size: int = 6

## How many consecutive draws before auto-breaking
@export var draw_break_threshold: int = DEFAULT_DRAW_BREAK_THRESHOLD

## Minimum cards required in deck to start battle
@export var min_deck_size: int = DEFAULT_MIN_DECK_SIZE

## Enemy deck in fixed order (will cycle)
@export var enemy_deck_order: Array = []

## Enemy data reference
var enemy_data: EnemyData = null

## Enemy deck pointer (current index when cycling)
var _enemy_deck_index: int = 0

## Special rules for this battle (extensible)
## Format: {"rule_name": rule_value}
@export var special_rules: Dictionary = {}

## Enable/disable specific mechanics
@export var enable_card_consumption: bool = true
@export var enable_buff_system: bool = false

## Deck management policy (replaces enable_card_consumption)
## Default: NoConsumptionPolicy (cards reused every round)
var deck_policy: IDeckPolicy = NoConsumptionPolicy.new()

func _init(
	p_target_wins: int = DEFAULT_TARGET_WINS,
	p_cards_per_round: int = DEFAULT_CARDS_PER_ROUND,
	p_enemy_deck: Array = []
) -> void:
	target_wins = p_target_wins
	cards_per_round = p_cards_per_round
	enemy_deck_order = p_enemy_deck.duplicate() if p_enemy_deck else []

## Get next enemy cards for a round
func get_enemy_cards(count: int) -> Array:
	if enemy_deck_order.size() == 0:
		return []

	var result: Array = []
	for i in range(count):
		var card_id = enemy_deck_order[_enemy_deck_index % enemy_deck_order.size()]
		result.append(card_id)
		_enemy_deck_index += 1

	return result

## Reset enemy deck pointer (for new battle)
func reset_deck_pointer() -> void:
	_enemy_deck_index = 0

## Check if special rule is active
func has_special_rule(rule_name: String) -> bool:
	return special_rules.has(rule_name)

## Get special rule value
func get_special_rule(rule_name: String, default: Variant = null) -> Variant:
	return special_rules.get(rule_name, default)

## Create config from EnemyData (factory method)
static func from_enemy_data(enemy: EnemyData) -> BattleConfig:
	var config := BattleConfig.new()
	match enemy.get_tier():
		EnemyData.EnemyTier.Grunt:
			config.target_wins = 3
		EnemyData.EnemyTier.Elite:
			config.target_wins = 4
		EnemyData.EnemyTier.Boss:
			config.target_wins = 5
	config.enemy_data = enemy
	config.enemy_deck_order = enemy.get_deck_prototype_ids()
	if GameState and GameState.battle_deck_policy:
		config.deck_policy = GameState.battle_deck_policy.new()
	return config
