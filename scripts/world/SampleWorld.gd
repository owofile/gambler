## Sample world scene for testing exploration-battle integration.
class_name SampleWorld
extends Node2D

@onready var battle_transition: BattleTransition = $BattleTransition

func _ready():
	EventBus.subscribe("BattleRequested", _on_battle_requested)
	print("[SampleWorld] World loaded at: %s" % get_path())

func _on_battle_requested(payload: Dictionary):
	var enemy_id = payload.get("enemy_id", "")
	print("[SampleWorld] Battle requested with enemy: %s" % enemy_id)

func get_battle_transition() -> BattleTransition:
	return battle_transition
