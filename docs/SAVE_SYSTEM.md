# 存档系统设计文档

> **版本**: v1.0
> **日期**: 2026-04-28
> **模块**: SaveManager, WorldState, CardMgr

---

## 1. 概述

### 1.1 设计目标

- **持久化游戏状态**：玩家数据、卡牌、背包、世界进度
- **版本迁移支持**：存档格式变更时自动迁移
- **事件驱动**：存档/读档发布事件，其他模块可订阅响应
- **OOP 封装**：数据类通过 getter/setter 访问，违反 OOP 原则时 Godot 4 会报 Parser Error

### 1.2 核心模块

| 模块 | 职责 | 类型 |
|------|------|------|
| `SaveManager` | 存档/读档核心逻辑 | Autoload |
| `WorldState` | 世界状态（flag 键值对） | Autoload |
| `CardMgr` | 卡牌实例管理 | Autoload |

---

## 2. 架构设计

### 2.1 模块关系图

```
┌─────────────────────────────────────────────────────────────┐
│                     SaveManager                             │
│  (Autoload - 存档/读档核心协调器)                          │
│                                                             │
│  save_game() ──→ _collect_save_data() ──→ JSON文件         │
│  load_game() ──→ JSON文件 ──→ _apply_save_data()           │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  WorldState │ │   CardMgr   │ │  (扩展槽位)  │
│  键值状态    │ │  卡牌实例    │ │  未来扩展    │
└─────────────┘ └─────────────┘ └─────────────┘
```

### 2.2 数据流

**存档流程**：
```
SaveManager.save_game()
    │
    ├── _collect_save_data()
    │       ├── WorldState.get_save_data() → world_state
    │       └── CardMgr.get_all_cards()  → card_instances
    │
    ├── JSON.stringify(save_data)
    │
    └── FileAccess.open(WRITE) → 保存到文件
```

**读档流程**：
```
SaveManager.load_game()
    │
    ├── FileAccess.open(READ) → JSON字符串
    │
    ├── JSON.parse() → save_data
    │
    ├── 版本检查 (_migrate_save_data)
    │
    └── _apply_save_data()
            ├── WorldState.load_save_data()
            ├── CardMgr.clear_all_cards()
            └── CardMgr.add_card() × N
```

---

## 3. SaveManager 详细设计

### 3.1 类定义

```gdscript
## Manages game persistence.
##
## Responsibility:
## - Save/load game state to JSON files
## - Coordinate with WorldState, CardMgr, and other contexts
## - Handle version migration
## - Provide auto-save functionality
##
## Usage:
##   SaveManager.save_game()
##   SaveManager.load_game()
##   SaveManager.auto_save()
##   SaveManager.has_save()
##
## Note: SaveManager is an Autoload singleton.
extends Node
```

### 3.2 常量定义

```gdscript
const SAVE_VERSION: int = 1           # 存档格式版本
const SAVE_DIR: String = "user://saves/"  # 存档目录
const AUTO_SAVE_PATH: String = "user://saves/autosave.json"  # 自动存档路径
const MAX_AUTO_SAVES: int = 3           # 最大自动存档数量（预留）
```

### 3.3 核心接口

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `save_game(path)` | path: String = "" | bool | 手动存档，默认保存到 autosave.json |
| `load_game(path)` | path: String = "" | bool | 读档，默认从 autosave.json 读取 |
| `auto_save()` | - | bool | 自动存档到 autosave.json |
| `has_save(path)` | path: String = "" | bool | 检查存档是否存在 |
| `list_saves()` | - | Array | 列出所有存档文件 |
| `get_last_save_info(path)` | path: String = "" | Dictionary | 获取存档信息（时间、卡牌数等） |
| `delete_save(path)` | path: String | bool | 删除指定存档 |

### 3.4 事件发布

存档系统通过 EventBus 发布以下事件：

| 事件名 | Payload | 触发时机 |
|--------|---------|---------|
| `GameSaved` | `{path, timestamp}` | 存档完成 |
| `GameLoaded` | `{path}` | 读档完成 |

其他模块可订阅这些事件进行响应：

```gdscript
EventBus.subscribe("GameLoaded", _on_game_loaded)

func _on_game_loaded(payload):
    var path = payload["path"]
    # 刷新UI、恢复场景等
```

---

## 4. 存档数据结构

### 4.1 JSON Schema

```json
{
  "version": 1,
  "timestamp": 1745798400,
  "current_zone": "res://scenes/Thryzhn/TestScenes/cave/cave/cave.tscn",
  "player_position": {
    "x": 100.0,
    "y": 200.0
  },
  "world_state": {
    "flag_key": "flag_value"
  },
  "card_instances": [
    {
      "prototype_id": "card_rusty_sword",
      "delta_value": 0,
      "bind_status": 0
    }
  ]
}
```

### 4.2 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `version` | int | 是 | 存档格式版本，用于版本迁移 |
| `timestamp` | int | 是 | Unix 时间戳 |
| `current_zone` | String | 否 | 当前场景路径 |
| `player_position` | Object | 否 | 玩家坐标 {x, y} |
| `world_state` | Object | 否 | 世界状态键值对 |
| `card_instances` | Array | 否 | 卡牌实例数组 |

### 4.3 卡牌数据结构

```json
{
  "prototype_id": "card_rusty_sword",
  "delta_value": 0,
  "bind_status": 0
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `prototype_id` | String | 卡牌原型ID，对应 card_prototypes.json |
| `delta_value` | int | 强化带来的点数变化 |
| `bind_status` | int | 0=None, 1=Locked, 2=Cursed |

---

## 5. WorldState 详细设计

### 5.1 类定义

```gdscript
## WorldState - Key-value state management for the World Context.
##
## Responsibility:
## - Store all game progress as key-value pairs
## - Support flag-based storytelling
## - Provide snapshot for save/load
## - Publish WorldFlagChanged events
##
## Usage:
##   WorldState.set_flag("npc_merchant_dead", true)
##   WorldState.set_flag("quest_progress", 3)
##   if WorldState.get_flag("npc_merchant_dead", false):
##       ...
##
## Note: WorldState is an Autoload singleton.
extends Node
```

### 5.2 核心接口

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `set_flag(key, value)` | key: String, value: Variant | void | 设置 flag |
| `get_flag(key, default)` | key: String, default: Variant | Variant | 获取 flag，默认值 |
| `has_flag(key)` | key: String | bool | 检查 flag 是否存在 |
| `remove_flag(key)` | key: String | void | 删除 flag |
| `get_all_flags()` | - | Dictionary | 获取所有 flags 副本 |
| `clear_all_flags()` | - | void | 清空所有 flags |
| `get_save_data()` | - | Dictionary | 获取存档数据 |
| `load_save_data(data)` | data: Dictionary | bool | 加载存档数据 |

### 5.3 事件发布

```gdscript
EventBus.publish("WorldFlagChanged", {
    "flag_name": key,
    "new_value": value,
    "old_value": old_value
})
```

---

## 6. 扩展指南

### 6.1 添加新的存档数据

**步骤 1**：修改 `_collect_save_data()`

```gdscript
func _collect_save_data() -> Dictionary:
    # ... 现有代码 ...

    return {
        "version": SAVE_VERSION,
        "timestamp": timestamp,
        # ... 现有字段 ...
        "new_field": _collect_new_data()  # 新增
    }
```

**步骤 2**：修改 `_apply_save_data()`

```gdscript
func _apply_save_data(data: Dictionary) -> void:
    # ... 现有代码 ...

    if data.has("new_field"):
        _apply_new_data(data["new_field"])
```

**步骤 3**：更新版本号（必要时）

```gdscript
const SAVE_VERSION: int = 2  # 递增版本号
```

### 6.2 添加新的存档模块（如背包系统）

**步骤 1**：创建管理器并实现 `get_save_data()` 和 `load_save_data()`

```gdscript
class_name InventoryManager
extends Node

func get_save_data() -> Dictionary:
    return {"items": _items}

func load_save_data(data: Dictionary) -> void:
    _items = data.get("items", [])
```

**步骤 2**：在 `SaveManager` 中集成

```gdscript
func _collect_save_data() -> Dictionary:
    var inventory_data = {}
    if InventoryManager:
        inventory_data = InventoryManager.get_save_data()
    return {
        # ...
        "inventory": inventory_data
    }
```

---

## 7. 版本迁移

### 7.1 迁移机制

当存档版本与代码版本不匹配时，调用 `_migrate_save_data()`：

```gdscript
func _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    match from_version:
        1:
            data = _migrate_from_v1_to_v2(data)
        2:
            data = _migrate_from_v2_to_v3(data)
        # ... 更多迁移 ...
    return data
```

### 7.2 迁移示例

```gdscript
func _migrate_from_v1_to_v2(data: Dictionary) -> Dictionary:
    # v1 没有 gold 字段，v2 需要添加默认值
    if not data.has("gold"):
        data["gold"] = 0
    # v1 的 card_instances 可能有旧格式，需要转换
    data["card_instances"] = _convert_card_format_v1_to_v2(data.get("card_instances", []))
    return data
```

---

## 8. 最佳实践

### 8.1 OOP 封装

所有数据类必须遵循封装原则：

```gdscript
# CardInstance.gd - 正确封装
class_name CardInstance
extends RefCounted

var _prototype_id: String = ""

func get_prototype_id() -> String:
    return _prototype_id

func set_prototype_id(value: String) -> void:
    if value.is_empty():
        push_error("Prototype ID cannot be empty")
        return
    _prototype_id = value
```

```gdscript
# SaveManager.gd - 必须使用 getter/setter
func _collect_save_data() -> Dictionary:
    for card in all_cards:
        card_data.append({
            "prototype_id": card.get_prototype_id(),  # ✅ 正确
            # card.prototype_id  # ❌ Godot 4 会报 Parser Error
        })
```

### 8.2 异步处理

存档操作可能较慢，应在主线程执行：

```gdscript
func save_game_async() -> void:
    await save_game()
    EventBus.publish("GameSaved", {...})
```

### 8.3 错误处理

```gdscript
func save_game(path: String = "") -> bool:
    if _is_loading:
        push_error("[SaveManager] Cannot save while loading")
        return false

    if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
        push_error("[SaveManager] Failed to overwrite existing save")
        return false

    return true
```

---

## 9. 待办事项

- [ ] 背包系统 (InventoryManager) - 道具、消耗品管理
- [ ] 多槽位存档 - 支持多个存档位
- [ ] 存档压缩 - 大型存档的压缩存储
- [ ] 云存档同步 - 未来扩展

---

## 10. 相关文档

- [MODULES.md](./MODULES.md) - 模块架构总览
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 项目架构文档
- [RETROSPECTIVE.md](./RETROSPECTIVE.md) - 问题复盘与经验总结
