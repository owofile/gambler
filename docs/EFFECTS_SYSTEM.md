# Card Effect System Design

## 更新记录

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-27 | v1.0 | 初始设计：接口规范、模块职责、执行顺序、扩展计划 |

---

## 1. 设计原则

### 1.1 核心哲学

> **每个模块只做它规定的事情，不做多的，也不做少的。**
>
> 执行顺序由系统统一控制，模块本身不感知顺序，不依赖其他模块的执行结果。模块间的信息共享通过 `EffectContext` 进行，而非直接调用。

### 1.2 四大原则

| 原则 | 说明 |
|------|------|
| **单一职责（SRP）** | 每个 EffectHandler 只实现一种效果，如加点数、扣血、抽卡 |
| **开闭原则（OCP）** | 新增效果不修改现有 EffectHandler 代码，只需注册到 Registry |
| **依赖倒置（DIP）** | EffectHandler 只依赖抽象的 `EffectContext`，不依赖具体战斗系统 |
| **接口即策略** | 复杂卡和简单卡都实现同一个接口，区别只在于 `apply()` 内部逻辑 |

### 1.3 简单 vs 复杂的边界

```
简单卡（10-15行）：
  - FixedBonusEffect: 给己方 +N 点
  - DirectDamageEffect: 给敌方 -N 点
  - SkipEffect: 本回合无效果

复杂卡（40-100行）：
  - BuffAllyDelayedEffect: 下回合给指定友方卡 +N 点
  - ConditionalBoostEffect: 满足条件时 +N 点
  - ChainLightningEffect: 依次弹射多张卡，每张递减

实现代价完全相同：实现接口 + 注册到 Registry
```

---

## 2. 模块架构

### 2.1 模块关系图

```
EffectContext（共享数据容器，唯一通信桥梁）
       ↑
       │
   ┌────┴────┐
   │         │
EffectHandler  EffectHandler   ← 彼此不直接通信
(独立计算)     (独立计算)
   │         │
   └────┬────┘
        ↓
EffectRegistry（效果注册表，按优先级排序）
        ↓
BattleFlowManager（执行器，按序调用）
        ↓
   ┌────┴────┐
   │         │
CardManager  BattleReport
(修改卡牌)   (记录结果)
```

### 2.2 EffectContext — 共享数据容器

EffectContext 是模块间共享信息的唯一通道。所有 EffectHandler 都只能通过它来：
- 读取当前状态（己方总点数、敌人总点数、出过的卡等）
- 修改当前状态（加减点数、标记卡牌等）
- 预约未来操作（延迟效果）

**设计要点：Context 越大越灵活，但模块间耦合越紧。控制字段增长的方法是：能通过已有字段计算出来的，就不新增专门的字段。**

---

## 3. IEffectHandler 接口规范

### 3.1 接口定义

```gdscript
class_name IEffectHandler
extends RefCounted

## 执行此效果。所有效果逻辑都写在这里。
## @param context 战斗上下文，通过它读写共享状态
func apply(context: EffectContext) -> void:
	pass

## 返回效果优先级。数字越小越先执行。
## @return int 优先级（见 EffectEnums）
func get_priority() -> int:
	return EffectEnums.EffectPriority.Normal

## 效果是否已耗尽（用于标记类效果）
## 默认返回 false，持续性效果可返回 true
func is_expired() -> bool:
	return false

## 获取效果描述（用于 UI 显示）
func get_description() -> String:
	return ""
```

### 3.2 优先级枚举

```gdscript
class_name EffectEnums
extends RefCounted

class EffectPriority:
	const Preemptive   = 0   # 先发制人（最先执行）
	const BuffDebuff   = 50  # 增益减益
	const ValueMod     = 100 # 数值修整
	const Normal       = 150 # 普通效果
	const PostProcess  = 200 # 后处理
	const RuleOverride = 300 # 规则覆盖（最后执行）
```

### 3.3 效果分类

| 分类 | 说明 | 优先级范围 | 示例 |
|------|------|-----------|------|
| **即时数值** | 直接加减总点数 | Preemptive ~ Normal | +2点、-3点 |
| **条件触发** | 满足条件才生效 | ValueMod ~ Normal | "血量<50时+5" |
| **标记类** | 预约下回合效果 | PostProcess | "下回合+3" |
| **规则覆盖** | 改变计算规则 | RuleOverride | "本回合点数互换" |

---

## 4. EffectContext 字段规范

### 4.1 当前字段（已存在）

| 字段 | 类型 | 用途 |
|------|------|------|
| `_player_deck` | DeckSnapshot | 己方出牌快照 |
| `_enemy_deck` | DeckSnapshot | 敌方出牌快照（当前为null） |
| `_player_played_cards` | Array | 己方已出的卡 |
| `_enemy_played_cards` | Array | 敌方已出的卡 |
| `_current_player_total` | int | 己方当前总点数 |
| `_current_enemy_total` | int | 敌方当前总点数 |
| `_player_wins` | int | 己方胜场数 |
| `_enemy_wins` | int | 敌方胜场数 |
| `_target_wins` | int | 获胜目标 |
| `_is_draw` | bool | 是否平局 |
| `_pending_costs` | Array | 待触发代价ID列表 |

### 4.2 扩展字段计划

| 字段 | 类型 | 用途 | 实现阶段 |
|------|------|------|---------|
| `_round` | int | 当前回合数 | Phase 2 |
| `_pending_buffs` | Array[PendingBuff] | 延迟buff队列 | Phase 2 |
| `_active_buffs` | Array[ActiveBuff] | 当前所有激活buff | Phase 1 |
| `_triggered_effects` | Array[String] | 本回合已触发过的效果ID（防止重复） | Phase 3 |
| `_modifier_stack` | Array[int] | 加成叠层（如"每有一张X，+1"） | Phase 3 |

### 4.3 Context 访问器约定

```gdscript
# 只读查询
func get_player_total() -> int
func get_enemy_total() -> int
func get_round() -> int
func get_player_played_cards() -> Array
func get_card_by_id(instance_id: String) -> CardSnapshot

# 状态修改
func add_player_total(value: int) -> void
func add_enemy_total(value: int) -> void
func add_pending_buff(buff: Dictionary) -> void      # 预约延迟效果
func add_triggered_effect(effect_id: String) -> void  # 标记已触发

# 目标查询
func get_player_cards() -> Array        # 所有己方出牌
func get_enemy_cards() -> Array         # 所有敌方出牌
func get_card_by_instance_id(id: String) -> CardSnapshot  # 精准查找
```

---

## 5. 执行顺序机制

### 5.1 为什么顺序重要

```
场景：己方出 [卡A:+3点, 卡B:每有一张+1点]

执行顺序不同，结果不同：

顺序A（先计算+3，再+1）：
  → 卡A基础+3=3
  → 每有一张+1，触发时只有卡A自己 → +1
  → 卡A最终=4

顺序B（先+1，再+3）：
  → 卡A基础+0
  → 每有一张+1，触发时只有卡A自己 → +1
  → 卡A最终=4

（此例恰好结果相同，但复杂场景下顺序决定生死）
```

### 5.2 优先级分组执行

所有 EffectHandler 在执行前由 Registry 按 `get_priority()` 排序，然后依次调用 `apply(context)`。

```
排序结果：
  EffectHandler_A (priority=0, Preemptive)
  EffectHandler_B (priority=50, BuffDebuff)
  EffectHandler_C (priority=100, ValueMod)
  EffectHandler_D (priority=100, ValueMod)
  EffectHandler_E (priority=200, PostProcess)
  EffectHandler_F (priority=300, RuleOverride)

执行流程：
  for handler in sorted_handlers:
      handler.apply(context)  # 每个独立执行，不感知其他handler
```

### 5.3 每个模块只做它规定的事

**EffectHandler 之间完全隔离**，不传递状态，不互相调用。

```
EffectHandler_A.apply(context):
    context.add_player_total(3)  ← 只做这件事，不关心后面谁执行

EffectHandler_B.apply(context):
    # 读取 context 里的当前总点数，独立计算
    var total = context.get_player_total()
    context.add_player_total(1)  ← 也只做自己的事
```

两者的执行结果都是累加到同一个 context.total 上，最终系统读取 `context.get_player_total()` 得出最终值。

### 5.4 可视化执行时序

```
BattleFlowManager._process_selected_cards_static()

  ┌─────────────────────────────────────────────────────┐
  │ Step 1: 创建 EffectContext                          │
  │   context._current_player_total = 0                 │
  │   context._current_enemy_total = 0                 │
  └──────────────────────┬──────────────────────────────┘
                         ↓
  ┌─────────────────────────────────────────────────────┐
  │ Step 2: 收集所有特效ID，按优先级排序                │
  │   [buff_debuff_handler, value_mod_handler, ...]    │
  └──────────────────────┬──────────────────────────────┘
                         ↓
  ┌─────────────────────────────────────────────────────┐
  │ Step 3: 依次执行每个 Handler.apply(context)        │
  │                                                  │
  │   Handler_A (priority=0):                         │
  │     context.add_player_total(3)  ← 3              │
  │                                                  │
  │   Handler_B (priority=50):                        │
  │     context.add_player_total(1)  ← 4              │
  │                                                  │
  │   Handler_C (priority=100):                        │
  │     context.add_pending_buff({...})  ← 预约下回合   │
  │                                                  │
  │   Handler_D (priority=300):                        │
  │     temp = context.get_player_total()             │
  │     context.set_enemy_total(temp)  ← 规则覆盖      │
  │                                                  │
  └──────────────────────┬──────────────────────────────┘
                         ↓
  ┌─────────────────────────────────────────────────────┐
  │ Step 4: 应用延迟buff（下回合开始时）                  │
  │   context._pending_buffs → 应用到对应卡牌            │
  └─────────────────────────────────────────────────────┘
```

---

## 6. Buff 系统设计

### 6.1 Buff 抽象

```gdscript
## Buff 基类（抽象）
class_name Buff
extends RefCounted

var _source_effect_id: String
var _source_card_id: String
var _is_permanent: bool

func _init(effect_id: String, card_id: String, permanent: bool):
	_source_effect_id = effect_id
	_source_card_id = card_id
	_is_permanent = permanent

## 应用到目标卡牌
func apply_to(target_card: CardInstance) -> void:
	pass

## 回合结束时调用，返回是否应该移除
func on_round_end() -> bool:
	return not _is_permanent

func is_permanent() -> bool:
	return _is_permanent

func get_source_card_id() -> String:
	return _source_card_id
```

```gdscript
## 临时Buff（持续N回合）
class_name TemporaryBuff
extends Buff

var _remaining_rounds: int
var _delta_value: int
var _description: String

func _init(effect_id, card_id, rounds, delta, desc):
	super._init(effect_id, card_id, false)
	_remaining_rounds = rounds
	_delta_value = delta
	_description = desc

func apply_to(target_card: CardInstance) -> void:
	target_card.add_delta(_delta_value)

func on_round_end() -> bool:
	_remaining_rounds -= 1
	if _remaining_rounds <= 0:
		target_card.add_delta(-_delta_value)  # 移除加成
		return true  # 移除此buff
	return false

func get_description() -> String:
	return "%s (剩余%d回合)" % [_description, _remaining_rounds]
```

```gdscript
## 永久Buff
class_name PermanentBuff
extends Buff

var _delta_value: int
var _description: String

func _init(effect_id, card_id, delta, desc):
	super._init(effect_id, card_id, true)
	_delta_value = delta
	_description = desc

func apply_to(target_card: CardInstance) -> void:
	target_card.add_delta(_delta_value)  # 永久加成

func on_round_end() -> bool:
	return false  # 不移除

func get_description() -> String:
	return _description
```

### 6.2 Buff 存储

```gdscript
## CardInstance 新增字段
var _active_buffs: Array[Buff] = []

func add_buff(buff: Buff) -> void:
	_active_buffs.append(buff)
	buff.apply_to(self)

func remove_buff(buff: Buff) -> void:
	if _active_buffs.has(buff):
		buff.on_remove(self)
		_active_buffs.erase(buff)

func get_buffs() -> Array[Buff]:
	return _active_buffs.duplicate()
```

---

## 7. 目标选择系统

### 7.1 目标过滤器

复杂效果需要精确指定目标。通过 `TargetSelector` 抽象：

```gdscript
## 目标选择器
class_name TargetSelector
extends RefCounted

enum Scope { PLAYER, ENEMY, ALL }
enum Filter { ALL, NOT_SELF, HIGHEST_VALUE, LOWEST_VALUE, RANDOM }

var _scope: Scope
var _filter: Filter
var _count: int = 1

func select(context: EffectContext, source_card_id: String) -> Array[CardSnapshot]:
	var pool: Array = []
	match _scope:
		Scope.PLAYER:  pool = context.get_player_played_cards()
		Scope.ENEMY:   pool = context.get_enemy_played_cards()
		Scope.ALL:     pool = context.get_player_played_cards() + context.get_enemy_played_cards()

	# 过滤
	if _filter == Filter.NOT_SELF:
		pool = pool.filter(func(c): return c.get_card_id() != source_card_id)
	elif _filter == Filter.HIGHEST_VALUE:
		pool = [pool.reduce(func(a, b): return a.get_final_value() > b.get_final_value() ? a : b)]
	elif _filter == Filter.LOWEST_VALUE:
		pool = [pool.reduce(func(a, b): return a.get_final_value() < b.get_final_value() ? a : b)]
	elif _filter == Filter.RANDOM:
		pool.shuffle()

	return pool.slice(0, mini(_count, pool.size()))
```

### 7.2 使用示例

```gdscript
## 给己方除自己外点数最高的卡 +3
class_name BuffHighestAllyEffect
extends IEffectHandler

var _selector: TargetSelector

func _init():
	_selector = TargetSelector.new()
	_selector._scope = TargetSelector.Scope.PLAYER
	_selector._filter = TargetSelector.Filter.NOT_SELF
	_selector._count = 1
	# 在外部设置 filter = HIGHEST_VALUE

func apply(context: EffectContext) -> void:
	var targets = _selector.select(context, context._source_card_id)
	for t in targets:
		t.add_delta(_bonus)
```

---

## 8. 效果注册机制

### 8.1 EffectRegistry

```gdscript
class_name EffectRegistry
extends Node

var _handlers: Dictionary = {}  # effect_id → IEffectHandler instance

func register(effect_id: String, handler: IEffectHandler) -> void:
	_handlers[effect_id] = handler

func get_handler(effect_id: String) -> IEffectHandler:
	if _handlers.has(effect_id):
		return _handlers[effect_id]
	push_warning("[EffectRegistry] Unknown effect: %s" % effect_id)
	return null

## 返回按优先级排序后的效果列表
func get_effects_sorted_by_priority(effect_ids: Array[String]) -> Array[IEffectHandler]:
	var result: Array[IEffectHandler] = []
	for eid in effect_ids:
		var h = get_handler(eid)
		if h:
			result.append(h)
	result.sort_custom(func(a, b): return a.get_priority() < b.get_priority())
	return result
```

### 8.2 JSON 配置驱动

```json
{
  "card_prototypes": [
    {
      "prototype_id": "card_spirit_ward",
      "card_class": "Creature",
      "base_value": 4,
      "effect_ids": ["buff_highest_ally_3", "cost_next_turn_skip"],
      "cost_id": ""
    },
    {
      "prototype_id": "card_blessed_aid",
      "card_class": "Bond",
      "base_value": 3,
      "effect_ids": ["temp_buff_all_allies_2_1r"],
      "cost_id": ""
    }
  ]
}
```

加载时：
```
effect_ids: ["buff_highest_ally_3", "cost_next_turn_skip"]
  ↓
EffectRegistry.get_effects_sorted_by_priority(effect_ids)
  ↓
按优先级排序后依次执行
```

---

## 9. 执行阶段划分

一场战斗按以下阶段执行特效：

```
PRE_BATTLE          → 战斗开始前（用于放置场地buff等）
PRE_ROUND           → 回合开始时（应用延迟buff、检测触发条件）
CALCULATE_VALUES    → 计算卡牌点数（基础值）
APPLY_IMMEDIATE     → 应用即时数值效果（+点/-点）
APPLY_CONDITIONAL   → 应用条件触发效果
APPLY_DELAYED       → 应用本回合触发的延迟效果
APPLY_POST_PROCESS  → 后处理（标记下回合效果）
POST_ROUND          → 回合结束时（触发代价、检测死亡）
POST_BATTLE         → 战斗结束（计算战利品、移除临时buff）
```

**EffectHandler 通过 `get_priority()` 落入对应阶段，无需显式声明阶段。**

---

## 10. 效果定义示例

### 10.1 简单效果（10行）

```gdscript
## 直接给己方 +3 点
class_name FixedBonusEffect
extends IEffectHandler

var _bonus: int

func _init(bonus: int = 3):
	_bonus = bonus

func apply(context: EffectContext) -> void:
	context.add_player_total(_bonus)

func get_priority() -> int:
	return EffectEnums.EffectPriority.Normal

func get_description() -> String:
	return "+%d 点" % _bonus
```

### 10.2 复杂效果：延迟Buff（50行）

```gdscript
## 本回合给己方 +0，但下回合给己方点数最高的卡 +N 点
class_name DelayedBuffHighestEffect
extends IEffectHandler

var _bonus: int
var _target_filter: int  # HIGHEST / LOWEST / RANDOM

func _init(bonus: int, filter: int = TargetSelector.Filter.HIGHEST_VALUE):
	_bonus = bonus
	_target_filter = filter

func apply(context: EffectContext) -> void:
	# 立即给0点（或者给一个较低的基础值）
	context.add_player_total(0)

	# 预约下回合开始时执行的buff
	context.add_pending_buff({
		"execute_at": "round_start",          # 下回合开始
		"target_scope": TargetSelector.Scope.PLAYER,
		"target_filter": _target_filter,
		"buff_type": "TemporaryBuff",
		"bonus": _bonus,
		"rounds": 1,
		"source_effect_id": "delayed_buff_highest"
	})

func get_priority() -> int:
	return EffectEnums.EffectPriority.ValueMod

func get_description() -> String:
	return "下回合给己方 %s 卡 +%d 点" % [_target_filter, _bonus]
```

### 10.3 条件效果

```gdscript
## 当己方总点数高于敌方时，额外 +5 点
class_name ConditionalBonusEffect
extends IEffectHandler

var _threshold: int
var _bonus: int

func _init(threshold: int, bonus: int):
	_threshold = threshold
	_bonus = bonus

func apply(context: EffectContext) -> void:
	if context.get_player_total() > context.get_enemy_total():
		context.add_player_total(_bonus)

func get_priority() -> int:
	return EffectEnums.EffectPriority.Conditional

func get_description() -> String:
	return "若己方点数>%d，额外 +%d" % [_threshold, _bonus]
```

---

## 11. Phase 实现计划

### Phase 1：基础框架（最小改动）

- [ ] 新增 `Buff` 基类 + `TemporaryBuff` + `PermanentBuff`
- [ ] CardInstance 增加 `_active_buffs` 数组及访问方法
- [ ] EffectContext 增加 `_active_buffs` 字段
- [ ] 新增 `TargetSelector` 类

**此阶段目标：** 不改变现有 `FixedBonusEffect` 等实现，只需注册新类即可运行。

### Phase 2：延迟机制

- [ ] EffectContext 增加 `_pending_buffs` 字段
- [ ] `context.add_pending_buff()` 方法
- [ ] BattleFlowManager 在 `ROUND_END_ANIMATING` 状态时收集，下回合 `PLAYER_SELECTING` 前应用
- [ ] 新增 `DelayedBuffHighestEffect` 作为第一个延迟特效示例

### Phase 3：条件与重复检测

- [ ] EffectContext 增加 `_triggered_effects` 防重复
- [ ] EffectContext 增加 `_round` 字段
- [ ] 新增 `ConditionalBonusEffect`
- [ ] 完善文档，更新 `card_prototypes.json` 示例

---

## 12. 存档设计

Buff 的存档只存以下字段：

```json
{
    "card_instances": [
        {
            "prototype_id": "card_spirit_ward",
            "delta_value": 2,
            "bind_status": 0,
            "active_buffs": [
                {
                    "buff_type": "TemporaryBuff",
                    "bonus": 3,
                    "remaining_rounds": 1,
                    "source_effect_id": "delayed_buff_highest"
                },
                {
                    "buff_type": "PermanentBuff",
                    "bonus": 1,
                    "source_effect_id": "soul_link"
                }
            ]
        }
    ]
}
```

**原则：Buff 配置（次数、增量）在 JSON 中定义，不在运行时动态生成新字段。**

---

## 13. 核心优势总结

| 设计点 | 优势 |
|--------|------|
| `IEffectHandler` 接口 | 新增效果0改动，只需注册 |
| 优先级分组 | 顺序由系统控制，handler 只管自己逻辑 |
| `EffectContext` 共享 | 模块间唯一通信渠道，信息不散落 |
| `Buff` 抽象 | 临时/永久 buff 共用一套存储机制 |
| `TargetSelector` 分离 | 目标选择逻辑与效果逻辑解耦 |
| Registry 驱动 | 所有效果配置在 JSON，程序不硬编码 |
| Phase 递增 | 每个 Phase 独立可运行，不破坏现有功能 |

---

## 14. 效果触发时机系统 (v2.0)

### 14.1 触发时机枚举

```gdscript
class_name EffectTriggerTiming
extends RefCounted

enum Timing {
    IMMEDIATE = 0,      # 即时 - 点数计算后立即执行
    SEQUENTIAL = 1,      # 顺序 - 按出牌顺序逐张执行
    DELAYED_NEXT = 2,   # 延迟下一张 - 效果作用于下一张出的牌
    DELAYED_ROUND = 3,   # 延迟回合 - 下回合生效
    MANUAL = 4           # 手动 - 需要玩家选择目标
}
```

### 14.2 触发时机说明

| 时机 | 值 | 说明 | 执行阶段 |
|------|---|------|----------|
| `IMMEDIATE` | 0 | 即时效果，点点数计算后立即执行 | 基础点数计算后 |
| `SEQUENTIAL` | 1 | 按出牌顺序逐张执行效果 | 每张牌触发一次 |
| `DELAYED_NEXT` | 2 | 效果作用于下一张出的牌 | 当前牌效果作用于下一张 |
| `DELAYED_ROUND` | 3 | 效果延迟到下回合生效 | 下回合开始时 |
| `MANUAL` | 4 | 需要玩家手动选择目标 | 等待玩家输入 |

### 14.3 扩展的 IEffectHandler 接口

```gdscript
class_name IEffectHandler
extends RefCounted

## 获取效果触发时机
func get_trigger_timing() -> int:
    return EffectTriggerTiming.Timing.IMMEDIATE

## 获取此效果作用于哪些卡牌
## context: 战斗上下文
## source_card_id: 拥有此效果的卡牌ID
## 返回: 卡牌实例ID数组
func get_target_card_ids(context: EffectContext, source_card_id: String) -> Array:
    return [source_card_id]  # 默认只作用于自己

## 执行效果（修改 context 中的总点数等）
func apply(context: EffectContext) -> void:
    pass

## 对特定卡牌执行效果（修改单张卡的点数）
func apply_to_card(context: EffectContext, target_card_id: String) -> void:
    pass

## 获取优先级（同一 Timing 内排序）
func get_priority() -> int:
    return EffectEnums.EffectPriority.Normal

## 获取效果描述
func get_description() -> String:
    return ""
```

### 14.4 出牌顺序追踪

EffectContext 新增字段：

```gdscript
var _selection_order: Array = []  # 出牌顺序 ["id1", "id2", "id3"]

func get_selection_order() -> Array
func set_selection_order(order: Array) -> void
func get_next_card_in_order(current_id: String) -> String  # 获取下一张
func get_card_order_index(card_id: String) -> int
func get_card_snapshot_by_id(card_id: String) -> CardSnapshot
```

### 14.5 执行流程

```
1. 玩家选择出牌顺序 → selection_order
2. 计算基础点数 → context._current_player_total
3. 按触发时机分组执行：
   a. IMMEDIATE → 立即修改 total
   b. SEQUENTIAL → 按顺序逐张修改
   c. DELAYED_NEXT → 当前牌效果作用于下一张
   d. DELAYED_ROUND → 预约下回合
   e. MANUAL → 等待玩家选择
4. 执行代价 (cost)
5. 比较总点数判定胜负
```

### 14.6 示例效果实现

#### 14.6.1 即时效果（已有）

```gdscript
class_name FixedBonusEffect
extends IEffectHandler

func get_trigger_timing() -> int:
    return EffectTriggerTiming.Timing.IMMEDIATE

func apply(context: EffectContext) -> void:
    context.add_player_total(_bonus)
```

#### 14.6.2 延迟下一张效果（新增）

```gdscript
class_name BoostNextCardEffect
extends IEffectHandler

func get_trigger_timing() -> int:
    return EffectTriggerTiming.Timing.DELAYED_NEXT

## 返回下一张牌的ID
func get_target_card_ids(context: EffectContext, source_card_id: String) -> Array:
    var next_card = context.get_next_card_in_order(source_card_id)
    if not next_card.is_empty():
        return [next_card]
    return []

## 不修改 total，而是修改目标牌的 delta
func apply_to_card(context: EffectContext, target_card_id: String) -> void:
    var card = context.get_card_snapshot_by_id(target_card_id)
    if card:
        card.add_delta_value(_bonus)
```

### 14.7 CardSnapshot 新增方法

```gdscript
func add_delta_value(delta: int) -> void:
    _final_value += delta
    if _final_value < 0:
        _final_value = 0
```

### 14.8 扩展 EffectRegistry

```gdscript
func get_effects_by_timing(effect_ids_with_source: Array) -> Dictionary:
    # 返回按触发时机分组的 effects
    # 格式: {timing: [{"handler": IEffectHandler, "source_id": "card_id"}, ...]}
```

### 14.9 JSON 配置示例

```json
{
    "card_test_boost": {
        "display_name": "测试增幅牌",
        "base_value": 5,
        "effect_ids": ["boost_next_3"]
    },
    "card_double_boost": {
        "display_name": "双重增幅",
        "base_value": 4,
        "effect_ids": ["boost_next_3", "boost_next_3"]
    },
    "card_instant": {
        "display_name": "即时增幅",
        "base_value": 3,
        "effect_ids": ["fixed_bonus_2"]
    }
}
```

### 14.10 扩展注意事项

1. **向后兼容**：IMMEDIATE 效果与原有逻辑完全兼容
2. **MANUAL 效果**：目前会在日志中提示跳过，后续需要 UI 层配合实现
3. **DELAYED_ROUND**：需要 BattleFlowManager 在下回合开始时处理

---

## 15. 代价系统 (Cost System)

### 15.1 代价接口

```gdscript
class_name ICostHandler
extends RefCounted

func trigger(context: CostContext) -> void:
    pass
```

### 15.2 已实现代价

| 代价ID | 类名 | 效果 |
|--------|------|------|
| `self_destroy` | SelfDestroyCost | 使用后立即销毁该卡牌 |
| `next_turn_unusable` | NextTurnUnusableCost | 下回合不可用 |
| `delayed_destroy` | DelayedDestroyCost | 下回合结束后销毁 |
| `value_buff_2` | ValueBuffCost | 增加2点数值 |
| `value_buff_3` | ValueBuffCost | 增加3点数值 |
| `value_reduction_2` | ValueReductionCost | 减少2点数值 |

### 15.3 CostContext

```gdscript
class_name CostContext
extends RefCounted

var _effect_context: EffectContext  # 战斗上下文
var _report: BattleReport          # 战斗报告
var _source_card: CardSnapshot     # 触发代价的卡牌
var _owner: String                 # "player" 或 "enemy"

## 销毁触发代价的卡牌
func destroy_source_card() -> void

## 禁用触发代价的卡牌（下回合不可用）
func disable_source_card() -> void
```

### 15.4 代价执行时机

代价在**回合结算后**执行：

```
1. 计算基础点数
2. 执行所有效果 (effect_ids)
3. 比较总点数，判定胜负
4. 执行代价 (cost_id) → 修改卡牌状态
```

### 15.5 JSON 配置示例

```json
{
    "card_explosive": {
        "display_name": "爆炸剑",
        "base_value": 8,
        "effect_ids": ["fixed_bonus_3"],
        "cost_id": "self_destroy"
    },
    "card_delayed_bomb": {
        "display_name": "定时炸弹",
        "base_value": 6,
        "effect_ids": [],
        "cost_id": "delayed_destroy"
    },
    "card_weakened": {
        "display_name": "虚弱之刃",
        "base_value": 10,
        "effect_ids": [],
        "cost_id": "value_reduction_2"
    }
}
```

### 15.6 创建新代价

1. 创建类继承 `ICostHandler`
2. 在 `CostRegistry._register_all_costs()` 中注册
3. 在 JSON 中使用 `cost_id` 引用
