# 问题复盘与经验总结

## 更新记录

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-24 | v1.0 | 初始创建，记录所有已知问题与解决方案 |

---

## 1. 问题清单

### 问题 1：Parser Error - class_name 与 Autoload 冲突

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

当遇到解析错误时，按以下顺序检查：

1. [ ] Autoload Enable 是否全部勾选？
2. [ ] Autoload 脚本是否使用了 class_name？（应移除）
3. [ ] 静态类/RefCounted 是否调用了 get_node()？（改用依赖注入）
4. [ ] 类型化 Array 赋值是否类型匹配？
5. [ ] match 语句中是否有错误的 return？

---

## 5. 后续开发注意事项

1. **任何新增的 Autoload 节点**，不要在脚本中写 `class_name`
2. **任何需要访问场景树的模块**，必须是 `Node` 或通过参数注入
3. **共享的数据结构**（DeckSnapshot、CardSnapshot 等）必须独立成文件
4. **修改 `project.godot` 后**，确认 Autoload Enable 状态
