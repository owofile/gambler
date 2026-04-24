class_name BattleManager
extends RefCounted

static func StartBattle(player_deck: DeckSnapshot, enemy: EnemyData, data_manager) -> BattleReport:
	var registry = data_manager.card_registry

	var report := BattleReport.new()
	var current_score: Array[int] = [0, 0]
	var consecutive_draws: int = 0
	var round_number: int = 0

	var target_wins: int
	match enemy.tier:
		EnemyData.EnemyTier.Grunt: target_wins = 3
		EnemyData.EnemyTier.Elite: target_wins = 4
		EnemyData.EnemyTier.Boss: target_wins = 5
		_: target_wins = 3

	print("[BattleManager] Battle start: %s (target: %d wins)" % [enemy.enemy_name, target_wins])

	while current_score[0] < target_wins and current_score[1] < target_wins:
		round_number += 1
		var round_detail := _simulate_round(
			round_number,
			player_deck,
			enemy,
			current_score,
			registry
		)
		report.rounds.append(round_detail)

		match round_detail.result:
			BattleEnums.ERoundResult.PlayerWin:
				current_score[0] += 1
				consecutive_draws = 0
			BattleEnums.ERoundResult.EnemyWin:
				current_score[1] += 1
				consecutive_draws = 0
			BattleEnums.ERoundResult.Draw:
				consecutive_draws += 1

		if consecutive_draws >= 2:
			current_score[0] += 1
			consecutive_draws = 0

		print("[BattleManager] Round %d: Player %d - %d Enemy (Draw streak: %d)" %
			[round_number, current_score[0], current_score[1], consecutive_draws])

	report.player_wins = current_score[0]
	report.enemy_wins = current_score[1]
	report.result = BattleEnums.EBattleResult.Victory if current_score[0] >= target_wins else BattleEnums.EBattleResult.Defeat

	if report.result == BattleEnums.EBattleResult.Victory:
		if enemy.loot_pool_prototype_ids.size() > 0:
			var random_idx := randi() % enemy.loot_pool_prototype_ids.size()
			report.cards_to_add.append(enemy.loot_pool_prototype_ids[random_idx])
			print("[BattleManager] Loot awarded: %s" % enemy.loot_pool_prototype_ids[random_idx])
	else:
		var removable: Array[String] = []
		for card in player_deck.cards:
			if card.bind_status != CardData.CardBindStatus.Locked:
				removable.append(card.instance_id)
		if removable.size() > 0:
			var random_idx := randi() % removable.size()
			report.cards_to_remove.append(removable[random_idx])
			print("[BattleManager] Card lost: %s" % removable[random_idx])

	print("[BattleManager] Battle end: %s (%d rounds)" % [
		BattleEnums.battle_result_to_string(report.result),
		report.rounds.size()
	])

	return report


static func _simulate_round(
	round_num: int,
	player_deck: DeckSnapshot,
	enemy: EnemyData,
	current_score: Array[int],
	registry
) -> RoundDetail:
	var detail := RoundDetail.new()
	detail.round_number = round_num

	var player_cards: Array[CardSnapshot] = _select_top_cards(player_deck, 3)
	var enemy_cards: Array[String] = _select_random_cards(enemy.deck_prototype_ids, 3)

	for card in player_cards:
		detail.player_card_ids.append(card.prototype_id)
	for card_id in enemy_cards:
		detail.enemy_card_ids.append(card_id)

	detail.player_total_value = _sum_card_values(player_cards)
	detail.enemy_total_value = _sum_enemy_card_values(enemy_cards, registry)

	if detail.player_total_value > detail.enemy_total_value:
		detail.result = BattleEnums.ERoundResult.PlayerWin
	elif detail.player_total_value < detail.enemy_total_value:
		detail.result = BattleEnums.ERoundResult.EnemyWin
	else:
		detail.result = BattleEnums.ERoundResult.Draw

	print("[BattleManager] Round %d: Player(%s) %d vs %d Enemy(%s) - %s" % [
		round_num,
		detail.player_card_ids,
		detail.player_total_value,
		detail.enemy_total_value,
		detail.enemy_card_ids,
		BattleEnums.round_result_to_string(detail.result)
	])

	return detail


static func _select_top_cards(deck: DeckSnapshot, count: int) -> Array[CardSnapshot]:
	var sorted_cards := deck.cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.final_value > b.final_value)

	var result: Array[CardSnapshot] = []
	var limit := mini(count, sorted_cards.size())
	for i in range(limit):
		result.append(sorted_cards[i])
	return result


static func _select_random_cards(card_ids: Array[String], count: int) -> Array[String]:
	if card_ids.size() == 0:
		return []

	var result: Array[String] = []
	var available := card_ids.duplicate()

	for i in range(mini(count, card_ids.size())):
		if available.size() == 0:
			break
		var idx := randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)

	return result


static func _sum_card_values(cards: Array[CardSnapshot]) -> int:
	var total: int = 0
	for card in cards:
		total += card.final_value
	return total


static func _sum_enemy_card_values(card_ids: Array[String], registry) -> int:
	var total: int = 0
	for proto_id in card_ids:
		var proto: CardData = registry.get_prototype(proto_id)
		if proto:
			total += proto.base_value
	return total
