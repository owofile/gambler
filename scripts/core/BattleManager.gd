class_name BattleManager
extends RefCounted

static func StartBattle(player_deck: DeckSnapshot, enemy: EnemyData, data_manager) -> BattleReport:
	var card_registry = data_manager.card_registry
	var effect_registry = data_manager.effect_registry
	var cost_registry = data_manager.cost_registry

	var report := BattleReport.new()
	var current_score: Array = [0, 0]
	var consecutive_draws: int = 0
	var round_number: int = 0

	var target_wins: int
	match enemy.get_tier():
		EnemyData.EnemyTier.Grunt: target_wins = 3
		EnemyData.EnemyTier.Elite: target_wins = 4
		EnemyData.EnemyTier.Boss: target_wins = 5
		_: target_wins = 3

	print("[BattleManager] Battle start: %s (target: %d wins)" % [enemy.get_enemy_name(), target_wins])

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
		var loot_pool: Array = enemy.get_loot_pool_prototype_ids()
		if loot_pool.size() > 0:
			var random_idx: int = randi() % loot_pool.size()
			report.cards_to_add.append(loot_pool[random_idx])
			print("[BattleManager] Loot awarded: %s" % loot_pool[random_idx])
	else:
		var removable: Array = []
		for c in player_deck.get_cards():
			var card: CardSnapshot = c as CardSnapshot
			if card and card.get_bind_status() != CardData.CardBindStatus.Locked and not _is_disabled(card.get_card_id(), report):
				removable.append(card.get_card_id())
		for remove_id in report.cards_to_remove:
			if removable.has(remove_id):
				removable.erase(remove_id)
		if removable.size() > 0:
			var random_idx: int = randi() % removable.size()
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
	var player_cards: Array = player_snapshot.get_cards()
	print("[BattleManager] ProcessSelectedCards ENTERED with %d cards" % player_cards.size())
	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			print("[BattleManager]   Card in snapshot: %s, cost_id: '%s'" % [card.get_prototype_id(), card.get_cost_id()])

	var card_registry = data_manager.card_registry
	var effect_registry = data_manager.effect_registry
	var cost_registry = data_manager.cost_registry

	var report := BattleReport.new()
	var context := EffectContext.new(
		player_snapshot,
		null,
		player_cards,
		[],
		0,
		0,
		0,
		0,
		3
	)

	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			context.add_player_total(card.get_final_value())

	var enemy_card_ids: Array = _select_random_cards(enemy.get_deck_prototype_ids(), 3)
	var enemy_total: int = _sum_enemy_card_values(enemy_card_ids, card_registry)
	context.set_current_enemy_total(enemy_total)

	var selection_order: Array = []
	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			selection_order.append(card.get_card_id())
	context.set_selection_order(selection_order)

	var effects_with_source: Array = []
	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			for eff_id in card.get_effect_ids():
				effects_with_source.append({
					"effect_id": eff_id,
					"source_id": card.get_card_id()
				})

	_execute_effects_by_timing(context, effect_registry, effects_with_source)

	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			print("[BattleManager] Checking card: %s, cost_id: '%s'" % [card.get_prototype_id(), card.get_cost_id()])
			if card.has_cost():
				print("[BattleManager] Card %s has cost: %s" % [card.get_prototype_id(), card.get_cost_id()])
				var cost_handler: ICostHandler = cost_registry.get_cost(card.get_cost_id())
				if cost_handler:
					print("[BattleManager] Found cost handler for: %s" % card.get_cost_id())
					var cost_ctx := CostContext.new(context, report, card, "player")
					cost_handler.trigger(cost_ctx)
				else:
					print("[BattleManager] No cost handler found for: %s" % card.get_cost_id())

	var player_card_ids_debug: Array = []
	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			player_card_ids_debug.append(card.get_prototype_id())
	print("[BattleManager] ProcessSelectedCards: Player(%s) %d vs %d Enemy(%s)" % [
		player_card_ids_debug,
		context.get_current_player_total(),
		context.get_current_enemy_total(),
		enemy_card_ids
	])

	return {
		"player_total": context.get_current_player_total(),
		"enemy_total": context.get_current_enemy_total(),
		"enemy_card_ids": enemy_card_ids,
		"report": report
	}


static func _is_disabled(instance_id: String, report: BattleReport) -> bool:
	if report.is_card_disabled(instance_id):
		return true
	return false


static func _simulate_round(
	round_num: int,
	player_deck: DeckSnapshot,
	enemy: EnemyData,
	current_score: Array,
	card_registry,
	effect_registry,
	cost_registry,
	report: BattleReport
) -> RoundDetail:
	var detail := RoundDetail.new()
	detail.round_number = round_num

	var player_cards: Array = _select_top_cards(player_deck, 3)
	var enemy_card_ids: Array = _select_random_cards(enemy.get_deck_prototype_ids(), 3)

	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			detail.player_card_ids.append(card.get_prototype_id())
	for card_id in enemy_card_ids:
		detail.enemy_card_ids.append(card_id)

	var player_base_total: int = _sum_card_values(player_cards)
	var enemy_base_total: int = _sum_enemy_card_values(enemy_card_ids, card_registry)

	var all_player_effects: Array = []
	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card:
			for eff_id in card.get_effect_ids():
				all_player_effects.append(eff_id)

	var sorted_effects: Array = effect_registry.get_effects_sorted_by_priority(all_player_effects)

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

	detail.player_total_value = context.get_current_player_total()
	detail.enemy_total_value = context.get_current_enemy_total()

	if context.get_current_player_total() > context.get_current_enemy_total():
		detail.result = BattleEnums.ERoundResult.PlayerWin
	elif context.get_current_player_total() < context.get_current_enemy_total():
		detail.result = BattleEnums.ERoundResult.EnemyWin
	else:
		detail.result = BattleEnums.ERoundResult.Draw

	for c in player_cards:
		var card: CardSnapshot = c as CardSnapshot
		if card and card.has_cost():
			var cost_handler: ICostHandler = cost_registry.get_cost(card.get_cost_id())
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


static func _select_top_cards(deck: DeckSnapshot, count: int) -> Array:
	var sorted_cards := deck.get_cards().duplicate()
	sorted_cards.sort_custom(func(a, b):
		var card_a: CardSnapshot = a as CardSnapshot
		var card_b: CardSnapshot = b as CardSnapshot
		if not card_a or not card_b:
			return false
		return card_a.get_final_value() > card_b.get_final_value()
	)

	var result: Array = []
	var limit := mini(count, sorted_cards.size())
	for i in range(limit):
		result.append(sorted_cards[i])
	return result


static func _execute_effects_by_timing(context: EffectContext, effect_registry, effects_with_source: Array) -> void:
	var by_timing = effect_registry.get_effects_by_timing(effects_with_source)

	if by_timing.has(EffectTriggerTiming.Timing.IMMEDIATE):
		for item in by_timing[EffectTriggerTiming.Timing.IMMEDIATE]:
			var handler: IEffectHandler = item["handler"]
			handler.apply(context)

	if by_timing.has(EffectTriggerTiming.Timing.SEQUENTIAL):
		for item in by_timing[EffectTriggerTiming.Timing.SEQUENTIAL]:
			var handler: IEffectHandler = item["handler"]
			handler.apply(context)

	if by_timing.has(EffectTriggerTiming.Timing.DELAYED_NEXT):
		for card_id in context.get_selection_order():
			var next_card = context.get_next_card_in_order(card_id)
			if not next_card.is_empty():
				for item in by_timing[EffectTriggerTiming.Timing.DELAYED_NEXT]:
					var handler: IEffectHandler = item["handler"]
					if handler.get_target_card_ids(context, card_id).has(next_card):
						handler.apply_to_card(context, next_card)

	if by_timing.has(EffectTriggerTiming.Timing.MANUAL):
		print("[BattleManager] MANUAL trigger timing requires player input, skipped for now")


static func _select_random_cards(card_ids: Array, count: int) -> Array:
	if card_ids.size() == 0:
		return []

	var result: Array = []
	var available: Array = card_ids.duplicate()

	for i in range(mini(count, card_ids.size())):
		if available.size() == 0:
			break
		var idx := randi() % available.size()
		var card_id: String = available[idx]
		result.append(card_id)
		available.remove_at(idx)

	return result


static func _sum_card_values(cards: Array) -> int:
	var total: int = 0
	for card in cards:
		var c: CardSnapshot = card as CardSnapshot
		if c:
			total += c.get_final_value()
	return total


static func _sum_enemy_card_values(card_ids: Array, registry) -> int:
	var total: int = 0
	for proto_id in card_ids:
		var proto: CardData = registry.get_prototype(proto_id)
		if proto:
			total += proto.base_value
	return total
