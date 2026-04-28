# 动画系统设计文档 v1.0

> **日期**: 2026-04-28
> **状态**: 规划中
> **目标**: 构建高度自由、可扩展的动画系统

---

## 1. 背景与目标

### 1.1 现状
- Battle System V2 已完成状态机架构
- 动画接口已预留 (`play_animation`, `animation_finished`)
- AnimationController.gd 存在但未被 V2 使用
- 卡牌 Widget (CardWidget) 已创建

### 1.2 目标效果
```
玩家操作:
  鼠标悬停 → Hover动画 (发光/飘动)
  点击选中 → Click动画 (缩小/弹跳)
  选择3张 → 组合移动动画 (排队飞向出牌区)

结算阶段:
  Player 23点 → 23个小球粒子
  Enemy 21点 → 21个小球粒子
  对比动画 → 直观显示胜负
```

### 1.3 设计原则
1. **OOP + 接口** - 任何动画实现 IAnimation 接口即可
2. **数据驱动** - 动画由卡牌数据配置决定
3. **组合自由** - 支持嵌套组合多个动画
4. **兼容现有** - 不破坏现有 Battle System V2

---

## 2. 核心架构

### 2.1 动画接口

```gdscript
## 基础动画接口
class_name IAnimation
extends RefCounted

## 播放动画
## config: Dictionary - 动画参数
## on_complete: Callable - 完成回调
func play(config: Dictionary, on_complete: Callable) -> void

## 停止动画
func stop() -> void

## 是否正在播放
func is_playing() -> bool
```

### 2.2 组合动画

```gdscript
## 顺序播放动画
class_name SequentialAnimation
extends IAnimation

## 并行播放动画
class_name ParallelAnimation
extends IAnimation

## 单次动画
class_name SingleAnimation
extends IAnimation
```

### 2.3 粒子动画

```gdscript
## 根据数量生成粒子
class_name ParticleAnimation
extends IAnimation

## config 参数:
##   - particle_count: int (粒子数量，如23)
##   - particle_type: String (粒子资源路径)
##   - emitter_position: Vector2 (发射位置)
##   - color: Color (粒子颜色)
```

---

## 3. 卡牌动画配置

### 3.1 动画配置结构

```gdscript
## CardData 或 CardPrototype 中添加
var animation_config: Dictionary = {
    "hover": "glow_blue",      # 悬停动画名称
    "click": "bounce",          # 点击动画名称
    "selected": "move_to_slot",  # 选中动画名称
    "reveal": "slash_effect",    # 揭示动画名称
    "particle": "spark"          # 结算粒子名称
}
```

### 3.2 动画注册表

```gdscript
## AnimationRegistry - 全局动画注册
class_name AnimationRegistry
extends Node

## 注册动画
func register(name: String, animation: IAnimation) -> void

## 获取动画
func get_animation(name: String) -> IAnimation

## 预设动画
const PRESETS: Dictionary = {
    "glow_blue": GlowAnimation.new(),
    "bounce": BounceAnimation.new(),
    "shake": ShakeAnimation.new(),
    "move_to_slot": MoveAnimation.new(),
    "spark": SparkParticle.new(),
    "soul_orb": SoulOrbParticle.new(),
    "feather_fall": FeatherParticle.new()
}
```

---

## 4. 卡牌 Widget 集成

### 4.1 CardWidget 结构

```
CardWidget
    ├── Sprite2D / TextureRect (卡牌外观)
    ├── AnimationPlayer (节点动画)
    └── 持有 IAnimation 组件
```

### 4.2 CardWidget 接口

```gdscript
class_name CardWidget
extends Control

## 播放交互动画
func play_animation(name: String) -> void

## 播放特效动画
func play_effect(animation: IAnimation, config: Dictionary, on_done: Callable) -> void

## 获取动画配置
func get_animation_name_for(event: String) -> String:
    ## event: "hover" | "click" | "selected" | "reveal"
    return _animation_config.get(event, "default")
```

---

## 5. 结算粒子系统

### 5.1 粒子生成流程

```
SettlementState
    │
    ├── 计算 Player 23点, Enemy 21点
    │
    ├── 创建 ParticleAnimation 实例
    │   ├── PlayerParticleEmitter(count: 23)
    │   └── EnemyParticleEmitter(count: 21)
    │
    └── 播放对比动画
        ├── 23个小球从左向右飞
        ├── 21个小球从右向左飞
        └── 碰撞/相遇 → 胜负判定
```

### 5.2 粒子动画参数

```gdscript
## Player 侧
{
    "particle_count": 23,
    "particle_scene": "res://particles/coin.tscn",
    "spawn_position": Vector2(100, 300),
    "direction": Vector2(1, 0),
    "spread": 30.0,  # 粒子扩散角度
    "color": Color.YELLOW
}

## Enemy 侧
{
    "particle_count": 21,
    "particle_scene": "res://particles/coin.tscn",
    "spawn_position": Vector2(700, 300),
    "direction": Vector2(-1, 0),
    "spread": 30.0,
    "color": Color.RED
}
```

---

## 6. 实现步骤

### Phase 1: 基础框架
- [ ] 创建 `IAnimation` 接口
- [ ] 创建 `SequentialAnimation` / `ParallelAnimation`
- [ ] 创建 `AnimationRegistry` 单例
- [ ] 实现基础动画: Glow, Bounce, Shake, Move

### Phase 2: 卡牌集成
- [ ] 扩展 `CardData` 添加 `animation_config`
- [ ] CardWidget 实现动画播放接口
- [ ] 注册默认动画到 Registry

### Phase 3: 粒子系统
- [ ] 创建 `ParticleAnimation`
- [ ] 创建粒子场景 `particles/coin.tscn`
- [ ] SettlementState 集成粒子动画

### Phase 4: 组合效果
- [ ] 实现卡牌组合动画 (3张牌排队飞)
- [ ] 实现结算对比动画

---

## 7. 文件结构

```
scripts/
├── animation/
│   ├── interfaces/
│   │   └── IAnimation.gd           # 动画接口
│   ├── base/
│   │   ├── SequentialAnimation.gd    # 顺序动画
│   │   └── ParallelAnimation.gd       # 并行动画
│   ├── effects/
│   │   ├── GlowAnimation.gd         # 发光
│   │   ├── BounceAnimation.gd        # 弹跳
│   │   ├── ShakeAnimation.gd         # 抖动
│   │   └── MoveAnimation.gd         # 移动
│   └── particles/
│       └── ParticleAnimation.gd      # 粒子动画
├── battle/
│   └── AnimationRegistry.gd          # 动画注册表
└── cards/
    └── CardData.gd                   # 添加 animation_config

scenes/
├── particles/
│   └── coin.tscn                    # 粒子场景
```

---

## 8. 扩展指南

### 添加新动画类型

```gdscript
## 1. 实现 IAnimation 接口
class_name MyAnimation
extends IAnimation

var _is_playing: bool = false

func play(config: Dictionary, on_complete: Callable) -> void:
    _is_playing = true
    # 动画逻辑...
    on_complete.call()

func stop() -> void:
    _is_playing = false

func is_playing() -> bool:
    return _is_playing

## 2. 注册到 AnimationRegistry
AnimationRegistry.register("my_animation", MyAnimation.new())

## 3. 在 CardData 中使用
animation_config = {"hover": "my_animation"}
```

---

## 9. 兼容性

### 现有系统
| 组件 | 兼容性 |
|------|--------|
| BattleCore | ✅ 不受影响 |
| BattleState | ✅ 保留 play_animation 接口 |
| CardManager | ✅ 不变 |
| CardInstance | ✅ 可扩展 animation_config |
| BattleUI_V2 | ✅ 可监听动画信号 |

### 数据流
```
CardData.animation_config
        ↓
CardWidget.get_animation_for(event)
        ↓
AnimationRegistry.get(name)
        ↓
IAnimation.play(config, callback)
```
