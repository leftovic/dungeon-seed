extends GutTest
## Tests for CoreLoop — the Cultivation Cycle orchestrator.
##
## Covers: initialization, idle tick processing, seed planting,
## expedition launch, state summary, and edge cases.
## Uses mock services for isolation. Real SeedData/AdventurerData for fidelity.
##
## @file tests/services/test_core_loop.gd
## @task TASK-017

const CoreLoopScript := preload("res://src/services/core_loop.gd")
const AdventurerRosterScript := preload("res://src/services/adventurer_roster.gd")


# ===========================================================================
# Mock Services
# ===========================================================================

class MockSeedGrove:
	extends RefCounted
	## Lightweight mock of SeedGrove (src/managers/seed_grove.gd).
	## Mimics the real API: add_seed, plant_seed, tick, get_planted_seeds,
	## remove_seed, get_available_slots, max_grove_slots.

	var seeds: Array = []
	var max_grove_slots: int = 5
	var plant_calls: int = 0
	var remove_calls: Array = []
	var tick_call_count: int = 0

	func add_seed(seed_data) -> void:
		seeds.append(seed_data)

	func plant_seed(seed_data) -> bool:
		plant_calls += 1
		if seed_data == null:
			return false
		if seed_data.is_planted:
			return false
		if not seeds.has(seed_data):
			return false
		if get_available_slots() <= 0:
			return false
		seed_data.plant(1.0)
		seed_data.phase = Enums.SeedPhase.SPORE
		seed_data.growth_progress = 0.0
		return true

	func get_planted_seeds() -> Array:
		var result: Array = []
		for s in seeds:
			if s.is_planted:
				result.append(s)
		return result

	func get_seed_by_id(seed_id: String):
		for s in seeds:
			if s.id == seed_id:
				return s
		return null

	func remove_seed(seed_id: String):
		remove_calls.append(seed_id)
		for i in range(seeds.size()):
			if seeds[i].id == seed_id:
				var removed = seeds[i]
				seeds.remove_at(i)
				return removed
		return null

	func get_available_slots() -> int:
		return max_grove_slots - get_planted_seeds().size()

	func tick(delta: float) -> Array:
		tick_call_count += 1
		var events: Array = []
		for seed_data in get_planted_seeds():
			if seed_data.phase == Enums.SeedPhase.BLOOM:
				continue
			var old_phase = seed_data.phase
			seed_data.advance_growth(delta)
			var new_phase = seed_data.phase
			if int(old_phase) != int(new_phase):
				events.append({
					"seed_id": seed_data.id,
					"event": "phase_changed",
					"data": {"old_phase": int(old_phase), "new_phase": int(new_phase)}
				})
				if new_phase == Enums.SeedPhase.BLOOM:
					events.append({
						"seed_id": seed_data.id,
						"event": "bloom_reached",
						"data": {}
					})
		return events


class MockDungeonGenerator:
	extends RefCounted
	var generate_calls: int = 0
	var _mock_dungeon = null

	func generate(seed_data):
		generate_calls += 1
		if _mock_dungeon != null:
			return _mock_dungeon
		return _make_default_dungeon()

	func _make_default_dungeon():
		var d := DungeonData.new()
		d.seed_id = "test"
		var entrance := RoomData.new()
		entrance.index = 0
		entrance.type = Enums.RoomType.ENTRANCE
		var combat := RoomData.new()
		combat.index = 1
		combat.type = Enums.RoomType.COMBAT
		combat.difficulty = 1
		var boss := RoomData.new()
		boss.index = 2
		boss.type = Enums.RoomType.BOSS
		boss.difficulty = 2
		d.rooms = [entrance, combat, boss]
		d.edges = [Vector2i(0, 1), Vector2i(1, 2)]
		d.entry_room_index = 0
		d.boss_room_index = 2
		d.difficulty = 1
		return d


class MockExpeditionRunner:
	extends RefCounted
	var run_calls: int = 0
	var _mock_result: Dictionary = {}
	var last_party: Array = []

	func run_expedition(dungeon, party, rng, loot_engine) -> Dictionary:
		run_calls += 1
		last_party = party
		if not _mock_result.is_empty():
			return _mock_result
		var hp_dict: Dictionary = {}
		for adv in party:
			hp_dict[adv.id] = adv.stats.get("health", 100)
		return {
			"status": Enums.ExpeditionStatus.COMPLETED,
			"rooms_cleared": 3,
			"total_rooms": 3,
			"loot": [{"item_id": "herb", "qty": 2}],
			"currency": {Enums.Currency.GOLD: 50, Enums.Currency.ESSENCE: 5},
			"xp_earned": 100,
			"combat_log": [],
			"party_hp": hp_dict,
			"adventurers_ko": [],
		}


class MockRewardProcessor:
	extends RefCounted
	var process_calls: int = 0
	var _mock_summary: Dictionary = {}

	func process_rewards(exp_result, party, wallet, inventory) -> Dictionary:
		process_calls += 1
		if not _mock_summary.is_empty():
			return _mock_summary
		var conditions: Dictionary = {}
		for adv in party:
			conditions[adv.id] = "fatigued"
			adv.is_available = false
		return {
			"xp_per_adventurer": {},
			"level_ups": {},
			"currency_earned": {},
			"items_received": [],
			"adventurer_conditions": conditions,
			"completion_bonus": {"bonus_xp": 0, "bonus_currency": {}},
		}


class MockSaveService:
	extends RefCounted
	var save_called: bool = false
	var save_count: int = 0
	var last_slot: int = -1
	var last_state: Dictionary = {}

	func save_game(slot: int, state: Dictionary) -> bool:
		save_called = true
		save_count += 1
		last_slot = slot
		last_state = state
		return true


# ===========================================================================
# Test Fixtures
# ===========================================================================

var loop: RefCounted
var grove: MockSeedGrove
var dgen: MockDungeonGenerator
var runner: MockExpeditionRunner
var rewards: MockRewardProcessor
var roster: RefCounted
var wallet: Wallet
var inventory: InventoryData
var save_svc: MockSaveService
var rng_inst: DeterministicRNG


func before_each() -> void:
	loop = CoreLoopScript.new()
	grove = MockSeedGrove.new()
	dgen = MockDungeonGenerator.new()
	runner = MockExpeditionRunner.new()
	rewards = MockRewardProcessor.new()
	roster = AdventurerRosterScript.new()
	wallet = Wallet.new()
	inventory = InventoryData.new()
	save_svc = MockSaveService.new()
	rng_inst = DeterministicRNG.new()
	rng_inst.seed_string("test_core_loop")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _init_loop() -> void:
	loop.initialize({
		"seed_grove": grove,
		"dungeon_generator": dgen,
		"expedition_runner": runner,
		"reward_processor": rewards,
		"loot_engine": null,
		"adventurer_roster": roster,
		"equipment_manager": null,
		"wallet": wallet,
		"inventory": inventory,
		"save_service": save_svc,
		"rng": rng_inst,
	})


func _make_adventurer(id: String = "adv_1",
		cls: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR) -> AdventurerData:
	var a := AdventurerData.new()
	a.id = id
	a.display_name = "Test %s" % id
	a.adventurer_class = cls
	a.level = 1
	a.xp = 0
	a.initialize_base_stats()
	a.is_available = true
	return a


func _add_adventurer(id: String = "adv_1") -> AdventurerData:
	var a := _make_adventurer(id)
	roster.add_adventurer(a)
	return a


func _make_seed(phase: Enums.SeedPhase = Enums.SeedPhase.SPORE,
		id: String = "seed_1") -> SeedData:
	var s := SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, id)
	s.phase = phase
	return s


## Directly inject a bloom seed into the grove (bypass plant_seed flow).
func _add_bloom_seed(id: String = "bloom_1") -> SeedData:
	var s := SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, id)
	s.phase = Enums.SeedPhase.BLOOM
	s.is_planted = true
	s.planted_at = 1.0
	grove.seeds.append(s)
	return s


## Setup a standard expedition scenario: one bloom seed + one adventurer.
func _setup_expedition(adv_id: String = "adv_1") -> Dictionary:
	_init_loop()
	var seed_data := _add_bloom_seed()
	var adv := _add_adventurer(adv_id)
	return {"seed": seed_data, "adventurer": adv}


# ===========================================================================
# §1 — Initialization & Configuration (~10 tests)
# ===========================================================================

func test_new_loop_is_not_initialized() -> void:
	assert_false(loop._initialized, "New CoreLoop should not be initialized")


func test_initialize_sets_flag() -> void:
	_init_loop()
	assert_true(loop._initialized, "initialize() should set _initialized to true")


func test_initialize_stores_seed_grove() -> void:
	_init_loop()
	assert_eq(loop._seed_grove, grove, "Should store seed_grove dependency")


func test_initialize_stores_all_dependencies() -> void:
	_init_loop()
	assert_eq(loop._dungeon_generator, dgen)
	assert_eq(loop._expedition_runner, runner)
	assert_eq(loop._reward_processor, rewards)
	assert_eq(loop._adventurer_roster, roster)
	assert_eq(loop._wallet, wallet)
	assert_eq(loop._inventory, inventory)
	assert_eq(loop._save_service, save_svc)
	assert_eq(loop._rng, rng_inst)


func test_initialize_with_empty_dict() -> void:
	loop.initialize({})
	assert_true(loop._initialized, "Should be initialized even with empty config")
	assert_null(loop._seed_grove, "Missing keys should default to null")


func test_initialize_can_be_called_twice() -> void:
	_init_loop()
	var new_grove := MockSeedGrove.new()
	loop.initialize({"seed_grove": new_grove})
	assert_eq(loop._seed_grove, new_grove, "Second init should overwrite deps")
	assert_true(loop._initialized)


func test_process_tick_before_init_returns_empty() -> void:
	var result = loop.process_tick(1.0)
	assert_eq(result["seeds_advanced"].size(), 0)
	assert_eq(result["conditions_updated"].size(), 0)


func test_plant_seed_before_init_fails() -> void:
	var seed_data := _make_seed()
	var result = loop.plant_seed(0, seed_data)
	assert_false(result["success"], "Should fail before init")


func test_launch_expedition_before_init_fails() -> void:
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"], "Should fail before init")


func test_get_state_summary_before_init_empty() -> void:
	var summary = loop.get_state_summary()
	assert_eq(summary.size(), 0, "Should return empty dict before init")


# ===========================================================================
# §2 — Idle Tick Processing (~15 tests)
# ===========================================================================

func test_tick_advances_seed_growth() -> void:
	_init_loop()
	var s := _make_seed(Enums.SeedPhase.SPORE, "t1")
	grove.add_seed(s)
	grove.plant_seed(s)
	# SPORE phase duration for COMMON = 60 * 1.0 = 60s. Advance by 30s.
	loop.process_tick(30.0)
	assert_true(s.growth_progress > 0.0, "Seed should have growth progress")


func test_tick_calls_grove_tick() -> void:
	_init_loop()
	loop.process_tick(10.0)
	assert_eq(grove.tick_call_count, 1, "Should call grove.tick() once per process_tick")


func test_tick_returns_seed_events() -> void:
	_init_loop()
	var s := _make_seed(Enums.SeedPhase.SPORE, "t1")
	grove.add_seed(s)
	grove.plant_seed(s)
	# Advance 60s — enough for SPORE→SPROUT (duration = 60 * 1.0)
	var result = loop.process_tick(60.0)
	assert_true(result["seeds_advanced"].size() > 0, "Should return seed events")


func test_tick_detects_phase_transition() -> void:
	_init_loop()
	var s := _make_seed(Enums.SeedPhase.SPORE, "t1")
	grove.add_seed(s)
	grove.plant_seed(s)
	var result = loop.process_tick(60.0)
	var found_phase_change: bool = false
	for event in result["seeds_advanced"]:
		if event.get("event") == "phase_changed":
			found_phase_change = true
	assert_true(found_phase_change, "Should detect SPORE→SPROUT transition")


func test_tick_no_advance_for_bloom() -> void:
	_init_loop()
	var s := _add_bloom_seed("bloom_test")
	var result = loop.process_tick(1000.0)
	assert_eq(result["seeds_advanced"].size(), 0, "Bloom seeds should not advance")
	assert_eq(s.phase, Enums.SeedPhase.BLOOM, "Phase should remain BLOOM")


func test_tick_skips_empty_grove() -> void:
	_init_loop()
	var result = loop.process_tick(60.0)
	assert_eq(result["seeds_advanced"].size(), 0, "Empty grove should produce no events")


func test_tick_multiple_seeds() -> void:
	_init_loop()
	var s1 := _make_seed(Enums.SeedPhase.SPORE, "s1")
	var s2 := _make_seed(Enums.SeedPhase.SPORE, "s2")
	grove.add_seed(s1)
	grove.plant_seed(s1)
	grove.add_seed(s2)
	grove.plant_seed(s2)
	loop.process_tick(30.0)
	assert_true(s1.growth_progress > 0.0, "Seed 1 should advance")
	assert_true(s2.growth_progress > 0.0, "Seed 2 should advance")


func test_tick_zero_delta_no_op() -> void:
	_init_loop()
	var s := _make_seed(Enums.SeedPhase.SPORE, "t1")
	grove.add_seed(s)
	grove.plant_seed(s)
	var result = loop.process_tick(0.0)
	assert_eq(result["seeds_advanced"].size(), 0, "Zero delta should be no-op")
	assert_eq(grove.tick_call_count, 0, "Should not call tick with zero delta")


func test_tick_negative_delta_no_op() -> void:
	_init_loop()
	var result = loop.process_tick(-5.0)
	assert_eq(result["seeds_advanced"].size(), 0, "Negative delta should be no-op")


func test_tick_condition_injured_to_fatigued() -> void:
	_init_loop()
	loop._condition_timers["adv_1"] = {"condition": "injured", "remaining": 100.0}
	var result = loop.process_tick(100.0)
	assert_eq(result["conditions_updated"].size(), 1)
	assert_eq(result["conditions_updated"][0]["old_condition"], "injured")
	assert_eq(result["conditions_updated"][0]["new_condition"], "fatigued")
	assert_eq(loop.get_condition("adv_1"), "fatigued")


func test_tick_condition_fatigued_to_healthy() -> void:
	_init_loop()
	loop._condition_timers["adv_1"] = {"condition": "fatigued", "remaining": 100.0}
	var result = loop.process_tick(100.0)
	assert_eq(result["conditions_updated"].size(), 1)
	assert_eq(result["conditions_updated"][0]["old_condition"], "fatigued")
	assert_eq(result["conditions_updated"][0]["new_condition"], "healthy")
	assert_eq(loop.get_condition("adv_1"), "healthy")


func test_tick_condition_partial_timer() -> void:
	_init_loop()
	loop._condition_timers["adv_1"] = {"condition": "injured", "remaining": 500.0}
	loop.process_tick(200.0)
	assert_eq(loop.get_condition("adv_1"), "injured", "Should still be injured")
	assert_true(loop.get_condition_remaining("adv_1") > 0.0)
	var expected_remaining: float = 300.0
	assert_almost_eq(loop.get_condition_remaining("adv_1"), expected_remaining, 0.01)


func test_tick_condition_recovery_restores_available() -> void:
	_init_loop()
	var adv := _add_adventurer("adv_1")
	adv.is_available = false
	loop._condition_timers["adv_1"] = {"condition": "fatigued", "remaining": 50.0}
	loop.process_tick(50.0)
	assert_true(adv.is_available, "Should restore is_available on recovery")


func test_tick_condition_exhausted_to_fatigued() -> void:
	_init_loop()
	loop._condition_timers["adv_1"] = {"condition": "exhausted", "remaining": 100.0}
	var result = loop.process_tick(100.0)
	assert_eq(result["conditions_updated"][0]["old_condition"], "exhausted")
	assert_eq(result["conditions_updated"][0]["new_condition"], "fatigued")
	assert_eq(loop.get_condition("adv_1"), "fatigued")


func test_tick_multiple_conditions_recover() -> void:
	_init_loop()
	_add_adventurer("adv_1")
	_add_adventurer("adv_2")
	loop._condition_timers["adv_1"] = {"condition": "fatigued", "remaining": 50.0}
	loop._condition_timers["adv_2"] = {"condition": "fatigued", "remaining": 50.0}
	var result = loop.process_tick(50.0)
	assert_eq(result["conditions_updated"].size(), 2, "Both should recover")
	assert_eq(loop.get_condition("adv_1"), "healthy")
	assert_eq(loop.get_condition("adv_2"), "healthy")


func test_tick_large_delta_cascading_recovery() -> void:
	_init_loop()
	var adv := _add_adventurer("adv_1")
	adv.is_available = false
	# Injured with 100s remaining → fatigued (900s) → healthy
	# Total: 100 + 900 = 1000s needed
	loop._condition_timers["adv_1"] = {"condition": "injured", "remaining": 100.0}
	var result = loop.process_tick(1100.0)
	# Should cascade: injured → fatigued → healthy
	assert_eq(result["conditions_updated"].size(), 2)
	assert_eq(result["conditions_updated"][0]["new_condition"], "fatigued")
	assert_eq(result["conditions_updated"][1]["new_condition"], "healthy")
	assert_eq(loop.get_condition("adv_1"), "healthy")
	assert_true(adv.is_available)


# ===========================================================================
# §3 — Seed Planting (~10 tests)
# ===========================================================================

func test_plant_success() -> void:
	_init_loop()
	var s := _make_seed()
	var result = loop.plant_seed(0, s)
	assert_true(result["success"], "Planting in empty grove should succeed")
	assert_eq(grove.plant_calls, 1, "Should call grove.plant_seed()")


func test_plant_null_seed_fails() -> void:
	_init_loop()
	var result = loop.plant_seed(0, null)
	assert_false(result["success"])
	assert_true(result["message"].find("null") >= 0)


func test_plant_negative_slot_fails() -> void:
	_init_loop()
	var s := _make_seed()
	var result = loop.plant_seed(-1, s)
	assert_false(result["success"])


func test_plant_out_of_range_slot_fails() -> void:
	_init_loop()
	var s := _make_seed()
	var result = loop.plant_seed(99, s)
	assert_false(result["success"])


func test_plant_occupied_slot_fails() -> void:
	_init_loop()
	var s1 := _make_seed(Enums.SeedPhase.SPORE, "s1")
	loop.plant_seed(0, s1)
	var s2 := _make_seed(Enums.SeedPhase.SPORE, "s2")
	var result = loop.plant_seed(0, s2)
	assert_false(result["success"], "Slot 0 should be occupied")
	assert_true(result["message"].find("occupied") >= 0)


func test_plant_triggers_auto_save() -> void:
	_init_loop()
	var s := _make_seed()
	loop.plant_seed(0, s)
	assert_true(save_svc.save_called, "Should auto-save after planting")
	assert_eq(save_svc.last_slot, 1, "Should use AUTO_SAVE_SLOT = 1")


func test_plant_returns_success_message() -> void:
	_init_loop()
	var s := _make_seed()
	var result = loop.plant_seed(0, s)
	assert_true(result["success"])
	assert_true(result["message"].length() > 0)


func test_plant_returns_failure_message() -> void:
	_init_loop()
	var result = loop.plant_seed(0, null)
	assert_false(result["success"])
	assert_true(result["message"].length() > 0)


func test_plant_no_grove_fails() -> void:
	loop.initialize({"seed_grove": null})
	var s := _make_seed()
	var result = loop.plant_seed(0, s)
	assert_false(result["success"])
	assert_true(result["message"].find("grove") >= 0)


func test_plant_max_slot_boundary() -> void:
	_init_loop()
	grove.max_grove_slots = 3
	var s := _make_seed(Enums.SeedPhase.SPORE, "edge_seed")
	# Slot 2 is the last valid index (0-based, max=3)
	var result = loop.plant_seed(2, s)
	assert_true(result["success"], "Slot at max-1 should be valid")


# ===========================================================================
# §4 — Expedition Launch (~15 tests)
# ===========================================================================

func test_expedition_full_flow() -> void:
	var data := _setup_expedition("adv_1")
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_true(result["success"], "Full expedition flow should succeed")
	assert_eq(result["message"], "Expedition complete")
	assert_true(result.has("reward_summary"), "Should include reward_summary")
	assert_true(result.has("status"), "Should include expedition status")


func test_expedition_requires_bloom_phase() -> void:
	_init_loop()
	var s := _make_seed(Enums.SeedPhase.SPORE, "spore_seed")
	s.is_planted = true
	s.planted_at = 1.0
	grove.seeds.append(s)
	_add_adventurer("adv_1")
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"])
	assert_true(result["message"].find("BLOOM") >= 0)


func test_expedition_empty_slot_fails() -> void:
	_init_loop()
	_add_adventurer("adv_1")
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"], "No seed in slot should fail")


func test_expedition_bud_seed_fails() -> void:
	_init_loop()
	var s := _make_seed(Enums.SeedPhase.SPORE, "bud_seed")
	s.phase = Enums.SeedPhase.BUD
	s.is_planted = true
	s.planted_at = 1.0
	grove.seeds.append(s)
	_add_adventurer("adv_1")
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"], "BUD seed should not be launchable")


func test_expedition_empty_party_fails() -> void:
	_init_loop()
	_add_bloom_seed()
	var result = loop.launch_expedition(0, [])
	assert_false(result["success"])
	assert_true(result["message"].find("empty") >= 0 or result["message"].find("Party") >= 0)


func test_expedition_unknown_adventurer_fails() -> void:
	_init_loop()
	_add_bloom_seed()
	var result = loop.launch_expedition(0, ["nonexistent_adv"])
	assert_false(result["success"])
	assert_true(result["message"].find("not found") >= 0)


func test_expedition_unavailable_adventurer_fails() -> void:
	_init_loop()
	_add_bloom_seed()
	var adv := _add_adventurer("adv_1")
	adv.is_available = false
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"])
	assert_true(result["message"].find("unavailable") >= 0 or
			result["message"].find("Unavailable") >= 0)


func test_expedition_duplicate_party_fails() -> void:
	_init_loop()
	_add_bloom_seed()
	_add_adventurer("adv_1")
	var result = loop.launch_expedition(0, ["adv_1", "adv_1"])
	assert_false(result["success"])
	assert_true(result["message"].find("Duplicate") >= 0 or
			result["message"].find("duplicate") >= 0)


func test_expedition_calls_dungeon_generator() -> void:
	_setup_expedition()
	loop.launch_expedition(0, ["adv_1"])
	assert_eq(dgen.generate_calls, 1, "Should call generate once")


func test_expedition_calls_runner() -> void:
	_setup_expedition()
	loop.launch_expedition(0, ["adv_1"])
	assert_eq(runner.run_calls, 1, "Should call run_expedition once")


func test_expedition_calls_reward_processor() -> void:
	_setup_expedition()
	loop.launch_expedition(0, ["adv_1"])
	assert_eq(rewards.process_calls, 1, "Should call process_rewards once")


func test_expedition_consumes_seed() -> void:
	_setup_expedition()
	loop.launch_expedition(0, ["adv_1"])
	assert_eq(grove.remove_calls.size(), 1, "Should remove seed from grove")
	assert_eq(grove.remove_calls[0], "bloom_1", "Should remove correct seed")


func test_expedition_triggers_auto_save() -> void:
	_setup_expedition()
	loop.launch_expedition(0, ["adv_1"])
	assert_true(save_svc.save_called, "Should auto-save after expedition")


func test_expedition_tracks_conditions() -> void:
	_setup_expedition("adv_1")
	loop.launch_expedition(0, ["adv_1"])
	# Default mock reward processor sets everyone to "fatigued"
	assert_eq(loop.get_condition("adv_1"), "fatigued")
	assert_true(loop.get_condition_remaining("adv_1") > 0.0)


func test_expedition_fatigued_adventurer_allowed() -> void:
	_init_loop()
	_add_bloom_seed("b1")
	_add_bloom_seed("b2")
	var adv := _add_adventurer("adv_1")

	# First expedition — adv becomes fatigued but remains available
	loop.launch_expedition(0, ["adv_1"])
	assert_eq(loop.get_condition("adv_1"), "fatigued")
	assert_true(adv.is_available, "Fatigued adventurers should be available")

	# Second expedition — fatigued adventurer should be launchable
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_true(result["success"], "Should allow fatigued adventurer on expedition")


func test_expedition_multi_party() -> void:
	_init_loop()
	_add_bloom_seed()
	_add_adventurer("adv_1")
	_add_adventurer("adv_2")
	_add_adventurer("adv_3")
	var result = loop.launch_expedition(0, ["adv_1", "adv_2", "adv_3"])
	assert_true(result["success"])
	assert_eq(runner.last_party.size(), 3, "Party should have 3 members")


# ===========================================================================
# §5 — State Summary (~5 tests)
# ===========================================================================

func test_summary_empty_state() -> void:
	_init_loop()
	var summary = loop.get_state_summary()
	assert_eq(summary["grove_slots"].size(), grove.max_grove_slots,
			"Should have placeholder for all max slots")
	assert_eq(summary["available_adventurers"].size(), 0)


func test_summary_with_seeds() -> void:
	_init_loop()
	_add_bloom_seed("s1")
	var summary = loop.get_state_summary()
	var occupied_slots: int = 0
	for slot_info in summary["grove_slots"]:
		if slot_info["seed_id"] != "":
			occupied_slots += 1
	assert_eq(occupied_slots, 1, "Should report 1 planted seed")


func test_summary_with_adventurers() -> void:
	_init_loop()
	_add_adventurer("adv_1")
	_add_adventurer("adv_2")
	var summary = loop.get_state_summary()
	assert_eq(summary["available_adventurers"].size(), 2)


func test_summary_with_wallet() -> void:
	_init_loop()
	wallet.credit(Enums.Currency.GOLD, 500)
	var summary = loop.get_state_summary()
	assert_eq(summary["wallet_balances"][Enums.Currency.GOLD], 500)


func test_summary_includes_conditions() -> void:
	_init_loop()
	loop._condition_timers["adv_1"] = {"condition": "injured", "remaining": 1000.0}
	var summary = loop.get_state_summary()
	assert_true(summary.has("conditions"))
	assert_true(summary["conditions"].has("adv_1"))


# ===========================================================================
# §6 — Edge Cases (~5 tests)
# ===========================================================================

func test_null_grove_tick_does_not_crash() -> void:
	loop.initialize({"seed_grove": null})
	var result = loop.process_tick(1.0)
	assert_eq(result["seeds_advanced"].size(), 0, "Should handle null grove gracefully")


func test_no_roster_expedition_fails() -> void:
	loop.initialize({"seed_grove": grove, "adventurer_roster": null})
	_add_bloom_seed()
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"])
	assert_true(result["message"].find("roster") >= 0)


func test_wallet_zero_balances_summary() -> void:
	_init_loop()
	var summary = loop.get_state_summary()
	assert_eq(summary["wallet_balances"][Enums.Currency.GOLD], 0)
	assert_eq(summary["wallet_balances"][Enums.Currency.ESSENCE], 0)
	assert_eq(summary["wallet_balances"][Enums.Currency.FRAGMENTS], 0)
	assert_eq(summary["wallet_balances"][Enums.Currency.ARTIFACTS], 0)


func test_sequential_expeditions() -> void:
	_init_loop()
	_add_bloom_seed("b1")
	_add_bloom_seed("b2")
	_add_adventurer("adv_1")

	var r1 = loop.launch_expedition(0, ["adv_1"])
	assert_true(r1["success"], "First expedition should succeed")

	# After first expedition, adv is fatigued but available
	var r2 = loop.launch_expedition(0, ["adv_1"])
	assert_true(r2["success"], "Second expedition should succeed (fatigued allowed)")

	assert_eq(save_svc.save_count, 2, "Should auto-save twice")
	assert_eq(grove.remove_calls.size(), 2, "Should consume two seeds")


func test_condition_query_healthy_default() -> void:
	_init_loop()
	assert_eq(loop.get_condition("unknown_adv"), "healthy",
			"Unknown adventurer should default to healthy")
	assert_eq(loop.get_condition_remaining("unknown_adv"), 0.0,
			"Unknown adventurer should have 0 remaining")


func test_expedition_injured_condition_applied() -> void:
	_init_loop()
	_add_bloom_seed()
	var adv := _add_adventurer("adv_1")

	# Configure reward processor to return injured condition
	rewards._mock_summary = {
		"xp_per_adventurer": {},
		"level_ups": {},
		"currency_earned": {},
		"items_received": [],
		"adventurer_conditions": {"adv_1": "injured"},
		"completion_bonus": {},
	}

	loop.launch_expedition(0, ["adv_1"])
	assert_eq(loop.get_condition("adv_1"), "injured")
	assert_false(adv.is_available, "Injured adventurer should not be available")


func test_expedition_exhausted_condition_applied() -> void:
	_init_loop()
	_add_bloom_seed()
	var adv := _add_adventurer("adv_1")

	rewards._mock_summary = {
		"xp_per_adventurer": {},
		"level_ups": {},
		"currency_earned": {},
		"items_received": [],
		"adventurer_conditions": {"adv_1": "exhausted"},
		"completion_bonus": {},
	}

	loop.launch_expedition(0, ["adv_1"])
	assert_eq(loop.get_condition("adv_1"), "exhausted")


func test_build_game_state_contains_required_keys() -> void:
	_init_loop()
	wallet.credit(Enums.Currency.GOLD, 100)
	_add_adventurer("adv_1")

	# Trigger auto-save via plant_seed to check state structure
	var s := _make_seed(Enums.SeedPhase.SPORE, "plant_test")
	loop.plant_seed(0, s)

	assert_true(save_svc.last_state.has("seeds"), "State should have seeds")
	assert_true(save_svc.last_state.has("adventurers"), "State should have adventurers")
	assert_true(save_svc.last_state.has("inventory"), "State should have inventory")
	assert_true(save_svc.last_state.has("wallet"), "State should have wallet")
	assert_true(save_svc.last_state.has("loop_state"), "State should have loop_state")
	assert_true(save_svc.last_state.has("settings"), "State should have settings")


func test_condition_recovery_injured_restores_available_at_fatigued() -> void:
	_init_loop()
	var adv := _add_adventurer("adv_1")
	adv.is_available = false
	loop._condition_timers["adv_1"] = {"condition": "injured", "remaining": 50.0}
	loop.process_tick(50.0)
	# Should now be fatigued with is_available = true
	assert_eq(loop.get_condition("adv_1"), "fatigued")
	assert_true(adv.is_available, "Fatigued adventurers should be available")


func test_no_dungeon_generator_expedition_fails() -> void:
	loop.initialize({
		"seed_grove": grove,
		"adventurer_roster": roster,
		"dungeon_generator": null,
	})
	_add_bloom_seed()
	_add_adventurer("adv_1")
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"])
	assert_true(result["message"].find("dungeon") >= 0 or
			result["message"].find("generator") >= 0)


func test_no_expedition_runner_fails() -> void:
	loop.initialize({
		"seed_grove": grove,
		"adventurer_roster": roster,
		"dungeon_generator": dgen,
		"expedition_runner": null,
	})
	_add_bloom_seed()
	_add_adventurer("adv_1")
	var result = loop.launch_expedition(0, ["adv_1"])
	assert_false(result["success"])
	assert_true(result["message"].find("runner") >= 0 or
			result["message"].find("expedition") >= 0)
