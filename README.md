# Gambler

Godot 4.3 卡牌对战游戏

## 快速开始

1. 用 Godot 4.3 打开项目
2. 运行主场景 `Main.tscn` 或 `MainV2.tscn`
3. 查看 [docs/index.md](docs/index.md) 了解文档结构

## 项目状态

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - 架构文档
- [docs/MODULES.md](docs/MODULES.md) - 模块说明
- [docs/EFFECTS_SYSTEM.md](docs/EFFECTS_SYSTEM.md) - 特效系统设计文档
- [docs/SAVE_SYSTEM.md](docs/SAVE_SYSTEM.md) - 存档系统设计文档
- [docs/RETROSPECTIVE.md](docs/RETROSPECTIVE.md) - 问题复盘与经验总结
- [docs/TECH_REFERENCE.md](docs/TECH_REFERENCE.md) - 技术参考
- [docs/BATTLE_FLOW_DESIGN.md](docs/BATTLE_FLOW_DESIGN.md) - 战斗流程设计

## 核心功能

| 模块 | 状态 | 说明 |
|------|------|------|
| 卡牌战斗 | ✅ | 完整战斗流程、选牌、比大小 |
| 卡牌背包 | ✅ | CardMgr 管理，最多20张 |
| 存档系统 | ✅ | SaveManager + WorldState |
| 对话系统 | ✅ | NarrativeEngine + DialogueSystem |
| 调试菜单 | ✅ | F1 打开，存档/读档/添加卡牌 |
| 特效系统 | 🔨 | 设计文档完成，待实现 |
| 物品背包 | 🔜 | 计划中 |

## 代码统计

| 语言 | 文件 | 行数 |
|------|------|------|
| GDScript | 78 | 6,257 |
| TSCN | 17 | 2,264 |
| JSON | 5 | 394 |
| **合计** | **100** | **8,915** |

## 版本

- **v4.1**: InputManager全局输入、调试菜单重构(OOP)、SaveManager封装修复
- **v4.0**: 新增调试菜单、卡牌背包系统、存档系统重构
- v3.5: 新增卡牌特效系统设计文档（EFFECTS_SYSTEM.md）
- v3.4: 运行时错误修复（着色器丢失、静态调用、缺失变量、主菜单音量加载）
- v3.3: 对话UI系统重构(DialogueSystem/DialogueUI)，MVC模式
- v3.0: 整合thryzhn横板探索系统
- v2.2: BattleUI_v1 Node2D 架构，卡片动画与交互系统
- v2.1: 状态机+代价系统完整工作，日志系统
- v2.0: 状态机+事件驱动
- v1.x: 基础战斗系统
