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
- [docs/BATTLE_SYSTEM_V2.md](docs/BATTLE_SYSTEM_V2.md) - 战斗系统 V2 架构文档

## 代码统计

> 使用脚本统计：`python tools/cloc_stats.py`

| 语言 | 文件 | 行数 |
|------|------|------|
| GDScript | 127 | 9,185 |
| TSCN | 21 | 2,329 |
| JSON | 6 | 573 |
| Shader | 5 | 105 |
| **合计** | **159** | **12,192** |

## 版本规范

> 项目处于原型/地基开发阶段，使用 `v0.x.x` 格式
> - **v0.x.0**: 新系统、大功能、重构
> - **v0.x.1**: 修bug、小优化
> - 完整可玩后发布 v1.0.0

## 版本历史

| 版本 | 描述 |
|------|------|
| **v0.9.1** | 新增物品背包系统(InvMgr)、Shader销毁动画、调试菜单物品测试 |
| **v0.9.0** | Battle System V2 状态机架构完成、压力测试通过 |
| **v0.8.1** | InputManager全局输入、调试菜单重构(OOP)、SaveManager封装修复 |
| **v0.8.0** | 新增调试菜单、卡牌背包系统、存档系统重构 |
| v0.7.0 | 新增卡牌特效系统设计文档（EFFECTS_SYSTEM.md） |
| v0.6.1 | 运行时错误修复 |
| v0.6.0 | 对话UI系统重构(DialogueSystem/DialogueUI)，MVC模式 |
| v0.5.0 | 整合thryzhn横板探索系统 |
| v0.4.0 | BattleUI_v1 Node2D 架构，卡片动画与交互系统 |
| v0.3.0 | 状态机+代价系统完整工作，日志系统 |
| v0.2.0 | 状态机+事件驱动 |
| v0.1.0 | 基础战斗系统 |
