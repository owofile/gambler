class_name AnimationController
extends Node

enum AnimType {
	PLAYER_CARD_ENTER,
	ENEMY_CARD_REVEAL,
	COMPARE,
	ROUND_END
}

var _is_playing: bool = false
var _current_anim: String = ""
var _pending_callback: Callable = Callable()

func _get_event_bus():
	return get_node("/root/EventBus")

func play_animation(type: AnimType, data: Dictionary, on_complete: Callable) -> void:
	if _is_playing:
		print("[AnimationController] Already playing animation: %s" % _current_anim)
		return

	_is_playing = true
	_current_anim = _get_anim_name(type)
	_pending_callback = on_complete

	print("[AnimationController] Playing: %s with data: %s" % [_current_anim, data])

	match type:
		AnimType.PLAYER_CARD_ENTER:
			_play_player_card_animation(data)
		AnimType.ENEMY_CARD_REVEAL:
			_play_enemy_card_animation(data)
		AnimType.COMPARE:
			_play_compare_animation(data)
		AnimType.ROUND_END:
			_play_round_end_animation(data)

func is_playing() -> bool:
	return _is_playing

func skip_animation() -> void:
	if _is_playing:
		print("[AnimationController] Skipping animation: %s" % _current_anim)
		_complete_animation()

func _play_player_card_animation(data: Dictionary) -> void:
	var cards = data.get("cards", [])
	print("[AnimationController] Player cards entering: %d cards" % cards.size())

	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_animation_timer_done)
	add_child(timer)
	timer.start(0.5)

func _play_enemy_card_animation(data: Dictionary) -> void:
	var card_id = data.get("card_id", "")
	var all_cards = data.get("all_cards", [])
	print("[AnimationController] Enemy card revealed: %s (total: %d)" % [card_id, all_cards.size()])

	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_animation_timer_done)
	add_child(timer)
	timer.start(0.5)

func _play_compare_animation(data: Dictionary) -> void:
	var player_cards = data.get("player_cards", [])
	var enemy_cards = data.get("enemy_cards", [])
	var player_total = data.get("player_total", 0)
	var enemy_total = data.get("enemy_total", 0)
	print("[AnimationController] Comparing: Player %s vs Enemy %s" % [player_cards, enemy_cards])
	print("[AnimationController] Totals: Player %d vs Enemy %d" % [player_total, enemy_total])

	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_animation_timer_done)
	add_child(timer)
	timer.start(1.0)

func _play_round_end_animation(data: Dictionary) -> void:
	var winner = data.get("winner", "draw")
	var scores = data.get("scores", [0, 0])
	print("[AnimationController] Round end: %s wins! Score: %d - %d" % [winner, scores[0], scores[1]])

	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_animation_timer_done)
	add_child(timer)
	timer.start(0.5)

func _on_animation_timer_done() -> void:
	_complete_animation()

func _complete_animation() -> void:
	_is_playing = false
	print("[AnimationController] Animation complete: %s" % _current_anim)

	if _pending_callback.is_valid():
		_pending_callback.call()
	_pending_callback = Callable()
	_current_anim = ""

func _get_anim_name(type: AnimType) -> String:
	match type:
		AnimType.PLAYER_CARD_ENTER: return "player_card_enter"
		AnimType.ENEMY_CARD_REVEAL: return "enemy_card_reveal"
		AnimType.COMPARE: return "compare"
		AnimType.ROUND_END: return "round_end"
	return "unknown"