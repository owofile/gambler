## Context passed to effect handlers during battle.
##
## Responsibility:
## - Provide effect handlers with battle state
## - Allow effect handlers to modify battle totals
class_name EffectContext
extends RefCounted

var _player_deck: DeckSnapshot = null
var _enemy_deck: DeckSnapshot = null
var _player_played_cards: Array = []
var _enemy_played_cards: Array = []
var _current_player_total: int = 0
var _current_enemy_total: int = 0
var _player_wins: int = 0
var _enemy_wins: int = 0
var _target_wins: int = 3
var _is_draw: bool = false
var _pending_costs: Array = []

func _init(
	p_deck: DeckSnapshot = null,
	e_deck: DeckSnapshot = null,
	p_played: Array = [],
	e_played: Array = [],
	p_total: int = 0,
	e_total: int = 0,
	p_wins: int = 0,
	e_wins: int = 0,
	target: int = 3
) -> void:
	_player_deck = p_deck
	_enemy_deck = e_deck
	_player_played_cards = p_played.duplicate() if p_played else []
	_enemy_played_cards = e_played.duplicate() if e_played else []
	_current_player_total = p_total
	_current_enemy_total = e_total
	_player_wins = p_wins
	_enemy_wins = e_wins
	_target_wins = target
	_pending_costs = []

func get_player_deck() -> DeckSnapshot:
	return _player_deck

func get_enemy_deck() -> DeckSnapshot:
	return _enemy_deck

func get_player_played_cards() -> Array:
	return _player_played_cards.duplicate()

func get_enemy_played_cards() -> Array:
	return _enemy_played_cards.duplicate()

func get_current_player_total() -> int:
	return _current_player_total

func set_current_player_total(value: int) -> void:
	_current_player_total = value

func add_player_total(value: int) -> void:
	_current_player_total += value

func get_current_enemy_total() -> int:
	return _current_enemy_total

func set_current_enemy_total(value: int) -> void:
	_current_enemy_total = value

func add_enemy_total(value: int) -> void:
	_current_enemy_total += value

func get_player_wins() -> int:
	return _player_wins

func get_enemy_wins() -> int:
	return _enemy_wins

func get_target_wins() -> int:
	return _target_wins

func is_draw() -> bool:
	return _is_draw

func set_is_draw(value: bool) -> void:
	_is_draw = value

func get_pending_costs() -> Array:
	return _pending_costs.duplicate()

func add_pending_cost(cost_id: String) -> void:
	if not cost_id.is_empty() and not _pending_costs.has(cost_id):
		_pending_costs.append(cost_id)
