# 卡牌系统 V2 设计文档

> **版本**: v1.1
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
│   ├── ValueLabel (数值显示)
│   └── HoverInfo (悬停信息面板)
│       └── VBox
│           ├── NameLabel
│           ├── ValueInfoLabel
│           ├── ClassLabel
│           └── EffectsLabel
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
BattleUI_V2._get_card_full_info(card)  # 获取完整信息
        ↓
CardWidget.setup(proto_id, instance_id, value, name, class, effects)
        ↓
用户交互 → card_clicked.emit() / _show_hover_info(true)
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
| `card_name` | String | 卡牌名称 |
| `card_class` | String | 卡牌类型 |
| `card_effects` | String | 卡牌效果描述 |

| 信号 | 参数 | 说明 |
|------|------|------|
| `card_clicked` | card_id | 卡牌被点击 |
| `card_hovered` | card_id | 卡牌被悬停 |
| `card_unhovered` | card_id | 卡牌离开悬停 |

| 方法 | 说明 |
|------|------|
| `setup(proto_id, instance_id, value, name, class, effects)` | 初始化卡牌 |
| `set_enabled(bool)` | 启用/禁用交互 |
| `set_selected(bool)` | 设置选中状态 |
| `play_animation(event_name, on_complete)` | 播放动画 |
| `_show_hover_info(bool)` | 显示/隐藏悬停信息面板 |

#### 重要：显示更新时机

`setup()` 负责设置所有卡牌数据（值、名称、类型、效果），但 `_update_display()` 依赖 `_ready()` 中获取的节点引用（`_value_label`、`_hover_*` 等）。

**正确流程**：
1. `_ready()` 执行 → 获取节点引用
2. `setup()` 调用 → 设置数据
3. `_update_display()` 执行 → 更新 Label 文本

如果在 `_ready()` 中调用 `_update_display()`，而 setup 还未被调用，则显示的是默认值（0）。

---

### 4.2 HoverInfo 面板

鼠标悬停时显示卡牌详细信息：

| 节点 | 内容 |
|------|------|
| `HoverInfo/VBox/NameLabel` | 卡牌名称 |
| `HoverInfo/VBox/ValueInfoLabel` | 数值 |
| `HoverInfo/VBox/ClassLabel` | 类型 |
| `HoverInfo/VBox/EffectsLabel` | 效果 |

---

### 4.3 BattleUI_V2

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

## 10. 经验总结

### 10.1 显示更新时机

**问题**：卡牌数值显示为 0，但数据实际是正确的。

**原因**：
- `_ready()` 在实例化时立即执行，此时节点引用已建立
- `setup()` 稍后被调用，设置 `card_value` 和其他数据
- `_update_display()` 在 `setup()` 中被调用，更新 Label 文本
- 如果在 `_ready()` 中过早调用 `_update_display()`，数据尚未设置

**教训**：`_update_display()` 依赖外部传入的数据，应在 `setup()` 中调用，而非 `_ready()` 中。

### 10.2 节点获取时机

`tsecn` 中定义的节点引用需要在 `_ready()` 中获取，因为：
- 实例化时节点尚未加入场景树
- `_ready()` 时所有子节点已可用
- 获取后保存为成员变量供后续使用

### 10.3 布局配置注意事项

- `PanelContainer` 的 `custom_minimum_size` 控制点击区域
- `ValueLabel` 等使用绝对偏移（`offset_*`）而非 `layout_mode = 2`
- `HoverInfo` 使用锚点 `anchors_preset = 1`（右对齐）配合负偏移定位

---

## 11. 待完成项

- [ ] 完善卡牌贴图系统（根据 prototype_id 加载不同贴图）
- [ ] 添加卡牌入场/退场动画
- [ ] 添加选中动画（缩放、弹跳）
- [ ] 实现拖拽出牌功能
- [ ] 添加卡背/翻牌动画
