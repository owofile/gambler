# Gambler 玩法设计文档

> 文档版本：v3.0
> 更新日期：2026-04-29
> 项目状态：**核心机制已实现，分类系统支持热更新，内容和UI仍在开发中**

---

## 一、设计理念

Gambler 是一款**卡牌消耗驱动**的箱庭探索游戏。

### 核心理念

**没有固定卡组，只有对游戏的理解。**

传统卡牌游戏：组建一套牌 → 保持牌组稳定 → 优化出牌策略
Gambler：持续获取卡牌 → 战斗中消耗卡牌 → 心跳机制强制销毁随机卡牌 → 玩家必须适应不断变化的牌池

### 核心循环

```
┌─────────────────────────────────────────────────────────────┐
│                      箱庭探索                                │
│  探索有限区域，与物体交互，与NPC对话，发现新卡牌              │
└─────────────────────┬───────────────────────────────────────┘
                      ↓ 获得卡牌
┌─────────────────────┴───────────────────────────────────────┐
│                      卡组池                                  │
│  动态变化的卡牌集合（上限20张），随时可能被心跳销毁           │
└─────────────────────┬───────────────────────────────────────┘
                      ↓ 战斗
┌─────────────────────┴───────────────────────────────────────┐
│                      战斗流程                                │
│  每回合选择3张牌出站 → 消耗卡牌 → 获得战利品                  │
└─────────────────────┬───────────────────────────────────────┘
                      ↓ 间隔触发
┌─────────────────────┴───────────────────────────────────────┐
│                      心跳机制                                │
│  定时从卡组中随机销毁1-2张卡牌，强制玩家保持牌池精简          │
└─────────────────────────────────────────────────────────────┘
```

### 设计目的

1. **消除"完美牌组"概念**：玩家无法依赖特定组合，必须理解每张卡的独立价值
2. **增加紧迫感**：心跳机制创造时间压力，不能无限制囤积卡牌
3. **鼓励冒险**：为了抵消心跳损失，玩家需要主动探索获取更多卡牌
4. **策略多样性**：根据当前牌池实时调整战术，而非执行预定计划

---

## 二、核心机制详解

### 2.1 卡组池（Deck Pool）

**不同于传统卡牌游戏的"牌组"概念**：
- 玩家拥有的是一个**动态卡牌池**，上限 20 张
- **没有套牌数量限制**，玩家可以囤积大量卡牌
- **心跳机制会强制销毁**，所以囤积是有风险的
- 锁定（Locked）状态的卡牌**不会被心跳销毁**

**卡牌属性**：
```gdscript
instance_id: String      # 唯一实例ID（UUID）
prototype_id: String    # 卡牌原型ID
delta_value: int        # 强化值（可累积）
bind_status: BindStatus # None/Locked/Cursed
```

**卡牌分类与点数范围**（由 `card_categories.json` 定义）：

| 分类 | 显示名 | 点数范围 | 设计意图 |
|------|--------|----------|----------|
| Artifact | 器物 | 5-9 | 高价值但可能有代价 |
| Creature | 生灵 | 3-6 | 中等价值，稳定 |
| Concept | 概念 | 2-7 | 低基础值，可能有强力效果 |
| Bond | 羁绊 | 2-4 | 低价值，但可能有特殊组合 |
| Sin | 罪孽 | 6-10 | 高风险高回报 |
| Authority | 权能 | 4-8 | 中高价值，通常有复杂效果 |
| Bird | 鸟类 | 3-7 | 灵活生物，高机动性 |

**注意**：当前只有 `Sin` 类定义了 `special_effect: "high_risk"`，其他分类的特殊效果待实现。

### 2.2 心跳机制（Heartbeat）

**机制说明**：
- `HeartTimerManager` 定时触发 `heartbeat_triggered` 信号
- 触发时从卡组中**随机选择1-2张卡牌销毁**
- 锁定（Locked）卡牌不会被销毁
- 如果卡组为空或全部锁定，则不销毁

**设计意图**：
- 创造**持续的时间压力**
- 防止玩家"养老"——囤积大量卡牌不行动
- 强制玩家在**数量和質量之间取舍**

**配置参数**：
```gdscript
_interval: float = 60.0  # 心跳间隔（秒）
```

**心跳事件流程**：
```
HeartTimer.trigger()
    ↓
heartbeat_triggered 信号发出
    ↓
订阅者（如 CardDestroyOnHeartbeat）监听并执行销毁
    ↓
从卡组随机选择非锁定卡牌
    ↓
CardMgr.remove_card() 销毁
    ↓
发布 CardLost 事件
```

### 2.3 战斗消耗机制

**核心规则**：
- 每回合玩家选择 **3 张卡牌** 出战
- 敌人也出 3 张卡（纯随机）
- 比较双方总点数，高者赢一回合
- 先赢到目标回合数（3/4/5）获胜

**卡牌消耗（ConsumeWithDrawPolicy）**：
- **出战的 3 张卡被消耗**（从卡组移除）
- 战斗结束后**从卡池补充新卡**（数量待定）
- 战利品系统：从敌人卡组随机获得 1 张卡

**消耗设计意图**：
- 每场战斗都会**净减少卡牌数量**（出战3张 + 战利品1张 ≈ -2）
- 玩家必须**持续探索获取新卡**才能维持牌池
- 与心跳机制形成**双重消耗压力**

### 2.4 箱庭探索

**箱庭（Sandbox）定义**：
- **有限区域的探索空间**
- 不是开放世界，而是精心设计的小型区域
- 包含可交互物体、NPC、隐藏要素

**已实现的探索组件**：
- `PlayerController`：方向键移动，CharacterBody2D
- `BattleTrigger`：进入区域触发战斗
- `ExplorationController`：管理探索模式切换
- `SampleWorld.tscn`：示例地图

**待实现的探索要素**：
- 可交互物体（与卡牌获取相关）
- 传送点/区域解锁
- 隐藏房间/秘密
- 地形解谜

### 2.5 区域Boss

**Boss 设计**：
- 敌人数据（`EnemyData`）包含 `tier`（Grunt/Elite/Boss）
- Boss 需要先赢 **5 回合**（而非 Grunt 的 3 回合）
- Boss 可能拥有特殊效果或更高点数

**区域进度**：
- 击败区域 Boss 解锁新区域（待实现 MapManager）

---

## 三、卡牌获取途径

| 途径 | 说明 | 当前状态 |
|------|------|----------|
| 箱庭探索交互 | 与场景中的物体/NPC互动获得 | 待实现交互逻辑 |
| NPC对话 | NarrativeEngine 触发 GiveItem | 已实现（merchant.json） |
| 战斗战利品 | 胜利后从敌人 loot_pool 获得 | 已实现 |
| 商人购买 | 对话中选择购买选项 | 待实现 |
| 隐藏要素 | 探索发现宝箱/秘密 | 待实现 |

---

## 四、对话与交互系统

### 4.1 对话树（NarrativeEngine）

基于 JSON 的对话树，支持条件判断和效果触发。

**条件类型**：
| 条件 | 说明 |
|------|------|
| `HasFlag` | 检查 WorldState 标志 |
| `HasCard` | 检查玩家是否拥有某张卡牌 |
| `DeckSizeGE` | 检查卡组数量 |
| `NpcAlive` | 检查 NPC 是否存活 |

**效果类型**：
| 效果 | 说明 |
|------|------|
| `GiveItem` | 给玩家卡牌 |
| `RemoveItem` | 从玩家移除卡牌 |
| `SetFlag` | 设置进度标志 |
| `StartBattle` | 触发战斗 |
| `KillNpc` | 标记 NPC 死亡 |

### 4.2 交互设计要点

对话应服务于**卡牌获取**和**剧情推进**：
- NPC 可以根据玩家拥有/不拥有某卡牌给出不同对话
- 某些对话选项需要特定卡牌才能解锁
- 击败特定敌人后才能获得某些卡牌

---

## 五、存档与进度

### 5.1 存档内容（SaveManager）

```gdscript
{
  "version": 1,
  "timestamp": 1234567890,
  "current_zone": "res://scenes/World/zone_01.tscn",
  "player_position": {"x": 100, "y": 200},
  "world_state": { "flag1": value1, ... },
  "card_instances": [卡牌列表 ],
  "inventory": { "items": [...] }
}
```

### 5.2 心跳进度保存

`HeartTimerManager` 支持存档：
- `interval`：心跳间隔
- `is_running`：是否运行中
- `elapsed`：已逝时间

---

## 八、战斗详细流程

```
探索模式
    ↓ [进入 BattleTrigger 或对话触发]
加载战斗场景（BattleUI_V2）
    ↓
BattleCore.start_battle(config)
    ↓
初始化：CardMgr 添加初始手牌（6张）
    ↓
┌─────────────────────────────────────────┐
│         回合循环（状态机）                │
│                                         │
│  PlayerSelectState（玩家选3张牌）        │
│         ↓                                │
│  EnemyRevealState（敌人随机出牌）        │
│         ↓                                │
│  SettlementState（计算胜负+效果）         │
│         ↓                                │
│  RoundEndState（销毁/补牌+心跳检测）      │
│         ↓                                │
│  [检查：是否结束？]                      │
│    ├─ 否 → 回到 PlayerSelectState        │
│    └─ 是 → BattleEndState               │
└─────────────────────────────────────────┘
    ↓
BattleEndState（显示胜负结果）
    ↓
[返回探索 或 触发后续事件]
```

### 战斗中的卡牌流转

```
战前：卡组池（最多20张）
    ↓ 开始战斗
BattleCore.start_battle() → 添加初始手牌（根据 deck_policy）
    ↓ 每回合
PlayerSelectState → 玩家选择3张
    ↓ 确认
这3张卡进入"已出牌"状态
    ↓ 回合结算
RoundEndState:
  - 出战卡被消耗（ConsumeWithDrawPolicy）
  - 战利品卡加入卡组（如果有）
  - 心跳可能触发（随机销毁1-2张）
    ↓ 下一回合
```

---

## 六、卡牌分类系统

### 6.1 分类架构

卡牌分类采用**双轨制设计**，兼顾向后兼容和可扩展性：

```
┌─────────────────────────────────────────────────────────────┐
│                     CardData                                 │
│  ├── card_class: CardClass (枚举) - 旧代码兼容              │
│  └── category_id: String (字符串) - 新代码使用              │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────┴───────────────────────────────────────┐
│                  CategoryRegistry                           │
│  └── 从 card_categories.json 加载分类元数据                │
│      - display_name: 显示名称                              │
│      - icon: 图标路径                                        │
│      - color: 显示颜色                                      │
│      - base_value_range: 推荐点数范围                        │
│      - special_effect: 特殊效果标记                          │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 分类定义文件

**位置**：`resources/card_categories.json`

**结构**：
```json
{
  "Bird": {
    "display_name": "鸟类",
    "description": "飞行生物、天际之灵",
    "icon": "res://assets/icons/bird.png",
    "base_value_range": [3, 7],
    "special_effect": null,
    "color": "#87CEEB"
  }
}
```

### 6.3 当前分类列表

| 分类ID | 显示名 | 点数范围 | 颜色 | 特殊效果 |
|--------|--------|----------|------|----------|
| Artifact | 器物 | 5-9 | #8B4513 | - |
| Bond | 羁绊 | 2-4 | #9370DB | - |
| Creature | 生灵 | 3-6 | #228B22 | - |
| Concept | 概念 | 2-7 | #4169E1 | - |
| Sin | 罪孽 | 6-10 | #8B0000 | high_risk |
| Authority | 权能 | 4-8 | #FFD700 | - |
| Bird | 鸟类 | 3-7 | #87CEEB | - |

### 6.4 添加新分类

**步骤**：
1. 在 `resources/card_categories.json` 中添加新的分类定义
2. 在 `card_prototypes.json` 中使用新的 `card_class` 值

**示例** - 添加"鱼类"：
```json
// card_categories.json
"Fish": {
  "display_name": "鱼类",
  "description": "水中生物、海洋之力",
  "icon": "res://assets/icons/fish.png",
  "base_value_range": [3, 6],
  "special_effect": "aquatic",
  "color": "#1E90FF"
}

// card_prototypes.json
"card_shark": {
  "card_class": "Fish",
  "base_value": 6,
  ...
}
```

### 6.5 核心文件

| 文件 | 职责 |
|------|------|
| `scripts/data/CategoryDefinition.gd` | 分类定义的数据类 |
| `scripts/data/CategoryRegistry.gd` | 分类注册表，从JSON加载 |
| `resources/card_categories.json` | 分类元数据配置 |
| `scripts/data/CardData.gd` | 包含 `category_id` 字段 |
| `scripts/data/CardPrototypeRegistry.gd` | 提供 `get_category_color()` 等辅助方法 |

### 6.6 API 用法

```gdscript
# 获取分类显示名
var name = DataManager.card_registry.get_category_display_name("Bird")  # → "鸟类"

# 获取分类颜色（用于UI）
var color = DataManager.card_registry.get_category_color("Bird")  # → "#87CEEB"

# 获取某分类的所有卡牌
var bird_cards = DataManager.card_registry.get_prototypes_by_category("Bird")

# 检查分类是否存在
var exists = CategoryRegistry.has_category("Dragon")
```

---

## 七、已实现 vs 待实现

### 已实现

| 系统 | 状态 | 核心文件 |
|------|------|----------|
| 卡组池管理 | ✅ | `CardManager.gd` |
| 心跳计时器 | ✅ 框架 | `HeartTimerManager.gd` |
| 身体部件追踪 | ✅ 框架 | `BodyPartManager.gd` |
| 战斗状态机 | ✅ | `BattleCore.gd` + states/ |
| 卡牌消耗政策 | ✅ | `ConsumeWithDrawPolicy.gd` |
| 对话树引擎 | ✅ | `NarrativeEngine.gd` |
| 存档系统 | ✅ | `SaveManager.gd` |
| 事件总线 | ✅ | `EventBus.gd` |
| 玩家移动 | ✅ | `PlayerController.gd` |

### 待实现/不完整

| 系统 | 说明 | 优先级 |
|------|------|--------|
| 心跳 → 卡牌销毁联动 | 当前 HeartTimer 未连接 CardMgr | 高 |
| BodyPart 实际效果 | BodyPart.MOUTH 等 enum 为空 | 高 |
| 交互物体系统 | 场景中可交互获取卡牌的物体 | 高 |
| 物品系统 UI | 背包 UI、商店 UI | 中 |
| 区域/Boss 系统 | MapManager、区域解锁 | 中 |
| 心跳 UI | 显示心跳进度/警告 | 中 |
| 场景切换动画 | SceneChanger 整合 | 低 |

---

## 九、设计建议

### 8.1 心跳机制的平衡

**问题**：如果心跳间隔太短，玩家会感到沮丧；太长则失去压力。

**建议**：
- 初始心跳间隔：**90-120秒**
- 随着游戏进度缩短（困难区域更长探索时间，更频繁心跳）
- 某些身体部件可以**延长心跳间隔**（如 HEART_PART 可延长30秒）

### 8.2 身体部件（Body Parts）设计

当前 `BodyPartManager` 只是框架，建议实际实现：

| 部件 | 效果 |
|------|------|
| HEART | 心跳间隔正常 |
| LUNGS | ？？ |
| EYES | 可发现隐藏物品 |
| MOUTH | 可与特定NPC对话 |
| ARMS | 可触发某些机关 |

### 8.3 卡牌获取 vs 消耗平衡

**目标**：保持卡组数量**相对稳定**，但有轻微净减少趋势

每场战斗理想消耗：
- 出战：-3张
- 战利品：+1张
- **净变化：-2张**

心跳触发频率：
- 假设 90 秒心跳一次
- 每场战斗 5 回合 × 30 秒/回合 = 150 秒
- 每场战斗可能触发 1-2 次心跳 = -2 到 -4 张

**总结**：每场战斗净消耗约 **-4 到 -6 张卡牌**
→ 玩家必须持续探索获取新卡

---

## 十、完整游戏循环（目标）

```
1. 主菜单 → 开始游戏
       ↓
2. 进入第一个箱庭区域（教程区）
       ↓
3. 探索场景
   - 与物体交互获得初始卡牌（Tutorial）
   - 与NPC对话了解游戏机制
   - 触发第一场战斗
       ↓
4. 战斗（使用刚获得的卡牌）
   - 熟悉选牌、出牌、结算流程
   - 理解卡牌消耗机制
       ↓
5. 战斗结束
   - 获得战利品卡牌
   - 心跳触发，销毁随机1-2张
   - 返回探索
       ↓
6. 继续探索
   - 深入区域寻找更多卡牌
   - 准备 Boss 战
       ↓
7. 击败区域 Boss
   - 获得 Boss 特有卡牌
   - 解锁新区域
       ↓
8. [循环] 进入下一个区域
```

---

## 十一、核心文件索引

| 功能 | 文件 |
|------|------|
| 心跳计时器 | `scripts/world/HeartbeatManager.gd` |
| 身体部件 | `scripts/world/BodyManager.gd` |
| 卡组管理 | `scripts/core/CardManager.gd` |
| 战斗状态机 | `scripts/battle/BattleCore.gd` |
| 战斗消耗策略 | `scripts/battle/policies/ConsumeWithDrawPolicy.gd` |
| 对话树引擎 | `scripts/dialogue/NarrativeEngine.gd` |
| 世界状态 | `scripts/world/WorldState.gd` |
| 事件总线 | `scripts/core/EventBus.gd` |
| 玩家控制器 | `scripts/player/PlayerController.gd` |
| 存档管理 | `scripts/world/SaveManager.gd` |
| 分类注册表 | `scripts/data/CategoryRegistry.gd` |
| 分类定义 | `scripts/data/CategoryDefinition.gd` |

---

## 十二、总结

Gambler 的核心魅力在于**卡牌的新鲜感**：你永远不知道下一张会是什么，也永远不知道它什么时候会消失。

- **心跳机制**创造持续的时间压力
- **战斗消耗**要求玩家积极参与而非囤积
- **箱庭探索**提供多样化的卡牌获取途径
- **无固定卡组**让每局游戏都是独特的挑战

当前项目骨架完整，但需要：
1. 实现心跳→卡牌销毁的联动
2. 丰富卡牌和敌人配置
3. 构建交互物体系统
4. 添加心跳 UI 反馈
