extends CanvasLayer

@onready var DialogueBoxParent = $DialogueBoxParent
@onready var ItemBar = $ItemBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
	pass


func _on_item_bar_on_item_selected(index: int) -> void:
	print("信号反射：" + str(index))
	
	match index:
		1:
			print("[Left_Arrow] 执行功能")
			# 在这里添加对应的功能代码
		2:
			print("[ItemSlot1] 执行对话功能")
			start_dialogue()  # 调用对话功能
		3:
			print("[ItemSlot2] 执行功能")
			# 在这里添加对应的功能代码
		4:
			print("[ItemSlot3] 执行功能")
			# 在这里添加对应的功能代码
		5:
			print("[Right_Arrow] 执行功能")
			# 在这里添加对应的功能代码

#单段调用
func start_dialogue():
	#DialogueBoxParent.change_sound_effect("res://scenes/Thryzhn/Sound/SFX/UI_Button_Hover_02.ogg")
	DialogueBoxParent.speaker_name = "owofile"
	DialogueBoxParent.show_single_dialogue("NO MATTER WHERE YOU ARE, PEOPLE ARE CONNECTED TO EACH OTHER","res://Art/logo_antver.png")
