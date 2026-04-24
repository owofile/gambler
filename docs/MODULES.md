# 模块化架构说明文档

## 概述

本文档展示项目中各模块的**独立职责**、**公开接口**、**依赖关系**。

---

## 模块关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                         SceneRunnerV2                            │
│                    (启动器，协调者)                               │
│  职责：创建模块、连接信号、启动游戏、Logger 日志                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────┐
│   BattleUI      │ │ CardManager│ │DataManager │
│   (界面)         │ │  (卡牌管理) │ │ (注册表)   │
│                 │ │            │ │            │
│  - 显示手牌     │ │ AddCard()  │ │card_registry│
│  - 显示选牌     │ │RemoveCard()│ │enemy_registry│
│  - 按钮响应     │ │GetAllCards()│ │effect_registry│
│                 │ │            │ │cost_registry│
│  直接持有引用    │ │ 直接持有引用 │ │  持有引用  │
└────────┬────────┘ └─────────────┘ └─────────────┘
         │
         │ emit_signal("cards_confirmed")
         │ 直接信号连接
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BattleFlowManager (状态机)                      │
│  职责：管理战斗流程状态、发布 Flow 事件、触发动画、完成战斗           │
│  状态：IDLE → PLAYER_SELECTING → PLAYER_ANIMATING → ENEMY_ANIMATING│
│       → COMPARE_ANIMATING → ROUND_END_ANIMATING → (循环或BATTLE_END)│
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BattleManager (核心战斗逻辑)                    │
│  职责：执行战斗计算（特效、代价）、返回结果                            │
│  方法：ProcessSelectedCards() → 代价累积到 BattleReport              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 模块职责表

### 1. SceneRunnerV2 (协调者)

| 项目 | 说明 |
|------|------|
| 职责 | 创建所有模块，连接信号，启动游戏，日志记录 |
| 创建的节点 | BattleUI, BattleFlowManager, CardSelector, AnimationController, Logger |
| 连接的信号 | BattleUI.cards_confirmed, BattleFlowManager.state_changed, BattleFlowManager.battle_end, BattleFlowManager.round_can_select |
| 调用的方法 | CardManager, BattleFlowManager, BattleManager.ProcessSelectedCards |

### 2. BattleFlowManager (状态机)

| 项目 | 说明 |
|------|------|
| 职责 | 管理战斗流程状态转换，发布 Flow 事件，累积代价 |
| 信号 | state_changed(state), battle_end(report), round_can_select(scores) |
| 状态 | IDLE, PLAYER_SELECTING, PLAYER_ANIMATING, ENEMY_ANIMATING, COMPARE_ANIMATING, ROUND_END_ANIMATING, BATTLE_END |
| 调用的方法 | BattleManager.ProcessSelectedCards(), on_animation_complete() |

### 3. BattleManager (核心逻辑)

| 项目 | 说明 |
|------|------|
| 职责 | 执行战斗计算（特效、代价），返回处理结果 |
| 公开方法 | `ProcessSelectedCards(snapshot, enemy, dataManager) → Dictionary` |
| 依赖 | DataManager (获取注册表) |

### 4. BattleUI (界面)

| 项目 | 说明 |
|------|------|
| 职责 | 显示手牌、处理选牌UI、显示战斗结果 |
| 发送的信号 | `cards_confirmed(Array[String])` |
| 接收的事件 | Flow_BattleStart, Flow_PlayerSelecting, Flow_BattleEnd 等 |

### 4.1 BattleUI_v1 (界面 - Node2D架构)

| 项目 | 说明 |
|------|------|
| 职责 | Node2D架构的卡牌UI，卡片动画与交互 |
| 主文件 | `scenes/battle_ui_v_1.gd` |
| 组件文件 | `scenes/user_card.gd` (卡牌容器组件) |
| 发送的信号 | `cards_confirmed(Array[String])` |
| 接收的事件 | Flow_BattleStart, Flow_PlayerSelecting, Flow_RoundEnd, Flow_BattleEnd 等 |
| 特性 | 鼠标悬停动画、选中高亮、出牌选择 |

### 4.2 CardMgr (Autoload)

| 项目 | 说明 |
|------|------|
| 职责 | 管理玩家卡牌实例（Add/Remove/GetAll/GetSnapshot） |
| 公开方法 | AddCard(prototypeId) → CardInstance, RemoveCard(instanceId) → bool, GetAllCards() → Array, GetDeckSnapshot(ids) → DeckSnapshot, GetDeckSize() → int |
| 访问路径 | `/root/CardMgr` |

### 5. BattleManager (核心逻辑)

| 项目 | 说明 |
|------|------|
| 职责 | 执行战斗计算，返回BattleReport |
| 公开方法 | `StartBattle(playerDeck, enemy, dataManager) → BattleReport` |
| 依赖 | DataManager (获取注册表) |
| **不依赖** | BattleUI, SceneRunner, CardSelector |

---

## 信号 vs 事件（重要区别）

### 信号 (Signal)

**信号是 GDScript 节点的自有特性**，通过 `emit_signal()` 发送：

```gdscript
# BattleUI.gd
signal cards_confirmed(selected_ids: Array[String])

func _on_button_pressed():
    emit_signal("cards_confirmed", selected_ids)
```

**连接信号**（在持有节点的脚本中）：
```gdscript
# SceneRunner.gd
_battle_ui.cards_confirmed.connect(_on_confirmed)
```

### 事件 (EventBus)

EventBus 是全局消息通道，**任何模块可以发布/订阅**：

```gdscript
# 发布
EventBus.Publish("BattleEnded", payload)

# 订阅
EventBus.Subscribe("BattleEnded", _on_battle_ended)
```

### 当前项目的信号和事件

| 发送者 | 方式 | 接收者 | 说明 |
|--------|------|--------|------|
| BattleUI | `emit_signal("cards_confirmed")` | SceneRunner | 选牌确认，**直接信号连接** |
| EventBus | `Publish()` | BattleUI 等 | 全局广播 |

---

## 调用链 vs 信号流

### 调用链（方法调用）

```
SceneRunner
    │
    ├── CardManager.AddCard() ──→ 创建卡牌实例
    │
    ├── BattleManager.StartBattle() ──→ 战斗计算
    │
    └── CardManager.RemoveCard() ──→ 移除卡牌
```

### 信号流（事件通知）

```
BattleUI
    │
    └── emit_signal("cards_confirmed", ids) ──→ SceneRunner（通过信号连接）
```

### 事件流（EventBus广播）

```
BattleManager/SceneRunner
    │
    └── EventBus.Publish("BattleEnded", payload) ──→ 所有订阅者
```

---

## 模块依赖图

```
                    ┌──────────────┐
                    │ DataManager  │
                    │  (Autoload) │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
      ┌────────────┐   ┌───────────┐   ┌────────────┐
      │  CardMgr   │   │  BattleUI │   │BattleManager│
      │ (Autoload) │   │           │   │            │
      └─────┬──────┘   └─────┬─────┘   └────────────┘
            │             │
            │             │
            │        ┌────┴────┐
            │        │SceneRunner│
            │        └────┬────┘
            │             │
            └─────────────┘

           get_node("/root/DataManager")
           get_node("/root/CardMgr")
```

---

## 常见错误对照表

| 错误现象 | 原因 | 解决方法 |
|---------|------|---------|
| 信号不触发 | 信号和事件混淆 | 确认是 `emit_signal` 还是 `EventBus.Publish` |
| get_node 失败 | 节点路径错误或未加载 | 确认节点存在且路径正确 |
| 空引用 | 引用未初始化 | 在 `_ready()` 中确认已赋值 |
| 选牌无法点击 | `_selection_enabled = false` | 调用 `enable_selection(true)` |
| 手牌不显示 | `refresh_hand()` 未调用 | 确认在数据更新后调用 |

---

## 接口速查

### SceneRunner 接口

```gdscript
# 创建模块
_setup_ui()      # 加载 BattleUI 场景
_setup_modules()  # 创建 CardSelector 等

# 连接信号（重要！）
_battle_ui.cards_confirmed.connect(_on_confirmed)  # 直接信号连接
# 注意：不是 EventBus.Subscribe

# 启动游戏
start_game()

# 处理确认
_on_battle_ui_cards_confirmed(selected_ids: Array[String])
```

### BattleUI 接口

```gdscript
# 设置
setup_battle(enemy: EnemyData)    # 初始化，显示敌人信息
enable_selection(enabled: bool)       # 启用/禁用选牌
refresh_hand()                       # 刷新手牌显示

# 接收信号
cards_confirmed(selected_ids)         # 发送信号，SceneRunner 连接此信号

# 事件订阅（EventBus）
Flow_BattleStart, Flow_PlayerSelecting, Flow_BattleEnd 等
```

### CardMgr Interface (Autoload)

```gdscript
# 获取实例
CardMgr.add_card(prototypeId: String) → CardInstance
CardMgr.remove_card(instanceId: String) → bool
CardMgr.get_all_cards() → Array
CardMgr.get_deck_snapshot(ids: Array) → DeckSnapshot
CardMgr.get_deck_size() → int

# 访问方式
get_node("/root/CardMgr").add_card(...)
```

### BattleManager 接口

```gdscript
# 单一入口
BattleManager.StartBattle(snapshot, enemy, dataManager) → BattleReport

# 不依赖 UI 或 SceneRunner
# 只接收 DeckSnapshot 和 EnemyData，返回 BattleReport
```

### EventBus 接口

```gdscript
EventBus.Subscribe(eventType: String, handler: Callable)
EventBus.Publish(eventType: String, payload)
EventBus.Unsubscribe(eventType: String, handler: Callable)
```

---

## 文件位置

| 模块 | 文件 |
|------|------|
| SceneRunner | `scripts/core/SceneRunnerV2.gd` |
| BattleUI | `scripts/ui/BattleUI.gd` |
| BattleUI_v1 | `scenes/battle_ui_v_1.gd` + `scenes/user_card.gd` |
| CardManager | `scripts/core/CardManager.gd` |
| BattleManager | `scripts/core/BattleManager.gd` |
| EventBus | `scripts/core/EventBus.gd` |
| DataManager | `scripts/autoload/DataManager.gd` |
| CardSelector | `scripts/core/CardSelector.gd` |
| AnimationController | `scripts/core/AnimationController.gd` |
| BattleFlowManager | `scripts/core/BattleFlowManager.gd` |

---

## 下一步

如果需要修改或排查问题：

1. **确认模块职责** - 查看上方"模块职责表"
2. **确认调用方式** - 信号用 `emit_signal`，事件用 `EventBus.Publish`
3. **确认依赖关系** - 查看"模块依赖图"

不要让信号和事件混淆！