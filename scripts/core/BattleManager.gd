class_name BattleManager
extends RefCounted

static func StartBattle(player_deck: DeckSnapshot, enemy: EnemyData, data_manager) -> BattleReport:
	var card_registry = data_manager.card_registry
	var effect_registry = data_manager.effect_registry
	var cost_registry = data_manager.cost_registry

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
			card_registry,
			effect_registry,
			cost_registry,
			report
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
			if card.bind_status != CardData.CardBindStatus.Locked and not _is_disabled(card.instance_id, report):
				removable.append(card.instance_id)
		for remove_id in report.cards_to_remove:
			if removable.has(remove_id):
				removable.erase(remove_id)
		if removable.size() > 0:
			var random_idx := randi() % removable.size()
			report.cards_to_remove.append(removable[random_idx])
			print("[BattleManager] Card lost: %s" % removable[random_idx])

	print("[BattleManager] Battle end: %s (%d rounds)" % [
		BattleEnums.battle_result_to_string(report.result),
		report.rounds.size()
	])

	return report


static func ProcessSelectedCards(
	player_snapshot: DeckSnapshot,
	enemy: EnemyData,
	data_manager
) -> Dictionary:
	print("[BattleManager] ProcessSelectedCards ENTERED with %d cards" % player_snapshot.cards.size())
	for card in player_snapshot.cards:
		print("[BattleManager]   Card in snapshot: %s, cost_id: '%s'" % [card.prototype_id, card.cost_id])

	var card_registry = data_manager.card_registry
	var effect_registry = data_manager.effect_registry
	var cost_registry = data_manager.cost_registry

	var report := BattleReport.new()
	var context := EffectContext.new(
		player_snapshot,
		null,
		player_snapshot.cards,
		[],
		0,
		0,
		0,
		0,
		3
	)

	for card in player_snapshot.cards:
		context.current_player_total += card.final_value

	var enemy_card_ids: Array[String] = _select_random_cards(enemy.deck_prototype_ids, 3)
	var enemy_total: int = _sum_enemy_card_values(enemy_card_ids, card_registry)
	context.current_enemy_total = enemy_total

	var all_effects: Array[String] = []
	for card in player_snapshot.cards:
		for eff_id in card.effect_ids:
			all_effects.append(eff_id)

	var sorted_effects: Array[IEffectHandler] = effect_registry.get_effects_sorted_by_priority(all_effects)
	for effect in sorted_effects:
		effect.apply(context)

	for card in player_snapshot.cards:
		print("[BattleManager] Checking card: %s, cost_id: '%s'" % [card.prototype_id, card.cost_id])
		if card.cost_id != "":
			print("[BattleManager] Card %s has cost: %s" % [card.prototype_id, card.cost_id])
			var cost_handler: ICostHandler = cost_registry.get_cost(card.cost_id)
			if cost_handler:
				print("[BattleManager] Found cost handler for: %s" % card.cost_id)
				var cost_ctx := CostContext.new(context, report, card, "player")
				cost_handler.trigger(cost_ctx)
			else:
				print("[BattleManager] No cost handler found for: %s" % card.cost_id)

	print("[BattleManager] ProcessSelectedCards: Player(%s) %d vs %d Enemy(%s)" % [
		player_snapshot.cards.map(func(c): return c.prototype_id),
		context.current_player_total,
		context.current_enemy_total,
		enemy_card_ids
	])

	return {
		"player_total": context.current_player_total,
		"enemy_total": context.current_enemy_total,
		"enemy_card_ids": enemy_card_ids,
		"report": report
	}


static func _is_disabled(instance_id: String, report: BattleReport) -> bool:
	if report.disabled_instance_ids.has(instance_id):
		return true
	return false


static func _simulate_round(
	round_num: int,
	player_deck: DeckSnapshot,
	enemy: EnemyData,
	current_score: Array[int],
	card_registry,
	effect_registry,
	cost_registry,
	report: BattleReport
) -> RoundDetail:
	var detail := RoundDetail.new()
	detail.round_number = round_num

	var player_cards: Array[CardSnapshot] = _select_top_cards(player_deck, 3)
	var enemy_card_ids: Array[String] = _select_random_cards(enemy.deck_prototype_ids, 3)

	for card in player_cards:
		detail.player_card_ids.append(card.prototype_id)
	for card_id in enemy_card_ids:
		detail.enemy_card_ids.append(card_id)

	var player_base_total: int = _sum_card_values(player_cards)
	var enemy_base_total: int = _sum_enemy_card_values(enemy_card_ids, card_registry)

	var all_player_effects: Array[String] = []
	for card in player_cards:
		for eff_id in card.effect_ids:
			all_player_effects.append(eff_id)

	var sorted_effects: Array[IEffectHandler] = effect_registry.get_effects_sorted_by_priority(all_player_effects)

	var context := EffectContext.new(
		player_deck,
		null,
		player_cards,
		[],
		player_base_total,
		enemy_base_total,
		current_score[0],
		current_score[1],
		3
	)

	for effect in sorted_effects:
		effect.apply(context)

	detail.player_total_value = context.current_player_total
	detail.enemy_total_value = context.current_enemy_total

	if context.current_player_total > context.current_enemy_total:
		detail.result = BattleEnums.ERoundResult.PlayerWin
	elif context.current_player_total < context.current_enemy_total:
		detail.result = BattleEnums.ERoundResult.EnemyWin
	else:
		detail.result = BattleEnums.ERoundResult.Draw

	for card in player_cards:
		if card.cost_id != "":
			var cost_handler: ICostHandler = cost_registry.get_cost(card.cost_id)
			if cost_handler:
				var cost_ctx := CostContext.new(context, report, card, "player")
				cost_handler.trigger(cost_ctx)

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
