# Godot 4.3 GDScript 技术参考手册

> 本文档所有代码均经过实际运行验证，适用于 Godot 4.3

---

## 1. 信号 (Signal) vs 事件 (EventBus)

### 1.1 信号 - 节点间直接通信

**用途**：父子节点或持有引用的节点间通信

```gdscript
# A.gd - 发送信号
signal cards_selected(card_ids: Array[String])

func _some_action():
    emit_signal("cards_selected", ["card1", "card2"])
```

```gdscript
# B.gd - 持有A的引用，连接信号
@onready var node_a: Node = $A

func _ready():
    node_a.cards_selected.connect(_on_cards_selected)

func _on_cards_selected(ids: Array[String]):
    print("收到卡牌: ", ids)
```

**关键点**：
- `emit_signal()` 发送信号
- `.connect()` 连接信号
- 信号在持有引用的节点间使用，不走全局通道

---

### 1.2 EventBus - 全局事件广播

**用途**：跨模块解耦通信，任何节点可发布/订阅

```gdscript
# EventBus.gd
extends Node

var _subscribers: Dictionary = {}

func Subscribe(event_type: String, handler: Callable) -> void:
    if not _subscribers.has(event_type):
        _subscribers[event_type] = []
    _subscribers[event_type].append(handler)

func Publish(event_type: String, payload) -> void:
    if _subscribers.has(event_type):
        for handler in _subscribers[event_type]:
            if handler.is_valid():
                handler.call(payload)

func Unsubscribe(event_type: String, handler: Callable) -> void:
    if _subscribers.has(event_type):
        _subscribers[event_type].erase(handler)
```

**使用 EventBus 发布**：
```gdscript
var event_bus = get_node("/root/EventBus")
event_bus.Publish("BattleEnded", {"result": "Victory", "score": [3, 1]})
```

**使用 EventBus 订阅**：
```gdscript
var event_bus = get_node("/root/EventBus")
event_bus.Subscribe("BattleEnded", _on_battle_ended)

func _on_battle_ended(payload):
    var result = payload.get("result")
    print("战斗结果: ", result)
```

---

## 2. Autoload 单例

### 2.1 Godot 4.3 Autoload 配置

在 `project.godot` 中配置（**注意：不加 `*` 前缀）：

```ini
[autoload]

DataManager="res://scripts/autoload/DataManager.gd"
CardManager="res://scripts/core/CardManager.gd"
EventBus="res://scripts/core/EventBus.gd"
```

### 2.2 访问 Autoload

```gdscript
# 方式1：在 Node 中使用 get_node
var card_mgr = get_node("/root/CardManager")
var cards = card_mgr.GetAllCards()

# 方式2：Autoload 节点名为全局可访问
DataManager.card_registry
```

### 2.3 Autoload 脚本写法

**不要用 `class_name`，会与节点名冲突**：
```gdscript
# 正确写法
extends Node

var card_registry: CardPrototypeRegistry

func _ready():
    card_registry = CardPrototypeRegistry.new()
```

---

## 3. 节点创建与场景实例化

### 3.1 动态创建节点

```gdscript
# 创建节点
var my_node = Node.new()
my_node.name = "MyNode"
add_child(my_node)

# 创建带脚本的节点
var scripted = Node.new()
scripted.script = preload("res://scripts/MyScript.gd")
add_child(scripted)
```

### 3.2 场景实例化

```gdscript
# 加载并实例化场景
var scene = load("res://scenes/MyScene.tscn")
var instance = scene.instantiate()
add_child(instance)
```

### 3.3 连接信号

```gdscript
# 实例化场景
var ui = scene.instantiate()
add_child(ui)

# 连接信号（重要：不走EventBus）
ui.some_signal.connect(_on_signal_handler)

# 带payload的信号
ui.cards_confirmed.connect(_on_cards_confirmed)

func _on_cards_confirmed(ids: Array[String]):
    print("收到: ", ids)
```

---

## 4. RefCounted 类

### 4.1 基本写法

```gdscript
class_name MyData
extends RefCounted

var value: int
var name: String

func _init(v: int = 0, n: String = ""):
    value = v
    name = n
```

### 4.2 继承 RefCounted 的类作为返回值

```gdscript
class_name CardManager
extends Node

# 返回 RefCounted 实例
func create_card() -> CardData:
    return CardData.new(1, "test")
```

### 4.3 RefCounted vs Node

| RefCounted | Node |
|-----------|------|
| 轻量引用对象 | 场景树节点 |
| 不能用 `get_node()` | 可以用 `get_node()` |
| 适合数据结构 | 适合UI、实体 |
| new() 创建 | instance() 或 new() 创建 |

---

## 5. 常用代码模式

### 5.1 单例模式

```gdscript
# 正确的 Autoload 模式
extends Node

var _instance: Node = null

func _ready():
    _instance = self

static func get_instance() -> Node:
    return _instance
```

### 5.2 注册表模式

```gdscript
class_name CardRegistry
extends Resource

var _cards: Dictionary = {}

func _init():
    _cards["card1"] = create_card("card1")
    _cards["card2"] = create_card("card2")

func get_card(id: String) -> CardData:
    return _cards.get(id)

func has_card(id: String) -> bool:
    return _cards.has(id)
```

### 5.3 状态机模式

```gdscript
enum State { IDLE, RUNNING, PAUSED }

var _current_state: State = State.IDLE

func set_state(new_state: State) -> void:
    _current_state = new_state
    match new_state:
        State.IDLE:
            _on_enter_idle()
        State.RUNNING:
            _on_enter_running()
```

---

## 6. Godot 4.3 语法注意

### 6.1 数组遍历

```gdscript
# 正确
for i in range(my_array.size()):
    print(my_array[i])

# 错误！GDScript 没有 i in array 语法
# for i in my_array:  # 会遍历值不是索引
```

### 6.2 字典访问

```gdscript
# 安全访问
var value = my_dict.get("key", "default")

# 检查存在
if my_dict.has("key"):
    do_something()
```

### 6.3 类型注解

```gdscript
# 变量声明
var my_list: Array[String] = []
var my_dict: Dictionary = {}

# 函数参数
func my_func(ids: Array[String]) -> void:
    pass
```

---

## 7. 已验证可用的代码模板

### 7.1 启动器模板

```gdscript
extends Node

var _ui = null

func _ready():
    _setup_ui()
    _start_game()

func _setup_ui():
    var scene = load("res://scenes/UI.tscn")
    _ui = scene.instantiate()
    add_child(_ui)
    _ui.some_signal.connect(_on_signal_handler)

func _on_signal_handler(payload):
    print("收到: ", payload)
```

### 7.2 UI 面板模板

```gdscript
extends Control

@onready var _label: Label = $VBox/Label
@onready var _button: Button = $VBox/Button

var _data: Array = []

func _ready():
    _button.pressed.connect(_on_button_pressed)

func set_data(new_data: Array) -> void:
    _data = new_data
    _refresh_display()

func _refresh_display():
    _label.text = "数据: %d 项" % _data.size()

func _on_button_pressed():
    emit_signal("data_submitted", _data)
```

---

## 8. Time 类（时间获取）

**官方文档**：https://docs.godotengine.org/en/stable/classes/class_time.html

```gdscript
# 获取当前日期时间字符串（推荐，最简单）
var date_str = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
# 结果：2026-04-24_14-30-45

# 获取当前日期时间字典
var datetime = Time.get_datetime_dict_from_system()
# 结果：{"year":2026, "month":4, "day":24, "hour":14, "minute":30, "second":45, "weekday":5, "dst":0}

# 获取 Unix 时间戳
var unix = Time.get_unix_time_from_system()

# 手动格式化
var datetime = Time.get_datetime_dict_from_system()
var date_str = "%04d-%02d-%02d_%02d-%02d-%02d" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute, datetime.second]
```

**常用方法速查**：

| 方法 | 返回值 | 说明 |
|------|--------|------|
| `get_datetime_string_from_system()` | String | 当前日期时间 `YYYY-MM-DDTHH:MM:SS` |
| `get_datetime_dict_from_system()` | Dictionary | 当前日期时间 `{year, month, day, hour, minute, second, ...}` |
| `get_date_string_from_system()` | String | 当前日期 `YYYY-MM-DD` |
| `get_unix_time_from_system()` | int | Unix 时间戳（秒） |

---

## 9. 快速排查表

| 问题 | 检查项 |
|------|--------|
| 信号不触发 | 是否用 `emit_signal` 而不是 `EventBus.Publish` |
| get_node 失败 | 节点是否存在，路径是否正确 |
| 空引用 | 确认 `_ready()` 中已赋值 |
| 选牌无响应 | `_selection_enabled` 是否为 true |
| 手牌不显示 | 是否调用 `refresh_hand()` |
| 类型错误 | GDScript 4.3 需要显式类型转换 |

---

## 10. 参考路径

| 模块 | 路径 |
|------|------|
| 场景 | `res://scenes/*.tscn` |
| 脚本 | `res://scripts/**/*.gd` |
| 资源 | `res://resources/*.json` |
| Autoload | `project.godot` 的 `[autoload]` 段 |
