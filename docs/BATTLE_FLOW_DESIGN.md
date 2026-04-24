# 战斗流程系统设计文档 (v2.0)

## 更新记录

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-24 | v2.0 | 新战斗流程系统设计，支持动画、单张出牌、状态机控制 |

---

## 1. 设计目标

1. **模块化**：各功能独立，职责清晰
2. **解耦**：UI、流程控制、战斗逻辑互不依赖
3. **可扩展**：方便后续添加新特效、动画、卡牌类型
4. **稳定**：不破坏现有已验证通过的代码

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        SceneRunner                               │
│                    (启动器，维持现状)                           │
└────────────────────────────┬────────────────────────────────────┘
							 │
							 ▼
┌─────────────────────────────────────────────────────────────────┐
│                   BattleFlowManager                             │
│                  (状态机，控制流程)                             │
│  - 管理战斗状态转换                                             │
│  - 调用 BattleManager 执行回合                                   │
│  - 发送流程事件供 UI 订阅                                      │
└────────┬───────────────────────┬───────────────────────┬─────────┘
		 │                       │                       │
		 ▼                       ▼                       ▼
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│ Animation   │        │ CardSelector│        │ BattleUI   │
│Controller   │        │ (选牌管理)  │        │ (界面显示)  │
└─────────────┘        └─────────────┘        └─────────────┘
```

---

## 3. 状态机设计

### 3.1 状态定义

| 状态 | 说明 | 触发条件 |
|------|------|---------|
| `IDLE` | 等待开始 | 初始化完成 |
| `PLAYER_SELECTING` | 玩家选牌中 | 战斗开始 |
| `PLAYER_ANIMATING` | 玩家出牌动画 | 选牌确认 |
| `ENEMY_ANIMATING` | 敌方出牌动画 | 玩家动画完成 |
| `COMPARE_ANIMATING` | 对比动画 | 敌方动画完成 |
| `ROUND_END_ANIMATING` | 回合结束动画 | 对比完成 |
| `BATTLE_END` | 战斗结束 | 达到目标胜场 |

### 3.2 状态转换图

```
IDLE ──▶ PLAYER_SELECTING
			  │
			  ▼
	PLAYER_ANIMATING ◀────┐
			  │             │
			  ▼             │
	ENEMY_ANIMATING       │
			  │             │
			  ▼             │
	COMPARE_ANIMATING     │
			  │             │
			  ▼             │
	ROUND_END_ANIMATING ──┘
			  │
			  ▼
	(回到 PLAYER_SELECTING 或 BATTLE_END)
```

---

## 4. 新增模块

### 4.1 BattleFlowManager

**文件**: `scripts/core/BattleFlowManager.gd`

**职责**：
- 控制战斗流程状态转换
- 调用 BattleManager 执行回合
- 发布流程事件

**接口**：
```gdscript
func start_battle(player_deck: DeckSnapshot, enemy: EnemyData)
func confirm_selection(card_instance_ids: Array[String])
func on_animation_complete(anim_type: String)
func get_current_state() -> State
```

### 4.2 CardSelector

**文件**: `scripts/core/CardSelector.gd`

**职责**：
- 管理玩家选牌状态
- 约束最大/最小选牌数
- 发布选牌变化事件

**接口**：
```gdscript
func set_available_cards(cards: Array[CardInstance])
func select_card(instance_id: String) -> bool
func deselect_card(instance_id: String) -> bool
func toggle_card(instance_id: String) -> bool
func get_selected_ids() -> Array[String]
func get_selected_count() -> int
func confirm()
func clear()
```

**约束**：
- 最大选牌数：3
- 最小选牌数：1
- 不可选已禁用的卡牌

### 4.3 AnimationController

**文件**: `scripts/core/AnimationController.gd`

**职责**：
- 统一管理动画播放
- 提供完成回调

**接口**：
```gdscript
enum AnimType { PLAYER_CARD_ENTER, ENEMY_CARD_REVEAL, COMPARE, ROUND_END }
func play_animation(type: AnimType, data: Dictionary, on_complete: Callable)
func is_playing() -> bool
```

---

## 5. EventBus 事件定义

### 5.1 流程事件（BattleFlowManager 发送）

| 事件名 | 说明 | Payload |
|--------|------|---------|
| `Flow_BattleStart` | 战斗开始 | `{enemy}` |
| `Flow_PlayerSelecting` | 进入选牌阶段 | `null` |
| `Flow_PlayerCardAnimStart` | 玩家出牌动画开始 | `{cards}` |
| `Flow_PlayerCardAnimEnd` | 玩家出牌动画结束 | `null` |
| `Flow_EnemyCardReveal` | 敌方卡牌揭示 | `{card}` |
| `Flow_CompareStart` | 对比动画开始 | `{player_card, enemy_card}` |
| `Flow_RoundEnd` | 回合结束 | `{winner, scores}` |
| `Flow_BattleEnd` | 战斗结束 | `{result}` |

### 5.2 UI 事件（CardSelector 发送）

| 事件名 | 说明 | Payload |
|--------|------|---------|
| `CardSel_Changed` | 选牌变化 | `{selected_ids}` |
| `CardSel_Confirmed` | 选牌确认 | `{selected_ids}` |

---

## 6. 流程时序

```
玩家        UI          CardSelector    BattleFlowManager    AnimationController
 │           │               │                 │                    │
 │           │               │◀─Flow_BattleStart─│                    │
 │◀──────────│───────────────│──────────────────│                    │
 │           │               │                 │                    │
 │◀──────────│───────────────│─Flow_PlayerSelecting                 │
 │           │               │                 │                    │
 │──选择卡牌─▶│               │                 │                    │
 │           │◀─CardSel_Changed──────────────│                    │
 │           │               │                 │                    │
 │──确认出牌─▶│               │                 │                    │
 │           │◀─CardSel_Confirmed───────────│                    │
 │           │               │                 │                    │
 │◀──────────│◀─Flow_PlayerCardAnimStart──│                    │
 │           │               │                 │◀─play_animation───│
 │           │               │                 │                    │
 │           │               │◀─Flow_PlayerCardAnimEnd──│
 │◀──────────│◀─Flow_EnemyCardReveal────────────────────────│
 │           │               │                 │                    │
 │           │               │                 │◀─play_animation───│
 │           │               │                 │                    │
 │           │               │◀─Flow_CompareStart─────────│
 │◀──────────│◀─Flow_CompareStart──────────────────────────────────│
 │           │               │                 │                    │
 │           │               │                 │◀─play_animation───│
 │           │               │                 │                    │
 │           │               │◀─Flow_RoundEnd─────────────│
 │◀──────────│◀─Flow_RoundEnd──────────────────────────────────│
 │           │               │                 │                    │
 │           │               │                 │◀─检查战斗是否结束──│
 │           │               │                 │                    │
 │◀──────────│◀─Flow_PlayerSelecting 或 Flow_BattleEnd─────────
```

---

## 7. 与现有代码的关系

| 现有文件 | 改动 | 说明 |
|---------|------|------|
| `BattleManager.gd` | **不变** | 核心逻辑保持 |
| `CardManager.gd` | **不变** | 卡牌管理保持 |
| `EventBus.gd` | **新增事件** | 添加流程相关事件 |
| `SceneRunner.gd` | **小改动** | 改用 BattleFlowManager |
| `BattleUI.gd` | **重构** | 订阅新事件，动画响应 |

---

## 8. 测试用例

| 测试编号 | 测试内容 | 预期结果 |
|---------|---------|---------|
| T1 | 正常选 3 张牌出牌 | 完整动画流程 |
| T2 | 只选 1 张牌出牌 | 确认按钮禁用 |
| T3 | 动画播放中再次点击 | 无响应 |
| T4 | 连续 3 回合平局 | 第 3 回合判玩家胜 |
| T5 | vengeance 触发 self_destroy | 战斗后卡牌消失 |
| T6 | 禁用卡牌是否可选 | 不可选，显示灰色 |

---

## 9. 实施阶段

### 阶段一：基础框架
1. 新增 `BattleFlowManager` 状态机
2. 新增 `EventBus` 流程事件
3. 让现有 UI 响应新事件（保持动画简单）

### 阶段二：动画系统
4. 新增 `AnimationController`
5. 重写 UI 动画部分
6. 动画回调接入流程

### 阶段三：细节打磨
7. 特效/代价 UI 展示
8. 敌方 AI 出牌逻辑
9. 音效配合
