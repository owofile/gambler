# 问题复盘与经验总结

## 更新记录

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-28 | v1.1 | 新增Godot 4 API变更、OOP封装、_process与await、调试策略等经验 |
| 2026-04-24 | v1.0 | 初始创建，记录所有已知问题与解决方案 |

---

## 1. 问题清单

### 问题 1：Godot 4 `call_deferred()` API 变更

**错误信息**：
```
Parser Error: Invalid argument for "call_deferred()" function: argument 1 should be "StringName" but is "Callable".
```

**根本原因**：
- Godot 4 中 `call_deferred()` 不再接受 `Callable`（lambda）
- 必须使用 `object.call_deferred("method_name", arg1, arg2)` 的字符串方法名语法

**解决方案**：
```gdscript
# 错误写法 - Godot 4 不支持
call_deferred(func(): get_tree().change_scene_to_file(path))

# 正确写法 - 使用字符串方法名
get_tree().call_deferred("change_scene_to_file", path)
```

**经验教训**：
- Godot 4 对 GDScript 语法有重大变更
- 迁移到 Godot 4 时需注意 API 差异
- 官方文档：https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html

---

### 问题 2：RefCounted 类私有属性直接访问

**错误信息**：
```
Invalid access to property or key 'prototype_id' on a base object of type 'RefCounted (CardInstance)'.
```

**根本原因**：
- `CardInstance` 使用私有变量 `_prototype_id` 并提供 getter/setter
- 外部代码（如 SaveManager）直接访问 `card.prototype_id` 违反封装

**解决方案**：
```gdscript
# CardInstance (正确封装的OOP设计)
var _prototype_id: String = ""

func get_prototype_id() -> String:
    return _prototype_id

# 外部访问 (必须使用getter)
card.get_prototype_id()  # ✅
card.prototype_id        # ❌ Parser Error

# Setter 也必须使用
instance.set_delta_value(5)   # ✅
instance.delta_value = 5       # ❌ Parser Error
```

**经验教训**：
- 遵循 OOP 封装原则：数据类必须将属性设为私有，通过 getter/setter 访问
- Godot 4 对属性访问检查更严格
- 所有数据类（RefCounted/Resource）必须实现完整的 getter/setter 封装

---

### 问题 3：`_process` 中使用 `await` 导致输入阻塞

**错误信息**：
- 调试菜单无法响应按键
- ESC/Enter 等按键完全无反应

**根本原因**：
```gdscript
func _process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_up"):
        # await 会阻塞整个 _process 函数 0.2 秒
        await get_tree().create_timer(0.2).timeout
        _move_selection_up()
```

- `_process` 中 `await` 会暂停整个函数
- 暂停期间无法处理其他输入
- `is_action_just_pressed()` 只在按键按下那一帧返回 `true`

**解决方案** - 使用 cooldown 变量代替 await：
```gdscript
var _input_cooldown: float = 0.0
const INPUT_DELAY := 0.2

func _process(delta: float) -> void:
    _input_cooldown = maxf(_input_cooldown - delta, 0.0)
    if _input_cooldown > 0:
        return  # 冷却中，跳过处理

    if Input.is_action_just_pressed("ui_up"):
        _move_selection_up()
        _input_cooldown = INPUT_DELAY  # 设置冷却
```

**经验教训**：
- `_process` 中避免使用 `await`（会阻塞整个函数）
- 使用 cooldown 变量实现延迟效果
- `is_action_just_pressed()` 检测的是"刚按下"状态，不是"按住"状态

---

### 问题 4：GDScript 缩进导致的 Parser Error

**错误信息**：
```
Parser Error: Expected statement, found "Indent" instead.
```

**根本原因**：
- GDScript 对缩进要求严格
- `else:` 必须与对应的 `if` 对齐
- 多余的缩进会导致解析错误

**错误示例**：
```gdscript
func _update_inventory_display() -> void:
    var all_cards = CardMgr.get_all_cards()
        if all_cards.size() == 0:  # ❌ 多了一个缩进
            text += "(空)"
```

**正确写法**：
```gdscript
func _update_inventory_display() -> void:
    var all_cards = CardMgr.get_all_cards()
    if all_cards.size() == 0:  # ✅ 与 var 对齐
        text += "(空)"
```

**经验教训**：
- GDScript 使用 Tab/空格混合时容易出错
- `else`/`elif` 必须与对应的 `if` 缩进一致
- 使用 IDE 的格式化功能保持一致缩进

---

### 问题 5：CanvasLayer `process_mode` 导致输入异常

**现象**：
- 调试菜单的 `_ready()` 打印正常
- 但 `_process` 完全不执行
- 所有输入无响应

**根本原因**：
- 场景文件中设置了 `process_mode = 2`（When Paused）
- 导致节点在暂停状态时不处理输入

**解决方案**：
```ini
# debug.tscn
[node name="DebugMenu" type="CanvasLayer"]
process_mode = 2  # ❌ When Paused - 删除此行

[node name="DebugMenu" type="CanvasLayer"]
# ✅ 默认值 (Inherit) - 正常处理输入
```

**经验教训**：
- Godot 4 CanvasLayer 默认 `process_mode = 0` (Inherit)
- `process_mode = 2` (When Paused) 会导致输入处理异常
- 创建 UI 层时要确保 `process_mode` 正确

---

### 问题 6：Parser Error - class_name 与 Autoload 冲突

**错误信息**：
```
Parser Error: Class "CardManager" hides an autoload singleton.
```

**根本原因**：
- Autoload 在 `project.godot` 中注册后，会成为全局单例
- 脚本中同时使用 `class_name CardManager` 会导致命名冲突

**解决方案**：
- Autoload 脚本移除 `class_name` 声明
- 仅使用 `extends Node`，通过节点名（CardManager）访问

```gdscript
# 错误写法 - Autoload 脚本使用 class_name
class_name CardManager
extends Node
...  # 与 Autoload 节点名冲突

# 正确写法 - Autoload 脚本不使用 class_name
extends Node
...  # 通过节点名 CardManager 访问
```

**经验教训**：
- Autoload 的节点名本身就提供了全局访问，不需要 `class_name`
- 如果需要共享类型，应该将类型定义在独立文件中（如 DeckSnapshot.gd）

---

### 问题 2：RefCounted 类中调用 get_node()

**错误信息**：
```
Parser Error: Function "get_node()" not found in base self.
```

**根本原因**：
- `BattleManager` 继承自 `RefCounted`，不是 Node
- `get_node()` 是 Node 类的方法，RefCounted 没有此方法

**解决方案**：
- 将依赖的节点通过参数传入静态方法
- 或在调用方（Node 类）获取节点后传入

```gdscript
# 错误写法 - RefCounted 中调用 get_node
class_name BattleManager
extends RefCounted

static func StartBattle(player_deck, enemy):
	var dm = get_node("/root/DataManager")  # RefCounted 没有 get_node

# 正确写法 - 通过参数传入依赖
static func StartBattle(player_deck, enemy, data_manager):
	var registry = data_manager.card_registry
```

**经验教训**：
- 静态类/RefCounted 不能直接访问场景树
- 需要依赖注入模式：通过参数传入所需服务

---

### 问题 3：Array 初始化时类型不匹配

**错误信息**：
```
Invalid assignment of property or key 'cards' with value of type 'Array' on a base object of type 'RefCounted (DeckSnapshot)'
```

**根本原因**：
- `DeckSnapshot.cards` 声明为 `Array[CardSnapshot]`
- 赋值时使用 `[]`（无类型数组），类型不匹配

**解决方案**：
- DeckSnapshot 的 `_init()` 中已经初始化了 `cards = []`
- 在外部不需要重新赋值

```gdscript
# 错误写法
var snapshot = DeckSnapshot.new()
snapshot.cards = []  # [] 是无类型数组，与 Array[CardSnapshot] 不兼容

# 正确写法 - 不需要额外赋值
var snapshot = DeckSnapshot.new()
snapshot.deck_id = UUID.v4()
# snapshot.cards 已在 _init() 中初始化
```

**经验教训**：
- GDScript 4.x 对类型检查更严格
- 有类型的 Array 赋值时必须类型匹配
- 在构造函数中初始化的属性，外部不要重复赋值

---

### 问题 4：UUID 生成逻辑错误

**错误信息**：
```
Out of bounds get index '8' (on base: 'Array[int]')
```

**根本原因**：
- UUID v4 需要 16 个字节
- 代码中 `for i in 8` 只创建了 8 个字节

```gdscript
# 错误写法
for i in 8:
	bytes.append(randi() % 256)  # 只有 8 个元素

# bytes[8] 访问越界

# 正确写法
for i in 16:
	bytes.append(randi() % 256)  # 16 个元素
```

**经验教训**：
- 编写代码前应确认数据结构的正确长度
- UUID 是标准格式，应查阅 RFC 4122 确认规范

---

### 问题 5：match 语句中的 return 逻辑错误

**错误信息**：
```
Parser Error: Could not parse global class "EnemyData"
```

**根本原因**：
- `match` 语句中不能用 `return` 跳出匹配
- 错误代码：
```gdscript
static func string_to_tier(s: String) -> EnemyTier:
	match s:
		"Elite": return EnemyTier.Elite
		"Boss": return EnemyTier.Boss
		return EnemyTier.Boss  # 这个 return 在 match 外，逻辑错误
	return EnemyTier.Grunt
```

**解决方案**：
```gdscript
static func string_to_tier(s: String) -> EnemyTier:
	match s:
		"Elite": return EnemyTier.Elite
		"Boss": return EnemyTier.Boss
		_: pass  # 或省略 default 分支
	return EnemyTier.Grunt
```

**经验教训**：
- GDScript 的 match 语句不是haustive 的
- 明确不需要处理的情况用 `_` 或 `pass`

---

### 问题 6：Autoload Enable 未启用

**错误信息**：
```
Parser Error: Identifier "DataManager" not declared in the current scope.
```

**根本原因**：
- Autoload 配置存在但 Enable 列未勾选
- 导致 DataManager 未实际加载

**解决方案**：
- 打开 **Project → Project Settings → Autoload**
- 确保 Enable 列全部打勾

**经验教训**：
- `project.godot` 中的配置和 UI 中的 Enable 状态可能不同步
- 遇到全局变量无法访问时，先检查 Enable 状态

---

## 2. Godot GDScript 关键注意点

### 2.1 class_name 使用规则

| 场景 | 是否可用 class_name |
|------|-------------------|
| Autoload 脚本 | ❌ 否（会与节点名冲突） |
| 独立数据类型（RefCounted） | ✅ 是 |
| 内部类（嵌套在脚本中） | ✅ 是 |

### 2.2 get_node() 调用规则

- **可用**：继承自 `Node` 的类（场景节点、Autoload 节点）
- **不可用**：`RefCounted`、`Resource` 等非 Node 类型

### 2.3 依赖注入模式

当静态类或 RefCounted 需要访问服务时，使用依赖注入：

```gdscript
# 调用方（Node）获取依赖并传入
var data_mgr = get_node("/root/DataManager")
var report = BattleManager.StartBattle(snapshot, enemy, data_mgr)

# BattleManager（RefCounted）通过参数接收
static func StartBattle(player_deck, enemy, data_manager):
	var registry = data_manager.card_registry
```

### 2.4 Autoload 访问方式

```gdscript
# 方式 1：通过节点路径（Node 类可用）
var dm = get_node("/root/DataManager")

# 方式 2：通过节点名（仅限 Autoload，Node 类可用）
# project.godot 中配置了 DataManager="res://..."
# 在其他 Node 中可以直接写 DataManager.xxx
```

### 2.5 Godot 4 `call_deferred()` 语法

```gdscript
# Godot 3.x (Callable lambda)
call_deferred(func(): some_object.method())

# Godot 4.x (必须用字符串方法名)
some_object.call_deferred("method", arg1, arg2)
```

### 2.6 `_process` 中避免 await

```gdscript
# ❌ 错误 - await 会阻塞整个函数
func _process(delta):
    if condition:
        await some_signal

# ✅ 正确 - 使用状态机或cooldown
func _process(delta):
    if _cooldown > 0:
        _cooldown -= delta
        return
    if condition:
        do_action()
        _cooldown = 0.2
```

### 2.7 数据类 OOP 封装规范

所有数据类必须遵循封装原则：

```gdscript
class_name CardInstance
extends RefCounted

# 私有属性
var _prototype_id: String = ""

# Getter (必须)
func get_prototype_id() -> String:
    return _prototype_id

# Setter (必须，验证输入)
func set_prototype_id(value: String) -> void:
    if value.is_empty():
        push_error("Prototype ID cannot be empty")
        return
    _prototype_id = value
```

---

## 3. 代码组织规范

### 3.1 文件命名

- 数据结构文件：`PascalCase.gd`（如 `CardData.gd`、`DeckSnapshot.gd`）
- 管理器/服务：`PascalCase + Manager/Handler.gd`
- 事件负载：`PascalCase + Payload.gd`

### 3.2 类定义位置

| 类型 | 文件位置 |
|------|---------|
| 共享数据结构（供多处引用） | 独立文件，不在内部类中 |
| 仅被单一模块使用 | 可作为内部类 |
| Autoload 服务 | 独立文件，不用 class_name |

### 3.3 避免内部类

```gdscript
# 不推荐 - DeckSnapshot 作为 CardManager 的内部类
class_name CardManager
extends Node
	class DeckSnapshot:  # 外部无法直接引用
		...

# 推荐 - DeckSnapshot 独立成文件
class_name DeckSnapshot
extends RefCounted
	...
```

---

## 4. 调试检查清单

### 解析错误 (Parser Error)
1. [ ] Autoload Enable 是否全部勾选？
2. [ ] Autoload 脚本是否使用了 class_name？（应移除）
3. [ ] 静态类/RefCounted 是否调用了 get_node()？（改用依赖注入）
4. [ ] 类型化 Array 赋值是否类型匹配？
5. [ ] match 语句中是否有错误的 return？
6. [ ] 缩进是否正确？（else 与 if 对齐）
7. [ ] 数据类属性是否使用 getter/setter 访问？

### 运行时错误 (Runtime Error)
1. [ ] `call_deferred()` 是否使用 Godot 4 语法（字符串方法名）？
2. [ ] CanvasLayer 的 `process_mode` 是否正确？
3. [ ] `_process` 中是否有 await 导致阻塞？

### 调试技巧
1. [ ] 在 `_init()`/`_ready()` 中添加 print 确认脚本加载
2. [ ] 在 `_process()` 中添加周期性 print 确认函数执行
3. [ ] 使用 `InputMap.has_action("action_name")` 检查输入映射
4. [ ] 场景节点路径是否正确（`$Panel/InfoLabel` vs `$Panel/VBox/InfoLabel`）

---

## 5. 后续开发注意事项

### OOP 与封装
1. **任何新增的 Autoload 节点**，不要在脚本中写 `class_name`
2. **任何需要访问场景树的模块**，必须是 `Node` 或通过参数注入
3. **共享的数据结构**（DeckSnapshot、CardSnapshot 等）必须独立成文件
4. **修改 `project.godot` 后**，确认 Autoload Enable 状态
5. **数据类必须封装**：所有 RefCounted/Resource 的属性必须是私有的，通过 getter/setter 访问

### Godot 4 迁移注意
1. `call_deferred()` 不再接受 Callable，使用 `object.call_deferred("method", args)`
2. `_process` 中避免使用 `await`，使用 cooldown 变量代替
3. Typed Array 有已知限制，使用无类型 Array + 显式类型转换

### 调试工作流
1. 先确认 `_ready()` 是否执行（添加 print）
2. 再确认 `_process()` 是否执行（添加周期性 print）
3. 检查 InputMap 配置和 process_mode 设置
4. 逐步注释代码隔离问题
