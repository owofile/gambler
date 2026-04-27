extends Control

@onready var DialogueNameText: Label = $DialogueNameText
@onready var DialogueText: RichTextLabel = $DialogueText
@onready var Avatar: NinePatchRect = $Avatar

#region 配置参数
var speaker_name: String = ""          # 默认对话者名称
var max_characters: int = 70              # 单次最大显示字符数
var characters_per_second: float = 20     # 打字机速度（字符/秒）
var segment_interval: float = 1.5         # 段落间隔时间（秒）
var auto_hide: bool = false               # 是否在对话结束后自动隐藏
var show_avatar: bool = true             # 是否显示头像
#endregion

#region 运行时变量
var _current_text: String = ""            # 当前显示文本
var _current_index: int = 0               # 当前字符索引
var _segment_queue: Array = []            # 对话队列（包含文本和头像信息）
var _typewriter_timer: Timer = Timer.new()
var _segment_timer: Timer = Timer.new()
var _current_avatar: String = ""          # 当前头像路径
#endregion

#region 音效
@onready var sound = $sound
var play_sound: bool = true

func _ready():
	# 初始化计时器
	add_child(_typewriter_timer)
	_typewriter_timer.timeout.connect(_update_typewriter)
	
	add_child(_segment_timer)
	_segment_timer.one_shot = true
	_segment_timer.timeout.connect(_show_next_segment)
	
	hide_dialogue()

# 显示单句对话（扩展头像支持）
func show_single_dialogue(text: String, avatar_path: String = ""):
	var segment = {"text": text, "avatar": avatar_path}
	queue_dialogue_segments([segment])

# 队列多段对话（支持每段不同头像）
func queue_dialogue_segments(segments: Array):
	# 标准化输入格式，兼容纯文本或完整配置
	for segment in segments:
		if segment is String:
			_segment_queue.append({"text": segment, "avatar": ""})
		else:
			_segment_queue.append({
				"text": segment.get("text", ""),
				"avatar": segment.get("avatar", "")
			})
	
	if not _segment_timer.is_stopped():
		return
	
	_show_next_segment()

# 隐藏对话框（重置所有状态）
func hide_dialogue():
	visible = false
	_current_text = ""
	_current_index = 0
	_typewriter_timer.stop()
	_segment_timer.stop()
	DialogueText.text = ""
	_update_avatar("")  # 清空头像

# 立即完成当前显示
func finish_typing():
	if _typewriter_timer.is_stopped():
		return
	
	_typewriter_timer.stop()
	DialogueText.text = _current_text
	_segment_timer.start(segment_interval)

#region 私有方法
func _split_text_to_fit(text: String) -> String:
	# 简单裁剪文本以适应最大字符限制
	return text.substr(0, max_characters) if text.length() > max_characters else text

func _show_next_segment():
	if _segment_queue.is_empty():
		if auto_hide:
			hide_dialogue()
		return
	
	visible = true
	var current_segment = _segment_queue.pop_front()
	
	# 更新对话内容
	_current_text = _split_text_to_fit(current_segment["text"])
	_current_index = 0
	DialogueText.text = ""
	DialogueNameText.text = speaker_name
	
	# 更新头像
	_update_avatar(current_segment.get("avatar", ""))
	
	_typewriter_timer.start(1.0 / characters_per_second)

func _update_typewriter():
	#对话音效
	sound.play()
	if _current_index >= _current_text.length():
		_typewriter_timer.stop()
		_segment_timer.start(segment_interval)
		return
	
	DialogueText.text += _current_text[_current_index]
	_current_index += 1

func _update_avatar(path: String):
	if not show_avatar:
		Avatar.hide()
		return
	
	if path == "":
		Avatar.hide()
		return
	
	# 仅当路径变化时加载新纹理
	if path != _current_avatar:
		_current_avatar = path
		var texture = load(path)
		if texture:
			Avatar.texture = texture
			Avatar.show()
		else:
			push_warning("Avatar texture load failed: %s" % path)
			Avatar.hide()
#endregion

# 修改音效的函数
func change_sound_effect(path: String):
	if sound:  # 确保音效节点存在
		var stream = AudioStreamPlayer.new()
		stream.stream = load(path)
		sound.stream = stream
	else:
		push_warning("Sound node not found")
