# 动画系统设计文档 v1.0

> **日期**: 2026-04-28
> **状态**: ✅ Phase 1-2 已完成
> **目标**: 构建高度自由，可扩展的动画系统

---

## 1. 已实现架构

### 1.1 文件结构

```
scripts/
├── animation/
│   ├── interfaces/
│   │   └── IAnimation.gd          # 动画接口
│   ├── base/
│   │   ├── BaseAnimation.gd        # 基础类
│   │   ├── SequentialAnimation.gd   # 顺序动画
│   │   └── ParallelAnimation.gd     # 并行动画
│   ├── effects/
│   │   ├── GlowAnimation.gd        # 发光
│   │   ├── BounceAnimation.gd       # 弹跳
│   │   ├── ShakeAnimation.gd       # 抖动
│   │   └── MoveAnimation.gd        # 移动
│   └── particles/
│       └── ParticleAnimation.gd      # 粒子
└── battle/
    └── AnimationRegistry.gd          # 动画注册表
```

---

## 2. 核心接口

### 2.1 IAnimation 接口

```gdscript
class_name IAnimation
extends RefCounted

func play(config: Dictionary, on_complete: Callable) -> void
func stop() -> void
func is_playing() -> bool
func get_animation_name() -> String
```

### 2.2 已实现动画

| 动画 | 说明 |
|-------|------|
| GlowAnimation | 发光效果 |
| BounceAnimation | 弹跳效果 |
| ShakeAnimation | 抖动效果 |
| MoveAnimation | 移动效果 |
| ParticleAnimation | 粒子生成 |
| SequentialAnimation | 顺序播放多个动画 |
| ParallelAnimation | 并行播放多个动画 |

---

## 3. CardWidget 动画集成

### 3.1 已实现

```gdscript
func play_animation(event_name: String, on_complete: Callable) -> void

## 支持事件
## hover - 鼠标悬停
## click - 鼠标点击
## selected - 选中
## particle - 粒子效果
```

### 3.2 使用方式

```gdscript
## CardWidget 自动播放
card_widget.play_animation("hover")
card_widget.play_animation("click")
card_widget.play_animation("selected")
card_widget.play_animation("particle")

## 手动播放
card_widget.play_animation("particle", func(): print("完成"))
```

---

## 4. AnimationRegistry

### 4.1 已注册动画

| 名称 | 类型 |
|------|------|
| glow | GlowAnimation |
| bounce | BounceAnimation |
| shake | ShakeAnimation |
| move | MoveAnimation |
| particle | ParticleAnimation |
| sequential | SequentialAnimation |
| parallel | ParallelAnimation |

### 4.2 使用方式

```gdscript
var reg = get_node("/root/AnimationRegistry")
reg.register("my_anim", MyAnimation.new())
var anim = reg.get_animation("glow")
anim.play(config, callback)
```

---

## 5. 粒子动画参数

```gdscript
{
    "target": Node,
    "particle_count": 23,
    "particle_scene": "res://particles/coin.tscn",
    "spawn_position": Vector2(100, 300),
    "direction": Vector2.RIGHT,
    "spread": 30.0,
    "color": Color.YELLOW,
    "lifetime": 1.0
}
```

---

## 6. 待实现

- [ ] 粒子场景 `scenes/particles/coin.tscn`
- [ ] 真实粒子效果替代 timer 模拟
- [ ] SettlementState 粒子集成
- [ ] 组合动画队列 (3张牌飞向出牌区)

---

## 7. 扩展指南

### 7.1 添加新动画

```gdscript
class_name MyAnimation
extends BaseAnimation

func play(config: Dictionary, on_complete: Callable) -> void:
    _is_playing = true
    # 实现动画逻辑
    _create_timer(duration).start()
    _on_complete = on_complete

func _on_timer_done() -> void:
    _is_playing = false
    _on_complete.call()
```

### 7.2 注册动画

```gdscript
var reg = get_node("/root/AnimationRegistry")
reg.register("my_effect", MyAnimation.new())
```

---

## 8. 兼容性

| 组件 | 状态 |
|------|------|
| BattleCore | ✅ 不受影响 |
| BattleState | ✅ 保留 play_animation 接口 |
| CardManager | ✅ 不变 |
| CardWidget | ✅ 已集成动画 |
| BattleUI_V2 | ✅ 可监听动画信号 |
