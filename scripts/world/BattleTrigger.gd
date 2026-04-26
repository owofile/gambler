## Area2D trigger that initiates battle when player enters.
##
## Responsibility:
## - Detect player collision
## - Emit battle request event
## - Notify GameStateManager to enter battle mode
class_name BattleTrigger
extends Area2D

@export var enemy_id: String = ""

signal battle_requested(enemy_id: String)

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		battle_requested.emit(enemy_id)
		EventBus.publish("BattleRequested", {"enemy_id": enemy_id})
		GameState.enter_battle()
