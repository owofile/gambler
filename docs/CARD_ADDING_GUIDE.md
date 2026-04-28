# 卡牌添加指南

> **版本**: v1.0
> **日期**: 2026-04-28

---

## 1. 概述

本文档说明如何向游戏中添加新卡牌，包括数据定义、纹理设置、效果配置等。

---

## 2. 卡牌数据定义

### 2.1 JSON 文件位置

```
res://resources/card_prototypes.json
```

### 2.2 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `card_class` | String | ✅ | 卡牌类型：Artifact, Bond, Creature, Concept, Sin, Authority |
| `base_value` | int | ✅ | 基础点数 |
| `effect_ids` | Array | ❌ | 特效ID列表，例：`["fixed_bonus_2"]` |
| `cost_id` | String | ❌ | 代价ID，例：`"self_destroy"` |
| `is_lockable` | bool | ❌ | 是否可被锁定，默认 `true` |
| `texture` | String | ❌ | 纹理路径，例：`"res://assets/cards/textures/my_card.png"` |
| `display_name` | String | ❌ | 显示名称，例：`"锈剑"` |

### 2.3 卡牌类型对应点数区间

| 类型 | 区间 | 说明 |
|------|------|------|
| Artifact | 5-9 | 器物 |
| Creature | 3-6 | 生灵 |
| Concept | 2-7 | 概念 |
| Bond | 2-4 | 羁绊 |
| Sin | 6-10 | 罪孽 |
| Authority | 4-8 | 权能 |

---

## 3. 添加新卡牌示例

### 3.1 基础卡牌

```json
{
    "card_new_sword": {
        "card_class": "Artifact",
        "base_value": 6,
        "effect_ids": [],
        "cost_id": "",
        "is_lockable": true,
        "texture": "res://assets/cards/textures/new_sword.png",
        "display_name": "新剑"
    }
}
```

### 3.2 带特效的卡牌

```json
{
    "card_blessed_blade": {
        "card_class": "Artifact",
        "base_value": 7,
        "effect_ids": ["fixed_bonus_3", "rule_reversal"],
        "cost_id": "",
        "is_lockable": true,
        "texture": "res://assets/cards/textures/blessed_blade.png",
        "display_name": "祝福之刃"
    }
}
```

### 3.3 带代价的卡牌

```json
{
    "card_sacrificial_dagger": {
        "card_class": "Artifact",
        "base_value": 12,
        "effect_ids": [],
        "cost_id": "self_destroy",
        "is_lockable": true,
        "texture": "res://assets/cards/textures/dagger.png",
        "display_name": "牺牲匕首"
    }
}
```

---

## 4. 纹理设置

### 4.1 目录结构

```
assets/
└── cards/
    └── textures/
        ├── card_rusty_sword.png    # 卡牌纹理
        ├── card_ancient_shield.png
        ├── default.png            # 默认/占位纹理
        └── ...
```

### 4.2 纹理要求

| 要求 | 说明 |
|------|------|
| 格式 | PNG 或其他 Godot 支持的格式 |
| 建议尺寸 | 256x256 或 512x512 |
| 透明背景 | 建议使用透明背景 PNG |

### 4.3 设置步骤

1. 将纹理图片放入 `res://assets/cards/textures/` 目录
2. 在 JSON 中设置 `texture` 字段为完整路径
3. 如果不设置 `texture`，将使用默认纹理

---

## 5. 特效系统

### 5.1 已实现特效

| 特效ID | 名称 | 效果 |
|--------|------|------|
| `fixed_bonus_2` | 固定加成+2 | 增加2点 |
| `fixed_bonus_3` | 固定加成+3 | 增加3点 |
| `fixed_bonus_5` | 固定加成+5 | 增加5点 |
| `rule_reversal` | 规则反转 | 交换双方总点数 |

### 5.2 代价系统

| 代价ID | 名称 | 效果 |
|--------|------|------|
| `self_destroy` | 自我毁灭 | 使用后摧毁该卡牌 |
| `next_turn_unusable` | 下回合不可用 | 下回合不能使用 |

---

## 6. CardData 类结构

### 6.1 属性列表

```gdscript
class_name CardData
extends RefCounted

var prototype_id: String      # 唯一标识符
var card_class: CardClass   # 卡牌类型枚举
var base_value: int         # 基础点数
var effect_ids: Array       # 特效ID列表
var cost_id: String         # 代价ID
var is_lockable: bool       # 是否可被锁定
var texture_path: String    # 纹理路径
var display_name: String    # 显示名称
```

### 6.2 CardClass 枚举

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

---

## 7. 完整添加流程

### Step 1: 准备纹理（可选）

将图片放入 `res://assets/cards/textures/` 目录

### Step 2: 编辑 JSON

在 `res://resources/card_prototypes.json` 中添加新条目

### Step 3: 重启游戏

Godot 会自动加载更新后的 JSON 数据

### Step 4: 验证

在游戏中查看新卡牌是否正确显示（名称、点数、纹理）

---

## 8. 架构图

```
card_prototypes.json
        ↓
CardPrototypeRegistry._parse_prototypes()
        ↓
CardData (运行时对象)
        ↓
CardWidget.setup() / _apply_texture()
        ↓
显示卡牌 (纹理、名称、点数)
```

---

## 9. 注意事项

1. **prototype_id 唯一性**：确保每个卡牌的 `prototype_id` 唯一
2. **纹理路径格式**：使用 Godot 资源路径格式 `res://...`
3. **JSON 语法**：确保 JSON 格式正确，缺少逗号会导致解析失败
4. **display_name 建议设置**：不设置时默认使用 prototype_id