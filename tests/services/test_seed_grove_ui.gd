extends GutTest
## Tests for SeedGroveUI — garden hub display controller (TASK-018).
##
## 6 test sections with 45 tests covering:
##   §1: Initialization (5 tests)
##   §2: Slot Display Data (13 tests)
##   §3: Slot Actions (8 tests)
##   §4: Timer Formatting (9 tests)
##   §5: Resource Display (5 tests)
##   §6: Full Refresh (5 tests)

const SeedGroveUIClass = preload("res://src/ui/seed_grove_ui.gd")
const SeedDataClass = preload("res://src/models/seed_data.gd")
const MutationSlotClass = preload("res://src/models/mutation_slot.gd")


# ---------------------------------------------------------------------------
# Mock Classes
# ---------------------------------------------------------------------------

## Lightweight mock for SeedGrove — only implements what the UI needs.
class MockGrove extends RefCounted:
	var max_grove_slots: int = 3
	var _planted_seeds: Array = []

	func get_planted_seeds() -> Array:
		return _planted_seeds


## Lightweight mock for Wallet — only implements what the UI needs.
class MockWallet extends RefCounted:
	var _balances: Dictionary = {}

	func get_balance(currency) -> int:
		return _balances.get(currency, 0)

	func set_balance(currency, amount: int) -> void:
		_balances[currency] = amount


# ---------------------------------------------------------------------------
# Test State
# ---------------------------------------------------------------------------

var ui
var grove: MockGrove
var wallet: MockWallet
var _seed_counter: int = 0


func before_each() -> void:
	ui = SeedGroveUIClass.new()
	grove = MockGrove.new()
	wallet = MockWallet.new()
	_seed_counter = 0


func after_each() -> void:
	if is_instance_valid(ui):
		ui.free()


# ---------------------------------------------------------------------------
# Test Helpers
# ---------------------------------------------------------------------------

## Creates a SeedData with controlled properties for testing.
func _make_seed(p_element: int = 0, p_rarity: int = 0, p_phase: int = 0, p_potential: float = 0.1) -> RefCounted:
	var seed = SeedDataClass.new()
	seed.id = "test_seed_%d" % _seed_counter
	seed.element = p_element as Enums.Element
	seed.rarity = p_rarity as Enums.SeedRarity
	seed.phase = p_phase as Enums.SeedPhase
	seed.growth_progress = 0.0
	seed.growth_rate = 60.0
	seed.mutation_potential = p_potential
	seed.mutation_slots.clear()
	seed.is_planted = true
	seed.planted_at = 1000.0
	seed.dungeon_traits = {
		"room_variety": 0.3,
		"hazard_frequency": 0.2,
		"loot_bias": "gold",
	}
	_seed_counter += 1
	return seed


## Creates a seed and adds it to the mock grove's planted list.
func _plant_seed(p_element: int = 0, p_rarity: int = 0, p_phase: int = 0, p_potential: float = 0.1) -> RefCounted:
	var seed = _make_seed(p_element, p_rarity, p_phase, p_potential)
	grove._planted_seeds.append(seed)
	return seed


## Adds a filled mutation slot to a seed.
func _add_mutation(seed, reagent_id: String) -> void:
	var slot = MutationSlotClass.new()
	slot.slot_index = seed.mutation_slots.size()
	slot.reagent_id = reagent_id
	seed.mutation_slots.append(slot)


## Adds an empty mutation slot to a seed.
func _add_empty_slot(seed) -> void:
	var slot = MutationSlotClass.new()
	slot.slot_index = seed.mutation_slots.size()
	seed.mutation_slots.append(slot)


# ===========================================================================
# §1 — Initialization (~5 tests)
# ===========================================================================

func test_init_enables_refresh_with_slots() -> void:
	ui.initialize(grove, wallet)
	var result = ui.refresh()
	assert_eq(result["slots"].size(), 3, "Should return max_grove_slots entries")


func test_refresh_before_init_returns_empty_slots() -> void:
	var result = ui.refresh()
	assert_eq(result["slots"].size(), 0, "Uninitialized UI returns no slots")


func test_refresh_before_init_returns_zero_wallet() -> void:
	var result = ui.refresh()
	assert_eq(result["wallet"]["gold"], 0)
	assert_eq(result["wallet"]["verdant_essence"], 0)
	assert_eq(result["wallet"]["materials"], 0)
	assert_eq(result["wallet"]["guild_favor"], 0)


func test_get_slot_action_before_init_returns_empty() -> void:
	var result = ui.get_slot_action(0)
	assert_eq(result, "empty", "Uninitialized UI returns 'empty' action")


func test_get_slot_display_before_init_returns_unoccupied() -> void:
	var result = ui.get_slot_display(0)
	assert_eq(result["occupied"], false, "Uninitialized UI returns unoccupied slot")


# ===========================================================================
# §2 — Slot Display Data (~13 tests)
# ===========================================================================

func test_slot_display_empty_slot_not_occupied() -> void:
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["occupied"], false)
	assert_eq(result["seed_species"], "")
	assert_eq(result["is_ready"], false)


func test_slot_display_empty_slot_has_correct_index() -> void:
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(2)
	assert_eq(result["index"], 2)


func test_slot_display_occupied_spore() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.SPORE))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["occupied"], true)
	assert_eq(result["growth_stage"], int(Enums.SeedPhase.SPORE))


func test_slot_display_occupied_sprout() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.SPROUT))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["growth_stage"], int(Enums.SeedPhase.SPROUT))


func test_slot_display_occupied_bud() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BUD))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["growth_stage"], int(Enums.SeedPhase.BUD))


func test_slot_display_occupied_bloom() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BLOOM))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["growth_stage"], int(Enums.SeedPhase.BLOOM))


func test_slot_display_bloom_is_ready_true() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BLOOM))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["is_ready"], true)


func test_slot_display_non_bloom_not_ready() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BUD))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["is_ready"], false)


func test_slot_display_species_terra() -> void:
	_plant_seed(int(Enums.Element.TERRA))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["seed_species"], "Terra Seed")


func test_slot_display_species_flame() -> void:
	_plant_seed(int(Enums.Element.FLAME))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["seed_species"], "Flame Seed")


func test_slot_display_vigor_from_mutation_potential() -> void:
	_plant_seed(0, 0, 0, 0.65)
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["vigor"], 65)


func test_slot_display_mutations_lists_filled_only() -> void:
	var seed = _plant_seed()
	_add_mutation(seed, "fire_reagent")
	_add_empty_slot(seed)
	_add_mutation(seed, "ice_reagent")
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["mutations"].size(), 2)
	assert_eq(result["mutations"][0], "fire_reagent")
	assert_eq(result["mutations"][1], "ice_reagent")


func test_slot_display_progress_zero_for_new_spore() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.SPORE))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["growth_progress"], 0.0)


func test_slot_display_progress_one_for_bloom() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BLOOM))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["growth_progress"], 1.0)


func test_slot_display_element_matches_enum() -> void:
	_plant_seed(int(Enums.Element.FROST))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["element"], int(Enums.Element.FROST))


func test_slot_display_rarity_matches_enum() -> void:
	_plant_seed(0, int(Enums.SeedRarity.EPIC))
	ui.initialize(grove, wallet)
	var result = ui.get_slot_display(0)
	assert_eq(result["rarity"], int(Enums.SeedRarity.EPIC))


# ===========================================================================
# §3 — Slot Actions (~8 tests)
# ===========================================================================

func test_action_empty_valid_slot_returns_plant() -> void:
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(0), "plant")


func test_action_spore_returns_inspect() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.SPORE))
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(0), "inspect")


func test_action_sprout_returns_inspect() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.SPROUT))
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(0), "inspect")


func test_action_bud_returns_inspect() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BUD))
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(0), "inspect")


func test_action_bloom_returns_harvest() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.BLOOM))
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(0), "harvest")


func test_action_negative_slot_returns_empty() -> void:
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(-1), "empty")


func test_action_beyond_max_slots_returns_empty() -> void:
	ui.initialize(grove, wallet)
	assert_eq(ui.get_slot_action(10), "empty")


func test_action_at_max_boundary_returns_empty() -> void:
	ui.initialize(grove, wallet)
	# max_grove_slots = 3, so slot index 3 is out of range (0-based)
	assert_eq(ui.get_slot_action(3), "empty")


# ===========================================================================
# §4 — Timer Formatting (~9 tests)
# ===========================================================================

func test_timer_hours_and_minutes() -> void:
	# 2h 15m = 8100s
	assert_eq(ui.format_timer(8100.0), "2h 15m")


func test_timer_minutes_and_seconds() -> void:
	# 45m 30s = 2730s
	assert_eq(ui.format_timer(2730.0), "45m 30s")


func test_timer_seconds_only() -> void:
	assert_eq(ui.format_timer(30.0), "30s")


func test_timer_zero_returns_ready() -> void:
	assert_eq(ui.format_timer(0.0), "Ready!")


func test_timer_negative_returns_ready() -> void:
	assert_eq(ui.format_timer(-5.0), "Ready!")


func test_timer_exactly_one_hour() -> void:
	assert_eq(ui.format_timer(3600.0), "1h 0m")


func test_timer_exactly_one_minute() -> void:
	assert_eq(ui.format_timer(60.0), "1m 0s")


func test_timer_large_value_24h() -> void:
	assert_eq(ui.format_timer(86400.0), "24h 0m")


func test_timer_fractional_rounds_up() -> void:
	# 59.1s rounds up to 60s = 1m 0s
	assert_eq(ui.format_timer(59.1), "1m 0s")


# ===========================================================================
# §5 — Resource Display (~5 tests)
# ===========================================================================

func test_resource_gold_format() -> void:
	assert_eq(ui.format_resource(int(Enums.Currency.GOLD), 1500), "1,500 Gold")


func test_resource_essence_format() -> void:
	assert_eq(ui.format_resource(int(Enums.Currency.ESSENCE), 340), "340 Verdant Essence")


func test_resource_zero_amount() -> void:
	assert_eq(ui.format_resource(int(Enums.Currency.GOLD), 0), "0 Gold")


func test_resource_large_number_with_commas() -> void:
	assert_eq(ui.format_resource(int(Enums.Currency.GOLD), 1000000), "1,000,000 Gold")


func test_resource_unknown_currency_fallback() -> void:
	assert_eq(ui.format_resource(99, 100), "100 Unknown")


# ===========================================================================
# §6 — Full Refresh (~5 tests)
# ===========================================================================

func test_refresh_slot_count_matches_max_grove_slots() -> void:
	_plant_seed(0, 0, int(Enums.SeedPhase.SPROUT))
	_plant_seed(int(Enums.Element.FLAME), 0, int(Enums.SeedPhase.BUD))
	ui.initialize(grove, wallet)
	var result = ui.refresh()
	# 3 max slots, 2 planted + 1 empty = 3 total
	assert_eq(result["slots"].size(), 3)


func test_refresh_occupied_and_empty_slots() -> void:
	_plant_seed()
	_plant_seed()
	ui.initialize(grove, wallet)
	var result = ui.refresh()
	assert_eq(result["slots"][0]["occupied"], true)
	assert_eq(result["slots"][1]["occupied"], true)
	assert_eq(result["slots"][2]["occupied"], false)


func test_refresh_no_planted_seeds_all_empty() -> void:
	ui.initialize(grove, wallet)
	var result = ui.refresh()
	assert_eq(result["slots"].size(), 3)
	assert_eq(result["slots"][0]["occupied"], false)
	assert_eq(result["slots"][1]["occupied"], false)
	assert_eq(result["slots"][2]["occupied"], false)


func test_refresh_wallet_balances_populated() -> void:
	wallet.set_balance(Enums.Currency.GOLD, 1500)
	wallet.set_balance(Enums.Currency.ESSENCE, 340)
	wallet.set_balance(Enums.Currency.FRAGMENTS, 50)
	wallet.set_balance(Enums.Currency.ARTIFACTS, 5)
	ui.initialize(grove, wallet)
	var result = ui.refresh()
	assert_eq(result["wallet"]["gold"], 1500)
	assert_eq(result["wallet"]["verdant_essence"], 340)
	assert_eq(result["wallet"]["materials"], 50)
	assert_eq(result["wallet"]["guild_favor"], 5)


func test_refresh_wallet_default_zero_balances() -> void:
	ui.initialize(grove, wallet)
	var result = ui.refresh()
	assert_eq(result["wallet"]["gold"], 0)
	assert_eq(result["wallet"]["verdant_essence"], 0)
	assert_eq(result["wallet"]["materials"], 0)
	assert_eq(result["wallet"]["guild_favor"], 0)
