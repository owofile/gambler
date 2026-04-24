# Gambler - Godot 卡牌对战游戏

基于 Godot 4.3 的卡牌对战游戏。

## 项目状态

**v2.1** - 战斗流程状态机完整，代价系统正常工作

## 已实现功能

- 卡牌原型注册系统（18 张卡牌，6 种类型）
- 卡牌实例管理（Add/Remove/GetSnapshot）
- 敌人登记系统（Grunt/Elite/Boss 三个等级）
- **战斗流程状态机**（BattleFlowManager）
- **代价系统**（SelfDestroyCost, NextTurnUnusableCost）
- **特效系统**（FixedBonusEffect, RuleReversalEffect）
- **日志系统**（Logger 保存到 `logs/` 目录）
- 事件总线（EventBus）
- 战斗 UI 界面（可交互选择 1-3 张牌）

## 战斗流程

```
PLAYER_SELECTING → PLAYER_ANIMATING → ENEMY_ANIMATING
    → COMPARE_ANIMATING → ROUND_END_ANIMATING
    → (循环直到某方达到目标胜场) → BATTLE_END
```

## 运行

1. 用 Godot 4.3 打开项目
2. 运行 `MainV2.tscn`
3. 选择 1-3 张卡牌，点击确认
4. 等待动画完成后继续选择，直到战斗结束

## 目录结构

```
gambler/
├── scripts/
│   ├── data/           # 数据结构 (CardData, CardInstance, BattleReport 等)
│   ├── core/           # 核心系统
│   │   ├── CardManager.gd        # 卡牌管理
│   │   ├── BattleManager.gd      # 战斗计算（特效/代价）
│   │   ├── BattleFlowManager.gd  # 状态机
│   │   ├── CardSelector.gd        # 选牌管理
│   │   ├── AnimationController.gd # 动画控制
│   │   └── Logger.gd             # 日志系统
│   ├── effects/        # 特效实现
│   ├── costs/          # 代价实现
│   ├── ui/             # UI 控制器
│   └── autoload/        # 全局单例 (DataManager)
├── scenes/             # 场景文件
│   └── BattleUI.tscn   # 战斗界面
├── resources/          # 配置数据
│   ├── card_prototypes.json
│   └── enemy_registry.json
├── logs/               # 日志输出目录
└── docs/               # 文档
```

## 文档

- [索引](./index.md) - 文档目录
- [架构文档](./ARCHITECTURE.md) - 详细架构说明
- [模块说明](./MODULES.md) - 模块职责和接口
- [技术参考](./TECH_REFERENCE.md) - Godot 4.3 API 参考
- [战斗流程设计](./BATTLE_FLOW_DESIGN.md) - v2.0 战斗流程
- [问题复盘](./RETROSPECTIVE.md) - 问题与解决

## 更新日志

| 版本 | 日期 | 描述 |
|------|------|------|
| v2.1 | 2026-04-24 | 状态机与 BattleManager 整合，代价系统完整工作，Logger 日志 |
| v2.0 | 2026-04-24 | 新战斗流程系统：BattleFlowManager 状态机、CardSelector |
| v1.7 | 2026-04-24 | 特效与代价系统 |
| v1.6 | 2026-04-24 | BattleUI 可交互测试通过 |
| v1.0 | 2026-04-24 | MVP 基础卡牌系统 |
