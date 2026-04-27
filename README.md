# Gambler

Godot 4.3 卡牌对战游戏

## 快速开始

1. 用 Godot 4.3 打开项目
2. 运行 `MainV2.tscn` 测试最新版本
3. 查看 [docs/index.md](docs/index.md) 了解文档结构

## 项目状态

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - 架构文档
- [docs/MODULES.md](docs/MODULES.md) - 模块说明
- [docs/EFFECTS_SYSTEM.md](docs/EFFECTS_SYSTEM.md) - 特效系统设计文档
- [docs/TECH_REFERENCE.md](docs/TECH_REFERENCE.md) - 技术参考
- [docs/BATTLE_FLOW_DESIGN.md](docs/BATTLE_FLOW_DESIGN.md) - 战斗流程设计

## 代码统计

| 语言 | 文件 | 行数 |
|------|------|------|
| GDScript | 76 | 7,473 |
| TSCN | 16 | 2,469 |
| JSON | 5 | 394 |
| **合计** | **97** | **10,336** |

统计工具: `tools/cloc_stats.py`

## 版本

- v3.5: 新增卡牌特效系统设计文档（EFFECTS_SYSTEM.md），Phase 1-3 实现计划
- v3.4: 运行时错误修复（着色器丢失、静态调用、缺失变量、主菜单音量加载）
- v3.3: 对话UI系统重构(DialogueSystem/DialogueUI)，MVC模式
- v3.0: 整合thryzhn横板探索系统
- v2.2: BattleUI_v1 Node2D 架构，卡片动画与交互系统
- v2.1: 状态机+代价系统完整工作，日志系统
- v2.0: 状态机+事件驱动
- v1.x: 基础战斗系统
