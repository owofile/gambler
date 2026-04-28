# 卡牌添加指南

> **版本**: v2.0
> **日期**: 2026-04-28

---

## 1. 概述

本文档说明如何向游戏中添加新卡牌，包括数据定义、纹理设置、效果配置、代价配置等。

---

## 2. 卡牌数据定义

### 2.1 JSON 文件位置

```
res://resources/card_prototypes.json
```

### 2.2 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `prototype_id` | String | ✅ | 唯一标识符，如 `card_rusty_sword` |
| `card_class` | String | ✅ | 卡牌类型 |
| `base_value` | int | ✅ | 基础点数 |
| `effect_ids` | Array | ❌ | 特效ID列表 |
| `cost_id` | String | ❌ | 代价ID |
| `is_lockable` | bool | ❌ | 是否可被锁定 |
| `texture` | String | ❌ | 纹理路径 |
| `display_name` | String | ❌ | 显示名称 |

### 2.3 卡牌类型

```gdscript
enum CardClass {
    Artifact,   # 器物
    Bond,       # 羁绊
    Creature,   # 生灵
    Concept,    # 概念
    Sin,        # 罪孽
    Authority   # 权能
}
```

### 2.4 数值区间建议

| 类型 | 区间 |
|------|------|
| Artifact | 5-9 |
| Creature | 3-6 |
| Concept | 2-7 |
| Bond | 2-4 |
| Sin | 6-10 |
| Authority | 4-8 |

---

## 3. 效果系统

### 3.1 效果触发时机

| 时机 | 值 | 说明 |
|------|---|------|
| `IMMEDIATE` | 0 | 即时效果，点数计算后立即执行 |
| `SEQUENTIAL` | 1 | 按出牌顺序逐张执行 |
| `DELAYED_NEXT` | 2 | 效果作用于下一张出的牌 |
| `DELAYED_ROUND` | 3 | 延迟到下回合生效（待实现） |
| `MANUAL` | 4 | 需要玩家选择目标（待实现） |

### 3.2 已实现特效

| 特效ID | 名称 | 时机 | 效果 |
|--------|------|------|------|
| `fixed_bonus_2` | 固定加成+2 | IMMEDIATE | 直接增加总点数 |
| `fixed_bonus_3` | 固定加成+3 | IMMEDIATE | 直接增加总点数 |
| `fixed_bonus_5` | 固定加成+5 | IMMEDIATE | 直接增加总点数 |
| `rule_reversal` | 规则反转 | IMMEDIATE | 交换双方总点数 |
| `boost_next_3` | 增幅+3 | DELAYED_NEXT | 下一张牌增加3点 |
| `boost_next_5` | 增幅+5 | DELAYED_NEXT | 下一张牌增加5点 |

### 3.3 特效执行流程

```
1. 玩家选择出牌顺序 → [Card_A, Card_B, Card_C]
2. 计算基础点数 → Card_A(5) + Card_B(3) + Card_C(4) = 12
3. 执行 IMMEDIATE 效果 → 直接修改总分
4. 执行 DELAYED_NEXT 效果 → Card_A效果作用于Card_B, Card_B效果作用于Card_C
5. 重新计算总分
```

### 3.4 DELAYED_NEXT 效果示例

```
卡牌：Card_A(base=5, effect=boost_next_3) + Card_B(base=3) + Card_C(base=4)

基础总分 = 12

DELAYED_NEXT 执行：
- Card_A 的 boost_next_3 作用于 Card_B → Card_B 值变为 6
- Card_B 没有 DELAYED_NEXT 效果
- Card_C 没有下一张，跳过

最终总分 = 5 + 6 + 4 = 15
```

---

## 4. 代价系统

### 4.1 代价执行时机

代价在**回合结算后**执行，用于修改卡牌状态。

### 4.2 已实现代价

| 代价ID | 名称 | 效果 |
|--------|------|------|
| `self_destroy` | 自我毁灭 | 使用后**立即**销毁该卡牌 |
| `next_turn_unusable` | 下回合不可用 | 下回合开始时标记为不可用 |
| `delayed_destroy` | 延迟毁灭 | 下回合结束后销毁 |
| `value_buff_2` | 数值增强+2 | 增加2点点数 |
| `value_buff_3` | 数值增强+3 | 增加3点点数 |
| `value_reduction_2` | 数值削减-2 | 减少2点点数 |

### 4.3 代价效果示例

```
卡牌：card_power_sacrifice(base=10, cost=value_reduction_2)

回合结算时：
1. 计算总分 = 10
2. 代价执行 → value_reduction_2 → 卡牌值变为 8
3. 最终总分 = 8
```

### 4.4 代价与效果的时机区别

| 类型 | 执行时机 | 作用对象 |
|------|----------|----------|
| 效果 (effect_ids) | 点数计算后 | 修改总分或单卡值 |
| 代价 (cost_id) | 回合结算后 | 标记卡牌销毁/禁用 |

---

## 5. 完整卡牌示例

### 5.1 基础卡牌

```json
{
    "card_rusty_sword": {
        "card_class": "Artifact",
        "base_value": 7,
        "effect_ids": [],
        "cost_id": "",
        "is_lockable": true,
        "texture": "res://assets/cards/textures/rusty_sword.png",
        "display_name": "锈剑"
    }
}
```

### 5.2 带特效卡牌

```json
{
    "card_booster_alpha": {
        "card_class": "Artifact",
        "base_value": 5,
        "effect_ids": ["boost_next_3"],
        "cost_id": "",
        "is_lockable": true,
        "display_name": "增幅器α"
    }
}
```

### 5.3 带代价卡牌

```json
{
    "card_self_destruct": {
        "card_class": "Artifact",
        "base_value": 8,
        "effect_ids": ["fixed_bonus_3"],
        "cost_id": "self_destroy",
        "is_lockable": true,
        "display_name": "自毁剑"
    }
}
```

### 5.4 组合卡牌

```json
{
    "card_power_sacrifice": {
        "card_class": "Artifact",
        "base_value": 10,
        "effect_ids": [],
        "cost_id": "value_reduction_2",
        "is_lockable": true,
        "display_name": "力量牺牲"
    }
}
```

---

## 6. 纹理设置

### 6.1 目录结构

```
assets/cards/textures/
├── card_rusty_sword.png
├── card_ancient_shield.png
└── lain_test.png
```

### 6.2 要求

| 要求 | 说明 |
|------|------|
| 格式 | PNG（建议透明背景） |
| 尺寸 | 256x256 或 512x512 |

### 6.3 使用

```json
{
    "texture": "res://assets/cards/textures/your_card.png"
}
```

---

## 7. 创建新特效/代价

### 7.1 创建新特效

1. 继承 `IEffectHandler`
2. 实现 `get_trigger_timing()` 和 `apply()`
3. 在 `EffectRegistry._register_all_effects()` 注册

### 7.2 创建新代价

1. 继承 `ICostHandler`
2. 实现 `trigger()`
3. 在 `CostRegistry._register_all_costs()` 注册

---

## 8. 调试日志

运行时可通过日志查看效果和代价触发：

```
[BattleManager] Card xxx has cost: self_destroy
[SelfDestroyCost] Card xxx will be destroyed
[ValueReductionCost] Card xxx reduced by 2, new value: 8
[SettlementState] Settlement report: remove=X, add=Y
```

---

## 9. 注意事项

1. **prototype_id 唯一性**：每个卡牌 ID 必须唯一
2. **纹理路径**：使用 `res://` 格式
3. **JSON 语法**：缺少逗号会导致解析失败
4. **display_name**：建议设置，否则显示 prototype_id