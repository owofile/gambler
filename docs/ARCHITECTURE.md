# Gambler 项目架构文档

## 更新记录

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-24 | v1.0 | 初始架构：卡牌系统与敌人系统数据结构 |
| 2026-04-24 | v1.1 | 新增 CardManager 卡牌管理模块 |
| 2026-04-24 | v1.2 | 新增 BattleManager 战斗核心模块 |
| 2026-04-24 | v1.3 | 新增 EventBus 事件总线、Payload 事件类、GameRunner 测试脚本 |
| 2026-04-24 | v1.4 | MVP 全链路跑通：获得牌→战斗→返回结果→卡牌仓库变化 |
| 2026-04-24 | v1.5 | 新增 BattleUI 场景、SceneRunner 测试场景运行器 |
| 2026-04-24 | v1.6 | BattleUI 可交互测试通过，游戏完整流程可玩 |
| 2026-04-24 | v1.7 | 新增特效与代价系统（EffectRegistry, CostRegistry） |
| 2026-04-24 | v1.7.1 | 修复 SceneRunner 代价执行逻辑，验证 self_destroy 正常工作 |
| 2026-04-24 | v2.0 | 新战斗流程系统：BattleFlowManager 状态机、CardSelector、AnimationController |
| 2026-04-24 | v2.1 | 状态机与 BattleManager 整合，代价系统完整工作，Logger 日志系统 |

---

## 1. 系统概述

本项目是 Godot 4.3 卡牌对战游戏，核心系统包括：
- 卡牌原型注册系统
- 卡牌实例管理系统
- 敌人登记系统

---

## 2. 目录结构

```
gambler/
├── scripts/
│   ├── data/                    # 数据结构定义
│   │   ├── CardData.gd          # 卡牌原型 & 枚举定义
│   │   ├── CardInstance.gd      # 卡牌实例
│   │   ├── CardPrototypeRegistry.gd  # 卡牌原型注册表
│   │   ├── EnemyData.gd         # 敌人数据结构 & 枚举定义
│   │   ├── EnemyRegistry.gd     # 敌人注册表
│   │   ├── BattleEnums.gd        # 战斗枚举 (RoundResult, BattleResult)
│   │   ├── RoundDetail.gd       # 回合详情结构
│   │   ├── BattleReport.gd      # 战斗报告结构
│   │   ├── DeckSnapshot.gd      # 牌组快照结构
│   │   ├── CardSnapshot.gd      # 卡牌快照结构
│   │   ├── EffectEnums.gd       # 特效优先级枚举
│   │   ├── EffectContext.gd      # 特效上下文
│   │   ├── CostContext.gd       # 代价上下文
│   │   ├── EffectRegistry.gd    # 特效注册表
│   │   └── CostRegistry.gd      # 代价注册表
│   ├── effects/                 # 特效实现
│   │   ├── IEffectHandler.gd     # 特效接口
│   │   ├── FixedBonusEffect.gd  # 固定加成特效
│   │   └── RuleReversalEffect.gd # 规则反转特效
│   ├── costs/                   # 代价实现
│   │   ├── ICostHandler.gd      # 代价接口
│   │   ├── NextTurnUnusableCost.gd # 下回合不可用代价
│   │   └── SelfDestroyCost.gd   # 自我毁灭代价
│   ├── core/                    # 核心系统
│   │   ├── CardManager.gd       # 卡牌管理模块
│   │   ├── BattleManager.gd     # 战斗核心模块
│   │   ├── EventBus.gd          # 事件总线
│   │   ├── BattleFlowManager.gd # 战斗流程状态机 (v2.0)
│   │   ├── CardSelector.gd      # 选牌管理器 (v2.0)
│   │   ├── AnimationController.gd # 动画控制器 (v2.0)
│   │   ├── SceneRunner.gd       # 测试场景运行器（v1.x）
│   │   ├── SceneRunnerV2.gd    # 测试场景运行器（v2.0）
│   │   └── GameRunner.gd        # 旧测试脚本（保留）
│   ├── ui/                      # UI 系统
│   │   └── BattleUI.gd          # 战斗界面 UI 控制器
│   ├── events/                  # 事件负载定义
│   │   ├── BattleEndedPayload.gd
│   │   ├── CardAcquiredPayload.gd
│   │   └── CardLostPayload.gd
│   ├── autoload/
│   │   └── DataManager.gd       # 全局单例，统一访问注册表
│   └── utils/
│       └── UUID.gd              # UUID v4 生成工具
├── resources/                   # 数据资源文件
│   ├── card_prototypes.json    # 卡牌原型配置
│   └── enemy_registry.json      # 敌人配置
├── scenes/                      # 场景文件
│   ├── BattleUI.tscn           # 战斗 UI 场景
│   ├── Main.tscn               # 主场景（v1.x）
│   └── MainV2.tscn             # 主场景（v2.0）
└── project.godot                # Godot 项目配置
```

---

## 3. 数据结构

### 3.1 CardData (卡牌原型)

**文件**: `scripts/data/CardData.gd`

```gdscript
class_name CardData
extends RefCounted

# 枚举
enum CardClass { Artifact, Bond, Creature, Concept, Sin, Authority }
enum CardBindStatus { None, Locked, Cursed }

# 属性
var prototype_id: String         # 唯一标识，如 "card_rusty_sword"
var card_class: CardClass       # 卡牌分类
var base_value: int             # 基础点数
var effect_ids: Array[String]   # 特效ID列表（第一阶段为空）
var cost_id: String             # 代价ID（第一阶段为空）
var is_lockable: bool            # 是否可被锁定
```

**点数区间规范**：
| 类型 | 区间 |
|------|------|
| 器物 (Artifact) | 5-9 |
| 生灵 (Creature) | 3-6 |
| 概念 (Concept) | 2-7 |
| 羁绊 (Bond) | 2-4 |
| 罪孽 (Sin) | 6-10 |
| 权能 (Authority) | 4-8 |

### 3.2 CardInstance (卡牌实例)

**文件**: `scripts/data/CardInstance.gd`

```gdscript
class_name CardInstance
extends RefCounted

var instance_id: String          # 唯一GUID
var prototype_id: String        # 指向原型
var delta_value: int            # 强化带来的点数变化，初始0
var bind_status: CardBindStatus # None/Locked/Cursed
```

### 3.3 EnemyData (敌人数据)

**文件**: `scripts/data/EnemyData.gd`

```gdscript
class_name EnemyData
extends RefCounted

enum EnemyTier { Grunt, Elite, Boss }

var enemy_id: String
var enemy_name: String
var tier: EnemyTier
var deck_prototype_ids: Array[String]   # 固定卡组原型ID
var loot_pool_prototype_ids: Array[String]  # 战利品池原型ID
```

---

## 4. 注册表系统

### 4.1 CardPrototypeRegistry

**文件**: `scripts/data/CardPrototypeRegistry.gd`

- 继承 `Resource`，可在编辑器中使用
- 支持从 JSON 文件加载或硬编码默认数据
- 对外接口：
  - `get_prototype(p_id: String) -> CardData`
  - `has_prototype(p_id: String) -> bool`
  - `get_all_prototype_ids() -> Array[String]`
  - `get_prototypes_by_class(card_class) -> Array[CardData]`

### 4.2 EnemyRegistry

**文件**: `scripts/data/EnemyRegistry.gd`

- 继承 `Resource`
- 支持从 JSON 文件加载或硬编码默认数据
- 对外接口：
  - `get_enemy(e_id: String) -> EnemyData`
  - `has_enemy(e_id: String) -> bool`
  - `get_all_enemy_ids() -> Array[String]`
  - `get_enemies_by_tier(tier) -> Array[EnemyData]`

---

## 5. 全局管理

### 5.1 DataManager

**文件**: `scripts/autoload/DataManager.gd`

- Autoload 单例，项目启动时自动初始化
- 统一访问入口：
  - `DataManager.card_registry`
  - `DataManager.enemy_registry`

### 5.2 CardManager

**文件**: `scripts/core/CardManager.gd`

- Autoload 单例，管理玩家卡牌实例
- 对外接口：
  - `AddCard(prototype_id) -> CardInstance` - 创建卡牌实例
  - `RemoveCard(instance_id) -> bool` - 移除卡牌（锁定卡不可移除）
  - `GetDeckSnapshot(selected_instance_ids) -> DeckSnapshot` - 获取深拷贝的战局快照
  - `GetAllCards() -> Array[CardInstance]` - 获取所有卡牌
  - `GetDeckSize() -> int` - 获取当前卡牌数量

**内部数据结构**：
```gdscript
const MAX_DECK_SIZE = 20
var _player_deck: Array[CardInstance]

struct DeckSnapshot:
	string deck_id
	Array[CardSnapshot] cards

struct CardSnapshot:
	string instance_id
	string prototype_id
	int final_value
	CardClass card_class
	Array[String] effect_ids
	CardBindStatus bind_status
```

---

## 5.3 BattleManager

**文件**: `scripts/core/BattleManager.gd`

- 静态类，每次战斗调用 `StartBattle(playerDeck, enemy)` 返回 `BattleReport`
- 不直接修改 CardManager，只计算和返回结果

**对外接口**：
```gdscript
static func StartBattle(playerDeck: DeckSnapshot, enemy: EnemyData) -> BattleReport
```

**胜场目标**：
| 敌人 tier | targetWins |
|-----------|------------|
| Grunt | 3 |
| Elite | 4 |
| Boss | 5 |

**回合逻辑**：
1. 玩家出点数最高的3张牌
2. 敌人随机出3张牌
3. 比较总点数，高者胜
4. 平局时：连续2次平局后第3回合判玩家胜

**战利品逻辑**：
- Victory: 从敌人 lootPool 中随机选1张加入玩家卡组
- Defeat: 从玩家快照中随机选1张非Locked卡移除

---

## 5.4 EventBus

**文件**: `scripts/core/EventBus.gd`

- Autoload 单例，事件发布-订阅系统
- 内部用 Dictionary 存储订阅者

**对外接口**：
```gdscript
func Subscribe(event_type: String, handler: Callable) -> void
func Unsubscribe(event_type: String, handler: Callable) -> void
func Publish(event_type: String, payload: Variant) -> void
func ClearAll() -> void
```

**事件列表**：
| 事件名 | Payload 类型 | 触发时机 |
|--------|-------------|---------|
| BattleEnded | BattleEndedPayload | 战斗结算完成 |
| CardAcquired | CardAcquiredPayload | 卡牌获得时 |
| CardLost | CardLostPayload | 卡牌失去时 |

---

## 5.5 GameRunner

**文件**: `scripts/core/GameRunner.gd`

- Node 节点，项目启动时自动执行第一场战斗测试
- 串联整个 MVP 流程

**测试流程**：
1. 添加6张初始卡到牌库
2. 加载 Grunt 敌人
3. 选取点数最高的3张卡出战
4. 执行 BattleManager.StartBattle()
5. 处理战利品：cardsToAdd → AddCard, cardsToRemove → RemoveCard
6. 发布 CardAcquired / CardLost / BattleEnded 事件

---

## 6. 数据流

```
resources/*.json (配置)
	→ Registry (运行时解析)
	→ CardData / EnemyData (原型数据)
	→ CardInstance (玩家仓库中的实例)
```

---

## 7. 扩展计划

- [ ] 特效系统 (effect_ids 填充)
- [ ] 代价系统 (cost_id 填充)
- [ ] 卡牌仓库持久化 (存档系统)
- [x] 战斗系统整合（见下方 BattleUI）
- [ ] 敌人AI系统

## 7.1 BattleUI 系统 (v1.5)

**文件**: `scenes/BattleUI.tscn` + `scripts/ui/BattleUI.gd`

**功能**：
- 手牌展示区：显示所有卡牌名称+点数
- 出牌选择：点击选择1-3张牌，确认后触发战斗
- 敌方信息：显示敌人名称、阶级、当前比分
- 结算区域：每回合点数对比、胜场进度条
- 战斗日志：滚动显示所有战斗信息

**信号**：
```gdscript
signal cards_confirmed(selected_ids: Array[String])
```

**使用方式**：
```gdscript
battle_ui.setup_battle(enemy: EnemyData)  # 初始化战斗
battle_ui.refresh_hand()                    # 刷新手牌
battle_ui.on_round_complete(round_detail)   # 回合结束后调用
battle_ui.on_battle_complete(report)        # 战斗结束后调用
```

---

## 7.2 可交互测试结果 (v1.6)

**测试时间**: 2026-04-24

**已验证功能**：
- ✅ CardManager.GetDeckSnapshot() 被 UI 正确消费
- ✅ 出牌选择→确认→BattleManager 流程无时序 bug
- ✅ BattleReport 字段足够驱动 UI 刷新
- ✅ EventBus.Publish 能在 UI 回调中正确响应
- ✅ 完整流程：选择卡牌 → 确认出牌 → 战斗结算 → 卡牌变化
- ✅ 信号与事件机制正常工作

---

## 7.3 信号与事件机制 (Signal & Event Pattern)

### 7.3.1 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                        BattleUI                              │
│   emit_signal("cards_confirmed", selected_ids)              │
└─────────────────────────┬───────────────────────────────────┘
						  ↓
┌─────────────────────────────────────────────────────────────┐
│                      SceneRunner                             │
│   _on_cards_confirmed() ← Callable 接收信号                  │
│   EventBus.Publish("BattleEnded", payload)                  │
└─────────────────────────┬───────────────────────────────────┘
						  ↓
┌─────────────────────────────────────────────────────────────┐
│                       EventBus                               │
│   Publish() → 遍历 _subscribers 逐个调用 handler             │
└─────────────────────────┬───────────────────────────────────┘
						  ↓
┌─────────────────────────────────────────────────────────────┐
│                   订阅者回调                                  │
│   _on_battle_ended_listener(payload)                         │
└─────────────────────────────────────────────────────────────┘
```

### 7.3.2 信号 vs 事件

| 类型 | 实现方式 | 用途 | 示例 |
|------|---------|------|------|
| **Signal** | `emit_signal()` | 节点内部通知 | `BattleUI.cards_confirmed` |
| **EventBus** | `EventBus.Publish()` | 跨模块广播 | `CardAcquired`, `BattleEnded` |

### 7.3.3 信号定义

**BattleUI.gd** - 定义并发射信号：
```gdscript
class_name BattleUI
extends Control

signal cards_confirmed(selected_ids: Array[String])

func _on_confirm_pressed() -> void:
	emit_signal("cards_confirmed", selected_ids)
```

### 7.3.4 信号连接

**SceneRunner.gd** - 连接信号到回调：
```gdscript
_battle_ui.connect("cards_confirmed", Callable(_on_cards_confirmed))
```

### 7.3.5 事件发布与订阅

**发布 (EventBus)**：
```gdscript
func Publish(event_type: String, payload: Variant) -> void:
	if _subscribers.has(event_type):
		for handler in _subscribers[event_type]:
			handler.call(payload)
```

**订阅**：
```gdscript
EventBus.Subscribe("BattleEnded", _on_battle_ended)
```

### 7.3.6 已验证的信号/事件

| 信号/事件 | 类型 | 触发时机 | 状态 |
|-----------|------|---------|------|
| `cards_confirmed` | Signal | 用户点击确认出牌 | ✅ |
| `BattleEnded` | Event | 战斗结算完成 | ✅ |
| `CardAcquired` | Event | 获得卡牌时 | ✅ |
| `CardLost` | Event | 失去卡牌时 | ✅ |

### 7.3.7 设计原则

1. **Signal 用于紧耦合**：UI 组件与控制者之间
2. **EventBus 用于解耦**：跨模块通信，全局广播
3. **使用 Callable 包装**：`_battle_ui.connect("signal", Callable(callback))`
4. **Payload 作为参数**：统一的事件数据结构

---

## 7.4 特效与代价系统 (v1.7)

### 7.4.1 特效优先级

| 优先级 | 值 | 说明 |
|--------|-----|------|
| `BuffDebuff` | 0 | 增益减益级（最先执行） |
| `ValueModifier` | 50 | 数值修整级 |
| `RuleReversal` | 100 | 规则反转级（最后执行） |

### 7.4.2 特效接口

```gdscript
class_name IEffectHandler
extends RefCounted

func apply(context: EffectContext) -> void
func get_priority() -> int
```

### 7.4.3 已实现特效

| 特效 | ID | 效果 | 优先级 |
|------|-----|------|--------|
| `FixedBonusEffect` | `fixed_bonus_2/3/5` | 增加固定点数 | ValueModifier |
| `RuleReversalEffect` | `rule_reversal` | 交换双方总点数 | RuleReversal |

### 7.4.4 代价接口

```gdscript
class_name ICostHandler
extends RefCounted

func trigger(context: CostContext) -> void
```

### 7.4.5 已实现代价

| 代价 | ID | 效果 |
|------|-----|------|
| `NextTurnUnusableCost` | `next_turn_unusable` | 标记卡牌下回合不可用 |
| `SelfDestroyCost` | `self_destroy` | 战斗后摧毁使用该代价的卡牌 |

### 7.4.6 特效执行流程

```
1. 收集玩家出牌的所有 effectIds
2. 按 Priority 排序（从低到高）
3. 创建 EffectContext
4. 依次调用各特效的 Apply()
5. 特效执行完后判定胜负
6. 收集 costIds，创建 CostContext
7. 调用代价的 Trigger()
```

### 7.4.7 EffectContext 属性

```gdscript
var player_deck: DeckSnapshot
var enemy_deck: DeckSnapshot
var player_played_cards: Array[CardSnapshot]
var enemy_played_cards: Array[CardSnapshot]
var current_player_total: int
var current_enemy_total: int
var player_wins: int
var enemy_wins: int
var target_wins: int
var is_draw: bool
var pending_costs: Array[String]
```

### 7.4.8 BattleReport 新增字段

```gdscript
var disabled_instance_ids: Array[String]  # 下回合不可用的卡牌
```

### 7.4.9 代价执行流程（v1.7.1）

```
战斗结束
	↓
SceneRunner._apply_battle_results()
	↓
遍历 report.cards_to_remove → CardManager.RemoveCard()
遍历 report.cards_to_add → CardManager.AddCard()
	↓
BattleUI.refresh_hand() 更新手牌显示
```

**验证结果（v1.7.1）**：
- ✅ `self_destroy` 代价正确标记卡牌
- ✅ `CardManager.RemoveCard()` 正确移除卡牌
- ✅ 手牌数量从 6 变为 5

---

## 8. 设计原则

1. **原型与实例分离**: `CardData` 定义模板，`CardInstance` 存储玩家实际拥有
2. **注册表模式**: 统一管理所有可配置实体，支持热更新
3. **可序列化**: 所有数据结构支持 JSON 序列化，方便存档
4. **面向对象**: 使用 Godot 的 `class_name` 和 `extends RefCounted`
5. **解耦**: Autoload 提供单一访问点，避免直接依赖
