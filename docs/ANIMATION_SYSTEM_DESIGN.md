# 动画系统设计文档 v1.1

> **日期**: 2026-04-28
> **状态**: ✅ 已完成
> **版本**: v1.1

---

## 1. 系统概述

动画系统采用 **接口 + 基类 + 具体实现** 的 OOP 架构，支持：
- 独立动画效果（Glow、Bounce、Shake、Move）
- 复合动画（Sequential、Parallel）
- 粒子动画
- 数据驱动的配置方式

### 1.1 设计原则

1. **单一职责**：每个动画类只负责一种效果
2. **开闭原则**：通过继承 `BaseAnimation` 扩展新动画，无需修改现有代码
3. **依赖倒置**：依赖 `IAnimation` 接口，不依赖具体实现
4. **状态管理**：通过 `_is_playing` 状态控制动画生命周期

---

## 2. 文件结构

```
scripts/
├── animation/
│   ├── interfaces/
│   │   └── IAnimation.gd          # 核心接口（契约）
│   ├── base/
│   │   ├── BaseAnimation.gd        # 基础类（通用功能）
│   │   ├── SequentialAnimation.gd   # 顺序播放（复合动画）
│   │   └── ParallelAnimation.gd     # 并行播放（复合动画）
│   ├── effects/
│   │   ├── GlowAnimation.gd        # 发光效果
│   │   ├── BounceAnimation.gd       # 弹跳效果
│   │   ├── ShakeAnimation.gd       # 抖动效果
│   │   └── MoveAnimation.gd        # 移动效果
│   └── particles/
│       └── ParticleAnimation.gd      # 粒子生成
└── battle/
    └── AnimationRegistry.gd          # 动画注册表（单例）
```

---

## 3. 核心接口

### 3.1 IAnimation 接口

所有动画类必须实现此接口。GDScript 没有真正的 interface 语法，靠约定实现：

```gdscript
class_name IAnimation
extends RefCounted

## 播放动画
## target: Node - 要动画的目标节点（不能为 null）
## config: Dictionary - 动画参数，如 {duration: 0.5, loops: 3}
## on_complete: Callable - 动画完成时调用
func play(target: Node, config: Dictionary, on_complete: Callable) -> void

## 停止动画（中断正在播放的动画）
func stop() -> void

## 是否正在播放
func is_playing() -> bool

## 获取动画名称（调试用）
func get_animation_name() -> String
```

**接口契约**：
- `play()` 被调用时，动画开始执行，完成时必须调用 `on_complete`
- `stop()` 被调用时，动画立即停止，`is_playing()` 返回 `false`
- `is_playing()` 返回 `true` 时表示动画正在执行

---

## 4. BaseAnimation 基类

所有动画效果类继承自此类。它提供通用功能和状态管理：

```gdscript
class_name BaseAnimation
extends Node

## ===== 状态变量 =====
var _is_playing: bool = false       # 播放状态标志
var _animation_name: String = ""    # 动画名称（用于调试）
var _timer: Timer = null            # 内部计时器（可选）
var _on_complete: Callable = Callable()  # 完成回调
var _target_node: Node = null       # 目标节点引用

## ===== 核心方法 =====
func play(target: Node, config: Dictionary, on_complete: Callable) -> void
func stop() -> void
func is_playing() -> bool
func get_animation_name() -> String

## ===== 子类可用方法 =====
func set_target(node: Node) -> void                    # 设置目标节点
func get_target() -> Node                              # 获取目标节点
func _create_timer(duration: float) -> Timer           # 创建计时器（自动管理生命周期）
func _clear_timer() -> void                            # 清除计时器
func _on_timer_complete() -> void                      # 计时器到期回调
```

### 4.1 状态流转

```
[空闲] --play()--> [播放中] --完成--> [空闲]
   ^                    |
   |_______stop()_______|
```

**状态说明**：
- **空闲（_is_playing = false）**：动画未执行或已完成
- **播放中（_is_playing = true）**：动画正在执行

### 4.2 play() 执行流程

```gdscript
func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
    _is_playing = true          # 1. 设置为播放状态
    _on_complete = on_complete  # 2. 保存回调
    _target_node = target       # 3. 保存目标引用
    # 4. 子类实现具体动画逻辑
```

### 4.3 计时器管理

```gdscript
func _create_timer(duration: float) -> Timer:
    _clear_timer()                     # 1. 先清除旧计时器
    _timer = Timer.new()               # 2. 创建新计时器
    _timer.one_shot = true             # 3. 单次触发
    _timer.wait_time = duration        # 4. 设置时长
    add_child(_timer)                  # 5. 添加为子节点（生命周期自动管理）
    _timer.timeout.connect(_on_timer_complete)  # 6. 连接信号
    return _timer
```

---

## 5. 已实现动画

### 5.1 GlowAnimation - 发光效果

**文件**: `scripts/animation/effects/GlowAnimation.gd`

**效果**: 放大 + 变亮 → 恢复原状

**参数**:

```gdscript
config = {
    "duration": 0.3,      # 动画总时长（默认 0.3）
    "min_scale": 1.0,     # 最小缩放（默认 1.0）
    "max_scale": 1.15     # 最大缩放（默认 1.15）
}
```

**实现原理**:
```
tween 0 → duration*0.5: modulate *= Color(1.2,1.2,0.8), scale → max_scale
tween 1 → duration*0.5: modulate 恢复, scale → min_scale
callback
```

---

### 5.2 BounceAnimation - 弹跳效果

**文件**: `scripts/animation/effects/BounceAnimation.gd`

**效果**: 向上弹跳 → 回落，循环 N 次

**参数**:

```gdscript
config = {
    "duration": 0.15,        # 单次弹跳时长（默认 0.15）
    "loops": 2,              # 弹跳次数（默认 2）
    "bounce_height": 15      # 弹跳高度像素（默认 15）
}
```

**实现原理**:
```
tween: position → original + Vector2(0, -bounce_height), duration
tween: position → original, duration
... 重复 loops 次 ...
callback
```

---

### 5.3 ShakeAnimation - 抖动效果

**文件**: `scripts/animation/effects/ShakeAnimation.gd`

**效果**: 上下左右震动

**参数**:

```gdscript
config = {
    "offset": Vector2(5, 5),   # 抖动偏移（默认 Vector2(5,5)）
    "duration": 0.1,           # 单次抖动时长（默认 0.1）
    "loops": 3                 # 抖动次数（默认 3）
}
```

**实现原理**:
```
保存 original_pos
for i in range(loops):
    tween: +offset.x (右)
    tween: -offset.x (左)
    tween: +offset.y (下)
    tween: -offset.y (上)
    tween: original_pos (回位)
callback
```

---

### 5.4 MoveAnimation - 移动效果

**文件**: `scripts/animation/effects/MoveAnimation.gd`

**效果**: 移动到指定位置

**参数**:

```gdscript
config = {
    "to": Vector2(100, 200),   # 目标位置（默认 target.position + Vector2(0,-50)）
    "duration": 0.3,           # 移动时长（默认 0.3）
    "ease": Tween.EASE_OUT     # 缓动类型（默认 EASE_OUT）
}
```

**实现原理**:
```
tween: position → to_pos, duration, ease_type
callback
```

---

### 5.5 ParticleAnimation - 粒子动画

**文件**: `scripts/animation/effects/ParticleAnimation.gd`

**效果**: 生成 N 个粒子向外飘散

**参数**:

```gdscript
config = {
    "particle_count": 23,      # 粒子数量（默认 10）
    "particle_scene": "",      # 粒子场景路径（可选，默认用 ColorRect）
    "spawn_position": Vector2.ZERO,  # 生成位置
    "direction": Vector2.RIGHT,      # 飘散主方向
    "spread": 30.0,            # 扩散范围（随机偏移）
    "color": Color.YELLOW,     # 粒子颜色
    "lifetime": 1.0            # 粒子存活时间
}
```

**实现原理**:
```
for i in range(particle_count):
    创建/加载粒子
    设置位置、颜色
    target.add_child(particle)
    tween: position → spawn + direction*200 + random_offset, lifetime
    tween: modulate:a → 0, lifetime*0.5
    callback: queue_free(particle)

timer: lifetime + 0.1 → _on_timer_complete (最终回调)
```

---

### 5.6 SequentialAnimation - 顺序动画

**文件**: `scripts/animation/base/SequentialAnimation.gd`

**效果**: 依次播放多个动画，全部完成后触发回调

```gdscript
var seq = SequentialAnimation.new()
seq.add(GlowAnimation.new())
seq.add(BounceAnimation.new())
seq.add(MoveAnimation.new())

seq.play(target, {
    "0": {"duration": 0.3},    # 第0个动画的参数
    "1": {"loops": 2},         # 第1个动画的参数
    "2": {"to": Vector2(100,0)}  # 第2个动画的参数
}, func(): print("完成"))
```

**实现原理**:
```
.play():
    _current_index = 0
    _play_next()

._play_next():
    if _current_index >= _animations.size():
        _is_playing = false
        _on_complete.call()
        return

    anim = _animations[_current_index]
    anim_config = _config.get(str(_current_index), {})
    _current_index++
    anim.play(_target_node, anim_config, _play_next)  # 递归
```

---

### 5.7 ParallelAnimation - 并行动画

**文件**: `scripts/animation/base/ParallelAnimation.gd`

**效果**: 同时播放多个动画，全部完成后触发回调

```gdscript
var par = ParallelAnimation.new()
par.add(GlowAnimation.new())
par.add(ShakeAnimation.new())

par.play(target, config, func(): print("全部完成"))
```

**实现原理**:
```
.play():
    _pending_count = _animations.size()
    for anim in _animations:
        anim.play(target, config, _on_child_complete)
    _is_playing = true

._on_child_complete():
    _pending_count--
    if _pending_count <= 0:
        _is_playing = false
        _on_complete.call()
```

---

## 6. AnimationRegistry

动画注册表（单例），管理所有动画实例的获取和注册：

```gdscript
## 获取单例
var reg = get_node("/root/AnimationRegistry")

## 获取动画实例（每次返回同一实例）
var anim = reg.get_animation("glow")  # -> Variant (实际是 GlowAnimation)

## 注册自定义动画
reg.register("my_anim", MyAnimation.new())

## 检查是否存在
reg.has_animation("bounce")  # -> bool

## 获取所有动画名称
reg.get_animation_names()  # -> Array
```

**已注册动画映射**:

| 名称 | 类型 | 说明 |
|------|------|------|
| glow | GlowAnimation | 发光效果 |
| bounce | BounceAnimation | 弹跳效果 |
| shake | ShakeAnimation | 抖动效果 |
| move | MoveAnimation | 移动效果 |
| particle | ParticleAnimation | 粒子效果 |
| sequential | SequentialAnimation | 顺序播放 |
| parallel | ParallelAnimation | 并行播放 |

---

## 7. CardWidget 集成

### 7.1 播放接口

```gdscript
## 播放动画（带回调）
card_widget.play_animation("hover", func(): print("完成"))

## 播放动画（无回调）
card_widget.play_animation("click")
```

### 7.2 事件映射

| 事件名 | 动画 | 触发时机 |
|--------|------|----------|
| hover | glow | 鼠标进入卡牌 |
| click | bounce | 鼠标点击卡牌 |
| selected | move | 卡牌被选中 |
| reveal | shake | 卡牌揭示 |
| particle | particle | 手动触发粒子 |

### 7.3 内部实现

```gdscript
func play_animation(event_name: String, on_complete: Callable = Callable()) -> void:
    var registry = _get_animation_registry()
    var anim_name = _get_animation_name_for(event_name)  # hover → glow
    var anim = registry.get_animation(anim_name)
    var config = _build_animation_config(event_name)
    anim.play(self, config, on_complete)  # self = CardWidget 作为 target

func _build_animation_config(event_name: String) -> Dictionary:
    match event_name:
        "hover":    return {"duration": 0.3}
        "click":    return {"duration": 0.15, "loops": 2}
        "selected": return {"to": position + Vector2(0, -50), "duration": 0.3}
        "particle": return {"particle_count": card_value, "spawn_position": global_position, "color": Color.YELLOW}
    return {}
```

### 7.4 自动触发点

```gdscript
func _on_mouse_entered() -> void:
    play_animation("hover")      # hover 事件

func _on_gui_input(event: InputEventMouseButton) -> void:
    if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        play_animation("click")  # click 事件

func set_selected(selected: bool) -> void:
    if selected:
        play_animation("selected")  # selected 事件
```

---

## 8. 使用流程

### 8.1 播放单个动画

```gdscript
var reg = get_node("/root/AnimationRegistry")
var anim = reg.get_animation("bounce")

anim.play(
    card_widget,                              # target
    {"duration": 0.15, "loops": 2},          # config
    func(): print("弹跳完成")                  # on_complete
)
```

### 8.2 播放序列动画

```gdscript
var seq = SequentialAnimation.new()
seq.add(BounceAnimation.new())
seq.add(GlowAnimation.new())

seq.play(
    card_widget,
    {
        "0": {"duration": 0.15, "loops": 2},  # Bounce 参数
        "1": {"duration": 0.3}                 # Glow 参数
    },
    func(): print("序列完成")
)
```

### 8.3 播放并行动画

```gdscript
var par = ParallelAnimation.new()
par.add(GlowAnimation.new())
par.add(ShakeAnimation.new())

par.play(
    card_widget,
    {
        "duration": 0.3  # 两者共用同一 config
    },
    func(): print("并发完成")
)
```

---

## 9. 扩展指南

### 9.1 创建新动画效果

```gdscript
## 1. 继承 BaseAnimation
class_name FadeAnimation
extends BaseAnimation

func _init():
    _animation_name = "Fade"

## 2. 实现 play() 方法
func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
    super.play(target, config, on_complete)  # 记得调用 super

    if not target:
        _on_complete.call()
        return

    var duration = config.get("duration", 0.5)
    var fade_out = config.get("fade_out", true)

    var tween = target.create_tween()
    if fade_out:
        tween.tween_property(target, "modulate:a", 0.0, duration)
    else:
        tween.tween_property(target, "modulate:a", 1.0, duration)

    tween.chain().tween_callback(_on_complete)
    _is_playing = true
```

### 9.2 注册新动画

```gdscript
## 方式1：修改 AnimationRegistry._init_presets()
func _init_presets() -> void:
    _presets["glow"] = GlowAnimation.new()
    _presets["bounce"] = BounceAnimation.new()
    _presets["fade"] = FadeAnimation.new()  # 添加这行

## 方式2：运行时注册
var reg = get_node("/root/AnimationRegistry")
reg.register("fade", FadeAnimation.new())
```

### 9.3 创建复合动画

```gdscript
## 创建一个"选中后发光再弹跳"的动画序列
var combo = SequentialAnimation.new()
combo.add(MoveAnimation.new())     # 先移动
combo.add(GlowAnimation.new())     # 再发光
combo.add(BounceAnimation.new())   # 最后弹跳

combo.play(card_widget, {
    "0": {"to": position + Vector2(0, -50)},
    "1": {"duration": 0.3},
    "2": {"loops": 2}
}, func(): print("组合动画完成"))
```

---

## 10. 注意事项

### 10.1 GDScript 语言限制

1. **接口不是真正的接口**：GDScript 没有 interface 关键字，接口靠约定实现
2. **协变返回类型**：`get_animation()` 返回 `Variant` 而非 `IAnimation`，因为动画类继承链是 `IAnimation → RefCounted`，而实现类继承 `BaseAnimation → Node`
3. **Callable 传递**：tween callback 直接传 `_on_complete`，不要用 lambda 包装

### 10.2 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `Invalid call. Nonexistent function 'play'` | 动画类未继承 `BaseAnimation` 或签名不对 | 确保 `play(target, config, on_complete)` |
| `Trying to return value of type 'X' from function whose return type is 'Y'` | 类型不兼容 | `get_animation()` 返回 `Variant` |
| `Attempt to call function 'null' on a null instance` | `on_complete` 为空或 `target` 为 null | 检查 `config.get("target")` 或加 null 检查 |
| tween callback 不触发 | 用 lambda 包装了 Callable | 直接传 `_on_complete` |

### 10.3 正确传递 Callback

```gdscript
## 错误 ❌
tween.chain().tween_callback(func(): _on_complete.call())

## 正确 ✅
tween.chain().tween_callback(_on_complete)

## 如果需要传参数，用 bind
tween.chain().tween_callback(_on_complete.bind(extra_arg))
```

### 10.4 target 不能为 null

```gdscript
func play(target: Node, config: Dictionary, on_complete: Callable) -> void:
    if not target:
        _on_complete.call()  # 必须调用回调，否则调用方会卡住
        return
    # ... 执行动画
```

---

## 11. 状态机详细说明

### 11.1 状态定义

| 状态 | `_is_playing` | 说明 |
|------|---------------|------|
| 空闲 | `false` | 初始状态或动画已完成 |
| 播放中 | `true` | 动画正在执行 |

### 11.2 状态转换图

```
     ┌─────────────────────────────────────┐
     │                                     │
     ▼                                     │
[空闲] ──play()──► [播放中] ──完成──► [空闲]
   ▲                  │
   │                  │
   └──────stop()──────┘
```

### 11.3 复合动画状态机

**SequentialAnimation**:
```
[空闲] → play() → [播放中: index=0] → anim0完成
                                   → [播放中: index=1] → anim1完成
                                   → [播放中: index=2] → anim2完成
                                   → [空闲] + callback
```

**ParallelAnimation**:
```
[空闲] → play() → [播放中: pending=N]
                    ├── anim0完成 → pending-- → 检查
                    ├── anim1完成 → pending-- → 检查
                    └── animN完成 → pending-- → 检查
                                        ↓
                                  pending<=0 → [空闲] + callback
```

---

## 12. 待实现

- [ ] 粒子场景 `scenes/particles/coin.tscn`
- [ ] SettlementState 粒子集成
- [ ] 组合动画队列（3张牌飞向出牌区）
- [ ] 动画编辑器工具
- [ ] 动画优先级/打断机制

---

## 13. 版本历史

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-28 | v1.1 | 修复 GDScript 兼容性，完善文档细节 |
| 2026-04-28 | v1.0 | 初始实现 |