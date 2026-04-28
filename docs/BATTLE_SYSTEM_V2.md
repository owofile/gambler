# 战斗模块 v2.0 设计文档

> **版本**: v2.1
> **日期**: 2026-04-28
> **模块**: BattleCore, BattleState, BattleUI (Interface), CardDeckManager
> **状态**: ✅ 测试通过，生产可用

---

## 0. 现有UI兼容性分析

### 0.1 现有UI问题 (battle_ui_v_1.gd)

| 问题 | 说明 | 影响 |
|------|------|------|
| 紧耦合 | 内部创建 `BattleRunner` | 无法独立使用新架构 |
| 无动画接口 | 没有 `play_animation` 钩子 | 无法插入动画 |
| 非被动接收 | UI 控制部分状态流转 | 与状态机设计冲突 |
| 不实现接口 | 未实现 `IBattleUI` | 无法对接 BattleCore |

### 0.2 结论

**现有UI需要重写或大幅改造**。建议：
- 新建 `BattleUI_V2` 实现 `IBattleUI`
- 保留原UI作为参考/回退
- 新UI完全被动接收 BattleCore 的指令

### 0.3 新UI职责

```
BattleCore (状态机)
    │
    ├──→ ui_show_hand(cards)          # 显示手牌
    ├──→ ui_highlight_card(id, bool)  # 高亮卡牌
    ├──→ ui_show_enemy_cards(cards)   # 显示敌方卡牌
    ├──→ ui_show_settlement(...)       # 显示结算
    ├──→ ui_clear_selection()          # 清空选择
    ├──→ ui_show_battle_result(result) # 显示战斗结果
    └──→ ui_enable_selection(bool)     # 启用/禁用选择

BattleUI_V2 → 发出信号:
    ├──→ card_selected(card_id)
    ├──→ card_deselected(card_id)
    ├──→ selection_confirmed(card_ids)
    └──→ animation_finished(anim_name)
```

---

## 1. 设计目标

1. **OOP + 状态机**：所有战斗流程都是状态，动画是状态的延续
2. **无硬编码**：所有数值、规则可配置
3. **模块化**：每个职责分离，方便调试和扩展
4. **支持动画**：状态转换触发动画，动画完成后进入下一状态

---

## 2. 核心状态机

```
┌─────────────────────────────────────────────────────────────┐
│                     BattleCore                                │
│  (主状态机，控制战斗生命周期)                                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    BattleState                                │
│  (所有状态的基类，定义 enter/exit/update 接口)               │
└─────────────────────────────────────────────────────────────┘
                  │
        ┌────────┴────────┐
        ▼                 ▼
┌───────────────┐  ┌───────────────┐
│  IdleState   │  │ PlayerSelect  │
│  (空闲/等待)  │  │  (玩家选牌)   │
└───────────────┘  └───────┬───────┘
                           │
                           ▼
                  ┌───────────────┐
                  │ EnemyReveal   │
                  │  (敌方出牌)   │
                  └───────┬───────┘
                          │
                          ▼
                  ┌───────────────┐
                  │   Settlement   │
                  │    (结算)      │
                  └───────┬───────┘
                          │
                          ▼
                  ┌───────────────┐
                  │ RoundEnd      │
                  │  (回合结束)   │
                  └───────┬───────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
    ┌───────────────┐           ┌───────────────┐
    │ ContinueLoop  │           │  BattleEnd    │
    │ (继续下一轮)  │           │  (战斗结束)   │
    └───────────────┘           └───────────────┘
```

---

## 3. 状态定义

### 3.1 IdleState
- **进入条件**: 战斗未开始或刚结束
- **职责**: 等待战斗启动
- **退出条件**: 调用 `start_battle()` 后进入 `PlayerSelect`

### 3.2 PlayerSelectState
- **进入条件**: 回合开始，玩家需要选牌
- **职责**: 显示手牌，接收玩家选择
- **退出条件**: 玩家确认出牌后进入 `EnemyReveal`
- **动画支持**:
  - `on_enter()`: 触发"显示手牌"动画
  - `on_card_selected()`: 触发"卡牌高亮"动画

### 3.3 EnemyRevealState
- **进入条件**: 玩家已确认出牌
- **职责**: 敌方生成并展示出牌
- **退出条件**: 展示完成后进入 `Settlement`
- **动画支持**:
  - `on_enter()`: 触发"敌方出牌"动画
  - `on_animation_complete()`: 动画完成，进入下一状态

### 3.4 SettlementState
- **进入条件**: 双方出牌就绪
- **职责**: 结算点数，判定胜负
- **退出条件**: 结算完成后进入 `RoundEnd`
- **动画支持**:
  - `on_enter()`: 触发"对战动画"
  - `on_settle_complete()`: 结算完成

### 3.5 RoundEndState
- **进入条件**: 回合结算完成
- **职责**: 处理卡牌消耗、补充手牌、更新分数
- **退出条件**: 检测战斗是否结束
  - 未结束 → `ContinueLoop` → 回到 `PlayerSelect`
  - 已结束 → `BattleEnd`

### 3.6 BattleEndState
- **进入条件**: 有人赢得足够回合
- **职责**: 显示战斗结果，清理资源
- **退出条件**: 完成后触发 `battle_completed` 信号

---

## 4. 核心类设计

### 4.1 BattleCore
```gdscript
class_name BattleCore
extends Node

## 状态机核心，管理战斗生命周期

signal battle_started()
signal battle_completed(result: int, report: BattleReport)
signal state_changed(state_name: String)

func start_battle(config: BattleConfig) -> void:
func get_current_state() -> BattleState:
func transition_to(state_class: GDScript) -> void:
```

### 4.2 BattleState (基类)
```gdscript
class_name BattleState
extends RefCounted

var _core: BattleCore
var _entered: bool = false

func enter() -> void:
func exit() -> void:
func update(delta: float) -> void:
func on_animation_complete() -> void:
```

### 4.3 BattleConfig
```gdscript
class_name BattleConfig
extends Resource

@export var target_wins: int = 3
@export var cards_per_round: int = 3
@export var initial_hand_size: int = 6
@export var deck_policy: IDeckPolicy  # 卡组消耗/补充策略
```

### 4.4 BattleReport
```gdscript
class_name BattleReport
extends RefCounted

var result: int
var player_wins: int
var enemy_wins: int
var total_rounds: int
var cards_played: Array
```

### 4.5 IDeckPolicy (接口)
```gdscript
class_name IDeckPolicy
extends RefCounted

func on_battle_start(deck_size: int, hand_size: int) -> bool:
func on_round_start(current_deck: int, hand_size: int) -> Array:  # 返回补充的牌
func on_cards_consumed(played: Array, current_deck: int) -> Array:  # 返回消耗的牌
func can_continue(current_deck: int, hand_size: int) -> bool:
```

---

## 5. 流程时序

```
T=0  [BattleCore.start_battle()]
        │
        ▼
T=1  [IdleState.exit()] → [PlayerSelectState.enter()]
        │                      │
        │                      ▼
        │              显示手牌动画（可选）
        │                      │
        ▼                      ▼
T=2  [玩家选择3张牌] ←────────┘
        │
        ▼
T=3  [PlayerSelectState.exit()] → [EnemyRevealState.enter()]
        │                              │
        │                              ▼
        │                      敌方出牌动画（可选）
        │                              │
        ▼                              ▼
T=4  [EnemyRevealState.exit()] → [SettlementState.enter()]
        │                             │
        │                             ▼
        │                     结算动画（可选）
        │                             │
        ▼                             ▼
T=5  [SettlementState.exit()] → [RoundEndState.enter()]
        │                            │
        │                            ▼
        │                    处理消耗/补牌
        │                    更新分数
        │                            │
        ▼                            ▼
T=6  [RoundEndState.exit()]
        │
        ├──→ [未分胜负] → [ContinueLoop] → T=1
        │
        └──→ [胜负已分] → [BattleEndState.enter()]
                              │
                              ▼
                       显示战斗结果
                              │
                              ▼
                       [BattleCore battle_completed]
```

---

## 6. UI 接口

### 6.1 IBattleUI (接口)
```gdscript
class_name IBattleUI
extends CanvasLayer

## UI 必须实现的接口，BattleCore 通过这些接口与 UI 通信

func show_hand(cards: Array) -> void:
func highlight_card(card_id: String, highlight: bool) -> void:
func show_enemy_cards(cards: Array) -> void:
func show_settlement(player_score: int, enemy_score: int, winner: String) -> void:
func show_battle_result(result: int) -> void:
func play_animation(anim_name: String, callback: Callable) -> void:
```

### 6.2 UI 事件（回调给 Core）
```gdscript
## UI 通过这些信号通知 Core

signal card_selected(card_id: String)
signal card_deselected(card_id: String)
signal selection_confirmed(card_ids: Array)
signal animation_finished(anim_name: String)
```

---

## 7. 预留扩展点

### 7.1 动画扩展
- 每个状态可以触发任意数量的动画
- 动画完成后调用 `on_animation_complete()` 继续状态流
- 跳过动画：直接在 `on_enter()` 调用 `on_animation_complete()`

### 7.2 卡牌效果扩展
- 在 `SettlementState` 中调用 `CardEffectSystem.resolve()`
- 效果系统返回修正后的分数

### 7.3 AI 扩展
- `EnemyRevealState` 调用 `IEnemyAI.get_next_cards(count)`
- AI 实现完全由外部注入

---

## 8. 使用示例

```gdscript
# 启动战斗
var core = BattleCore.new()
core.initialize(card_manager, data_manager)
core.battle_completed.connect(_on_battle_completed)
core.start_battle(config)

# 玩家选牌后确认
core.on_selection_confirmed(selected_card_ids)

# UI 动画完成后通知
core.on_animation_finished("player_reveal")
```

---

## 9. 文件结构

```
scripts/
├── battle/
│   ├── BattleCore.gd           # 核心状态机
│   ├── states/
│   │   ├── BattleState.gd       # 状态基类
│   │   ├── IdleState.gd
│   │   ├── PlayerSelectState.gd
│   │   ├── EnemyRevealState.gd
│   │   ├── SettlementState.gd
│   │   ├── RoundEndState.gd
│   │   └── BattleEndState.gd
│   ├── BattleConfig.gd
│   ├── BattleReport.gd
│   ├── policies/
│   │   ├── IDeckPolicy.gd
│   │   ├── NoConsumptionPolicy.gd
│   │   └── ConsumeWithDrawPolicy.gd
│   └── interfaces/
│       ├── IBattleUI.gd
│       └── IEnemyAI.gd
```

---

## 10. 状态流转图（带动画钩子）

```
                    ┌────────────────────────────────────────┐
                    │              BattleCore                 │
                    │  start_battle() → Idle → PlayerSelect    │
                    └────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────────────┐
    │                    状态转换规则                               │
    ├───────────────────────────────────────────────────────────────┤
    │  Idle              │ exit() → 检查资源 → enter(PlayerSelect)  │
    │  PlayerSelect      │ exit() → 锁定选择 → enter(EnemyReveal)   │
    │  EnemyReveal       │ exit() → 显示敌方 → enter(Settlement)    │
    │  Settlement        │ exit() → 计算结果 → enter(RoundEnd)      │
    │  RoundEnd          │ exit() → 检查胜负 → Idle/BattleEnd        │
    │  BattleEnd         │ exit() → 清理资源 → 完成                  │
    └───────────────────────────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────────────┐
    │                    动画钩子                                    │
    ├───────────────────────────────────────────────────────────────┤
    │  每个状态 enter() 时可调用 core.play_animation()                │
    │  动画完成后 UI 调用 core.on_animation_finished()              │
    │  状态收到通知后调用 exit() 进入下一状态                        │
    └───────────────────────────────────────────────────────────────┘
```

---

## 11. 与现有系统集成

### 11.1 CardManager
- 通过 `CardManager.get_all_cards()` 获取手牌
- 通过 `CardManager.add_card()` / `remove_card()` 管理消耗/补牌

### 11.2 DataManager
- 通过 `DataManager.card_registry` 获取卡牌数据
- 通过 `DataManager.enemy_registry` 获取敌人配置

### 11.3 EventBus
- `BattleCore` 发布事件：`battle_started`, `battle_completed`, `state_changed`
- UI 订阅：`card_selected`, `selection_confirmed`, `animation_finished`

---

## 12. 已创建文件清单

```
scripts/battle/
├── BattleCore.gd              # 核心状态机
├── BattleUI_V2.gd             # UI实现
├── interfaces/
│   └── IBattleUI.gd           # UI接口
├── policies/
│   ├── IDeckPolicy.gd         # 策略接口
│   ├── NoConsumptionPolicy.gd  # 无消耗
│   ├── ConsumeWithDrawPolicy.gd # 消耗+补牌
│   └── ForceExitPolicy.gd      # 强制退出
└── states/
    ├── BattleState.gd           # 状态基类
    ├── IdleState.gd            # 空闲
    ├── PlayerSelectState.gd    # 选牌
    ├── EnemyRevealState.gd      # 敌方出牌
    ├── SettlementState.gd       # 结算
    ├── RoundEndState.gd         # 回合结束
    └── BattleEndState.gd       # 战斗结束
```

## 13. 待办事项

- [x] 实现 BattleCore 状态机框架
- [x] 实现所有 State 类
- [x] 实现 IBattleUI 接口
- [x] 实现所有 DeckPolicy
- [x] 创建 BattleUI_V2
- [x] 连接 BattleCore 和 BattleUI_V2 信号
- [x] 添加动画系统支持
- [x] 添加调试工具
- [x] 测试完整战斗流程
- [x] 压力测试脚本 BattleStressTest

---

## 14. 已修复的 Bug

### 14.1 Stack Overflow in transition_to()
- **问题**: `exit()` 调用 `ui_enable_selection(false)` → `_ui.enable_selection()` → 回调 `state_changed` → `transition_to()` → 循环
- **修复**: BattleState `play_animation()` 使用 `call_deferred()` 延迟动画回调
- **相关文件**: `BattleState.gd`, `PlayerSelectState.gd`, `EnemyRevealState.gd`, `SettlementState.gd`, `RoundEndState.gd`

### 14.2 状态转换同步执行导致流程串行
- **问题**: `enter()` 中直接调用 `_transition_to_next()` 导致所有状态在同一个调用栈执行完
- **修复**: 使用 `call_deferred()` 延迟到下一帧执行
- **相关文件**: 所有 State 类的 `on_animation_complete()`

### 14.3 SettlementState 胜负判断错误
- **问题**: `result.get("winner")` 返回 nil（BattleManager 不返回 winner 字段）
- **修复**: SettlementState 自己比较 `_player_score` 和 `_enemy_score` 判断胜负
- **相关文件**: `SettlementState.gd`

---

## 15. 压力测试脚本 (BattleStressTest)

### 14.1 用途
直接测试 BattleCore API，绕过 UI 层，快速验证战斗逻辑。

### 14.2 使用方法
1. 在 Godot 中打开 `scenes/battle/BattleStressTest.tscn`
2. 运行场景
3. 观察 Console 输出

### 14.3 测试内容
- `BattleCore.initialize()` - 初始化
- `BattleCore.start_battle()` - 启动战斗
- `BattleCore.on_selection_confirmed()` - 玩家确认出牌
- 状态机流转 `PlayerSelect → EnemyReveal → Settlement → RoundEnd`
- 胜利条件检测 (target_wins)
- `battle_completed` 信号

### 14.4 示例输出
```
========================================
[BattleStressTest] Starting stress test...
========================================
[BattleStressTest] Added card: card_rusty_sword (id: xxx)
[BattleStressTest] State changed: PlayerSelect
[BattleStressTest] PlayerSelect - hand size: 6
[BattleStressTest]   Selected[0]: xxx (random)
[BattleStressTest] Calling on_selection_confirmed with 3 cards...
[BattleStressTest] State changed: EnemyReveal
[BattleStressTest] State changed: Settlement
[BattleStressTest] State changed: RoundEnd
[BattleStressTest] RoundEnd #1 - remaining cards: 6
[BattleStressTest]   Score: Player 1 vs Enemy 0 (target: 3)
========================================
[BattleStressTest] BATTLE COMPLETED!
[BattleStressTest] Result: 0 (Victory)
========================================
```

---

## 15. 卡牌系统设计

### 15.1 卡牌选择模式

Battle System V2 支持两种卡牌选择模式：

| 模式 | 配置 | 说明 |
|------|------|------|
| **随机** | `enemy_deck_random = true` | 每轮随机选择卡牌 |
| **顺序循环** | `enemy_deck_random = false` | 按 `enemy_deck_order` 顺序轮换 |

### 15.2 玩家卡牌选择

测试脚本 `BattleStressTest` 支持两种玩家选牌模式：

```gdscript
var _random_player_cards: bool = true  # 配置开关

if _random_player_cards:
    # 随机选择：洗牌后取前N张
    var available_indices: Array = []
    for i in range(hand.size()):
        available_indices.append(i)
    available_indices.shuffle()
    for i in range(_config.cards_per_round):
        selected_ids.append(hand[available_indices[i]].get_card_id())
else:
    # 固定选择：总是前N张
    for i in range(_config.cards_per_round):
        selected_ids.append(hand[i].get_card_id())
```

### 15.3 敌方卡牌生成

`BattleConfig.get_enemy_cards(count)` 实现：

```gdscript
func get_enemy_cards(count: int) -> Array:
    if enemy_deck_random:
        # 随机模式：从卡组中随机抽取，可能重复
        for i in range(count):
            var random_idx = randi() % enemy_deck_order.size()
            result.append(enemy_deck_order[random_idx])
    else:
        # 顺序模式：循环遍历
        for i in range(count):
            result.append(enemy_deck_order[_enemy_deck_index % enemy_deck_order.size()])
            _enemy_deck_index += 1
```

### 15.4 扩展方式

如需更复杂的卡牌选择逻辑，可实现策略模式：

```gdscript
class_name IEnemyCardSelector
extends RefCounted
func select_cards(deck: Array, count: int) -> Array
```

内置实现：
- `RandomEnemyCardSelector` - 随机选择
- `SequentialEnemyCardSelector` - 顺序选择
- `WeightedEnemyCardSelector` - 加权随机（根据卡牌强度）

---

## 16. 测试报告 (2026-04-28)

### 16.1 测试场景

| 测试项 | 场景 | 结果 |
|--------|------|------|
| 状态机流转 | `BattleStressTest.tscn` | ✅ PASS |
| 随机玩家选牌 | `_random_player_cards = true` | ✅ PASS |
| 随机敌方选牌 | `enemy_deck_random = true` | ✅ PASS |
| 胜负判定 | 22 > 21 → Player Win | ✅ PASS |
| 3胜制结束 | Enemy 3 wins → BattleEnd | ✅ PASS |
| Cost 系统 | `self_destroy` 代价触发 | ✅ PASS |
| 程序正常退出 | `get_tree().quit()` | ✅ PASS |

### 16.2 测试日志摘要

```
Round 1: Player 20 vs 21 Enemy → Enemy Win (0-1)
Round 2: Player 18 vs 21 Enemy → Enemy Win (0-2)
Round 3: Player 22 vs 21 Enemy → Player Win (1-2)
Round 4: Player 16 vs 21 Enemy → Enemy Win (1-3) → BATTLE END
Result: Defeat (Enemy 3 wins)
```

### 16.3 已验证功能

| 功能 | 状态 | 说明 |
|------|------|------|
| BattleCore 状态机 | ✅ | PlayerSelect → EnemyReveal → Settlement → RoundEnd |
| call_deferred 异步 | ✅ | 解决 stack overflow |
| 胜负判定修复 | ✅ | SettlementState 自己比较分数 |
| 随机卡牌选择 | ✅ | 敌方卡牌可重复 |
| Cost 系统联动 | ✅ | card_vengeance 的 self_destroy 触发 |
| 20回合限制 | ✅ | 超时强制结束 |
| battle_completed 信号 | ✅ | 正常发出并处理 |

### 16.4 Bug 修复历史

| Bug | 原因 | 修复 |
|-----|------|------|
| Stack overflow | `exit()` → `ui_enable_selection()` → 递归 | 使用 `call_deferred()` |
| 状态同步执行 | `enter()` 直接调用 `_transition_to_next()` | `on_animation_complete()` + `call_deferred()` |
| 永远平局 | `result.get("winner")` 返回 nil | SettlementState 自己判断胜负 |
| 敌方卡组为空 | `get_current_enemy_cards()` 时序问题 | 异步通知 |

---

## 17. 扩展指南

### 17.1 添加新状态

1. 在 `scripts/battle/states/` 创建新状态类：
```gdscript
class_name NewState
extends BattleState

func _init(core: BattleCore) -> void:
    super._init(core)
    _state_name = "NewState"

func enter() -> void:
    _core.notify_state_changed(_state_name)
    # 业务逻辑
    play_animation("new_state")

func on_animation_complete() -> void:
    call_deferred("_transition_to_next")

func _transition_to_next() -> void:
    _core.transition_to(NextState)
```

2. 在 `BattleCore.transition_to()` 中切换到新状态

### 17.2 添加新 DeckPolicy

1. 创建策略类实现 `IDeckPolicy`：
```gdscript
class_name MyPolicy
extends IDeckPolicy

func on_round_start(current_deck: int, hand_size: int) -> Array:
    # 返回要添加的卡牌 prototype_id 数组
    return []

func on_cards_consumed(played: Array, current_deck: int) -> Array:
    # 返回要消耗的卡牌 instance_id 数组
    return []

func can_continue(current_deck: int, hand_size: int) -> bool:
    return current_deck >= hand_size
```

2. 在 `BattleConfig.deck_policy` 中设置

### 17.3 添加卡牌选择器

1. 实现 `select_cards(deck: Array, count: int) -> Array`
2. 在 `BattleConfig` 中添加选择器引用
3. 修改 `get_enemy_cards()` 使用选择器

---

## 18. 与旧系统集成

### 18.1 切换路径

| 旧系统 | 新系统 |
|--------|--------|
| `BattleFlowManager` | `BattleCore` + States |
| `BattleRunner` | `BattleConfig` |
| `BattleUI_v1` | `BattleUI_V2` |
| 内置卡组 | `IDeckPolicy` |

### 18.2 共存策略

新系统与旧系统可共存，通过不同场景加载：
- `BattleTest.tscn` → 新系统测试
- 原有场景 → 旧系统继续运行
