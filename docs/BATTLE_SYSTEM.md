# 战斗系统设计文档

> **版本**: v1.0
> **日期**: 2026-04-28
> **模块**: BattleFlow, BattleRunner, BattleConfig, CardConsumer, CrossTurnState

---

## 1. 概述

### 1.1 设计目标

- **6阶段固定流程**：所有战斗统一流程，不可修改
- **数据驱动**：每场战斗参数由 BattleConfig 提供
- **OOP 模块化**：各模块职责分离
- **容错保护**：空牌、缺牌、平局死循环等场景处理

### 1.2 核心模块

| 模块 | 类型 | 职责 |
|------|------|------|
| `BattleFlow` | Node | 6阶段状态机核心 |
| `BattleRunner` | Node | 协调器，管理生命周期 |
| `BattleConfig` | Resource | 每场战斗配置 |
| `CardConsumer` | RefCounted | 卡牌消耗逻辑 |
| `CrossTurnState` | RefCounted | 跨回合状态(Buff/Debuff) |

---

## 2. 架构设计

### 2.1 模块关系图

```
┌─────────────────────────────────────────────────────────────┐
│                     BattleFlow                              │
│  (6阶段状态机 - 核心战斗逻辑)                            │
│                                                          │
│  PLAYER_SELECT → ENEMY_REVEAL → SETTLE →                 │
│  CONSUME → ROUND_END → BATTLE_END                        │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│BattleConfig │ │CardConsumer│ │CrossTurnState│
│ 每场配置    │ │ 消耗模块 │ │ 跨回合状态  │
└──────────────┘ └──────────┘ └──────────────┘
        ▲
        │
┌───────┴───────┐
│ BattleRunner │
│ (协调器)     │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│  Battle_UI  │
│  (界面)     │
└───────────┘
```

### 2.2 战斗触发流程

```
Cave场景 (玩家移动)
    ↓ (进入门)
[检查卡牌数量 >= 3]
    ↓ 不足则提示
    ↓ 足够则切换场景
Battle_UI_v1._ready()
    ↓
BattleRunner.setup(ui, enemy)
    ↓
BattleRunner._start_battle()
    ↓
BattleFlow.start_battle(snapshot, enemy, config)
    ↓
进入 PLAYER_SELECT 阶段
    ↓ (等待玩家选牌)
玩家选牌 → cards_confirmed 信号
    ↓
BattleRunner._on_cards_confirmed()
    ↓
BattleFlow.confirm_selection()
    ↓
进入 ENEMY_REVEAL → SETTLE → CONSUME → ROUND_END → CHECK
    ↓
CHECK: 胜负未分 → 回到 PLAYER_SELECT
CHECK: 胜负已分 → _trigger_battle_end()
    ↓
BattleRunner._on_battle_end()
    ↓
切换回 Cave 场景
```

---

## 3. 6阶段状态机

### 3.1 阶段定义

```gdscript
enum Phase {
    INVALID = -1,
    IDLE = 0,
    PLAYER_SELECT = 1,      # 玩家选牌阶段
    ENEMY_REVEAL = 2,     # 敌方卡牌揭示
    SETTLE = 3,           # 结算阶段
    CONSUME = 4,          # 消耗阶段
    ROUND_END = 5,         # 回合结束
    BATTLE_END = 99         # 战斗结束
}
```

### 3.2 阶段转换图

```
                    ┌─────────────────┐
                    │  PLAYER_SELECT   │
                    │  (玩家选牌)     │
                    └────────┬────────┘
                             │ confirm_selection()
                             ▼
                    ┌─────────────────┐
                    │  ENEMY_REVEAL  │
                    │  (敌方揭示)     │
                    └────────┬────────┘
                             │ (自动)
                             ▼
                    ┌─────────────────┐
                    │     SETTLE     │
                    │    (结算)      │
                    └────────┬────────┘
                             │ (自动)
                             ▼
                    ┌─────────────────┐
                    │    CONSUME     │
                    │    (消耗)     │
                    └────────┬────────┘
                             │ (自动)
                             ▼
                    ┌─────────────────┐
                    │   ROUND_END    │
                    │   (回合结束)   │
                    └────────┬────────┘
                             ▼
                    ┌─────────────────┐
                    │     CHECK      │
                    │   (胜负检查)   │
                    └───────┬─────────┘
                            │
           ┌────────────────┴────────────────┐
           ▼                                 ▼
  ┌───────────────┐              ┌───────────────┐
  │   胜负未分    │              │   胜负已分    │
  │ 继续下一回合  │              │战斗结束      │
  └───────┬───────┘              └───────────────┘
          │
          └──────────────────→ PLAYER_SELECT
```

---

## 4. BattleConfig 配置

### 4.1 配置项

```gdscript
class_name BattleConfig
extends Resource

@export var target_wins: int = 3           # 获胜回合数
@export var cards_per_round: int = 3        # 每回合出牌数
@export var draw_break_threshold: int = 2      # 平局破局阈值
@export var min_deck_size: int = 3           # 最小牌组要求
@export var enemy_deck_order: Array = []      # 敌方牌组顺序
@export var enable_card_consumption: bool = true # 是否启用消耗
@export var enable_buff_system: bool = false    # 是否启用Buff系统
```

### 4.2 敌方牌组循环

```gdscript
func get_enemy_cards(count: int) -> Array:
    # 从 enemy_deck_order 依次取牌
    # 循环使用直到牌组耗尽
    for i in range(count):
        card = enemy_deck_order[_enemy_deck_index % size]
        _enemy_deck_index += 1
    return cards
```

---

## 5. CardConsumer 消耗模块

### 5.1 消耗流程

```
玩家出牌 → 回合结算 → CONSUME 阶段
    │
    ▼
CardConsumer.consume_played_cards(played_card_ids)
    │
    ├─── 检查保护例外 (Locked 卡牌)
    │
    ├─── 验证卡牌有效性
    │
    └─── CardMgr.remove_card() 移除卡牌
```

### 5.2 消耗例外

```gdscript
enum ConsumptionException {
    None = 0,
    Locked = 1,      # 锁定卡不消耗
    PreserveTag = 2   # 保留标签卡不消耗
}
```

---

## 6. 容错保护

### 6.1 空牌保护

```gdscript
# 战斗开始前检查
if CardMgr.get_deck_size() < min_deck_size:
    阻止进入战斗，提示玩家

# 回合开始前检查
if CardMgr.get_deck_size() < cards_per_round:
    判负 (Defeat)
```

### 6.2 平局破局

```gdscript
# 连续平局达到阈值后强制判定
if consecutive_draws >= draw_break_threshold:
    scores[0] += 1  # 玩家获胜
```

---

## 7. IDeckPolicy 牌组策略系统

### 7.1 概述

IDeckPolicy 是卡组管理的策略接口，替代原有的 `enable_card_consumption` 布尔开关，提供灵活的卡组消耗/补充机制。

### 7.2 接口定义

```gdscript
class_name IDeckPolicy
extends RefCounted

signal deck_modified(new_size: int)
signal battle_forced_end(reason: String)

func on_battle_start(current_deck_size: int, cards_per_round: int) -> bool
func on_round_start(current_deck_size: int, cards_per_round: int) -> Array
func on_cards_played(played_card_ids: Array, current_deck_size: int) -> Array
func can_continue_battle(current_deck_size: int, cards_per_round: int) -> bool
func get_policy_name() -> String
```

### 7.3 内置策略

| 策略 | 说明 |
|------|------|
| `NoConsumptionPolicy` | 卡牌不消耗，每回合重复使用（默认） |
| `ConsumeWithDrawPolicy` | 出牌消耗，每回合开始时检查并补充 |
| `ForceExitPolicy` | 出牌消耗，牌不足时强制退出战斗 |

### 7.4 使用方式

```gdscript
# 方式1: 通过 BattleConfig 设置
var config = BattleConfig.from_enemy_data(enemy)
config.deck_policy = ConsumeWithDrawPolicy.new()

# 方式2: 通过 GameState 全局设置（调试菜单）
GameState.battle_deck_policy = ForceExitPolicy
# 下场战斗自动使用该策略
```

### 7.5 调试菜单

在调试菜单（F3）中可以选择消耗策略：
- `NoConsumptionPolicy` - 无消耗（默认）
- `ConsumeWithDrawPolicy` - 消耗+补牌
- `ForceExitPolicy` - 消耗+强制退出

---

## 8. 问题清单

| # | 问题 | 优先级 | 状态 |
|---|------|--------|------|
| 1 | `enable_card_consumption=false` 时仍可能执行消耗 | 高 | 已修复（IDeckPolicy） |
| 2 | 空牌/缺牌时卡死 | 高 | 已修复（IDeckPolicy） |
| 3 | `cards_confirmed` 信号重复发送 | 中 | 待排查 |
| 4 | 战斗结束后 UI 未重置 | 中 | 待修复 |
| 5 | 补牌机制缺失 | 高 | 已实现（IDeckPolicy） |
| 6 | Buff/跨回合状态未实现 | 中 | 待实现 |
| 7 | BOSS 多阶段机制未实现 | 低 | 后续 |

---

## 9. 待办事项

- [x] 修复消耗逻辑（IDeckPolicy 策略系统）
- [x] 实现补牌机制（IDeckPolicy 策略系统）
- [x] 修复空牌检测流程（can_continue_battle）
- [ ] 修复 UI 状态重置
- [ ] 排查信号重复发送问题
- [ ] 实现 Buff/跨回合状态系统
- [ ] 实现 BOSS 多阶段出牌配置

---

## 9. 相关文档

- [MODULES.md](./MODULES.md) - 模块架构总览
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 项目架构文档
- [RETROSPECTIVE.md](./RETROSPECTIVE.md) - 问题复盘与经验总结
