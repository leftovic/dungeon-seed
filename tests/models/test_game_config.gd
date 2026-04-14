## tests/models/test_game_config.gd
## Comprehensive test suite for GameConfig (TASK-003b)
## Tests all 9 const dictionaries, helper methods, and spec compliance.
## Framework: GUT (Godot Unit Testing)
extends GutTest


# ===========================================================================
# §1. BASE_GROWTH_SECONDS Tests
# ===========================================================================

func test_base_growth_seconds_has_all_rarity_keys() -> void:
	# FR-001: All SeedRarity enum values present
	var expected_keys: Array[int] = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	
	var actual_keys: Array = GameConfig.BASE_GROWTH_SECONDS.keys()
	assert_eq(actual_keys.size(), 5, "BASE_GROWTH_SECONDS has exactly 5 keys")
	
	for key: int in expected_keys:
		assert_true(
			GameConfig.BASE_GROWTH_SECONDS.has(key),
			"BASE_GROWTH_SECONDS has key %d" % key
		)


func test_base_growth_seconds_exact_values() -> void:
	# FR-002: Exact values per spec
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON], 60)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON], 120)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE], 300)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC], 600)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY], 1200)


func test_base_growth_seconds_all_positive() -> void:
	# NFR-009: All values > 0
	for value: int in GameConfig.BASE_GROWTH_SECONDS.values():
		assert_gt(value, 0, "All BASE_GROWTH_SECONDS values are positive")


func test_base_growth_seconds_monotonically_increasing() -> void:
	# Verify rarity order increases
	assert_lt(
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON],
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON]
	)
	assert_lt(
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON],
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE]
	)
	assert_lt(
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE],
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC]
	)
	assert_lt(
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC],
		GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY]
	)


# ===========================================================================
# §2. MUTATION_SLOTS Tests
# ===========================================================================

func test_mutation_slots_has_all_rarity_keys() -> void:
	# FR-012: All SeedRarity enum values present
	var expected_keys: Array[int] = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	
	var actual_keys: Array = GameConfig.MUTATION_SLOTS.keys()
	assert_eq(actual_keys.size(), 5, "MUTATION_SLOTS has exactly 5 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.MUTATION_SLOTS.has(key))


func test_mutation_slots_exact_values() -> void:
	# FR-013: Exact values per spec
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.COMMON], 1)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.UNCOMMON], 2)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.RARE], 3)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.EPIC], 4)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.LEGENDARY], 5)


# ===========================================================================
# §3. PHASE_GROWTH_MULTIPLIERS Tests
# ===========================================================================

func test_phase_growth_multipliers_has_all_phase_keys() -> void:
	# FR-018: All SeedPhase enum values present
	var expected_keys: Array[int] = [
		Enums.SeedPhase.SPORE,
		Enums.SeedPhase.SPROUT,
		Enums.SeedPhase.BUD,
		Enums.SeedPhase.BLOOM,
	]
	
	var actual_keys: Array = GameConfig.PHASE_GROWTH_MULTIPLIERS.keys()
	assert_eq(actual_keys.size(), 4, "PHASE_GROWTH_MULTIPLIERS has exactly 4 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.PHASE_GROWTH_MULTIPLIERS.has(key))


func test_phase_growth_multipliers_exact_values() -> void:
	# FR-019: Exact values per spec - FIXED: should be 1.0, 1.5, 2.0, 3.0
	assert_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE], 1.0)
	assert_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPROUT], 1.5)
	assert_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BUD], 2.0)
	assert_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BLOOM], 3.0)


func test_phase_growth_multipliers_all_positive() -> void:
	# All multipliers >= 1.0
	for value: float in GameConfig.PHASE_GROWTH_MULTIPLIERS.values():
		assert_gte(value, 1.0, "All PHASE_GROWTH_MULTIPLIERS are >= 1.0")


func test_phase_growth_multipliers_monotonically_increasing() -> void:
	# Each phase has higher multiplier than previous
	assert_lt(
		GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE],
		GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPROUT]
	)
	assert_lt(
		GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPROUT],
		GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BUD]
	)
	assert_lt(
		GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BUD],
		GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BLOOM]
	)


# ===========================================================================
# §4. ELEMENT_NAMES Tests
# ===========================================================================

func test_element_names_has_all_element_keys() -> void:
	# FR-020: All Element enum values present
	var expected_keys: Array[int] = [
		Enums.Element.TERRA,
		Enums.Element.FLAME,
		Enums.Element.FROST,
		Enums.Element.ARCANE,
		Enums.Element.SHADOW,
		Enums.Element.NONE,
	]
	
	var actual_keys: Array = GameConfig.ELEMENT_NAMES.keys()
	assert_eq(actual_keys.size(), 6, "ELEMENT_NAMES has exactly 6 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.ELEMENT_NAMES.has(key))


func test_element_names_non_empty_strings() -> void:
	# FR-020: All values are non-empty strings
	for value: String in GameConfig.ELEMENT_NAMES.values():
		assert_gt(value.length(), 0, "All ELEMENT_NAMES values are non-empty")


func test_element_names_char_limit() -> void:
	# NFR-005: All strings <= 20 characters
	for value: String in GameConfig.ELEMENT_NAMES.values():
		assert_lte(value.length(), 20, "Element name '%s' is <= 20 chars" % value)


# ===========================================================================
# §5. ROOM_DIFFICULTY_SCALE Tests
# ===========================================================================

func test_room_difficulty_scale_has_all_room_type_keys() -> void:
	# FR-016: All RoomType enum values present
	var expected_keys: Array[int] = [
		Enums.RoomType.COMBAT,
		Enums.RoomType.TREASURE,
		Enums.RoomType.TRAP,
		Enums.RoomType.PUZZLE,
		Enums.RoomType.REST,
		Enums.RoomType.BOSS,
	]
	
	var actual_keys: Array = GameConfig.ROOM_DIFFICULTY_SCALE.keys()
	assert_eq(actual_keys.size(), 6, "ROOM_DIFFICULTY_SCALE has exactly 6 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.ROOM_DIFFICULTY_SCALE.has(key))


func test_room_difficulty_scale_exact_values() -> void:
	# FR-017: Exact values per spec - FIXED: TRAP was 1.2, should be 0.8
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.COMBAT], 1.0)
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.TREASURE], 0.5)
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.TRAP], 0.8)
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.PUZZLE], 0.6)
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.REST], 0.0)
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.BOSS], 2.0)


func test_room_difficulty_scale_range() -> void:
	# FR-016: All values in range [0.0, 2.0]
	for value: float in GameConfig.ROOM_DIFFICULTY_SCALE.values():
		assert_gte(value, 0.0)
		assert_lte(value, 2.0)


# ===========================================================================
# §6. XP_PER_TIER Tests
# ===========================================================================

func test_xp_per_tier_has_all_level_tier_keys() -> void:
	# FR-003: All LevelTier enum values present
	var expected_keys: Array[int] = [
		Enums.LevelTier.NOVICE,
		Enums.LevelTier.SKILLED,
		Enums.LevelTier.VETERAN,
		Enums.LevelTier.ELITE,
	]
	
	var actual_keys: Array = GameConfig.XP_PER_TIER.keys()
	assert_eq(actual_keys.size(), 4, "XP_PER_TIER has exactly 4 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.XP_PER_TIER.has(key))


func test_xp_per_tier_exact_values() -> void:
	# FR-004: Exact values per spec
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE], 0)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED], 100)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN], 350)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE], 750)


func test_xp_per_tier_monotonically_increasing() -> void:
	# NFR-010: Strictly increasing
	assert_lt(
		GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE],
		GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED]
	)
	assert_lt(
		GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED],
		GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN]
	)
	assert_lt(
		GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN],
		GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE]
	)


# ===========================================================================
# §7. BASE_STATS Tests
# ===========================================================================

func test_base_stats_has_all_class_keys() -> void:
	# FR-005: All AdventurerClass enum values present
	var expected_keys: Array[int] = [
		Enums.AdventurerClass.WARRIOR,
		Enums.AdventurerClass.RANGER,
		Enums.AdventurerClass.MAGE,
		Enums.AdventurerClass.ROGUE,
		Enums.AdventurerClass.ALCHEMIST,
		Enums.AdventurerClass.SENTINEL,
	]
	
	var actual_keys: Array = GameConfig.BASE_STATS.keys()
	assert_eq(actual_keys.size(), 6, "BASE_STATS has exactly 6 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.BASE_STATS.has(key))


func test_base_stats_warrior_exact_values() -> void:
	# FR-006
	var warrior_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR]
	assert_eq(warrior_stats["health"], 120)
	assert_eq(warrior_stats["attack"], 18)
	assert_eq(warrior_stats["defense"], 15)
	assert_eq(warrior_stats["speed"], 8)
	assert_eq(warrior_stats["utility"], 5)


func test_base_stats_ranger_exact_values() -> void:
	# FR-007 - FIXED: health was 90, should be 85
	var ranger_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.RANGER]
	assert_eq(ranger_stats["health"], 85)
	assert_eq(ranger_stats["attack"], 14)
	assert_eq(ranger_stats["defense"], 10)
	assert_eq(ranger_stats["speed"], 15)
	assert_eq(ranger_stats["utility"], 10)


func test_base_stats_mage_exact_values() -> void:
	# FR-008
	var mage_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.MAGE]
	assert_eq(mage_stats["health"], 70)
	assert_eq(mage_stats["attack"], 12)
	assert_eq(mage_stats["defense"], 8)
	assert_eq(mage_stats["speed"], 10)
	assert_eq(mage_stats["utility"], 20)


func test_base_stats_rogue_exact_values() -> void:
	# FR-009 - FIXED: attack was 20, should be 16
	var rogue_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.ROGUE]
	assert_eq(rogue_stats["health"], 75)
	assert_eq(rogue_stats["attack"], 16)
	assert_eq(rogue_stats["defense"], 8)
	assert_eq(rogue_stats["speed"], 18)
	assert_eq(rogue_stats["utility"], 12)


func test_base_stats_alchemist_exact_values() -> void:
	# FR-010 - FIXED: defense was 9, should be 12
	var alchemist_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.ALCHEMIST]
	assert_eq(alchemist_stats["health"], 80)
	assert_eq(alchemist_stats["attack"], 10)
	assert_eq(alchemist_stats["defense"], 12)
	assert_eq(alchemist_stats["speed"], 10)
	assert_eq(alchemist_stats["utility"], 18)


func test_base_stats_sentinel_exact_values() -> void:
	# FR-011
	var sentinel_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.SENTINEL]
	assert_eq(sentinel_stats["health"], 130)
	assert_eq(sentinel_stats["attack"], 10)
	assert_eq(sentinel_stats["defense"], 20)
	assert_eq(sentinel_stats["speed"], 6)
	assert_eq(sentinel_stats["utility"], 8)


func test_base_stats_all_have_required_keys() -> void:
	# FR-005: Each class dict has exactly ["health", "attack", "defense", "speed", "utility"]
	var required_keys: Array[String] = ["health", "attack", "defense", "speed", "utility"]
	
	for class_enum: int in GameConfig.BASE_STATS.keys():
		var stats: Dictionary = GameConfig.BASE_STATS[class_enum]
		var stat_keys: Array = stats.keys()
		
		assert_eq(stat_keys.size(), 5, "Class %d has exactly 5 stat keys" % class_enum)
		
		for key: String in required_keys:
			assert_true(stats.has(key), "Class %d has key '%s'" % [class_enum, key])


func test_base_stats_all_positive() -> void:
	# NFR-009: All stat values > 0
	for class_enum: int in GameConfig.BASE_STATS.keys():
		var stats: Dictionary = GameConfig.BASE_STATS[class_enum]
		for stat_value: int in stats.values():
			assert_gt(stat_value, 0, "All BASE_STATS values are positive")


# ===========================================================================
# §8. CURRENCY_EARN_RATES Tests
# ===========================================================================

func test_currency_earn_rates_has_all_currency_keys() -> void:
	# FR-014: All Currency enum values present
	var expected_keys: Array[int] = [
		Enums.Currency.GOLD,
		Enums.Currency.ESSENCE,
		Enums.Currency.FRAGMENTS,
		Enums.Currency.ARTIFACTS,
	]
	
	var actual_keys: Array = GameConfig.CURRENCY_EARN_RATES.keys()
	assert_eq(actual_keys.size(), 4, "CURRENCY_EARN_RATES has exactly 4 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.CURRENCY_EARN_RATES.has(key))


func test_currency_earn_rates_exact_values() -> void:
	# FR-015: Exact values per spec
	assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.GOLD], 10)
	assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.ESSENCE], 2)
	assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.FRAGMENTS], 1)
	assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.ARTIFACTS], 0)


func test_currency_earn_rates_range() -> void:
	# FR-014: All values in range [0, 10]
	for value: int in GameConfig.CURRENCY_EARN_RATES.values():
		assert_gte(value, 0)
		assert_lte(value, 10)


# ===========================================================================
# §9. RARITY_COLORS Tests
# ===========================================================================

func test_rarity_colors_has_all_rarity_keys() -> void:
	# FR-021: All SeedRarity enum values present
	var expected_keys: Array[int] = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	
	var actual_keys: Array = GameConfig.RARITY_COLORS.keys()
	assert_eq(actual_keys.size(), 5, "RARITY_COLORS has exactly 5 keys")
	
	for key: int in expected_keys:
		assert_true(GameConfig.RARITY_COLORS.has(key))


func test_rarity_colors_exact_values() -> void:
	# FR-022: Exact values per spec - FIXED: COMMON was 0.66, should be 0.78; LEGENDARY was 1.0, should be 0.95
	var common_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.COMMON]
	assert_eq(common_color.r, 0.78)
	assert_eq(common_color.g, 0.78)
	assert_eq(common_color.b, 0.78)
	
	var uncommon_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.UNCOMMON]
	assert_eq(uncommon_color.r, 0.18)
	assert_eq(uncommon_color.g, 0.80)
	assert_eq(uncommon_color.b, 0.25)
	
	var rare_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.RARE]
	assert_eq(rare_color.r, 0.25)
	assert_eq(rare_color.g, 0.52)
	assert_eq(rare_color.b, 0.96)
	
	var epic_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.EPIC]
	assert_eq(epic_color.r, 0.64)
	assert_eq(epic_color.g, 0.21)
	assert_eq(epic_color.b, 0.93)
	
	var legendary_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.LEGENDARY]
	assert_eq(legendary_color.r, 0.95)
	assert_eq(legendary_color.g, 0.77)
	assert_eq(legendary_color.b, 0.06)


func test_rarity_colors_rgb_in_range() -> void:
	# NFR-006: All RGB components in [0.0, 1.0]
	for color: Color in GameConfig.RARITY_COLORS.values():
		assert_gte(color.r, 0.0)
		assert_lte(color.r, 1.0)
		assert_gte(color.g, 0.0)
		assert_lte(color.g, 1.0)
		assert_gte(color.b, 0.0)
		assert_lte(color.b, 1.0)


func test_rarity_colors_all_distinct() -> void:
	# NFR-006: All colors must be different
	var colors: Array = GameConfig.RARITY_COLORS.values()
	for i: int in range(colors.size()):
		for j: int in range(i + 1, colors.size()):
			assert_ne(colors[i], colors[j], "All rarity colors are distinct")


# ===========================================================================
# §10. Helper Method Tests
# ===========================================================================

func test_get_base_stats_returns_copy() -> void:
	# FR-024, NFR-011: Returns new dict, not reference
	var warrior_stats1: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	var warrior_stats2: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	
	# Should be equal but different objects
	assert_eq(warrior_stats1, warrior_stats2)
	assert_ne(warrior_stats1, warrior_stats2)  # Different object references


func test_get_base_stats_mutation_doesnt_affect_const() -> void:
	# FR-024: Verify mutation of returned dict doesn't affect const
	var warrior_stats: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	warrior_stats["health"] = 999
	
	var warrior_stats_fresh: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	assert_eq(warrior_stats_fresh["health"], 120, "Const dict is unaffected by mutation")


func test_get_base_stats_invalid_class() -> void:
	# Test invalid class enum returns empty dict
	var result: Dictionary = GameConfig.get_base_stats(9999)
	assert_eq(result.size(), 0, "Invalid class returns empty dict")


func test_get_growth_seconds() -> void:
	# Test get_growth_seconds helper
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.COMMON), 60)
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.RARE), 300)
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.LEGENDARY), 1200)


func test_get_growth_seconds_invalid_rarity() -> void:
	# Invalid rarity returns 0
	assert_eq(GameConfig.get_growth_seconds(9999), 0)


func test_get_mutation_slots() -> void:
	# Test get_mutation_slots helper
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.COMMON), 1)
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.EPIC), 4)
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.LEGENDARY), 5)


func test_get_xp_for_tier() -> void:
	# Test get_xp_for_tier helper
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.NOVICE), 0)
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.SKILLED), 100)
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.VETERAN), 350)
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.ELITE), 750)


func test_get_rarity_color() -> void:
	# Test get_rarity_color helper
	var common_color: Color = GameConfig.get_rarity_color(Enums.SeedRarity.COMMON)
	assert_eq(common_color, Color(0.78, 0.78, 0.78))
	
	var legendary_color: Color = GameConfig.get_rarity_color(Enums.SeedRarity.LEGENDARY)
	assert_eq(legendary_color, Color(0.95, 0.77, 0.06))


func test_get_room_difficulty() -> void:
	# Test get_room_difficulty helper
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.COMBAT), 1.0)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.TRAP), 0.8)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.BOSS), 2.0)


func test_get_phase_multiplier() -> void:
	# Test get_phase_multiplier helper
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.SPORE), 1.0)
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.SPROUT), 1.5)
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.BUD), 2.0)
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.BLOOM), 3.0)


# ===========================================================================
# §11. Completeness & Integration Tests
# ===========================================================================

func test_all_enums_have_entries_fr025() -> void:
	# FR-025: Every enum value has exactly one dict entry
	
	# SeedRarity enums
	for rarity: int in range(5):  # 0-4 for COMMON..LEGENDARY
		assert_true(
			GameConfig.BASE_GROWTH_SECONDS.has(rarity),
			"SeedRarity.%d in BASE_GROWTH_SECONDS" % rarity
		)
		assert_true(
			GameConfig.MUTATION_SLOTS.has(rarity),
			"SeedRarity.%d in MUTATION_SLOTS" % rarity
		)
		assert_true(
			GameConfig.RARITY_COLORS.has(rarity),
			"SeedRarity.%d in RARITY_COLORS" % rarity
		)
	
	# LevelTier enums
	for tier: int in range(4):  # 0-3 for NOVICE..ELITE
		assert_true(
			GameConfig.XP_PER_TIER.has(tier),
			"LevelTier.%d in XP_PER_TIER" % tier
		)
	
	# AdventurerClass enums
	for cls: int in range(6):  # 0-5 for WARRIOR..SENTINEL
		assert_true(
			GameConfig.BASE_STATS.has(cls),
			"AdventurerClass.%d in BASE_STATS" % cls
		)
	
	# Currency enums
	for curr: int in range(4):  # 0-3 for GOLD..ARTIFACTS
		assert_true(
			GameConfig.CURRENCY_EARN_RATES.has(curr),
			"Currency.%d in CURRENCY_EARN_RATES" % curr
		)
	
	# RoomType enums
	for room: int in range(6):  # 0-5 for COMBAT..BOSS
		assert_true(
			GameConfig.ROOM_DIFFICULTY_SCALE.has(room),
			"RoomType.%d in ROOM_DIFFICULTY_SCALE" % room
		)
	
	# SeedPhase enums
	for phase: int in range(4):  # 0-3 for SPORE..BLOOM
		assert_true(
			GameConfig.PHASE_GROWTH_MULTIPLIERS.has(phase),
			"SeedPhase.%d in PHASE_GROWTH_MULTIPLIERS" % phase
		)
	
	# Element enums (6 values)
	for elem: int in range(6):  # 0-5 for TERRA..NONE
		assert_true(
			GameConfig.ELEMENT_NAMES.has(elem),
			"Element.%d in ELEMENT_NAMES" % elem
		)


func test_no_orphaned_dictionary_entries() -> void:
	# Verify no extra/orphaned keys in any dict
	
	# BASE_GROWTH_SECONDS should have exactly 5 (SeedRarity count)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS.size(), 5)
	
	# MUTATION_SLOTS should have exactly 5 (SeedRarity count)
	assert_eq(GameConfig.MUTATION_SLOTS.size(), 5)
	
	# PHASE_GROWTH_MULTIPLIERS should have exactly 4 (SeedPhase count)
	assert_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS.size(), 4)
	
	# ELEMENT_NAMES should have exactly 6 (Element count)
	assert_eq(GameConfig.ELEMENT_NAMES.size(), 6)
	
	# ROOM_DIFFICULTY_SCALE should have exactly 6 (RoomType count)
	assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE.size(), 6)
	
	# XP_PER_TIER should have exactly 4 (LevelTier count)
	assert_eq(GameConfig.XP_PER_TIER.size(), 4)
	
	# BASE_STATS should have exactly 6 (AdventurerClass count)
	assert_eq(GameConfig.BASE_STATS.size(), 6)
	
	# CURRENCY_EARN_RATES should have exactly 4 (Currency count)
	assert_eq(GameConfig.CURRENCY_EARN_RATES.size(), 4)
	
	# RARITY_COLORS should have exactly 5 (SeedRarity count)
	assert_eq(GameConfig.RARITY_COLORS.size(), 5)


func test_all_dictionary_keys_are_ints() -> void:
	# NFR-007: All keys are enum values (integers), not strings
	var dicts: Array = [
		GameConfig.BASE_GROWTH_SECONDS,
		GameConfig.MUTATION_SLOTS,
		GameConfig.PHASE_GROWTH_MULTIPLIERS,
		GameConfig.ELEMENT_NAMES,
		GameConfig.ROOM_DIFFICULTY_SCALE,
		GameConfig.XP_PER_TIER,
		GameConfig.BASE_STATS,
		GameConfig.CURRENCY_EARN_RATES,
		GameConfig.RARITY_COLORS,
	]
	
	for dict: Dictionary in dicts:
		for key in dict.keys():
			assert_eq(typeof(key), TYPE_INT, "All dict keys are integers (enum values)")
