## Manages fade transition between exploration and battle.
##
## Responsibility:
## - Handle scene transitions with animation
## - Trigger battle scene loading
## - Return to exploration after battle ends
class_name BattleTransition
extends CanvasLayer

signal battle_started(enemy_id: String)
signal battle_ended(result: Dictionary)

@export var battle_scene_path: String = ""

var _enemy_id: String = ""

func _ready():
	EventBus.subscribe("BattleRequested", _on_battle_requested)
	EventBus.subscribe("BattleEnded", _on_battle_ended)

func _on_battle_requested(payload: Dictionary) -> void:
	_enemy_id = payload.get("enemy_id", "")
	_fade_to_battle()

func _fade_to_battle():
	var anim := $AnimationPlayer
	anim.play("Gradient")
	await anim.animation_finished

	if battle_scene_path.is_empty():
		push_error("[BattleTransition] battle_scene_path not set!")
		return

	get_tree().change_scene_to_file(battle_scene_path)
	EventBus.publish("BattleStarting", {"enemy_id": _enemy_id})

	anim.play_backwards("Gradient")
	await anim.animation_finished

	battle_started.emit(_enemy_id)

func _on_battle_ended(payload: Dictionary) -> void:
	print("[BattleTransition] Battle ended: %s" % payload)
	battle_ended.emit(payload)

func set_battle_scene(path: String) -> void:
	battle_scene_path = path
