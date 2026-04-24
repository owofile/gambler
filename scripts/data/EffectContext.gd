class_name EffectContext
extends RefCounted

var player_deck: DeckSnapshot
var enemy_deck: DeckSnapshot
var player_played_cards: Array[CardSnapshot]
var enemy_played_cards: Array[CardSnapshot]
var current_player_total: int
var current_enemy_total: int
var player_wins: int
var enemy_wins: int
var target_wins: int
var is_draw: bool
var pending_costs: Array[String]

func _init(
	p_deck: DeckSnapshot = null,
	e_deck: DeckSnapshot = null,
	p_played: Array[CardSnapshot] = [],
	e_played: Array[CardSnapshot] = [],
	p_total: int = 0,
	e_total: int = 0,
	p_wins: int = 0,
	e_wins: int = 0,
	target: int = 3
) -> void:
	player_deck = p_deck
	enemy_deck = e_deck
	player_played_cards = p_played.duplicate()
	enemy_played_cards = e_played.duplicate()
	current_player_total = p_total
	current_enemy_total = e_total
	player_wins = p_wins
	enemy_wins = e_wins
	target_wins = target
	pending_costs = []