# 动画系统设计文档 v1.2

> **日期**: 2026-04-29
> **状态**: ✅ 已完成
> **版本**: v1.2

---

## 1. 系统概述

动画系统采用 **接口 + 基类 + 具体实现** 的 OOP 架构，支持：
- 独立动画效果（Glow、Blow、Shake、Move）
- 复合动画（Sequential、Parallel）
- 粒子动画
- 销毁动画（Tween-based 和 Shader-based）
- 数据驱动的配置方式

### 1.1 设计原则

1. **单一职责**：每个动画类只负责一种效果
2. **开闭原则**：通过继承 `BaseAnimation` 扩展新动画，无需修改现有代码
3. **依赖倒置**：依赖 `IAnimation` 接口，不依赖具体实现
4. **状态管理**：通过 `_is_playing` 状态控制动画生命周期
5. **双重实现**：同一效果提供 Tween 和 Shader 两种实现，便于选择

### 1.2 架构图

```
IAnimation (接口约定)
    │
    └── BaseAnimation (通用功能: _is_playing, _timer, set_target, etc.)
            │
            ├── TweenAnimation (具体实现)
            │   ├── GlowAnimation
            │   ├── ShakeAnimation
            │   ├── MoveAnimation
            │   └── DestroyAnimation (Tween版)
            │       ├── FadeDestroyAnimation
            │       ├── ShrinkDestroyAnimation
            │       └── ShakeDestroyAnimation
            │
            └── ShaderAnimation (着色器实现)
                └── ShaderDestroyAnimation (着色器版)
                    ├── ShaderFadeDestroyAnimation
                    ├── ShaderShrinkDestroyAnimation
                    └── ShaderShakeDestroyAnimation
```

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
│   │   ├── BounceAnimation.gd      # 弹跳效果
│   │   ├── ShakeAnimation.gd       # 抖动效果
│   │   ├── MoveAnimation.gd        # 移动效果
│   │   ├── FadeDestroyAnimation.gd        # Tween淡出销毁
│   │   ├── ShrinkDestroyAnimation.gd      # Tween缩放销毁
│   │   ├── ShakeDestroyAnimation.gd       # Tween震动销毁
│   │   ├── ShaderDestroyAnimation.gd      # Shader动画基类
│   │   ├── ShaderFadeDestroyAnimation.gd  # Shader淡出销毁
│   │   ├── ShaderShrinkDestroyAnimation.gd # Shader缩放销毁
│   │   └── ShaderShakeDestroyAnimation.gd  # Shader震动销毁
│   └── particles/
│       └── ParticleAnimation.gd    # 粒子生成
└── battle/
    └── AnimationRegistry.gd         # 动画注册表（单例）

shaders/
└── destroy/
    ├── FadeDestroy.gdshader        # 淡出着色器
    ├── ShrinkDestroy.gdshader      # 缩放着色器
    └── ShakeDestroy.gdshader       # 震动着色器
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
| fade_destroy | FadeDestroyAnimation | 淡出销毁（Tween） |
| shrink_destroy | ShrinkDestroyAnimation | 缩放销毁（Tween） |
| shake_destroy | ShakeDestroyAnimation | 震动销毁（Tween） |
| shader_fade_destroy | ShaderFadeDestroyAnimation | 淡出销毁（Shader） |
| shader_shrink_destroy | ShaderShrinkDestroyAnimation | 缩放销毁（Shader） |
| shader_shake_destroy | ShaderShakeDestroyAnimation | 震动销毁（Shader） |

---

### 5.8 销毁动画族 - Card Destruction Effects

**效果**: 卡牌销毁时播放的特殊效果动画

#### 5.8.1 Tween vs Shader 实现对比

| 特性 | Tween 实现 | Shader 实现 |
|------|-----------|-------------|
| 文件 | `FadeDestroyAnimation.gd` | `ShaderFadeDestroyAnimation.gd` |
| 渲染方式 | CPU (Tween) | GPU (ShaderMaterial) |
| 性能 | 一般 | 优秀（大量销毁时） |
| 代码复杂度 | 简单 | 中等 |
| 扩展性 | 简单修改 | 需要修改 shader 文件 |

**选择建议**：
- 少量卡牌销毁 → Tween 实现即可
- 大量卡牌同时销毁 → Shader 实现性能更好

#### 5.8.2 FadeDestroyAnimation - Tween 淡出销毁

**文件**: `scripts/animation/effects/FadeDestroyAnimation.gd`

**效果**: 淡出 + 缩小 → 销毁

```gdscript
config = {
    "duration": 0.4,        # 总时长（默认 0.4）
    "fade_delay": 0.0,      # 开始淡出延迟（默认 0.0）
    "shrink_scale": 0.1     # 最终缩放值（默认 0.1）
}
```

**实现原理**:
```
tween: scale → shrink_scale, duration * 0.6, EASE_OUT
tween: modulate:a → 0, duration * 0.4 (延迟 fade_delay)
callback
```

#### 5.8.3 ShrinkDestroyAnimation - Tween 缩放销毁

**文件**: `scripts/animation/effects/ShrinkDestroyAnimation.gd`

**效果**: 快速缩小 → 淡出 → 销毁

```gdscript
config = {
    "duration": 0.3,        # 总时长（默认 0.3）
    "shrink_scale": 0.0,    # 最终缩放值（默认 0.0）
    "shrink_ease": EASE_IN  # 缓动类型（默认 EASE_IN）
}
```

**实现原理**:
```
tween: scale → shrink_scale, duration, shrink_ease
tween: modulate:a → 0, duration * 0.5
callback
```

#### 5.8.4 ShakeDestroyAnimation - Tween 震动销毁

**文件**: `scripts/animation/effects/ShakeDestroyAnimation.gd`

**效果**: 震动 + 淡出 + 缩小 → 销毁

```gdscript
config = {
    "duration": 0.5,        # 总时长（默认 0.5）
    "shake_offset": Vector2(5, 5),  # 震动偏移（默认 Vector2(5,5)）
    "shake_loops": 3,       # 震动次数（默认 3）
    "fade_delay": 0.1      # 开始淡出延迟（默认 0.1）
}
```

**实现原理**:
```
并行:
  - tween: position 震动 (shake_loops 次)
  - tween: scale → 0.2, duration * 0.6, EASE_OUT
tween: modulate:a → 0, duration * 0.3 (延迟 fade_delay)
callback
```

#### 5.8.5 ShaderFadeDestroyAnimation - Shader 淡出销毁

**文件**: `scripts/animation/effects/ShaderFadeDestroyAnimation.gd`
**Shader**: `shaders/destroy/FadeDestroy.gdshader`

**效果**: GPU 加速淡出 + 缩小

**实现原理**:
```
1. 创建 ShaderMaterial，设置 shader 参数
2. 挂载到 CardWidget 的 Sprite 节点上
3. Tween 驱动 'progress' uniform (0.0 → 1.0)
4. Shader 内部计算 scale 和 alpha
```

**Shader 核心逻辑**:
```glsl
void fragment() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 scale = mix(1.0, shrink_scale, smoothstep(0.0, 1.0, p));
    // ... UV 缩放逻辑
    float alpha_fade_point = smoothstep(fade_delay, 1.0, p);
    COLOR.a *= (1.0 - alpha_fade_point);
}
```

#### 5.8.6 ShaderShrinkDestroyAnimation - Shader 缩放销毁

**文件**: `scripts/animation/effects/ShaderShrinkDestroyAnimation.gd`
**Shader**: `shaders/destroy/ShrinkDestroy.gdshader`

**效果**: GPU 加速缩放 + 淡出

#### 5.8.7 ShaderShakeDestroyAnimation - Shader 震动销毁

**文件**: `scripts/animation/effects/ShaderShakeDestroyAnimation.gd`
**Shader**: `shaders/destroy/ShakeDestroy.gdshader`

**效果**: GPU 加速震动 + 缩放 + 淡出

**Shader 核心逻辑**:
```glsl
float shake(float t, float freq, float amp) {
    return sin(t * freq) * amp;
}
void fragment() {
    float shake_phase = p * float(shake_loops) * 6.28318;
    float shake_x = shake(shake_phase, 20.0, shake_offset.x / 100.0);
    // ... 结合震动和缩放
}
```

---

## 7. CardWidget 集成

### 7.1 播放接口

```gdscript
## 播放动画（带回调）
card_widget.play_animation("hover", func(): print("完成"))

## 播放动画（无回调）
card_widget.play_animation("click")

## 播放销毁动画（带回调）
card_widget.play_animation("shrink_destroy", func(): print("销毁完成"))
```

### 7.2 事件映射

| 事件名 | 动画 | 触发时机 |
|--------|------|----------|
| hover | glow | 鼠标进入卡牌 |
| click | bounce | 鼠标点击卡牌 |
| selected | move | 卡牌被选中 |
| reveal | shake | 卡牌揭示 |
| particle | particle | 手动触发粒子 |
| shrink_destroy | shrink_destroy | 卡牌销毁（缩放） |
| fade_destroy | fade_destroy | 卡牌销毁（淡出） |
| shake_destroy | shake_destroy | 卡牌销毁（震动） |

### 7.3 销毁动画流程

```
回合结束 → SettlementState 记录待销毁卡牌
    ↓
RoundEndState.play_animation("round_end")
    ↓
on_animation_complete()
    ↓
BattleUI_V2.play_destroy_animation(card_ids, callback)
    ↓
CardWidget.play_animation(destroy_type, on_widget_destroyed)
    ↓
所有动画完成 → callback()
    ↓
apply_settlement_cards() 移除卡牌
```

### 7.4 内部实现

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

## 12. Shader 动画详细说明

### 12.1 概述

Shader 动画使用 GPU 渲染实现高性能的销毁效果。Tween 驱动 `progress` uniform (0.0→1.0)，Shader 内部计算 UV 缩放和 alpha 混合。

### 12.2 架构

```
ShaderDestroyAnimation (GDScript)
├── play(): 创建 ShaderMaterial，挂载到目标 Sprite
├── 启动 Tween: tween_method 驱动 progress uniform
│
└── .gdshader (GPU)
    └── fragment(): 根据 progress 计算缩放和透明度
```

### 12.3 文件对应关系

| GDScript 类 | Shader 文件 | 效果 |
|-------------|-------------|------|
| ShaderFadeDestroyAnimation | FadeDestroy.gdshader | 淡出 + 缩小 |
| ShaderShrinkDestroyAnimation | ShrinkDestroy.gdshader | 缩放 + 淡出 |
| ShaderShakeDestroyAnimation | ShakeDestroy.gdshader | 震动 + 缩放 + 淡出 |

### 12.4 Shader 实现要点

#### 12.4.1 缩放原理

```glsl
// 以 UV 中心为基准缩放
vec2 centered_uv = UV - vec2(0.5);
centered_uv *= scale;
centered_uv += vec2(0.5);

// 超出范围则透明
if (centered_uv.x < 0.0 || centered_uv.x > 1.0 || ...) {
    COLOR.a = 0.0;
}
```

#### 12.4.2 震动原理

```glsl
float shake(float t, float freq, float amp) {
    return sin(t * freq) * amp;
}
// t = time, freq = 频率, amp = 振幅

float shake_phase = progress * float(shake_loops) * 6.28318;
// progress 0→1 对应 0 → shake_loops 个完整周期
```

### 12.5 创建新的 Shader 动画

**步骤 1**: 创建 `.gdshader` 文件
```glsl
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // 实现效果
}
```

**步骤 2**: 创建 GDScript 动画类
```gdscript
class_name MyShaderAnimation
extends ShaderDestroyAnimation

func _init():
    super("res://shaders/path/to/my_shader.gdshader")
    _animation_name = "MyShader"
```

**步骤 3**: 注册到 AnimationRegistry
```gdscript
_presets["my_shader"] = MyShaderAnimation.new()
```

**步骤 4**: 在 CardWidget 添加事件映射
```gdscript
func _get_animation_name_for(event_name: String) -> String:
    match event_name:
        # ... existing ...
        "my_shader": return "my_shader"
    return ""
```

### 12.6 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 动画没变化 | Sprite 未正确获取 | 检查 `CardContainer/Sprite` 路径 |
| Shader 不生效 | material 未设置 | 确保 `sprite.material = _material` |
| 编译错误 | uniform 类型错误 | 使用 `hint_range` 等正确 hint |

### 12.7 性能对比

| 场景 | Tween | Shader |
|------|-------|--------|
| 1-3 张卡牌销毁 | ✅ 足够 | ✅ 可用 |
| 5+ 张卡牌同时销毁 | ⚠️ 可能有卡顿 | ✅ GPU 加速更流畅 |
| 移动端 | ⚠️ 耗电 | ✅ 更省电 |

---

## 13. 销毁动画完整流程

### 13.1 触发链路

```
1. 回合结算
   SettlementState.calculate_settlement()
   → 判定胜负
   → CostContext 执行代价 (SelfDestroyCost, DelayedDestroyCost)
   → 标记 card_id 到 BattleReport

2. 记录待销毁卡牌
   SettlementState.enter()
   → _core.record_settlement_cards(cards_to_remove, cards_to_add)

3. 回合结束动画
   RoundEndState.enter()
   → play_animation("round_end")
   → on_animation_complete()

4. 执行销毁动画
   RoundEndState._transition_to_next()
   → _core.ui_play_destroy_animation(all_destroy_ids, callback)

5. UI 播放动画
   BattleUI_V2.play_destroy_animation(card_ids, callback)
   → for widget in widgets_to_destroy:
       widget.play_animation("shader_shrink_destroy", on_widget_destroyed)

6. 卡牌 Widget 执行动画
   CardWidget.play_animation("shader_shrink_destroy", callback)
   → AnimationRegistry.get_animation("shader_shrink_destroy")
   → ShaderShrinkDestroyAnimation.play(self, config, callback)
       → 创建 ShaderMaterial
       → 挂载到 Sprite
       → 启动 Tween 驱动 progress

7. 动画完成
   所有 widget 动画完成后
   → callback()
   → RoundEndState._on_destroy_complete()
   → _apply_settlement_and_transition()
       → _core.remove_card_from_deck(card_id)
       → _core.add_card_to_deck(proto_id)
       → transition_to(PlayerSelectState)
```

### 13.2 数据流

```
CostContext.destroy_source_card()
    ↓
BattleReport.add_card_to_remove(card_id)
    ↓
SettlementState._settlement_report.get_cards_to_remove()
    ↓
BattleCore._settlement_cards_to_remove
    ↓
RoundEndState._destroy_card_ids
    ↓
BattleUI_V2.play_destroy_animation(card_ids, callback)
    ↓
CardWidget.play_animation("shader_shrink_destroy", callback)
    ↓
AnimationRegistry.get_animation("shader_shrink_destroy")
    ↓
ShaderShrinkDestroyAnimation.play(widget, config, callback)
    ↓
(widget.queue_free() 在 callback 中调用) ← 注意：当前需要手动调用
```

### 13.3 代码位置索引

| 功能 | 文件 | 方法/变量 |
|------|------|----------|
| 代价触发 | `SelfDestroyCost.gd` | `trigger()` → `context.destroy_source_card()` |
| 代价触发 | `DelayedDestroyCost.gd` | `trigger()` → `context.mark_delayed_destroy()` |
| 记录销毁 | `SettlementState.gd:27-33` | `record_settlement_cards()` |
| 获取销毁列表 | `BattleCore.gd` | `get_settlement_cards_to_remove()` |
| 执行销毁动画 | `RoundEndState.gd:35` | `ui_play_destroy_animation()` |
| 播放销毁动画 | `BattleUI_V2.gd:224` | `play_destroy_animation()` |
| 动画名称映射 | `CardWidget.gd:115` | `_get_animation_name_for()` |
| 动画配置 | `CardWidget.gd:124` | `_build_animation_config()` |
| 执行动画 | `CardWidget.gd:94` | `play_animation()` |

### 13.4 添加新销毁动画步骤

1. **创建动画类** (如需新效果):
   ```
   scripts/animation/effects/MyDestroyAnimation.gd
   ```

2. **创建 Shader** (如需 GPU 渲染):
   ```
   shaders/destroy/MyDestroy.gdshader
   ```

3. **注册到 AnimationRegistry**:
   ```gdscript
   _presets["my_destroy"] = MyDestroyAnimation.new()
   ```

4. **在 CardWidget 添加映射**:
   ```gdscript
   "my_destroy": return "my_destroy"
   ```

5. **使用动画**:
   ```gdscript
   widget.play_animation("my_destroy", callback)
   ```

---

## 14. 版本历史

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-04-29 | v1.2 | 新增 Shader 销毁动画，添加完整流程文档 |
| 2026-04-28 | v1.1 | 修复 GDScript 兼容性，完善文档细节 |
| 2026-04-28 | v1.0 | 初始实现 |

---

## 15. 待实现

- [ ] PropertyTweenAnimation（属性动画泛化）
- [ ] 动画编辑器工具
- [ ] 组合动画队列（3张牌飞向出牌区）
- [ ] 动画优先级/打断机制
- [ ] SettlementState 粒子集成