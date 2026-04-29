# 模块化架构说明文档

## 更新记录

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-29 | v4.2 | 新增物品背包系统(InvMgr)、销毁动画优化、Shader着色器动画、战斗结算修复 |
| 2026-04-28 | v4.1 | InputManager全局输入、调试菜单重构(OOP)、SaveManager修复OOP封装、调试菜单UI改进 |
| 2026-04-28 | v4.0 | 新增调试菜单(DebugMenu)、卡牌背包系统、存档系统重构、移hardcoded初始卡牌 |
| 2026-04-27 | v3.5 | 新增 EFFECTS_SYSTEM.md 设计文档（Phase 1-3 计划，Buff系统、目标选择、执行顺序） |
| 2026-04-27 | v3.4 | 运行时错误修复：着色器丢失、SceneManager静态调用、CardSelector缺失变量、主菜单音量加载 |
| 2026-04-27 | v3.3 | 对话UI系统重构(DialogueSystem/DialogueUI)，MVC模式 |
| 2026-04-27 | v3.2 | 新增MapManager、QuestManager、示例配置JSON |
| 2026-04-27 | v3.1 | 新增事件总线增强（幂等+确认机制）、WorldState、SaveManager、NarrativeEngine |

---

## 系统架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Autoload Layer                                  │
│  DataManager → CardMgr → EventBus → GameState → WorldState → SaveManager    │
│  → MapManager → QuestManager → SceneChanger → InputManager                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           World Context (世界上下文)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ WorldState  │  │ SaveManager │  │ MapManager  │  │ QuestManager│        │
│  │  键值状态   │  │   存档管理   │  │   地图管理   │  │   任务系统   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Narrative Context (叙事上下文)                        │
│  ┌───────────────────┐        ┌───────────────────┐                         │
│  │  NarrativeEngine  │───────▶│  DialogueSystem   │                         │
│  │   (逻辑/规则引擎)  │        │   (Orchestrator)  │                         │
│  └───────────────────┘        └─────────┬─────────┘                         │
│                                          │                                   │
│                              ┌───────────┴───────────┐                       │
│                              ▼                       ▼                       │
│                      ┌─────────────┐        ┌─────────────┐                │
│                      │DialogueBox  │        │  ItemBar    │                │
│                      │  (视图)     │        │  (选项UI)   │                │
│                      └─────────────┘        └─────────────┘                │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Battle Context (战斗上下文)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │BattleManager│  │BattleFlow   │  │CardSelector │  │  BattleUI   │        │
│  │  (核心逻辑)  │  │  Manager    │  │  (选牌)     │  │  (界面)     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Card Context (卡牌上下文)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                          │
│  │ CardManager │  │CardInstance │  │  Registry   │                          │
│  │  (仓库管理)  │  │  (卡牌实例)  │  │  (原型注册)  │                          │
│  └─────────────┘  └─────────────┘  └─────────────┘                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. 战斗上下文 (Battle Context)

**核心文件**:
- `scripts/core/BattleManager.gd` - 战斗核心逻辑
- `scripts/core/BattleFlowManager.gd` - 战斗状态机
- `scripts/core/CardSelector.gd` - 选牌管理
- `scripts/ui/BattleUI.gd` / `scenes/battle_ui_v_1.gd` - 战斗界面

**对外接口**:
```gdscript
BattleManager.StartBattle(playerDeck, enemy) -> BattleReport
BattleFlowManager.start_battle()
BattleFlowManager.confirm_selection()
```

---

## 2. 卡牌上下文 (Card Context)

**核心文件**:
- `scripts/core/CardManager.gd` - 卡牌管理
- `scripts/data/CardInstance.gd` - 卡牌实例
- `scripts/data/CardPrototypeRegistry.gd` - 原型注册表

**对外接口**:
```gdscript
CardMgr.add_card(prototype_id) -> CardInstance
CardMgr.remove_card(instance_id) -> bool
CardMgr.get_all_cards() -> Array
CardMgr.get_deck_snapshot(ids) -> DeckSnapshot
CardMgr.clear_all_cards()  # 存档用
```

---

## 3. 叙事上下文 (Narrative Context) v3.3

**核心文件**:
- `scripts/dialogue/NarrativeEngine.gd` - 对话树逻辑/规则引擎
- `scripts/dialogue/DialogueSystem.gd` - 统一调度器 (Orchestrator)
- `scenes/Thryzhn/UI_Scenes/dialogue/dialogue.tscn` - UI组件

**MVC架构**:

| 角色 | 组件 | 职责 |
|------|------|------|
| Model | NarrativeEngine | 对话树解析、条件评估、效应执行 |
| View | DialogueBoxParent, ItemBar | 文字显示、选项展示 |
| Controller | DialogueSystem | 协调Model和View，管理游戏状态 |

**使用方式**:
```gdscript
# 简单对话
EventBus.publish("StartDialogue", {"lines": ["Hello!", "Bye!"]})

# 树形对话
EventBus.publish("StartDialogueTree", {
    "path": "res://dialogues/merchant.json",
    "start_node": "start"
})

# 前进/确认
DialogueSystem.advance()
DialogueSystem.select_option(index)
```

**条件类型**: HasFlag, HasItem, DeckSizeGE, NpcAlive, Comparison

**效应类型**: SetFlag, GiveItem, RemoveItem, StartBattle, TriggerDialogue, KillNpc, GiveGold, TakeGold

---

## 4. 世界上下文 (World Context) v3.2

**核心文件**:
- `scripts/world/WorldState.gd` - 键值状态
- `scripts/world/SaveManager.gd` - 存档管理
- `scripts/world/MapManager.gd` - 地图/区域管理
- `scripts/world/QuestManager.gd` - 任务管理

### WorldState
```gdscript
WorldState.set_flag(key, value)
WorldState.get_flag(key, default)
WorldState.has_flag(key)
```

### SaveManager
```gdscript
SaveManager.save_game()
SaveManager.load_game() -> bool
SaveManager.auto_save() -> bool
SaveManager.has_save() -> bool
```

### MapManager
```gdscript
MapManager.load_zone_config()
MapManager.load_zone(zone_id) -> bool
MapManager.teleport_to(tp_id) -> bool
MapManager.is_zone_unlocked(zone_id) -> bool
MapManager.get_current_zone() -> String
```

### QuestManager
```gdscript
QuestManager.load_quest_config()
QuestManager.start_quest(quest_id) -> bool
QuestManager.get_quest_info(quest_id) -> Dictionary
QuestManager.get_active_quests() -> Array
# 自动监听BattleEnded, CardAcquired, WorldFlagChanged等事件更新进度
```

---

## 5. 事件总线 (EventBus)

### 基础API (向后兼容)
```gdscript
EventBus.subscribe(event_type, handler)
EventBus.publish(event_type, payload)
```

### 幂等性 (v3.1)
```gdscript
# 相同event_id的事件不会重复处理
EventBus.publish("BattleEnded", {"event_id": "unique_123", ...})
```

### 命令+确认模式 (v3.1)
```gdscript
# 发布者等待所有订阅者确认
var success = EventBus.publish_with_ack("BattleEnded", payload, 5000)

# 订阅者必须调用ack()
EventBus.subscribe_with_ack("BattleEnded", _handler)
func _handler(payload):
    EventBus.ack(payload["event_id"])
```

---

## 6. 标准化事件列表

| 事件名 | 类型 | 触发时机 |
|--------|------|---------|
| `BattleEnded` | Ack | 战斗结算完成 |
| `CardAcquired` | Basic | 获得卡牌 |
| `CardLost` | Basic | 失去卡牌 |
| `WorldFlagChanged` | Basic | Flag变化 |
| `DialogueNodeShown` | Basic | 显示对话节点 |
| `DialogueOptionSelected` | Basic | 选择对话选项 |
| `DialogueEnded` | Basic | 对话结束 |
| `BattleRequested` | Basic | 请求战斗 |
| `GameModeChanged` | Basic | 模式切换 |
| `QuestStarted` | Basic | 任务开始 |
| `QuestCompleted` | Basic | 任务完成 |
| `ZoneLoaded` | Basic | 区域加载 |
| `ZoneUnlocked` | Basic | 区域解锁 |
| `GameSaved` | Basic | 存档完成 |
| `GameLoaded` | Basic | 读档完成 |

---

## 7. 状态持久化

### 存档结构
```json
{
  "version": 1,
  "timestamp": 1234567890,
  "current_zone": "zone_village",
  "player_position": {"x": 100, "y": 200},
  "world_state": { "flag1": true, "flag2": 3 },
  "card_instances": [
    {"prototype_id": "card_sword", "delta_value": 0, "bind_status": 0}
  ],
  "active_quests": ["quest_1"],
  "completed_quests": ["quest_0"]
}
```

### 加载顺序
```
SaveManager.load_game()
    ↓
WorldState.load_save_data()
    ↓
CardMgr.clear_all_cards() → CardMgr.add_card()
    ↓
QuestManager.load_save_data()
    ↓
MapManager.load_save_data()
```

---

## 8. Autoload 顺序与依赖

```
DataManager (无依赖)
    ↓
CardMgr (依赖DataManager)
    ↓
EventBus (无依赖)
    ↓
GameState (无依赖)
    ↓
WorldState (无依赖)
    ↓
SaveManager (依赖WorldState, CardMgr)
    ↓
MapManager (依赖WorldState)
    ↓
QuestManager (依赖WorldState, CardMgr, EventBus)
    ↓
SceneChanger (无依赖)
    ↓
InputManager (无依赖)
```

---

## 9. 目录结构 (v4.0)

```
gambler/
├── scripts/
│   ├── core/
│   │   ├── BattleManager.gd
│   │   ├── BattleFlowManager.gd
│   │   ├── CardManager.gd
│   │   ├── CardSelector.gd
│   │   ├── EventBus.gd
│   │   ├── GameStateManager.gd
│   │   ├── Logger.gd
│   │   └── SceneRunnerV2.gd
│   ├── data/
│   │   ├── CardData.gd
│   │   ├── CardInstance.gd
│   │   ├── CardSnapshot.gd
│   │   ├── DeckSnapshot.gd
│   │   ├── EffectContext.gd
│   │   ├── CostContext.gd
│   │   └── ...
│   ├── effects/                   # 特效系统 (v3.5 设计文档)
│   │   ├── IEffectHandler.gd     # 特效接口（核心契约）
│   │   ├── FixedBonusEffect.gd   # 固定加成
│   │   └── RuleReversalEffect.gd # 规则反转
│   ├── costs/                     # 代价系统
│   │   ├── ICostHandler.gd
│   │   ├── NextTurnUnusableCost.gd
│   │   └── SelfDestroyCost.gd
│   ├── dialogue/
│   │   ├── NarrativeEngine.gd    # Model
│   │   ├── DialogueSystem.gd     # Controller
│   │   └── DialogueUI.gd
│   ├── world/
│   │   ├── WorldState.gd
│   │   ├── SaveManager.gd
│   │   ├── MapManager.gd
│   │   ├── QuestManager.gd
│   │   └── WorldManager.gd
│   ├── player/
│   │   ├── PlayerController.gd
│   │   └── PlayerStateMachine.gd
│   └── autoload/
│       ├── DataManager.gd
│       ├── CardMgr.gd
│       ├── EventBus.gd
│       └── InputManager.gd
├── scenes/
│   ├── Thryzhn/
│   │   ├── MainMenu/
│   │   ├── UI_Scenes/
│   │   │   ├── dialogue/
│   │   │   ├── settings/
│   │   │   └── debug/            # 调试菜单 (v4.0)
│   │   │       ├── debug.tscn
│   │   │       └── gd/debug_menu.gd
│   │   ├── Player/
│   │   ├── SceneChanger/
│   │   └── TestScenes/cave/
│   ├── BattleUI_v1.tscn
│   └── Battle_UI_v1.tscn
├── resources/
│   ├── card_prototypes.json       # 卡牌原型配置
│   └── enemy_registry.json        # 敌人配置
├── dialogues/                     # 对话树JSON
│   └── merchant.json
├── config/                        # 游戏配置
│   ├── zones.json
│   └── quests.json
├── Shader/
│   └── Grass_Sway.gdshader
└── docs/
    ├── ARCHITECTURE.md
    ├── MODULES.md
    ├── EFFECTS_SYSTEM.md          # 特效系统设计文档 (v3.5)
    └── SAVE_SYSTEM.md             # 存档系统设计文档 (v1.0)
```
gambler/
├── scripts/
│   ├── core/
│   │   ├── BattleManager.gd
│   │   ├── BattleFlowManager.gd
│   │   ├── CardManager.gd
│   │   ├── CardSelector.gd
│   │   ├── EventBus.gd
│   │   ├── GameStateManager.gd
│   │   ├── Logger.gd
│   │   └── SceneRunnerV2.gd
│   ├── data/
│   │   ├── BattleReport.gd
│   │   ├── CardData.gd
│   │   ├── CardInstance.gd
│   │   ├── CardSnapshot.gd
│   │   ├── DeckSnapshot.gd
│   │   ├── EffectContext.gd
│   │   ├── CostContext.gd
│   │   └── ...
│   ├── effects/                   # 特效系统 (v3.5 设计文档)
│   │   ├── IEffectHandler.gd     # 特效接口（核心契约）
│   │   ├── FixedBonusEffect.gd   # 固定加成
│   │   └── RuleReversalEffect.gd # 规则反转
│   ├── costs/                     # 代价系统
│   │   ├── ICostHandler.gd
│   │   ├── NextTurnUnusableCost.gd
│   │   └── SelfDestroyCost.gd
│   ├── dialogue/
│   │   ├── NarrativeEngine.gd    # Model
│   │   ├── DialogueSystem.gd     # Controller
│   │   └── DialogueUI.gd
│   ├── world/
│   │   ├── WorldState.gd
│   │   ├── SaveManager.gd
│   │   ├── MapManager.gd
│   │   ├── QuestManager.gd
│   │   └── WorldManager.gd
│   ├── player/
│   │   ├── PlayerController.gd
│   │   └── PlayerStateMachine.gd
│   └── autoload/
│       ├── DataManager.gd
│       ├── CardMgr.gd
│       ├── EventBus.gd
│       └── InputManager.gd
├── scenes/
│   ├── Thryzhn/
│   │   ├── MainMenu/
│   │   ├── UI_Scenes/
│   │   │   ├── dialogue/
│   │   │   └── settings/
│   │   ├── Player/
│   │   └── SceneChanger/
│   ├── BattleUI_v1.tscn
│   └── Battle_UI_v1.tscn
├── resources/
│   ├── card_prototypes.json       # 卡牌原型配置
│   └── enemy_registry.json        # 敌人配置
├── dialogues/                     # 对话树JSON
│   └── merchant.json
├── config/                        # 游戏配置
│   ├── zones.json
│   └── quests.json
├── Shader/
│   └── Grass_Sway.gdshader
└── docs/
    ├── ARCHITECTURE.md
    ├── MODULES.md
    ├── EFFECTS_SYSTEM.md          # 特效系统设计文档 (v3.5)
    ├── SAVE_SYSTEM.md             # 存档系统设计文档 (v1.0)
    └── BATTLE_SYSTEM.md           # 战斗系统设计文档 (v1.0)
```

---

## 10. 设计原则 (OOP & 模块化)

### 单一职责原则 (SRP)
- 每个类只做一件事
- NarrativeEngine 不直接操作UI，只发布事件
- DialogueSystem 作为Orchestrator协调各组件

### 依赖倒置原则 (DIP)
- 上层模块依赖抽象（事件接口）
- 不直接依赖具体实现

### 迪米特法则 (LoD)
- 模块只与直接朋友通信
- NarrativeEngine 只知道 DialogueSystem
- DialogueSystem 只知道 NarrativeEngine + UI组件

### 聚合根保护
- WorldState 是 WorldContext 的聚合根
- 外部只能通过 WorldState 访问/修改状态

### 事件驱动解耦
- 模块间通过 EventBus 异步通信
- 新增功能只需添加事件订阅者

---

## 11. 新游戏流程 (v4.0)

### 11.1 游戏启动流程

```
主菜单
    ↓
[开始游戏] → 清空状态 → 自动创建存档 → 进入游戏世界
    ↓
[设置] → 打开设置界面
```

### 11.2 新游戏初始化

开始新游戏时执行：
```gdscript
WorldState.clear_all_flags()   # 清空世界状态
CardMgr.clear_all_cards()       # 清空卡牌背包
SaveManager.auto_save()         # 创建初始存档（空卡牌）
```

### 11.3 调试菜单

**文件**:
- `scenes/Thryzhn/UI_Scenes/debug/debug.tscn` - 调试菜单场景
- `scenes/Thryzhn/UI_Scenes/debug/gd/debug_menu.gd` - 调试菜单脚本
- `scripts/autoload/InputManager.gd` - 全局输入管理器

**打开方式**: 按 `ui_DebugMenu`（默认 F1）

**输入映射**（需在 Project Settings 中配置）:
| Action | 用途 |
|--------|------|
| `ui_DebugMenu` | 打开/关闭调试菜单 |
| `ui_DebugMenu_Up` | 上移选择 |
| `ui_DebugMenu_Down` | 下移选择 |
| `ui_DebugMenu_Accept` | 确认/执行 |
| `ui_DebugMenu_Cancel` | 返回（先关闭库存面板，再关闭菜单） |

**功能**:
| 选项 | 说明 |
|------|------|
| 存档 | 调用 `SaveManager.auto_save()` |
| 读档 | 调用 `SaveManager.load_game()` |
| 添加随机卡牌 | 从卡牌原型库随机添加一张到背包 |
| 显示背包 | 打开/关闭库存面板 |

**OOP设计**:
- `_handle_cancel()` - 优先关闭库存面板，再关闭菜单
- `_close_inventory()` - 专门负责关闭库存面板
- `_back()` - 专门负责关闭菜单

### 11.4 卡牌背包系统

**文件**: `scripts/core/CardManager.gd` (Autoload)

**接口**:
```gdscript
CardMgr.add_card(prototype_id)     # 添加卡牌
CardMgr.remove_card(instance_id)    # 移除卡牌（锁定卡不可移除）
CardMgr.get_all_cards()            # 获取所有卡牌
CardMgr.get_deck_size()            # 背包卡牌数量
CardMgr.clear_all_cards()          # 清空背包
CardMgr.MAX_DECK_SIZE              # 最大容量 = 20
```

### 11.5 存档系统

**文件**: `scripts/world/SaveManager.gd` (Autoload)

**接口**:
```gdscript
SaveManager.save_game(path)        # 手动存档
SaveManager.load_game(path)         # 读档
SaveManager.auto_save()            # 自动存档到 autosave.json
SaveManager.has_save()             # 检查存档是否存在
SaveManager.list_saves()           # 列出所有存档
SaveManager.get_last_save_info()   # 获取存档信息
```

**存档数据结构**:
```json
{
  "version": 1,
  "timestamp": 1234567890,
  "current_zone": "zone_village",
  "player_position": {"x": 100, "y": 200},
  "world_state": { "flag1": true, "flag2": 3 },
  "card_instances": [
    {"prototype_id": "card_sword", "delta_value": 0, "bind_status": 0}
  ],
  "inventory": {
    "version": 1,
    "items": [
      {"instance_id": "xxx", "prototype_id": "item_potion_health", "quantity": 3, "metadata": {}}
    ]
  }
}
```

### 11.6 物品背包系统

**文件**: `scripts/core/InventoryManager.gd` (Autoload: InvMgr)

**接口**:
```gdscript
InvMgr.add_item(prototype_id, quantity=1)  # 添加物品（自动堆叠）
InvMgr.remove_item(instance_id, quantity=1) # 移除物品（减少数量）
InvMgr.remove_item_by_prototype(prototype_id, quantity=1) # 按原型移除
InvMgr.has_item(prototype_id)              # 检查是否有该物品
InvMgr.get_item_count(prototype_id)        # 获取物品数量
InvMgr.get_item(instance_id)               # 获取物品实例
InvMgr.get_all_items()                     # 获取所有物品
InvMgr.get_inventory_size()               # 背包格数
InvMgr.is_full()                           # 背包是否已满
InvMgr.clear_all_items()                  # 清空背包
InvMgr.MAX_SIZE                            # 最大容量 = 99
```

**数据类**:

```gdscript
ItemInstance (RefCounted)
├── get_id() / set_id()                    # 实例ID（不是get_instance_id）
├── get_prototype_id() / set_prototype_id()
├── get_quantity() / set_quantity()
├── add_quantity(amount) / remove_quantity(amount)
├── get_metadata(key) / set_metadata(key, value)
└── to_dict() / from_dict()  # 存档序列化

ItemData (RefCounted - 原型定义)
├── prototype_id, display_name, description
├── item_type: ItemType.Type (None, Consumable, Equipment, QuestItem, Material, KeyItem)
├── max_stack: int (默认99)
├── icon_path, is_droppable, is_discardable
├── is_consumable() / is_equipment() / is_quest_item()
├── can_stack()
└── to_dict() / from_dict()

ItemType (RefCounted - 枚举)
├── Type.None = 0
├── Type.Consumable = 1    # 消耗品
├── Type.Equipment = 2     # 装备
├── Type.QuestItem = 3     # 任务物品
├── Type.Material = 4      # 材料
├── Type.KeyItem = 5       # 关键物品
├── type_to_string() / string_to_type()
```

**原型注册表**: `scripts/data/ItemPrototypeRegistry.gd`
```gdscript
DataManager.item_registry  # ItemPrototypeRegistry 实例 (通过DataManager访问)
├── register_item(ItemData)
├── get_prototype(prototype_id) -> ItemData
├── has_prototype(prototype_id) -> bool
├── unregister_item(prototype_id)
├── get_all_prototypes() -> Array
└── get_count() -> int
```

**示例物品原型** (`resources/item_prototypes.json`):
| 原型ID | 名称 | 类型 | 可堆叠 |
|--------|------|------|--------|
| item_potion_health | 生命药水 | Consumable | 10 |
| item_potion_mana | 魔法药水 | Consumable | 10 |
| item_sword_basic | 新手剑 | Equipment | 1 |
| item_key_dungeon | 地牢钥匙 | KeyItem | 1 |
| item_iron_ore | 铁矿 | Material | 99 |
| item_quest_scroll | 古老卷轴 | QuestItem | 1 |

---

## 12. 待办事项

- [x] InputManager - 全局输入管理器，F1键触发调试菜单
- [x] 调试菜单 (DebugMenu) - 存档、读档、添加卡牌、背包显示
- [x] 物品背包系统 (InvMgr) - 消耗品、装备、任务物品管理
- [ ] 继续游戏按钮 - 主菜单增加"继续"选项检测存档
- [ ] 自动存档触发器 - 区域切换时自动存档
- [ ] ChapterManager - 章节/进度系统
- [ ] NPC系统 - NPC状态、位置、交互
- [ ] 商店系统 - 基于对话树的商品购买
- [ ] UI响应式布局 - 适配不同分辨率
- [ ] 背包UI - 物品背包界面显示和交互
