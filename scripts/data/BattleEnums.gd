class_name BattleEnums
extends RefCounted

enum ERoundResult {
	PlayerWin,
	EnemyWin,
	Draw
}

enum EBattleResult {
	Victory,
	Defeat
}

static func round_result_to_string(result: ERoundResult) -> String:
	match result:
		ERoundResult.PlayerWin: return "PlayerWin"
		ERoundResult.EnemyWin: return "EnemyWin"
		ERoundResult.Draw: return "Draw"
	return "Unknown"

static func battle_result_to_string(result: EBattleResult) -> String:
	match result:
		EBattleResult.Victory: return "Victory"
		EBattleResult.Defeat: return "Defeat"
	return "Unknown"