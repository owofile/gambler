# Gambler Project OOP Programming Standard

> **Version**: 1.0
> **Date**: 2026-04-24
> **Godot Version**: 4.3+
> **Language**: GDScript

---

## Table of Contents

1. [Overview](#1-overview)
2. [SOLID Principles](#2-solid-principles)
3. [Class Design](#3-class-design)
4. [Naming Conventions](#4-naming-conventions)
5. [Encapsulation](#5-encapsulation)
6. [Interfaces](#6-interfaces)
7. [Dependency Management](#7-dependency-management)
8. [Godot-Specific Guidelines](#8-godot-specific-guidelines)
9. [Code Organization](#9-code-organization)
10. [Documentation](#10-documentation)

---

## 1. Overview

This document defines the OOP programming standards for the Gambler project. All code must adhere to these guidelines to ensure maintainability, testability, and scalability.

### 1.1 Core Principles

| Principle | Description |
|-----------|-------------|
| **SOLID** | Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion |
| **DRY** | Don't Repeat Yourself |
| **KISS** | Keep It Simple, Stupid |
| **YAGNI** | You Aren't Gonna Need It |

### 1.2 Godot Class Types

| Type | Use When | Example |
|------|----------|---------|
| `class_name` + `extends Node` | Game objects, managers | `CardManager`, `BattleFlowManager` |
| `class_name` + `extends RefCounted` | Data containers, interfaces | `CardInstance`, `IEffectHandler` |
| `class_name` + `extends Resource` | Saveable assets | Card prototypes from JSON |
| Inner class | Helper classes, states | `StateMachine.State` |

---

## 2. SOLID Principles

### 2.1 Single Responsibility Principle (SRP)

**Rule**: A class should have only one reason to change.

**BAD** (violates SRP):
```gdscript
# This class handles deck management AND battle logic AND logging
class_name CardBattleManager
    func add_card(): pass
    func remove_card(): pass
    func calculate_battle(): pass
    func log_to_file(): pass  # Should be separate
```

**GOOD** (follows SRP):
```gdscript
class_name CardManager
    func add_card(): pass
    func remove_card(): pass

class_name BattleCalculator
    func calculate_battle(): pass

class_name FileLogger
    func log(message: String): pass
```

### 2.2 Open/Closed Principle (OCP)

**Rule**: Open for extension, closed for modification.

**BAD**:
```gdscript
func process_card(card_type: String) -> int:
    if card_type == "attack":
        return 10
    elif card_type == "defense":
        return 5
    # Adding new type requires modifying this function
```

**GOOD** (using polymorphism):
```gdscript
class_name Card
    func get_value() -> int: pass

class_name AttackCard extends Card
    func get_value() -> int: return 10

class_name DefenseCard extends Card
    func get_value() -> int: return 5

func process_card(card: Card) -> int:
    return card.get_value()  # Extensible without modification
```

### 2.3 Liskov Substitution Principle (LSP)

**Rule**: Objects of a superclass should be replaceable with objects of a subclass without breaking the application.

```gdscript
class_name Effect
    func apply(context: EffectContext) -> void: pass

class_name DamageEffect extends Effect
    func apply(context: EffectContext) -> void:
        context.target.health -= context.value

# Any Effect implementation can be used interchangeably
func apply_all_effects(effects: Array[Effect], context: EffectContext) -> void:
    for effect in effects:
        effect.apply(context)  # Works with any Effect subclass
```

### 2.4 Interface Segregation Principle (ISP)

**Rule**: Clients should not be forced to depend on interfaces they do not use.

**BAD**:
```gdscript
class_name IUnitAction
    func move_to(pos: Vector2) -> void: pass
    func attack(target) -> void: pass
    func heal(amount: int) -> void: pass  # Not all units can heal

class_name Soldier extends IUnitAction
    func move_to(pos: Vector2) -> void: pass
    func attack(target) -> void: pass
    func heal(amount: int) -> void:
        pass  # Soldier can't heal, but forced to implement
```

**GOOD**:
```gdscript
class_name IMovable
    func move_to(pos: Vector2) -> void: pass

class_name IAttackable
    func attack(target) -> void: pass

class_name IHealable
    func heal(amount: int) -> void: pass

class_name Soldier extends Node
    var _movable: IMovable
    var _attackable: IAttackable
    # Only implements what Soldier actually needs
```

### 2.5 Dependency Inversion Principle (DIP)

**Rule**: High-level modules should not depend on low-level modules. Both should depend on abstractions.

**BAD** (depends on concrete class):
```gdscript
class_name BattleProcessor
    var _card_manager: CardManager  # Depends on concrete

    func battle():
        var cards = _card_manager.GetAllCards()  # Tight coupling
```

**GOOD** (depends on abstraction):
```gdscript
class_name BattleProcessor
    var _card_registry: CardRegistry  # Depends on interface/abstraction

    func battle():
        var cards = _card_registry.get_all_cards()  # Loose coupling
```

---

## 3. Class Design

### 3.1 Class Declaration Order

Follow this order based on [Godot Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):

```gdscript
## 1. Annotations
@icon("res://path/to/icon.svg")
@export

## 2. Class declaration
class_name MyClass
extends BaseClass

## 3. Documentation comment
## Brief description of the class.
##
## Detailed description if needed.

## 4. Signals
signal state_changed(previous, new)
signal cards_selected(ids: Array[String])

## 5. Enums (after signals, before constants)
enum State {
    IDLE,
    RUNNING,
    COMPLETED
}

## 6. Constants
const MAX_SIZE := 100
const DEFAULT_NAME := "Unknown"

## 7. Static variables
static var _instance_count := 0

## 8. Export variables
@export var speed: int = 10
@export var resource_path: String = "res://default.tres"

## 9. Public variables
var health: int = 100
var name: String = "Player"

## 10. Private variables
var _internal_state: State = State.IDLE
var _cache: Dictionary = {}

## 11. @onready variables
@onready var _sprite: Sprite2D = get_node("Sprite")
@onready var _label: Label = get_node("Label")

## 12. Lifecycle methods
func _init():
    _instance_count += 1

func _ready():
    pass

func _process(delta: float):
    pass

## 13. Public methods
func take_damage(amount: int) -> void:
    health = max(0, health - amount)

## 14. Private methods
func _calculate_final_value() -> int:
    return base_value + bonus

## 15. Inner classes
class InnerClass:
    pass
```

### 3.2 Constructor Guidelines

```gdscript
class_name CardInstance
extends RefCounted

## Use _init() for initialization
func _init(
    p_instance_id: String = "",
    p_prototype_id: String = "",
    p_delta: int = 0,
    p_bind: CardData.CardBindStatus = CardData.CardBindStatus.None
) -> void:
    _instance_id = p_instance_id
    _prototype_id = p_prototype_id
    _delta_value = p_delta
    _bind_status = p_bind

## Prefer named parameters with default values
## Use p_ prefix to avoid shadowing
```

---

## 4. Naming Conventions

Based on [Godot Naming Conventions](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#naming-conventions):

| Type | Convention | Example |
|------|------------|---------|
| File names | snake_case | `card_manager.gd`, `battle_flow.gd` |
| Class names | PascalCase | `class_name CardManager` |
| Node names | PascalCase | `Camera3D`, `Player` |
| Variables | snake_case | `var player_health: int` |
| Private variables | _snake_case | `var _internal_state: int` |
| Functions | snake_case | `func calculate_damage():` |
| Private functions | _snake_case | `func _process_internal():` |
| Constants | CONSTANT_CASE | `const MAX_SPEED := 200` |
| Enum names | PascalCase | `enum Element { FIRE, WATER, EARTH }` |
| Enum members | CONSTANT_CASE | `Element.FIRE` |
| Signals | snake_case (past tense) | `signal health_changed` |
| Boolean variables | is/has/can prefix | `var is_alive: bool`, `var has_key: bool` |

### 4.1 Naming Examples

```gdscript
## Classes
class_name BattleFlowManager
class_name CardSelector
class_name EffectRegistry

## Interfaces (I prefix)
class_name IEffectHandler
class_name ICostHandler

## Constants
const MAX_DECK_SIZE := 20
const DEFAULT_CARD_VALUE := 1
const EVENT_BATTLE_START := "battle_started"

## Variables
var player_health: int = 100
var card_instances: Array[CardInstance] = []
var _current_state: State = State.IDLE
var _is_processing: bool = false

## Functions
func calculate_total_value() -> int:
func _process_state_change():
func get_card_snapshot() -> CardSnapshot:

## Signals
signal battle_started()
signal card_selected(instance_id: String)
signal cards_confirmed(selected_ids: Array[String])
```

### 4.2 Forbidden Names

- Do not use single letter names except for loop counters: `for i in range(10):`
- Do not use Hungarian notation: `var int_count: int` (bad)
- Do not use abbreviations unless universally understood: `obj` (bad), `object` (good)

---

## 5. Encapsulation

### 5.1 Data Class Encapsulation

**Rule**: All data classes MUST have private members with getter/setter methods.

**BAD** (no encapsulation):
```gdscript
class_name CardSnapshot
extends RefCounted

var instance_id: String
var prototype_id: String
var final_value: int
var effect_ids: Array[String]
var cost_id: String

# External code can directly modify:
card_snapshot.final_value = -999  # Invalid value!
```

**GOOD** (proper encapsulation):
```gdscript
class_name CardSnapshot
extends RefCounted

var _instance_id: String = ""
var _prototype_id: String = ""
var _final_value: int = 0
var _effect_ids: Array[String] = []
var _cost_id: String = ""

func get_instance_id() -> String:
    return _instance_id

func set_instance_id(value: String) -> void:
    if value.is_empty():
        push_error("Instance ID cannot be empty")
        return
    _instance_id = value

func get_final_value() -> int:
    return _final_value

func set_final_value(value: int) -> void:
    if value < 0:
        push_warning("Final value should not be negative, clamping to 0")
        value = 0
    _final_value = value

func get_effect_ids() -> Array[String]:
    return _effect_ids.duplicate()

func get_cost_id() -> String:
    return _cost_id

## For read-only access to arrays, return duplicate
## For modification, provide specific methods
```

### 5.2 Validation in Setters

```gdscript
func set_health(value: int) -> void:
    if value < 0:
        push_error("Health cannot be negative")
        return
    if value > MAX_HEALTH:
        push_warning("Health exceeds maximum, clamping to %d" % MAX_HEALTH)
        value = MAX_HEALTH
    _health = value
    health_changed.emit(_health)
```

### 5.3 Computed Properties

```gdscript
var _base_value: int = 0
var _bonus_value: int = 0

func get_total_value() -> int:
    return _base_value + _bonus_value

func get_is_max_health() -> bool:
    return _health >= MAX_HEALTH
```

---

## 6. Interfaces

### 6.1 Interface Naming

Use `I` prefix for interface classes:

```gdscript
class_name IEffectHandler
extends RefCounted

func apply(context: EffectContext) -> void:
    pass

func get_priority() -> int:
    return 0
```

### 6.2 Interface Rules

| Rule | Description |
|------|-------------|
| Single responsibility | Interface should have ≤ 5 methods |
| Cohesion | Methods should be related to one purpose |
| Naming | Name describes capability, not implementation |
| Default implementation | Provide default `pass` for optional methods |

### 6.3 Interface Example

```gdscript
## IEffectHandler.gd
class_name IEffectHandler
extends RefCounted

func apply(context: EffectContext) -> void:
    pass

func get_priority() -> int:
    return EffectPriority.NORMAL

## IRealtimeEffect.gd
class_name IRealtimeEffect
extends RefCounted

func apply_instant(context: EffectContext) -> void:
    pass
```

### 6.4 Using Interfaces

```gdscript
func apply_effects(effects: Array[IEffectHandler], context: EffectContext) -> void:
    var sorted = effects.duplicate()
    sorted.sort_custom(func(a, b): return a.get_priority() < b.get_priority())

    for effect in sorted:
        if effect is IRealtimeEffect:
            (effect as IRealtimeEffect).apply_instant(context)
        else:
            effect.apply(context)
```

---

## 7. Dependency Management

### 7.1 Dependency Injection

**Rule**: Pass dependencies through constructor or export variables, NEVER use Service Locator anti-pattern.

### 7.2 Service Locator Anti-Pattern (FORBIDDEN)

**BAD** - Service Locator pattern:
```gdscript
func _get_card_manager():
    return get_node("/root/CardManager")  # NEVER do this

func _get_data_manager():
    return get_node("/root/DataManager")  # NEVER do this
```

**Why it's bad**:
- Hidden dependencies
- Difficult to test (can't mock)
- Violates DIP
- Creates tight coupling

### 7.3 Dependency Injection Patterns

**Pattern 1: Constructor Injection**

```gdscript
class_name BattleProcessor
var _card_registry: CardRegistry
var _effect_registry: EffectRegistry

func _init(
    card_reg: CardRegistry,
    effect_reg: EffectRegistry
) -> void:
    _card_registry = card_reg
    _effect_registry = effect_reg
```

**Pattern 2: Export Injection (Godot-preferred)**

```gdscript
class_name BattleProcessor
extends Node

@export var _card_registry: CardRegistry
@export var _effect_registry: EffectRegistry

func _ready() -> void:
    assert(_card_registry != null, "CardRegistry must be exported")
    assert(_effect_registry != null, "EffectRegistry must be exported")
```

**Pattern 3: Initialization Method**

```gdscript
class_name BattleProcessor
var _card_registry: CardRegistry = null

func initialize(card_reg: CardRegistry, effect_reg: EffectRegistry) -> void:
    _card_registry = card_reg
    _effect_registry = effect_reg
```

### 7.4 Godot Autoload Guidelines

Autoload should be used ONLY for true singletons that persist across all scenes:

```ini
# project.godot
[autoload]
DataManager="res://scripts/autoload/DataManager.gd"
EventBus="res://scripts/core/EventBus.gd"
```

**When to use Autoload**:
- Global state that must persist (Player data, Game state)
- EventBus for cross-module communication
- Services that are always needed

**When NOT to use Autoload**:
- Regular managers (inject instead)
- Objects that should have multiple instances
- Data that can be passed through dependencies

### 7.5 Dependency Diagram

```
## GOOD (Dependency Injection)
SceneRunnerV2
    ├── BattleUI (injected via scene instance)
    ├── BattleFlowManager (created as child)
    │   └── _data_manager: DataManager (injected via export)
    └── CardSelector (created as child)

## BAD (Service Locator)
BattleFlowManager
    └── _get_card_manager() → get_node("/root/CardManager")  # FORBIDDEN
```

---

## 8. Godot-Specific Guidelines

### 8.1 Signals vs EventBus

| Scenario | Use | Example |
|----------|-----|---------|
| Between two tightly coupled nodes | Signal | `BattleUI.cards_confirmed.connect(_on_cards_confirmed)` |
| One-to-many across modules | EventBus | `EventBus.Publish("BattleEnded", payload)` |
| UI to controller | Signal | Direct connection |
| Global notifications | EventBus | `CardAcquired`, `GoldChanged` |

### 8.2 Signal Declaration

```gdscript
signal battle_started()
signal card_selected(instance_id: String)
signal cards_confirmed(selected_ids: Array[String])

## Emit signals with emit_signal()
emit_signal("card_selected", card_id)

## Or use shorthand (preferred)
card_selected.emit(card_id)
```

### 8.3 Node Lifecycle

```gdscript
func _init():
    ## Called when object is created in memory
    ## Use for early initialization
    pass

func _enter_tree():
    ## Called when node enters the scene tree
    ## Use for setup that requires parent
    pass

func _ready():
    ## Called when node and all children have entered tree
    ## Use for final initialization
    _initialize_ui()
    _setup_connections()

func _exit_tree():
    ## Called when node is about to leave the scene tree
    ## Use for cleanup
    _cleanup()

func _process(delta: float):
    ## Called every frame
    pass

func _physics_process(delta: float):
    ## Called every physics frame (fixed timestep)
    pass
```

### 8.4 extends Choice

| Base Class | Use When |
|------------|----------|
| `extends Node` | Regular game objects, managers |
| `extends RefCounted` | Data containers, interfaces, non-node objects |
| `extends Resource` | Saveable data, assets |
| `extends Object` | Very lightweight objects (rarely needed) |

### 8.5 Typing Guidelines

```gdscript
## Explicit typing (required for exported and public variables)
@export var player_name: String = ""
var health: int = 100

## Type inference (OK for local variables)
var damage := calculate_damage()
var enemies := get_enemies()

## Array typing (always use typed arrays)
var cards: Array[CardInstance] = []
var values: Array[int] = [1, 2, 3]
var effects: Array[IEffectHandler] = []

## Dictionary typing
var player_data: Dictionary = {}
var config: Dictionary = {
    "difficulty": 1,
    "sound_enabled": true
}
```

### 8.6 Async/Await Patterns

```gdscript
## Awaiting a signal
await get_tree().create_timer(0.5).timeout
await some_signal

## Awaiting with timeout
func wait_with_timeout(signal_to_wait, timeout_seconds: float) -> bool:
    var timer = get_tree().create_timer(timeout_seconds)
    var result = await signal_to_wait_or_timeout(signal_to_wait, timer)
    return result == signal_to_wait

## Async initialization
func initialize_async() -> void:
    var resources = await load_resources()
    _setup_with_resources(resources)
```

---

## 9. Code Organization

### 9.1 Directory Structure

```
gambler/
├── scripts/
│   ├── autoload/              # Autoload singletons (global services)
│   │   └── DataManager.gd
│   ├── core/                 # Core game systems
│   │   ├── CardManager.gd
│   │   ├── BattleManager.gd
│   │   ├── BattleFlowManager.gd
│   │   └── EventBus.gd
│   ├── data/                 # Data structures (no logic)
│   │   ├── CardData.gd
│   │   ├── CardInstance.gd
│   │   ├── CardSnapshot.gd
│   │   ├── DeckSnapshot.gd
│   │   ├── EnemyData.gd
│   │   └── BattleReport.gd
│   ├── interfaces/           # Interface definitions
│   │   ├── IEffectHandler.gd
│   │   └── ICostHandler.gd
│   ├── effects/              # Effect implementations
│   │   ├── EffectRegistry.gd
│   │   ├── FixedBonusEffect.gd
│   │   └── RuleReversalEffect.gd
│   ├── costs/               # Cost implementations
│   │   ├── CostRegistry.gd
│   │   ├── SelfDestroyCost.gd
│   │   └── NextTurnUnusableCost.gd
│   ├── ui/                 # UI controllers
│   │   └── BattleUI.gd
│   ├── coordinators/        # Scene orchestrators
│   │   └── SceneRunnerV2.gd
│   └── utils/              # Utilities
│       ├── Logger.gd
│       └── UUID.gd
├── scenes/
│   ├── BattleUI.tscn
│   └── MainV2.tscn
├── resources/
│   ├── card_prototypes.json
│   └── enemy_registry.json
├── docs/
│   ├── OOP_STANDARD.md      # This document
│   ├── ARCHITECTURE.md
│   └── MODULES.md
├── logs/                   # Runtime logs (auto-generated)
└── project.godot
```

### 9.2 Module Responsibility Matrix

| Module | Responsibility | Depends On |
|--------|---------------|-----------|
| `CardManager` | Card instance lifecycle | DataManager |
| `BattleManager` | Battle calculation | DataManager registries |
| `BattleFlowManager` | State machine | BattleManager, CardManager |
| `CardSelector` | Selection logic | CardManager |
| `EventBus` | Event publishing/subscribing | None |
| `DataManager` | Registry access | None |

---

## 10. Documentation

### 10.1 Class Documentation

```gdscript
## Manages card instances in the player's deck.
##
## Responsibility:
## - Create and destroy CardInstance objects
## - Track deck size limits
## - Provide deck snapshots for battles
##
## Usage:
##   var card = CardManager.AddCard("card_rusty_sword")
##   var removed = CardManager.RemoveCard(card.instance_id)
##
## Note: CardManager is an Autoload singleton.
class_name CardManager
extends Node
```

### 10.2 Method Documentation

```gdscript
## Adds a new card instance to the player's deck.
##
## Params:
##   prototype_id: String - The prototype identifier (e.g., "card_rusty_sword")
##
## Returns:
##   CardInstance - The newly created instance, or null if failed
##
## Failure cases:
##   - Prototype not found
##   - Deck is at maximum capacity (MAX_DECK_SIZE)
##
## Example:
##   var card = CardManager.AddCard("card_justice")
##   if card:
##       print("Card added: ", card.instance_id)
func AddCard(prototype_id: String) -> CardInstance:
    pass
```

### 10.3 Inline Comments

```gdscript
# Use TODO for future work
# TODO: Implement card trading functionality

# Use FIXME for known issues
# FIXME: This leaks memory when card is destroyed

# Use NOTE for important information
# NOTE: This method is called from both client and server

# Use section comments for code organization
#region Card Lifecycle
func add_card():
    pass
func remove_card():
    pass
#endregion
```

---

## Appendix A: Checklist

Before committing code, verify:

- [ ] All classes follow single responsibility
- [ ] No `get_node("/root/...")` calls (use DI)
- [ ] Data classes have getter/setter
- [ ] Interfaces use `I` prefix
- [ ] Naming conventions followed
- [ ] No hardcoded strings for repeated values (use constants)
- [ ] All signals documented
- [ ] Error cases handled
- [ ] Documentation comments added

## Appendix B: Reference

- [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [SOLID Principles (DigitalOcean)](https://www.digitalocean.com/community/conceptual_articles/s-o-l-i-d-the-first-five-principles-of-object-oriented-design)
- [GDScript Basics](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
