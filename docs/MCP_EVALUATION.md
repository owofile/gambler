# MCP Server Evaluation for Gambler Project

**Date**: 2026-04-28
**Project**: Gambler (Godot-based card battle game)
**Question**: Should we create an MCP server to manage/interact with the battle system?

---

## 1. What is MCP?

MCP (Model Context Protocol) is a standardized protocol that allows LLMs to interact with external tools and services through a well-defined interface. It enables AI agents to call functions, access resources, and trigger workflows in external systems.

---

## 2. Project Architecture Summary

```
Gambler/
├── scripts/
│   ├── battle/              # Battle System V2
│   │   ├── BattleCore.gd   # State machine manager
│   │   ├── BattleConfig.gd  # Configuration
│   │   ├── states/          # 6 battle states
│   │   ├── policies/        # Deck policies
│   │   └── interfaces/      # UI interface
│   ├── core/                # CardManager, BattleManager
│   ├── data/                # CardInstance, CardSnapshot, etc.
│   └── autoload/            # DataManager
└── scenes/
    └── battle/
        ├── BattleStressTest.tscn  # Test scene
        └── BattleUI_V2.tscn       # UI implementation
```

**Current Test Flow**:
1. User runs `BattleStressTest.tscn` in Godot
2. Script creates `BattleCore`, initializes with `CardManager` + `DataManager`
3. Battle runs through state machine: `PlayerSelect → EnemyReveal → Settlement → RoundEnd`
4. Output goes to Godot console

---

## 3. MCP Server Proposal

### 3.1 What would it do?

An MCP server could expose battle system functionality as tools:

```json
{
  "tools": [
    {
      "name": "start_battle",
      "description": "Start a new battle with given config",
      "inputSchema": {...}
    },
    {
      "name": "get_battle_state",
      "description": "Get current battle state, scores, cards"
    },
    {
      "name": "simulate_round",
      "description": "Simulate a round with selected card IDs"
    },
    {
      "name": "get_card_info",
      "description": "Get information about a card prototype"
    }
  ]
}
```

### 3.2 Benefits

| Benefit | Description |
|---------|-------------|
| **External Control** | Start battles, simulate rounds from external scripts |
| **Automated Testing** | AI agents could run battle simulations programmatically |
| **CI/CD Integration** | Battle system could be tested in CI pipelines |
| **Remote Debugging** | Query battle state from external tools |
| **Scripting** | Python/JS scripts could interact with game logic |

### 3.3 Drawbacks

| Drawback | Description |
|---------|-------------|
| **Added Complexity** | MCP server is another service to maintain |
| **Godot Dependency** | Godot engine must be running (not headless) |
| **Over-engineering** | Current workflow (run scene in Godot) works fine |
| **Limited Use Case** | Only useful if you need external/automated control |
| **Performance** | IPC between MCP server and Godot adds latency |

---

## 4. Decision Matrix

| Factor | Weight | Score (1-5) | Reason |
|--------|--------|-------------|--------|
| Current workflow adequacy | High | 5 | Running scenes in Godot works fine |
| Automated testing need | Medium | 3 | Could be useful but not critical |
| CI/CD integration need | Low | 2 | No CI pipeline currently |
| External script integration | Low | 2 | No external scripts planned |
| Development effort | High | 3 | MCP server takes time to build properly |
| Maintenance burden | Medium | 2 | Additional service to maintain |

**Weighted Score**: ~2.8/5

---

## 5. Recommendation

### **Not Recommended (At This Time)**

**Reasons**:

1. **Current workflow is sufficient** - The `BattleStressTest.tscn` scene already allows direct testing of the battle system with full console output

2. **No demonstrated need** - You haven't expressed need for:
   - Automated battle simulation
   - CI/CD integration
   - External scripting access
   - Remote monitoring

3. **Complexity without clear ROI** - Building a proper MCP server requires:
   - Designing tool schemas
   - Implementing server (Python or TypeScript)
   - Setting up transport (stdio or HTTP)
   - Testing with MCP inspector
   - Documentation and evaluations

4. **Godot is not a service** - The game is designed to run as an interactive application. An MCP server would be fighting against this architecture.

---

## 6. When It Would Make Sense

Consider revisiting if:

- You want to run **automated battle simulations** in a CI pipeline
- You need **external Python/JS scripts** to analyze battle data
- You want **AI agents** to interact with the game for reinforcement learning experiments
- The project evolves into a **headless battle simulator** with an API layer
- You develop a **web-based battle log analyzer** that queries game state

---

## 7. Alternative Approaches

If you need more advanced testing capabilities:

| Alternative | Effort | Benefit |
|-------------|--------|---------|
| **Enhance BattleStressTest** | Low | Add more test scenarios, assertions |
| **Add Godot headless mode** | Medium | Run tests without display |
| **Create Python test harness** | Medium | Use `godot-py` or similar for external control |
| **Build REST API in Godot** | Medium | Expose HTTP endpoints for game control |

---

## 8. Conclusion

The current architecture is well-designed and the testing workflow is functional. An MCP server would add significant complexity without solving a demonstrated problem. **Recommended action**: Continue with current Godot-based testing approach. If specific needs arise (CI/CD, external scripts, AI training), revisit this decision.

---

**Prepared by**: opencode assistant
**For**: Gambler Project
