# Gambler - Godot 卡牌对战游戏

基于 Godot 4.3 的卡牌对战游戏 MVP。

## 项目状态

v1.6 - 可交互测试通过

## 已实现功能

- 卡牌原型注册系统（18 张卡牌，6 种类型）
- 卡牌实例管理
- 敌人登记系统
- 战斗核心模块（纯点数比大小）
- 事件总线（EventBus）
- 战斗 UI 界面

## 目录结构

```
gambler/
├── scripts/
│   ├── data/           # 数据结构
│   ├── core/          # 核心系统
│   ├── ui/            # UI 控制器
│   ├── events/         # 事件负载
│   └── autoload/       # 全局单例
├── scenes/             # 场景文件
├── resources/          # 配置数据
└── project.godot
```

## 运行

使用 Godot 4.3 打开项目，运行 `Main.tscn`

## 文档

- [架构文档](./ARCHITECTURE.md)
- [问题复盘](./RETROSPECTIVE.md)