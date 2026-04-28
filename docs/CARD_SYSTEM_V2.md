# 卡牌系统 V2 设计文档

> **版本**: v1.0
> **日期**: 2026-04-28

---

## 1. 概述

本文档描述新的模块化卡牌系统设计，通过预制体（Prefab）实现卡牌的复用，减少硬编码。

---

## 2. 设计目标

1. **减少重复代码** - 不再为6张卡牌编写18个独立函数
2. **状态与显示分离** - 卡牌数据（CardInstance）与显示（CardWidget）解耦
3. **统一交互处理** - 所有卡牌共享同一套点击/悬停逻辑
4. **灵活布局** - 卡牌数量和位置可配置

---

## 3. 架构设计

### 3.1 核心组件

```
BattleUI_V2
├── CardWidget (预制体 x6)
│   ├── CardContainer
│   │   └── Sprite (卡牌贴图)
│   ├── ValueLabel (数值)
│   └── HoverInfo (悬停信息)
└── Control (按钮、分数显示等)
```

### 3.2 数据流

```
BattleCore
  └→ show_hand(cards: Array)
        ↓
CardMgr.get_all_cards()
        ↓
BattleUI_V2._create_card_widgets()
        ↓
CardWidget.setup(proto_id, instance_id, value)
        ↓
用户交互 → card_clicked.emit()
        ↓
BattleCore.on_selection_confirmed()
```

---

## 4. 组件定义

### 4.1 CardWidget

| 属性 | 类型 | 说明 |
|------|------|------|
| `card_id` | String | 卡牌实例ID |
| `prototype_id` | String | 卡牌原型ID |
| `card_value` | int | 卡牌数值 |

| 信号 | 参数 | 说明 |
|------|------|------|
| `card_clicked` | card_id | 卡牌被点击 |
| `card_hovered` | card_id | 卡牌被悬停 |
| `card_unhovered` | card_id | 卡牌离开悬停 |

| 方法 | 说明 |
|------|------|
| `setup(proto_id, instance_id, value)` | 初始化卡牌 |
| `set_enabled(bool)` | 启用/禁用交互 |
| `set_selected(bool)` | 设置选中状态 |

### 4.2 BattleUI_V2

| 方法 | 说明 |
|------|------|
| `show_hand(cards)` | 显示所有手牌 |
| `highlight_card(card_id, highlight)` | 高亮/取消高亮 |
| `clear_selection()` | 清空所有选择 |
| `enable_selection(enabled)` | 启用/禁用选择 |

---

## 5. 文件结构

```
scenes/battle/
├── BattleUI_V2.tscn       # 主UI场景
└── widgets/
    └── CardWidget.tscn     # 卡牌预制体

scripts/battle/
├── BattleUI_V2.gd         # 主UI逻辑
└── widgets/
    └── CardWidget.gd       # 卡牌控件脚本
```

---

## 6. 使用流程

### 6.1 初始化

```gdscript
# 1. 加载UI
var ui = preload("res://scenes/battle/BattleUI_V2.tscn").instantiate()
add_child(ui)

# 2. 初始化
ui.initialize(battle_core)

# 3. 显示手牌
ui.show_hand(CardMgr.get_all_cards())
```

### 6.2 交互流程

```
用户点击卡牌
  ↓
CardWidget.card_clicked.emit(card_id)
  ↓
BattleUI_V2._on_card_widget_clicked()
  ↓
BattleUI_V2.highlight_card(card_id, true)
  ↓
BattleUI_V2.card_selected.emit(card_id)
  ↓
BattleCore.on_selection_confirmed()
```

---

## 7. 状态定义

### CardWidget 状态

| 状态 | 视觉表现 |
|------|----------|
| 禁用 | 灰色 (modulate: 0.5, 0.5, 0.5) |
| 默认 | 白色 (modulate: 1.0, 1.0, 1.0) |
| 悬停 | 淡黄 (modulate: 1.1, 1.1, 0.9) |
| 选中 | 高亮 (modulate: 1.3, 1.0, 0.8) |

---

## 8. 布局配置

| 参数 | 值 | 说明 |
|------|---|------|
| `CARD_START_X` | 100 | 起始X坐标 |
| `CARD_START_Y` | 300 | 起始Y坐标 |
| `CARD_SPACING` | 120 | 卡牌间距 |
| `MAX_DISPLAY` | 6 | 最大显示数量 |

---

## 9. 待完成项

- [ ] 完善卡牌贴图系统（根据 prototype_id 加载不同贴图）
- [ ] 添加卡牌入场/退场动画
- [ ] 添加选中动画（缩放、弹跳）
- [ ] 实现拖拽出牌功能
- [ ] 添加卡背/翻牌动画
