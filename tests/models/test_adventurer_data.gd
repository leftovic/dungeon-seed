## tests/models/test_adventurer_data.gd
## GUT test suite for TASK-006: Adventurer Data Model & Class Definitions
## Covers: adventurer_data.gd — construction, base stats, XP, leveling,
## tier boundaries, effective stats, serialization, edge cases.
extends GutTest

const AdventurerData = preload("res://src/models/adventurer_data.gd")


# =============================================================================
# HELPERS
# =============================================================================

func _create_adventurer(
	adv_class: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR,
	p_name: String = "Test Hero",
	p_id: String = "test-uuid-001"
) -> AdventurerData:
	var adv: AdventurerData = AdventurerData.new()
	adv.id = p_id
	adv.display_name = p_name
	adv.adventurer_class = adv_class
	adv.initialize_base_stats()
	return adv


func _all_classes() -> Array:
	return [
		Enums.AdventurerClass.WARRIOR,
		Enums.AdventurerClass.RANGER,
		Enums.AdventurerClass.MAGE,
		Enums.AdventurerClass.ROGUE,
		Enums.AdventurerClass.ALCHEMIST,
		Enums.AdventurerClass.SENTINEL,
	]


func _expected_base_stats(adv_class: Enums.AdventurerClass) -> Dictionary:
	match adv_class:
		Enums.AdventurerClass.WARRIOR:
			return { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
		Enums.AdventurerClass.RANGER:
			return { "health": 85, "attack": 14, "defense": 8, "speed": 18, "utility": 10 }
		Enums.AdventurerClass.MAGE:
			return { "health": 70, "attack": 12, "defense": 6, "speed": 10, "utility": 20 }
		Enums.AdventurerClass.ROGUE:
			return { "health": 80, "attack": 15, "defense": 7, "speed": 16, "utility": 14 }
		Enums.AdventurerClass.ALCHEMIST:
			return { "health": 90, "attack": 10, "defense": 10, "speed": 12, "utility": 18 }
		Enums.AdventurerClass.SENTINEL:
			return { "health": 140, "attack": 8, "defense": 20, "speed": 5, "utility": 8 }
		_:
			return {}


# =============================================================================
# SECTION A: CONSTRUCTION & DEFAULT VALUES
# =============================================================================

func test_new_instance_is_not_null() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_not_null(adv, "AdventurerData.new() should return a non-null instance")


func test_default_id_is_empty_string() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.id, "", "Default id should be empty string")


func test_default_display_name_is_empty_string() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.display_name, "", "Default display_name should be empty string")


func test_default_adventurer_class_is_warrior() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.adventurer_class, Enums.AdventurerClass.WARRIOR, "Default class should be WARRIOR")


func test_default_level_is_one() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.level, 1, "Default level should be 1")


func test_default_xp_is_zero() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.xp, 0, "Default xp should be 0")


func test_default_is_available_is_true() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_true(adv.is_available, "Default is_available should be true")


func test_default_equipment_has_three_null_slots() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.equipment.size(), 3, "Equipment should have 3 slots")
	assert_null(adv.equipment.get("weapon"), "Weapon slot should be null")
	assert_null(adv.equipment.get("armor"), "Armor slot should be null")
	assert_null(adv.equipment.get("accessory"), "Accessory slot should be null")


func test_default_stats_is_empty_dict() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.stats, {}, "Default stats should be empty dict before initialize_base_stats()")


# =============================================================================
# SECTION B: BASE STATS INITIALIZATION — PER CLASS
# =============================================================================

func test_warrior_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.WARRIOR)
	var expected: Dictionary = { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
	assert_eq(adv.stats, expected, "Warrior base stats should match GDD spec")


func test_ranger_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.RANGER)
	var expected: Dictionary = { "health": 85, "attack": 14, "defense": 10, "speed": 15, "utility": 10 }
	assert_eq(adv.stats, expected, "Ranger base stats should match GDD spec")


func test_mage_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.MAGE)
	var expected: Dictionary = { "health": 70, "attack": 12, "defense": 8, "speed": 10, "utility": 20 }
	assert_eq(adv.stats, expected, "Mage base stats should match GDD spec")


func test_rogue_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ROGUE)
	var expected: Dictionary = { "health": 75, "attack": 16, "defense": 8, "speed": 18, "utility": 12 }
	assert_eq(adv.stats, expected, "Rogue base stats should match GDD spec")


func test_alchemist_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ALCHEMIST)
	var expected: Dictionary = { "health": 80, "attack": 10, "defense": 12, "speed": 10, "utility": 18 }
	assert_eq(adv.stats, expected, "Alchemist base stats should match GDD spec")


func test_sentinel_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.SENTINEL)
	var expected: Dictionary = { "health": 130, "attack": 10, "defense": 20, "speed": 6, "utility": 8 }
	assert_eq(adv.stats, expected, "Sentinel base stats should match GDD spec")


func test_all_classes_have_five_stat_keys() -> void:
	var expected_keys: Array[String] = ["health", "attack", "defense", "speed", "utility"]
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		for key in expected_keys:
			assert_has(adv.stats, key, "Class %s missing stat key: %s" % [adv_class, key])
		assert_eq(adv.stats.size(), 5, "Class %s should have exactly 5 stat keys" % adv_class)


func test_all_classes_have_positive_stat_values() -> void:
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		for stat_name in adv.stats:
			assert_gt(adv.stats[stat_name], 0, "Class %s stat %s should be > 0" % [adv_class, stat_name])


func test_each_class_has_distinct_stat_distribution() -> void:
	var stat_sets: Array[Dictionary] = []
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		for existing in stat_sets:
			assert_ne(adv.stats, existing, "Each class must have a unique stat distribution")
		stat_sets.append(adv.stats.duplicate())


func test_game_config_base_stats_has_six_entries() -> void:
	assert_eq(GameConfig.BASE_STATS.size(), 6, "GameConfig.BASE_STATS should have 6 class entries")


func test_initialize_base_stats_without_class_set_uses_warrior() -> void:
	var adv: AdventurerData = AdventurerData.new()
	# Default class is WARRIOR, so init without setting class should use Warrior stats
	adv.initialize_base_stats()
	var expected: Dictionary = { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
	assert_eq(adv.stats, expected, "Default class init should use WARRIOR stats")


# =============================================================================
# SECTION C: XP-TO-NEXT-LEVEL CALCULATION
# =============================================================================

func test_xp_to_next_level_at_level_1() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 1
	assert_eq(adv.xp_to_next_level(), 100, "Level 1 → 2 should cost 100 XP")


func test_xp_to_next_level_at_level_2() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 2
	assert_eq(adv.xp_to_next_level(), 115, "Level 2 → 3 should cost 115 XP")


func test_xp_to_next_level_at_level_5() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 5
	var expected: int = roundi(100 * pow(1.15, 4))
	assert_eq(adv.xp_to_next_level(), expected, "Level 5 → 6 should follow exponential curve")


func test_xp_to_next_level_at_level_10() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 10
	var expected: int = roundi(100 * pow(1.15, 9))
	assert_eq(adv.xp_to_next_level(), expected, "Level 10 → 11 should follow exponential curve")


func test_xp_to_next_level_at_level_15() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 15
	var expected: int = roundi(100 * pow(1.15, 14))
	assert_eq(adv.xp_to_next_level(), expected, "Level 15 → 16 should follow exponential curve")


func test_xp_to_next_level_always_positive() -> void:
	var adv: AdventurerData = _create_adventurer()
	for lvl in range(1, 50):
		adv.level = lvl
		assert_gt(adv.xp_to_next_level(), 0, "XP threshold at level %d should be positive" % lvl)


func test_xp_to_next_level_increases_with_level() -> void:
	var adv: AdventurerData = _create_adventurer()
	var prev_xp: int = 0
	for lvl in range(1, 30):
		adv.level = lvl
		var current_xp: int = adv.xp_to_next_level()
		assert_gt(current_xp, prev_xp, "XP threshold should increase at level %d" % lvl)
		prev_xp = current_xp


# =============================================================================
# SECTION D: GAIN XP & LEVEL-UP
# =============================================================================

func test_gain_xp_no_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(50)
	assert_false(leveled, "50 XP should not trigger level-up from level 1")
	assert_eq(adv.xp, 50, "XP should be 50")
	assert_eq(adv.level, 1, "Level should remain 1")


func test_gain_xp_exact_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(100)
	assert_true(leveled, "100 XP should trigger level-up from level 1")
	assert_eq(adv.level, 2, "Level should be 2")
	assert_eq(adv.xp, 0, "XP should be 0 after exact level-up")


func test_gain_xp_with_remainder() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(130)
	assert_true(leveled, "130 XP should trigger level-up from level 1")
	assert_eq(adv.level, 2, "Level should be 2")
	assert_eq(adv.xp, 30, "XP remainder should be 30")


func test_gain_xp_multi_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	# Level 1→2: 100, Level 2→3: 115 → total 215 for 2 level-ups
	var leveled: bool = adv.gain_xp(250)
	assert_true(leveled, "250 XP should trigger multi-level-up")
	assert_eq(adv.level, 3, "Level should be 3 after multi-level-up")
	assert_eq(adv.xp, 35, "XP remainder should be 250 - 100 - 115 = 35")


func test_gain_xp_zero_returns_false() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(0)
	assert_false(leveled, "0 XP should not trigger level-up")
	assert_eq(adv.xp, 0, "XP should remain 0")
	assert_eq(adv.level, 1, "Level should remain 1")


func test_gain_xp_negative_returns_false() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.xp = 50
	var leveled: bool = adv.gain_xp(-10)
	assert_false(leveled, "Negative XP should not trigger level-up")
	assert_eq(adv.xp, 50, "XP should remain unchanged")
	assert_eq(adv.level, 1, "Level should remain 1")


func test_gain_xp_large_amount_many_levels() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(5000)
	assert_true(leveled, "5000 XP should trigger many level-ups")
	assert_gt(adv.level, 10, "Level should be well above 10")
	assert_gte(adv.xp, 0, "XP remainder should be non-negative")
	assert_lt(adv.xp, adv.xp_to_next_level(), "XP remainder should be less than next threshold")


func test_gain_xp_accumulates_across_calls() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.gain_xp(50)
	assert_eq(adv.xp, 50)
	assert_eq(adv.level, 1)
	adv.gain_xp(50)
	assert_eq(adv.level, 2, "Two 50 XP grants should total to 100, triggering level-up")
	assert_eq(adv.xp, 0)


func test_level_never_decreases() -> void:
	var adv: AdventurerData = _create_adventurer()
	var prev_level: int = adv.level
	for i in range(20):
		adv.gain_xp(randi_range(10, 200))
		assert_gte(adv.level, prev_level, "Level should never decrease")
		prev_level = adv.level


func test_xp_remainder_always_valid_after_gain() -> void:
	var adv: AdventurerData = _create_adventurer()
	for i in range(50):
		adv.gain_xp(randi_range(1, 500))
		assert_gte(adv.xp, 0, "XP should never be negative after gain_xp")
		assert_lt(adv.xp, adv.xp_to_next_level(), "XP should be less than threshold after gain_xp")


# =============================================================================
# SECTION E: LEVEL TIER
# =============================================================================

func test_tier_novice_level_1() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 1
	assert_eq(adv.get_level_tier(), Enums.LevelTier.NOVICE, "Level 1 should be NOVICE")


func test_tier_novice_level_5() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 5
	assert_eq(adv.get_level_tier(), Enums.LevelTier.NOVICE, "Level 5 should be NOVICE")


func test_tier_skilled_level_6() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 6
	assert_eq(adv.get_level_tier(), Enums.LevelTier.SKILLED, "Level 6 should be SKILLED")


func test_tier_skilled_level_10() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 10
	assert_eq(adv.get_level_tier(), Enums.LevelTier.SKILLED, "Level 10 should be SKILLED")


func test_tier_veteran_level_11() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 11
	assert_eq(adv.get_level_tier(), Enums.LevelTier.VETERAN, "Level 11 should be VETERAN")


func test_tier_veteran_level_15() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 15
	assert_eq(adv.get_level_tier(), Enums.LevelTier.VETERAN, "Level 15 should be VETERAN")


func test_tier_elite_level_16() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 16
	assert_eq(adv.get_level_tier(), Enums.LevelTier.ELITE, "Level 16 should be ELITE")


func test_tier_elite_level_99() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 99
	assert_eq(adv.get_level_tier(), Enums.LevelTier.ELITE, "Level 99 should be ELITE")


func test_tier_transitions_through_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	assert_eq(adv.get_level_tier(), Enums.LevelTier.NOVICE, "Start as NOVICE")
	adv.level = 6
	assert_eq(adv.get_level_tier(), Enums.LevelTier.SKILLED, "Level 6 transitions to SKILLED")
	adv.level = 11
	assert_eq(adv.get_level_tier(), Enums.LevelTier.VETERAN, "Level 11 transitions to VETERAN")
	adv.level = 16
	assert_eq(adv.get_level_tier(), Enums.LevelTier.ELITE, "Level 16 transitions to ELITE")


# =============================================================================
# SECTION F: EFFECTIVE STATS
# =============================================================================

func test_effective_stats_returns_dictionary_with_five_keys() -> void:
	var adv: AdventurerData = _create_adventurer()
	var effective: Dictionary = adv.get_effective_stats()
	assert_eq(effective.size(), 5, "Effective stats should have 5 keys")
	assert_has(effective, "health")
	assert_has(effective, "attack")
	assert_has(effective, "defense")
	assert_has(effective, "speed")
	assert_has(effective, "utility")


func test_effective_stats_equals_base_stats_without_equipment() -> void:
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		var effective: Dictionary = adv.get_effective_stats()
		assert_eq(effective, adv.stats, "Effective stats should equal base stats without equipment")


func test_effective_stats_returns_deep_copy() -> void:
	var adv: AdventurerData = _create_adventurer()
	var effective: Dictionary = adv.get_effective_stats()
	effective["health"] = 999
	assert_ne(adv.stats["health"], 999, "Mutating effective stats should not change base stats")
	assert_eq(adv.stats["health"], 120, "Base health should remain 120 for Warrior")


# =============================================================================
# SECTION G: SERIALIZATION — to_dict()
# =============================================================================

func test_to_dict_contains_all_keys() -> void:
	var adv: AdventurerData = _create_adventurer()
	var d: Dictionary = adv.to_dict()
	var expected_keys: Array[String] = [
		"id", "display_name", "adventurer_class", "level",
		"xp", "stats", "equipment", "is_available"
	]
	for key in expected_keys:
		assert_has(d, key, "to_dict() missing key: %s" % key)


func test_to_dict_serializes_class_as_int() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.MAGE)
	var d: Dictionary = adv.to_dict()
	assert_typeof(d["adventurer_class"], TYPE_INT, "adventurer_class should serialize as int")
	assert_eq(d["adventurer_class"], int(Enums.AdventurerClass.MAGE))


func test_to_dict_preserves_all_values() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ROGUE, "Shadow", "rogue-42")
	adv.level = 7
	adv.xp = 55
	adv.is_available = false
	var d: Dictionary = adv.to_dict()
	assert_eq(d["id"], "rogue-42")
	assert_eq(d["display_name"], "Shadow")
	assert_eq(d["level"], 7)
	assert_eq(d["xp"], 55)
	assert_eq(d["is_available"], false)


func test_to_dict_equipment_uses_string_keys() -> void:
	var adv: AdventurerData = _create_adventurer()
	var d: Dictionary = adv.to_dict()
	var equip: Dictionary = d["equipment"]
	assert_has(equip, "weapon", "Equipment should have 'weapon' string key")
	assert_has(equip, "armor", "Equipment should have 'armor' string key")
	assert_has(equip, "accessory", "Equipment should have 'accessory' string key")


func test_to_dict_is_json_compatible() -> void:
	var adv: AdventurerData = _create_adventurer()
	var d: Dictionary = adv.to_dict()
	var json_str: String = JSON.stringify(d)
	assert_gt(json_str.length(), 0, "JSON.stringify() should produce non-empty string")
	var parsed: Variant = JSON.parse_string(json_str)
	assert_not_null(parsed, "JSON.parse_string() should successfully parse the output")


# =============================================================================
# SECTION H: SERIALIZATION — from_dict() ROUND-TRIP
# =============================================================================

func test_round_trip_all_classes() -> void:
	for adv_class in _all_classes():
		var original: AdventurerData = _create_adventurer(adv_class, "Hero %d" % adv_class, "id-%d" % adv_class)
		original.level = 8
		original.xp = 42
		original.is_available = false
		var d: Dictionary = original.to_dict()
		var restored: AdventurerData = AdventurerData.from_dict(d)
		assert_eq(restored.to_dict(), d, "Round-trip should be lossless for class %s" % adv_class)


func test_from_dict_restores_correct_types() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ALCHEMIST)
	adv.level = 12
	adv.xp = 200
	var d: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(restored.adventurer_class, Enums.AdventurerClass.ALCHEMIST)
	assert_eq(restored.level, 12)
	assert_eq(restored.xp, 200)
	assert_typeof(restored.level, TYPE_INT, "Level should be int after deserialization")
	assert_typeof(restored.xp, TYPE_INT, "XP should be int after deserialization")


func test_from_dict_missing_keys_uses_defaults() -> void:
	var partial: Dictionary = { "id": "partial-hero" }
	var adv: AdventurerData = AdventurerData.from_dict(partial)
	assert_eq(adv.id, "partial-hero")
	assert_eq(adv.display_name, "", "Missing display_name should default to empty")
	assert_eq(adv.level, 1, "Missing level should default to 1")
	assert_eq(adv.xp, 0, "Missing xp should default to 0")
	assert_true(adv.is_available, "Missing is_available should default to true")


func test_from_dict_empty_dict_no_crash() -> void:
	var adv: AdventurerData = AdventurerData.from_dict({})
	assert_not_null(adv, "from_dict({}) should not crash and should return an instance")
	assert_eq(adv.level, 1)
	assert_eq(adv.xp, 0)


func test_from_dict_invalid_class_defaults_to_warrior() -> void:
	var d: Dictionary = _create_adventurer().to_dict()
	d["adventurer_class"] = 99
	var adv: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(adv.adventurer_class, Enums.AdventurerClass.WARRIOR, "Invalid class should default to WARRIOR")
	assert_push_error_count(1)


func test_from_dict_extra_keys_are_ignored() -> void:
	var d: Dictionary = _create_adventurer().to_dict()
	d["unknown_field"] = "should be ignored"
	d["another_unknown"] = 42
	var adv: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(adv.to_dict().has("unknown_field"), false, "Extra keys should not appear in to_dict()")


func test_from_dict_json_round_trip() -> void:
	var original: AdventurerData = _create_adventurer(Enums.AdventurerClass.SENTINEL, "Iron Wall", "sent-01")
	original.level = 16
	original.xp = 300
	var json_str: String = JSON.stringify(original.to_dict())
	var parsed: Dictionary = JSON.parse_string(json_str)
	var restored: AdventurerData = AdventurerData.from_dict(parsed)
	assert_eq(restored.display_name, "Iron Wall")
	assert_eq(restored.adventurer_class, Enums.AdventurerClass.SENTINEL)
	assert_eq(restored.level, 16)
	assert_eq(restored.xp, 300)
	assert_eq(restored.get_level_tier(), Enums.LevelTier.ELITE)


# =============================================================================
# SECTION I: GAMECONFIG CONSTANTS
# =============================================================================

func test_game_config_base_stats_exists() -> void:
	assert_not_null(GameConfig.BASE_STATS, "GameConfig.BASE_STATS should exist")
	assert_typeof(GameConfig.BASE_STATS, TYPE_DICTIONARY, "BASE_STATS should be a Dictionary")


func test_game_config_xp_curve_exists() -> void:
	assert_not_null(GameConfig.XP_CURVE, "GameConfig.XP_CURVE should exist")
	assert_eq(GameConfig.XP_CURVE["BASE_XP"], 100, "BASE_XP should be 100")
	assert_eq(GameConfig.XP_CURVE["GROWTH_RATE"], 1.15, "GROWTH_RATE should be 1.15")


func test_game_config_xp_per_tier_exists() -> void:
	assert_not_null(GameConfig.XP_PER_TIER, "GameConfig.XP_PER_TIER should exist")
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE], 0)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED], 100)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN], 350)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE], 750)


# =============================================================================
# SECTION J: EDGE CASES & STRESS
# =============================================================================

func test_gain_xp_from_high_level() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 50
	var threshold: int = adv.xp_to_next_level()
	var leveled: bool = adv.gain_xp(threshold)
	assert_true(leveled, "Should still be able to level up at level 50")
	assert_eq(adv.level, 51)
	assert_eq(adv.xp, 0)


func test_many_small_xp_gains() -> void:
	var adv: AdventurerData = _create_adventurer()
	for i in range(100):
		adv.gain_xp(1)
	assert_eq(adv.level, 2, "100 XP in single-point increments should reach level 2")
	assert_eq(adv.xp, 0, "XP should be exactly 0 after reaching level 2 threshold")


func test_availability_toggle() -> void:
	var adv: AdventurerData = _create_adventurer()
	assert_true(adv.is_available)
	adv.is_available = false
	assert_false(adv.is_available)
	adv.is_available = true
	assert_true(adv.is_available)


func test_equipment_slot_assignment() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.equipment["weapon"] = "sword_001"
	adv.equipment["armor"] = "plate_001"
	adv.equipment["accessory"] = "ring_001"
	assert_eq(adv.equipment["weapon"], "sword_001")
	assert_eq(adv.equipment["armor"], "plate_001")
	assert_eq(adv.equipment["accessory"], "ring_001")


func test_equipment_survives_serialization() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.equipment["weapon"] = "bow_003"
	var d: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(restored.equipment["weapon"], "bow_003", "Equipment should survive serialization")
	assert_null(restored.equipment["armor"], "Unset slots should remain null")
