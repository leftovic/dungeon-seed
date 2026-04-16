extends GutTest
## Tests for RewardProcessor — expedition reward processing service.
##
## Covers: XP distribution, currency credits, loot distribution,
## condition updates, completion bonuses, and full process_rewards flow.

const RewardProcessorScript := preload("res://src/services/reward_processor.gd")

var processor


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_adventurer(id: String = "", cls: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR, lvl: int = 1) -> AdventurerData:
	var a := AdventurerData.new()
	a.id = id if id != "" else "adv_%d" % randi()
	a.display_name = "Test %s" % id
	a.adventurer_class = cls
	a.level = lvl
	a.xp = 0
	a.initialize_base_stats()
	return a


func _make_party(count: int = 3) -> Array:
	var party: Array = []
	for i in range(count):
		party.append(_make_adventurer("adv_%d" % i))
	return party


func _make_wallet() -> Wallet:
	return Wallet.new()


func _make_inventory() -> InventoryData:
	return InventoryData.new()


func _make_expedition_result(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"status": Enums.ExpeditionStatus.COMPLETED,
		"rooms_cleared": 5,
		"total_rooms": 5,
		"loot": [{"item_id": "wooden_sword", "qty": 1}],
		"currency": {Enums.Currency.GOLD: 100, Enums.Currency.ESSENCE: 10},
		"xp_earned": 300,
		"party_hp": {},
		"adventurers_ko": [],
	}
	for key: String in overrides:
		base[key] = overrides[key]
	return base


func before_each() -> void:
	processor = RewardProcessorScript.new()


# ===========================================================================
# §1 — XP Distribution (~15 tests)
# ===========================================================================

func test_xp_equal_split_among_survivors() -> void:
	var party := _make_party(3)
	var result = processor.distribute_xp(300, party, [])
	assert_eq(result["adv_0"]["xp_received"], 100)
	assert_eq(result["adv_1"]["xp_received"], 100)
	assert_eq(result["adv_2"]["xp_received"], 100)


func test_xp_ko_members_get_half() -> void:
	var party := _make_party(2)
	var ko_list := ["adv_1"]
	var result = processor.distribute_xp(300, party, ko_list)
	# Weights: adv_0=1.0, adv_1=0.5, total=1.5
	# adv_0 gets 300/1.5*1.0=200, adv_1 gets 300/1.5*0.5=100
	assert_eq(result["adv_0"]["xp_received"], 200)
	assert_eq(result["adv_1"]["xp_received"], 100)


func test_xp_all_party_ko_still_get_xp() -> void:
	var party := _make_party(2)
	var ko_list := ["adv_0", "adv_1"]
	var result = processor.distribute_xp(200, party, ko_list)
	# Both at 0.5 weight, total=1.0, each gets 200/1.0*0.5=100
	assert_eq(result["adv_0"]["xp_received"], 100)
	assert_eq(result["adv_1"]["xp_received"], 100)


func test_xp_single_adventurer_gets_full() -> void:
	var party := _make_party(1)
	var result = processor.distribute_xp(500, party, [])
	assert_eq(result["adv_0"]["xp_received"], 500)


func test_xp_level_up_detection() -> void:
	var adv := _make_adventurer("hero", Enums.AdventurerClass.WARRIOR, 1)
	adv.xp = 0
	var xp_needed := adv.xp_to_next_level()
	var result = processor.distribute_xp(xp_needed + 10, [adv], [])
	assert_true(result["hero"]["leveled_up"], "Should detect level-up")
	assert_eq(result["hero"]["old_level"], 1)
	assert_eq(result["hero"]["new_level"], 2)


func test_xp_no_level_up_when_insufficient() -> void:
	var adv := _make_adventurer("hero", Enums.AdventurerClass.WARRIOR, 1)
	var result = processor.distribute_xp(10, [adv], [])
	assert_false(result["hero"]["leveled_up"], "Should not level up with 10 XP")
	assert_eq(result["hero"]["old_level"], 1)
	assert_eq(result["hero"]["new_level"], 1)


func test_xp_multiple_level_ups() -> void:
	var adv := _make_adventurer("hero", Enums.AdventurerClass.WARRIOR, 1)
	# Give enough XP for several level-ups
	var result = processor.distribute_xp(5000, [adv], [])
	assert_true(result["hero"]["leveled_up"], "Should have leveled up")
	assert_true(result["hero"]["new_level"] > 2, "Should have gained multiple levels")


func test_xp_zero_handled_gracefully() -> void:
	var party := _make_party(2)
	var result = processor.distribute_xp(0, party, [])
	assert_eq(result["adv_0"]["xp_received"], 0)
	assert_eq(result["adv_1"]["xp_received"], 0)


func test_xp_negative_rejected() -> void:
	var party := _make_party(2)
	var result = processor.distribute_xp(-100, party, [])
	assert_eq(result["adv_0"]["xp_received"], 0)
	assert_eq(result["adv_1"]["xp_received"], 0)


func test_xp_min_one_per_adventurer() -> void:
	var party := _make_party(3)
	# 3 XP among 3 = 1 each
	var result = processor.distribute_xp(3, party, [])
	assert_true(result["adv_0"]["xp_received"] >= 1, "Min 1 XP")
	assert_true(result["adv_1"]["xp_received"] >= 1, "Min 1 XP")
	assert_true(result["adv_2"]["xp_received"] >= 1, "Min 1 XP")


func test_xp_min_one_for_ko_member() -> void:
	# Very small XP with KO penalty should still yield at least 1
	var party := _make_party(2)
	var ko_list := ["adv_1"]
	var result = processor.distribute_xp(2, party, ko_list)
	assert_true(result["adv_1"]["xp_received"] >= 1, "KO'd member should still get min 1 XP")


func test_xp_empty_party() -> void:
	var result = processor.distribute_xp(100, [], [])
	assert_eq(result.size(), 0)


func test_xp_result_has_all_keys() -> void:
	var party := _make_party(1)
	var result = processor.distribute_xp(50, party, [])
	assert_true(result.has("adv_0"))
	var info: Dictionary = result["adv_0"]
	assert_true(info.has("xp_received"))
	assert_true(info.has("leveled_up"))
	assert_true(info.has("old_level"))
	assert_true(info.has("new_level"))


func test_xp_ko_penalty_constant_is_half() -> void:
	assert_almost_eq(processor.KO_XP_PENALTY, 0.5, 0.001)


func test_xp_large_party_split() -> void:
	var party: Array = []
	for i in range(6):
		party.append(_make_adventurer("adv_%d" % i))
	var result = processor.distribute_xp(600, party, [])
	for i in range(6):
		assert_eq(result["adv_%d" % i]["xp_received"], 100)


# ===========================================================================
# §2 — Currency Credits (~10 tests)
# ===========================================================================

func test_currency_gold_credited() -> void:
	var wallet := _make_wallet()
	var result = processor.credit_currency({Enums.Currency.GOLD: 100}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 100)
	assert_eq(result[Enums.Currency.GOLD], 100)


func test_currency_essence_credited() -> void:
	var wallet := _make_wallet()
	var result = processor.credit_currency({Enums.Currency.ESSENCE: 50}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.ESSENCE), 50)
	assert_eq(result[Enums.Currency.ESSENCE], 50)


func test_currency_multiple_types() -> void:
	var wallet := _make_wallet()
	var currencies := {
		Enums.Currency.GOLD: 100,
		Enums.Currency.ESSENCE: 20,
		Enums.Currency.FRAGMENTS: 5,
	}
	var result = processor.credit_currency(currencies, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 100)
	assert_eq(wallet.get_balance(Enums.Currency.ESSENCE), 20)
	assert_eq(wallet.get_balance(Enums.Currency.FRAGMENTS), 5)
	assert_eq(result.size(), 3)


func test_currency_zero_amount_skipped() -> void:
	var wallet := _make_wallet()
	var result = processor.credit_currency({Enums.Currency.GOLD: 0}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 0)
	assert_eq(result.size(), 0)


func test_currency_empty_dict() -> void:
	var wallet := _make_wallet()
	var result = processor.credit_currency({}, wallet)
	assert_eq(result.size(), 0)
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 0)


func test_currency_negative_skipped() -> void:
	var wallet := _make_wallet()
	var result = processor.credit_currency({Enums.Currency.GOLD: -10}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 0)
	assert_eq(result.size(), 0)


func test_currency_null_wallet_returns_empty() -> void:
	var result = processor.credit_currency({Enums.Currency.GOLD: 100}, null)
	assert_eq(result.size(), 0)


func test_currency_accumulates_on_existing() -> void:
	var wallet := _make_wallet()
	wallet.credit(Enums.Currency.GOLD, 50)
	processor.credit_currency({Enums.Currency.GOLD: 100}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 150)


func test_currency_fragments_credited() -> void:
	var wallet := _make_wallet()
	processor.credit_currency({Enums.Currency.FRAGMENTS: 7}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.FRAGMENTS), 7)


func test_currency_artifacts_credited() -> void:
	var wallet := _make_wallet()
	processor.credit_currency({Enums.Currency.ARTIFACTS: 2}, wallet)
	assert_eq(wallet.get_balance(Enums.Currency.ARTIFACTS), 2)


# ===========================================================================
# §3 — Loot Distribution (~10 tests)
# ===========================================================================

func test_loot_item_added_to_inventory() -> void:
	var inv := _make_inventory()
	var loot := [{"item_id": "wooden_sword", "qty": 1}]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(inv.get_quantity("wooden_sword"), 1)
	assert_eq(result.size(), 1)


func test_loot_multiple_items() -> void:
	var inv := _make_inventory()
	var loot := [
		{"item_id": "wooden_sword", "qty": 1},
		{"item_id": "cloth_tunic", "qty": 2},
	]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(inv.get_quantity("wooden_sword"), 1)
	assert_eq(inv.get_quantity("cloth_tunic"), 2)
	assert_eq(result.size(), 2)


func test_loot_empty_array() -> void:
	var inv := _make_inventory()
	var result = processor.distribute_loot([], inv)
	assert_eq(result.size(), 0)
	assert_eq(inv.get_total_item_count(), 0)


func test_loot_quantities_preserved() -> void:
	var inv := _make_inventory()
	var loot := [{"item_id": "copper_ring", "qty": 5}]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(inv.get_quantity("copper_ring"), 5)
	assert_eq(result[0]["qty"], 5)


func test_loot_duplicate_items_stack() -> void:
	var inv := _make_inventory()
	var loot := [
		{"item_id": "wooden_sword", "qty": 2},
		{"item_id": "wooden_sword", "qty": 3},
	]
	processor.distribute_loot(loot, inv)
	assert_eq(inv.get_quantity("wooden_sword"), 5)


func test_loot_null_inventory_returns_empty() -> void:
	var result = processor.distribute_loot([{"item_id": "x", "qty": 1}], null)
	assert_eq(result.size(), 0)


func test_loot_zero_qty_skipped() -> void:
	var inv := _make_inventory()
	var loot := [{"item_id": "wooden_sword", "qty": 0}]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(result.size(), 0)
	assert_eq(inv.get_total_item_count(), 0)


func test_loot_missing_item_id_skipped() -> void:
	var inv := _make_inventory()
	var loot := [{"qty": 1}]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(result.size(), 0)


func test_loot_empty_item_id_skipped() -> void:
	var inv := _make_inventory()
	var loot := [{"item_id": "", "qty": 1}]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(result.size(), 0)


func test_loot_result_contains_item_info() -> void:
	var inv := _make_inventory()
	var loot := [{"item_id": "iron_sword", "qty": 2}]
	var result = processor.distribute_loot(loot, inv)
	assert_eq(result[0]["item_id"], "iron_sword")
	assert_eq(result[0]["qty"], 2)


# ===========================================================================
# §4 — Condition Updates (~15 tests)
# ===========================================================================

func test_condition_completed_all_fatigued() -> void:
	var party := _make_party(3)
	var hp_dict := {"adv_0": 100, "adv_1": 80, "adv_2": 60}
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": hp_dict,
		"adventurers_ko": [],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "fatigued")
	assert_eq(conditions["adv_1"], "fatigued")
	assert_eq(conditions["adv_2"], "fatigued")


func test_condition_completed_adventurers_unavailable() -> void:
	var party := _make_party(2)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": {"adv_0": 50, "adv_1": 50},
	})
	processor.update_conditions(party, result_data)
	assert_false(party[0].is_available)
	assert_false(party[1].is_available)


func test_condition_failed_ko_injured() -> void:
	var party := _make_party(2)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"party_hp": {"adv_0": 50, "adv_1": 0},
		"adventurers_ko": ["adv_1"],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_1"], "injured")


func test_condition_failed_survivor_fatigued() -> void:
	var party := _make_party(2)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"party_hp": {"adv_0": 80, "adv_1": 0},
		"adventurers_ko": ["adv_1"],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "fatigued")


func test_condition_low_hp_exhausted() -> void:
	var party := _make_party(1)
	# Warrior health = 120, 25% = 30. Set HP to 20 (below threshold)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": {"adv_0": 20},
		"adventurers_ko": [],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "exhausted")


func test_condition_at_exactly_25_percent_not_exhausted() -> void:
	var party := _make_party(1)
	# Warrior health = 120, 25% = 30. At exactly 30 -> ratio = 0.25, not < 0.25
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": {"adv_0": 30},
		"adventurers_ko": [],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "fatigued")


func test_condition_full_hp_after_completion_is_fatigued() -> void:
	var party := _make_party(1)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": {"adv_0": 120},
		"adventurers_ko": [],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "fatigued")


func test_condition_ko_plus_low_hp_is_injured() -> void:
	var party := _make_party(1)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"party_hp": {"adv_0": 0},
		"adventurers_ko": ["adv_0"],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "injured")


func test_condition_injured_sets_unavailable() -> void:
	var party := _make_party(1)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"party_hp": {"adv_0": 0},
		"adventurers_ko": ["adv_0"],
	})
	processor.update_conditions(party, result_data)
	assert_false(party[0].is_available)


func test_condition_exhausted_sets_unavailable() -> void:
	var party := _make_party(1)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": {"adv_0": 10},
		"adventurers_ko": [],
	})
	processor.update_conditions(party, result_data)
	assert_false(party[0].is_available)


func test_condition_multiple_adventurers_mixed() -> void:
	var party := _make_party(3)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"party_hp": {"adv_0": 80, "adv_1": 0, "adv_2": 10},
		"adventurers_ko": ["adv_1"],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "fatigued")
	assert_eq(conditions["adv_1"], "injured")
	assert_eq(conditions["adv_2"], "exhausted")


func test_condition_empty_party() -> void:
	var result_data := _make_expedition_result()
	var conditions = processor.update_conditions([], result_data)
	assert_eq(conditions.size(), 0)


func test_condition_missing_hp_defaults_to_max() -> void:
	var party := _make_party(1)
	# No party_hp entry for adv_0 — should default to max HP, so fatigued
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"party_hp": {},
		"adventurers_ko": [],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "fatigued")


func test_condition_all_ko_in_failed() -> void:
	var party := _make_party(2)
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"party_hp": {"adv_0": 0, "adv_1": 0},
		"adventurers_ko": ["adv_0", "adv_1"],
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_eq(conditions["adv_0"], "injured")
	assert_eq(conditions["adv_1"], "injured")


func test_condition_returns_dict_with_all_party_ids() -> void:
	var party := _make_party(3)
	var result_data := _make_expedition_result({
		"party_hp": {"adv_0": 100, "adv_1": 100, "adv_2": 100},
	})
	var conditions = processor.update_conditions(party, result_data)
	assert_true(conditions.has("adv_0"))
	assert_true(conditions.has("adv_1"))
	assert_true(conditions.has("adv_2"))


# ===========================================================================
# §5 — Completion Bonus (~10 tests)
# ===========================================================================

func test_bonus_full_clear_xp() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 5,
		"total_rooms": 5,
		"xp_earned": 400,
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_xp"], 100)  # 400 * 0.25


func test_bonus_full_clear_gold() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 5,
		"total_rooms": 5,
		"currency": {Enums.Currency.GOLD: 200},
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_currency"][Enums.Currency.GOLD], 100)  # 200 * 0.50


func test_bonus_partial_clear_no_bonus() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 3,
		"total_rooms": 5,
		"xp_earned": 400,
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_xp"], 0)
	assert_eq(bonus["bonus_currency"].size(), 0)


func test_bonus_zero_total_rooms_no_bonus() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 0,
		"total_rooms": 0,
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_xp"], 0)


func test_bonus_empty_result_no_bonus() -> void:
	var bonus = processor.calculate_completion_bonus({})
	assert_eq(bonus["bonus_xp"], 0)
	assert_eq(bonus["bonus_currency"].size(), 0)


func test_bonus_xp_percentage_correct() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 10,
		"total_rooms": 10,
		"xp_earned": 1000,
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_xp"], 250)  # 1000 * 0.25


func test_bonus_gold_percentage_correct() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 10,
		"total_rooms": 10,
		"currency": {Enums.Currency.GOLD: 500},
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_currency"][Enums.Currency.GOLD], 250)  # 500 * 0.50


func test_bonus_no_gold_in_currency_no_gold_bonus() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 5,
		"total_rooms": 5,
		"currency": {Enums.Currency.ESSENCE: 50},
		"xp_earned": 200,
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_xp"], 50)  # 200 * 0.25
	assert_false(bonus["bonus_currency"].has(Enums.Currency.GOLD))


func test_bonus_constants_values() -> void:
	assert_almost_eq(processor.FULL_CLEAR_XP_BONUS, 0.25, 0.001)
	assert_almost_eq(processor.FULL_CLEAR_GOLD_BONUS, 0.50, 0.001)


func test_bonus_zero_xp_full_clear() -> void:
	var result_data := _make_expedition_result({
		"rooms_cleared": 5,
		"total_rooms": 5,
		"xp_earned": 0,
		"currency": {Enums.Currency.GOLD: 100},
	})
	var bonus = processor.calculate_completion_bonus(result_data)
	assert_eq(bonus["bonus_xp"], 0)
	assert_eq(bonus["bonus_currency"][Enums.Currency.GOLD], 50)


# ===========================================================================
# §6 — Full Process (~10 tests)
# ===========================================================================

func test_process_returns_all_required_keys() -> void:
	var party := _make_party(2)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"party_hp": {"adv_0": 100, "adv_1": 80},
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	assert_true(summary.has("xp_per_adventurer"))
	assert_true(summary.has("level_ups"))
	assert_true(summary.has("currency_earned"))
	assert_true(summary.has("items_received"))
	assert_true(summary.has("adventurer_conditions"))
	assert_true(summary.has("completion_bonus"))


func test_process_successful_expedition() -> void:
	var party := _make_party(2)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"party_hp": {"adv_0": 100, "adv_1": 80},
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	# XP distributed
	assert_true(summary["xp_per_adventurer"].has("adv_0"))
	assert_true(summary["xp_per_adventurer"]["adv_0"] > 0)
	# Currency credited (base gold 100 + 50% bonus = 150)
	assert_true(wallet.get_balance(Enums.Currency.GOLD) > 0)
	# Loot added
	assert_eq(inv.get_quantity("wooden_sword"), 1)
	# Conditions set
	assert_eq(summary["adventurer_conditions"]["adv_0"], "fatigued")


func test_process_failed_expedition() -> void:
	var party := _make_party(2)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.FAILED,
		"rooms_cleared": 3,
		"total_rooms": 5,
		"party_hp": {"adv_0": 60, "adv_1": 0},
		"adventurers_ko": ["adv_1"],
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	assert_eq(summary["adventurer_conditions"]["adv_1"], "injured")
	assert_eq(summary["adventurer_conditions"]["adv_0"], "fatigued")
	# No completion bonus for partial clear
	assert_eq(summary["completion_bonus"]["bonus_xp"], 0)


func test_process_empty_result() -> void:
	var party := _make_party(2)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var summary = processor.process_rewards({}, party, wallet, inv)
	assert_eq(summary["xp_per_adventurer"].size(), 0)
	assert_eq(summary["currency_earned"].size(), 0)
	assert_eq(summary["items_received"].size(), 0)


func test_process_deterministic_results() -> void:
	# Run the same expedition twice with identical inputs, results should match
	var make_run := func() -> Dictionary:
		var p := [_make_adventurer("a", Enums.AdventurerClass.WARRIOR, 1),
				  _make_adventurer("b", Enums.AdventurerClass.MAGE, 1)]
		var w := _make_wallet()
		var i := _make_inventory()
		var r := _make_expedition_result({
			"party_hp": {"a": 80, "b": 50},
			"xp_earned": 200,
			"currency": {Enums.Currency.GOLD: 100},
			"loot": [{"item_id": "wooden_sword", "qty": 1}],
		})
		return processor.process_rewards(r, p, w, i)

	var run1: Dictionary = make_run.call()
	var run2: Dictionary = make_run.call()
	assert_eq(run1["xp_per_adventurer"]["a"], run2["xp_per_adventurer"]["a"])
	assert_eq(run1["xp_per_adventurer"]["b"], run2["xp_per_adventurer"]["b"])


func test_process_with_completion_bonus_applied() -> void:
	var party := _make_party(1)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"rooms_cleared": 5,
		"total_rooms": 5,
		"xp_earned": 400,
		"currency": {Enums.Currency.GOLD: 200},
		"party_hp": {"adv_0": 100},
		"loot": [],
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	# Base gold 200 + 50% bonus = 300
	assert_eq(wallet.get_balance(Enums.Currency.GOLD), 300)
	# Base XP 400 + 25% bonus = 500 for single adventurer
	assert_eq(summary["xp_per_adventurer"]["adv_0"], 500)


func test_process_no_loot_handled() -> void:
	var party := _make_party(1)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"loot": [],
		"party_hp": {"adv_0": 100},
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	assert_eq(summary["items_received"].size(), 0)


func test_process_no_currency_handled() -> void:
	var party := _make_party(1)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"currency": {},
		"party_hp": {"adv_0": 100},
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	assert_eq(summary["currency_earned"].size(), 0)


func test_process_level_ups_tracked() -> void:
	var adv := _make_adventurer("hero", Enums.AdventurerClass.WARRIOR, 1)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var xp_needed := adv.xp_to_next_level()
	var result_data := _make_expedition_result({
		"xp_earned": xp_needed + 50,
		"party_hp": {"hero": 100},
		"loot": [],
		"currency": {},
		"rooms_cleared": 3,
		"total_rooms": 5,
		"adventurers_ko": [],
	})
	var summary = processor.process_rewards(result_data, [adv], wallet, inv)
	assert_true(summary["level_ups"].has("hero"), "Should track level-up")
	assert_eq(summary["level_ups"]["hero"]["old_level"], 1)
	assert_eq(summary["level_ups"]["hero"]["new_level"], 2)


func test_process_exhausted_with_full_clear() -> void:
	var party := _make_party(1)
	var wallet := _make_wallet()
	var inv := _make_inventory()
	var result_data := _make_expedition_result({
		"status": Enums.ExpeditionStatus.COMPLETED,
		"rooms_cleared": 5,
		"total_rooms": 5,
		"party_hp": {"adv_0": 5},
		"adventurers_ko": [],
		"loot": [],
		"currency": {Enums.Currency.GOLD: 100},
		"xp_earned": 200,
	})
	var summary = processor.process_rewards(result_data, party, wallet, inv)
	assert_eq(summary["adventurer_conditions"]["adv_0"], "exhausted")
	assert_false(party[0].is_available)
