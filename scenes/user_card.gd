extends Node2D

signal card_hovered(index: int)
signal card_unhovered(index: int)
signal card_clicked(index: int)

@onready var sprite2d_card_01 = $user_card_01/Sprite2D
@onready var sprite2d_card_02 = $user_card_02/Sprite2D
@onready var sprite2d_card_03 = $user_card_03/Sprite2D
@onready var sprite2d_card_04 = $user_card_04/Sprite2D
@onready var sprite2d_card_05 = $user_card_05/Sprite2D
@onready var sprite2d_card_06 = $user_card_06/Sprite2D

var _sprite_nodes: Array = []
var _hover_enabled: bool = true

func _ready() -> void:
	_sprite_nodes = [sprite2d_card_01, sprite2d_card_02, sprite2d_card_03, sprite2d_card_04, sprite2d_card_05, sprite2d_card_06]
	print("[user_card] Ready, sprites count: %d" % _sprite_nodes.size())

func _on_user_card_01_mouse_entered() -> void:
	print("[user_card] Card 0 hovered")
	card_hovered.emit(0)

func _on_user_card_01_mouse_exited() -> void:
	print("[user_card] Card 0 unhovered")
	card_unhovered.emit(0)

func _on_user_card_02_mouse_entered() -> void:
	print("[user_card] Card 1 hovered")
	card_hovered.emit(1)

func _on_user_card_02_mouse_exited() -> void:
	print("[user_card] Card 1 unhovered")
	card_unhovered.emit(1)

func _on_user_card_03_mouse_entered() -> void:
	print("[user_card] Card 2 hovered")
	card_hovered.emit(2)

func _on_user_card_03_mouse_exited() -> void:
	print("[user_card] Card 2 unhovered")
	card_unhovered.emit(2)

func _on_user_card_04_mouse_entered() -> void:
	print("[user_card] Card 3 hovered")
	card_hovered.emit(3)

func _on_user_card_04_mouse_exited() -> void:
	print("[user_card] Card 3 unhovered")
	card_unhovered.emit(3)

func _on_user_card_05_mouse_entered() -> void:
	print("[user_card] Card 4 hovered")
	card_hovered.emit(4)

func _on_user_card_05_mouse_exited() -> void:
	print("[user_card] Card 4 unhovered")
	card_unhovered.emit(4)

func _on_user_card_06_mouse_entered() -> void:
	print("[user_card] Card 5 hovered")
	card_hovered.emit(5)

func _on_user_card_06_mouse_exited() -> void:
	print("[user_card] Card 5 unhovered")
	card_unhovered.emit(5)

func _on_user_card_01_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[user_card] Card 0 clicked")
		card_clicked.emit(0)

func _on_user_card_02_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[user_card] Card 1 clicked")
		card_clicked.emit(1)

func _on_user_card_03_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[user_card] Card 2 clicked")
		card_clicked.emit(2)

func _on_user_card_04_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[user_card] Card 3 clicked")
		card_clicked.emit(3)

func _on_user_card_05_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[user_card] Card 4 clicked")
		card_clicked.emit(4)

func _on_user_card_06_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[user_card] Card 5 clicked")
		card_clicked.emit(5)
