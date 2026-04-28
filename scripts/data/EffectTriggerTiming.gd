## Effect Trigger Timing Enum
##
## Defines when an effect is triggered during battle
class_name EffectTriggerTiming
extends RefCounted

enum Timing {
	IMMEDIATE = 0,      # 即时 - 点数计算后立即执行
	SEQUENTIAL = 1,      # 顺序 - 按出牌顺序逐张执行
	DELAYED_NEXT = 2,   # 延迟下一张 - 效果作用于下一张出的牌
	DELAYED_ROUND = 3,   # 延迟回合 - 下回合生效
	MANUAL = 4           # 手动 - 需要玩家选择目标
}

static func timing_to_string(timing: int) -> String:
	match timing:
		Timing.IMMEDIATE: return "IMMEDIATE"
		Timing.SEQUENTIAL: return "SEQUENTIAL"
		Timing.DELAYED_NEXT: return "DELAYED_NEXT"
		Timing.DELAYED_ROUND: return "DELAYED_ROUND"
		Timing.MANUAL: return "MANUAL"
	return "UNKNOWN"

static func timing_from_string(s: String) -> int:
	match s.to_upper():
		"IMMEDIATE": return Timing.IMMEDIATE
		"SEQUENTIAL": return Timing.SEQUENTIAL
		"DELAYED_NEXT": return Timing.DELAYED_NEXT
		"DELAYED_ROUND": return Timing.DELAYED_ROUND
		"MANUAL": return Timing.MANUAL
	return Timing.IMMEDIATE