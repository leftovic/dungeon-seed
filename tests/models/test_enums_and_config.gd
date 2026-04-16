## tests/models/test_enums_and_config.gd
## GUT test suite for TASK-003: Enums, Constants & Data Dictionary
## Covers: enums.gd (all 10 enums) and game_config.gd (all 9 const dictionaries + helpers)
extends GutTest


# ---------------------------------------------------------------------------
# Section A: Enum Existence and Value Tests
# ---------------------------------------------------------------------------

func test_seed_rarity_values() -> void:
	assert_eq(Enums.SeedRarity.COMMON, 0, "SeedRarity.COMMON should be 0")
	assert_eq(Enums.SeedRarity.UNCOMMON, 1, "SeedRarity.UNCOMMON should be 1")
	assert_eq(Enums.SeedRarity.RARE, 2, "SeedRarity.RARE should be 2")
	assert_eq(Enums.SeedRarity.EPIC, 3, "SeedRarity.EPIC should be 3")
	assert_eq(Enums.SeedRarity.LEGENDARY, 4, "SeedRarity.LEGENDARY should be 4")


func test_seed_rarity_count() -> void:
	assert_eq(Enums.SeedRarity.size(), 5, "SeedRarity should have exactly 5 values")


func test_element_values() -> void:
	assert_eq(Enums.Element.TERRA, 0, "Element.TERRA should be 0")
	assert_eq(Enums.Element.FLAME, 1, "Element.FLAME should be 1")
	assert_eq(Enums.Element.FROST, 2, "Element.FROST should be 2")
	assert_eq(Enums.Element.ARCANE, 3, "Element.ARCANE should be 3")
	assert_eq(Enums.Element.SHADOW, 4, "Element.SHADOW should be 4")
	assert_eq(Enums.Element.NONE, 5, "Element.NONE should be 5")


func test_element_count() -> void:
	assert_eq(Enums.Element.size(), 6, "Element should have exactly 6 values (including NONE)")


func test_seed_phase_values() -> void:
	assert_eq(Enums.SeedPhase.SPORE, 0, "SeedPhase.SPORE should be 0")
	assert_eq(Enums.SeedPhase.SPROUT, 1, "SeedPhase.SPROUT should be 1")
	assert_eq(Enums.SeedPhase.BUD, 2, "SeedPhase.BUD should be 2")
	assert_eq(Enums.SeedPhase.BLOOM, 3, "SeedPhase.BLOOM should be 3")


func test_seed_phase_count() -> void:
	assert_eq(Enums.SeedPhase.size(), 4, "SeedPhase should have exactly 4 values")


func test_room_type_values() -> void:
	assert_eq(Enums.RoomType.COMBAT, 0, "RoomType.COMBAT should be 0")
	assert_eq(Enums.RoomType.TREASURE, 1, "RoomType.TREASURE should be 1")
	assert_eq(Enums.RoomType.TRAP, 2, "RoomType.TRAP should be 2")
	assert_eq(Enums.RoomType.PUZZLE, 3, "RoomType.PUZZLE should be 3")
	assert_eq(Enums.RoomType.REST, 4, "RoomType.REST should be 4")
	assert_eq(Enums.RoomType.BOSS, 5, "RoomType.BOSS should be 5")


func test_room_type_count() -> void:
	assert_eq(Enums.RoomType.size(), 8, "RoomType should have exactly 8 values")


func test_adventurer_class_values() -> void:
	assert_eq(Enums.AdventurerClass.WARRIOR, 0, "AdventurerClass.WARRIOR should be 0")
	assert_eq(Enums.AdventurerClass.RANGER, 1, "AdventurerClass.RANGER should be 1")
	assert_eq(Enums.AdventurerClass.MAGE, 2, "AdventurerClass.MAGE should be 2")
	assert_eq(Enums.AdventurerClass.ROGUE, 3, "AdventurerClass.ROGUE should be 3")
	assert_eq(Enums.AdventurerClass.ALCHEMIST, 4, "AdventurerClass.ALCHEMIST should be 4")
	assert_eq(Enums.AdventurerClass.SENTINEL, 5, "AdventurerClass.SENTINEL should be 5")


func test_adventurer_class_count() -> void:
	assert_eq(Enums.AdventurerClass.size(), 6, "AdventurerClass should have exactly 6 values")


func test_level_tier_values() -> void:
	assert_eq(Enums.LevelTier.NOVICE, 0, "LevelTier.NOVICE should be 0")
	assert_eq(Enums.LevelTier.SKILLED, 1, "LevelTier.SKILLED should be 1")
	assert_eq(Enums.LevelTier.VETERAN, 2, "LevelTier.VETERAN should be 2")
	assert_eq(Enums.LevelTier.ELITE, 3, "LevelTier.ELITE should be 3")


func test_level_tier_count() -> void:
	assert_eq(Enums.LevelTier.size(), 4, "LevelTier should have exactly 4 values")


func test_item_rarity_values() -> void:
	assert_eq(Enums.ItemRarity.COMMON, 0, "ItemRarity.COMMON should be 0")
	assert_eq(Enums.ItemRarity.UNCOMMON, 1, "ItemRarity.UNCOMMON should be 1")
	assert_eq(Enums.ItemRarity.RARE, 2, "ItemRarity.RARE should be 2")
	assert_eq(Enums.ItemRarity.EPIC, 3, "ItemRarity.EPIC should be 3")
	assert_eq(Enums.ItemRarity.LEGENDARY, 4, "ItemRarity.LEGENDARY should be 4")


func test_item_rarity_count() -> void:
	assert_eq(Enums.ItemRarity.size(), 5, "ItemRarity should have exactly 5 values")


func test_equip_slot_values() -> void:
	assert_eq(Enums.EquipSlot.NONE, -1, "EquipSlot.NONE should be -1")
	assert_eq(Enums.EquipSlot.WEAPON, 0, "EquipSlot.WEAPON should be 0")
	assert_eq(Enums.EquipSlot.ARMOR, 1, "EquipSlot.ARMOR should be 1")
	assert_eq(Enums.EquipSlot.ACCESSORY, 2, "EquipSlot.ACCESSORY should be 2")


func test_equip_slot_count() -> void:
	assert_eq(Enums.EquipSlot.size(), 4, "EquipSlot should have exactly 4 values (NONE, WEAPON, ARMOR, ACCESSORY)")


func test_currency_values() -> void:
	assert_eq(Enums.Currency.GOLD, 0, "Currency.GOLD should be 0")
	assert_eq(Enums.Currency.ESSENCE, 1, "Currency.ESSENCE should be 1")
	assert_eq(Enums.Currency.FRAGMENTS, 2, "Currency.FRAGMENTS should be 2")
	assert_eq(Enums.Currency.ARTIFACTS, 3, "Currency.ARTIFACTS should be 3")


func test_currency_count() -> void:
	assert_eq(Enums.Currency.size(), 4, "Currency should have exactly 4 values")


func test_expedition_status_values() -> void:
	assert_eq(Enums.ExpeditionStatus.PREPARING, 0, "ExpeditionStatus.PREPARING should be 0")
	assert_eq(Enums.ExpeditionStatus.IN_PROGRESS, 1, "ExpeditionStatus.IN_PROGRESS should be 1")
	assert_eq(Enums.ExpeditionStatus.COMPLETED, 2, "ExpeditionStatus.COMPLETED should be 2")
	assert_eq(Enums.ExpeditionStatus.FAILED, 3, "ExpeditionStatus.FAILED should be 3")


func test_expedition_status_count() -> void:
	assert_eq(Enums.ExpeditionStatus.size(), 4, "ExpeditionStatus should have exactly 4 values")


# ---------------------------------------------------------------------------
# Section B: GameConfig Dictionary Completeness Tests
# ---------------------------------------------------------------------------

func test_base_growth_seconds_completeness() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.BASE_GROWTH_SECONDS.has(rarity_value),
			"BASE_GROWTH_SECONDS missing key for SeedRarity value %d" % rarity_value
		)


func test_base_growth_seconds_values() -> void:
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON], 60)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON], 120)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE], 300)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC], 600)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY], 1200)


func test_base_growth_seconds_positive() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_gt(
			GameConfig.BASE_GROWTH_SECONDS[rarity_value], 0,
			"BASE_GROWTH_SECONDS must be positive for rarity %d" % rarity_value
		)


func test_base_growth_seconds_monotonically_increasing() -> void:
	var values: Array = Enums.SeedRarity.values()
	for i: int in range(1, values.size()):
		assert_gt(
			GameConfig.BASE_GROWTH_SECONDS[values[i]],
			GameConfig.BASE_GROWTH_SECONDS[values[i - 1]],
			"BASE_GROWTH_SECONDS should increase with rarity"
		)


func test_xp_per_tier_completeness() -> void:
	for tier_value: int in Enums.LevelTier.values():
		assert_true(
			GameConfig.XP_PER_TIER.has(tier_value),
			"XP_PER_TIER missing key for LevelTier value %d" % tier_value
		)


func test_xp_per_tier_values() -> void:
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE], 0)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED], 100)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN], 350)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE], 750)


func test_xp_per_tier_monotonically_increasing() -> void:
	var values: Array = Enums.LevelTier.values()
	for i: int in range(1, values.size()):
		assert_gt(
			GameConfig.XP_PER_TIER[values[i]],
			GameConfig.XP_PER_TIER[values[i - 1]],
			"XP_PER_TIER should be monotonically increasing"
		)


func test_base_stats_completeness() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		assert_true(
			GameConfig.BASE_STATS.has(cls_value),
			"BASE_STATS missing key for AdventurerClass value %d" % cls_value
		)


func test_base_stats_required_keys() -> void:
	var required_keys: Array[String] = ["health", "attack", "defense", "speed", "utility"]
	for cls_value: int in Enums.AdventurerClass.values():
		var stats: Dictionary = GameConfig.BASE_STATS[cls_value]
		for key: String in required_keys:
			assert_true(
				stats.has(key),
				"BASE_STATS[%d] missing key '%s'" % [cls_value, key]
			)


func test_base_stats_all_positive() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		var stats: Dictionary = GameConfig.BASE_STATS[cls_value]
		for key: String in stats.keys():
			assert_gt(
				stats[key], 0,
				"BASE_STATS[%d]['%s'] must be positive" % [cls_value, key]
			)


func test_base_stats_exactly_five_keys() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		assert_eq(
			GameConfig.BASE_STATS[cls_value].size(), 5,
			"BASE_STATS[%d] should have exactly 5 keys" % cls_value
		)


func test_mutation_slots_completeness() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.MUTATION_SLOTS.has(rarity_value),
			"MUTATION_SLOTS missing key for SeedRarity value %d" % rarity_value
		)


func test_mutation_slots_values() -> void:
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.COMMON], 1)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.UNCOMMON], 2)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.RARE], 3)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.EPIC], 4)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.LEGENDARY], 5)


func test_mutation_slots_monotonically_increasing() -> void:
	var values: Array = Enums.SeedRarity.values()
	for i: int in range(1, values.size()):
		assert_gt(
			GameConfig.MUTATION_SLOTS[values[i]],
			GameConfig.MUTATION_SLOTS[values[i - 1]],
			"MUTATION_SLOTS should increase with rarity"
		)


func test_currency_earn_rates_completeness() -> void:
	for curr_value: int in Enums.Currency.values():
		assert_true(
			GameConfig.CURRENCY_EARN_RATES.has(curr_value),
			"CURRENCY_EARN_RATES missing key for Currency value %d" % curr_value
		)


func test_currency_earn_rates_non_negative() -> void:
	for curr_value: int in Enums.Currency.values():
		assert_true(
			GameConfig.CURRENCY_EARN_RATES[curr_value] >= 0,
			"CURRENCY_EARN_RATES must be non-negative for currency %d" % curr_value
		)


func test_room_difficulty_scale_completeness() -> void:
	for room_value: int in Enums.RoomType.values():
		assert_true(
			GameConfig.ROOM_DIFFICULTY_SCALE.has(room_value),
			"ROOM_DIFFICULTY_SCALE missing key for RoomType value %d" % room_value
		)


func test_room_difficulty_scale_non_negative() -> void:
	## DEVIATION from ticket: Changed from assert_gt(> 0.0) to assert_true(>= 0.0)
	## because REST rooms have difficulty scale 0.0 (no combat), which is correct
	## per GDD §4.2 and the reference implementation in ticket Section 16.2.
	for room_value: int in Enums.RoomType.values():
		assert_true(
			GameConfig.ROOM_DIFFICULTY_SCALE[room_value] >= 0.0,
			"ROOM_DIFFICULTY_SCALE must be non-negative for room type %d" % room_value
		)


func test_phase_growth_multipliers_completeness() -> void:
	for phase_value: int in Enums.SeedPhase.values():
		assert_true(
			GameConfig.PHASE_GROWTH_MULTIPLIERS.has(phase_value),
			"PHASE_GROWTH_MULTIPLIERS missing key for SeedPhase value %d" % phase_value
		)


func test_phase_growth_multipliers_positive() -> void:
	for phase_value: int in Enums.SeedPhase.values():
		assert_gt(
			GameConfig.PHASE_GROWTH_MULTIPLIERS[phase_value], 0.0,
			"PHASE_GROWTH_MULTIPLIERS must be positive for phase %d" % phase_value
		)


func test_element_names_completeness() -> void:
	for elem_value: int in Enums.Element.values():
		assert_true(
			GameConfig.ELEMENT_NAMES.has(elem_value),
			"ELEMENT_NAMES missing key for Element value %d" % elem_value
		)


func test_element_names_non_empty() -> void:
	for elem_value: int in Enums.Element.values():
		assert_ne(
			GameConfig.ELEMENT_NAMES[elem_value], "",
			"ELEMENT_NAMES must not be empty for element %d" % elem_value
		)


func test_rarity_colors_completeness() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.RARITY_COLORS.has(rarity_value),
			"RARITY_COLORS missing key for SeedRarity value %d" % rarity_value
		)


func test_rarity_colors_are_color_type() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.RARITY_COLORS[rarity_value] is Color,
			"RARITY_COLORS[%d] must be a Color instance" % rarity_value
		)


# ---------------------------------------------------------------------------
# Section C: Helper Method Tests
# ---------------------------------------------------------------------------

func test_seed_rarity_name_common() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.COMMON), "Common")


func test_seed_rarity_name_uncommon() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.UNCOMMON), "Uncommon")


func test_seed_rarity_name_rare() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.RARE), "Rare")


func test_seed_rarity_name_epic() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.EPIC), "Epic")


func test_seed_rarity_name_legendary() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.LEGENDARY), "Legendary")


func test_get_base_stats_warrior() -> void:
	var stats: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	assert_true(stats.has("health"), "Warrior stats must have 'health'")
	assert_true(stats.has("attack"), "Warrior stats must have 'attack'")
	assert_true(stats.has("defense"), "Warrior stats must have 'defense'")
	assert_true(stats.has("speed"), "Warrior stats must have 'speed'")
	assert_true(stats.has("utility"), "Warrior stats must have 'utility'")
	assert_eq(stats.size(), 5, "Warrior stats should have exactly 5 keys")


func test_get_base_stats_all_classes() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		var stats: Dictionary = GameConfig.get_base_stats(cls_value)
		assert_eq(
			stats.size(), 5,
			"get_base_stats(%d) should return a Dictionary with 5 keys" % cls_value
		)


# ---------------------------------------------------------------------------
# Section D: Remaining Enums Helper Method Tests
# ---------------------------------------------------------------------------

func test_item_rarity_name_all() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.COMMON), "Common")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.UNCOMMON), "Uncommon")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.RARE), "Rare")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.EPIC), "Epic")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.LEGENDARY), "Legendary")


func test_adventurer_class_name_all() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.WARRIOR), "Warrior")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.RANGER), "Ranger")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.MAGE), "Mage")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.ROGUE), "Rogue")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.ALCHEMIST), "Alchemist")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.SENTINEL), "Sentinel")


func test_element_name_all() -> void:
	assert_eq(Enums.element_name(Enums.Element.TERRA), "Terra")
	assert_eq(Enums.element_name(Enums.Element.FLAME), "Flame")
	assert_eq(Enums.element_name(Enums.Element.FROST), "Frost")
	assert_eq(Enums.element_name(Enums.Element.ARCANE), "Arcane")
	assert_eq(Enums.element_name(Enums.Element.SHADOW), "Shadow")
	assert_eq(Enums.element_name(Enums.Element.NONE), "None")


func test_equip_slot_name_all() -> void:
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.NONE), "None")
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.WEAPON), "Weapon")
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.ARMOR), "Armor")
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.ACCESSORY), "Accessory")


# ---------------------------------------------------------------------------
# Section E: Remaining GameConfig Helper Method Tests
# ---------------------------------------------------------------------------

func test_get_growth_seconds_all() -> void:
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.COMMON), 60)
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.UNCOMMON), 120)
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.RARE), 300)
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.EPIC), 600)
	assert_eq(GameConfig.get_growth_seconds(Enums.SeedRarity.LEGENDARY), 1200)


func test_get_mutation_slots_all() -> void:
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.COMMON), 1)
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.UNCOMMON), 2)
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.RARE), 3)
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.EPIC), 4)
	assert_eq(GameConfig.get_mutation_slots(Enums.SeedRarity.LEGENDARY), 5)


func test_get_xp_for_tier_all() -> void:
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.NOVICE), 0)
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.SKILLED), 100)
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.VETERAN), 350)
	assert_eq(GameConfig.get_xp_for_tier(Enums.LevelTier.ELITE), 750)


func test_get_rarity_color_type() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		var color: Color = GameConfig.get_rarity_color(rarity_value)
		assert_true(color is Color, "get_rarity_color(%d) should return a Color" % rarity_value)


func test_get_room_difficulty_all() -> void:
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.COMBAT), 1.0)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.TREASURE), 0.5)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.TRAP), 0.8)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.PUZZLE), 0.6)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.REST), 0.0)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.BOSS), 2.0)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.ENTRANCE), 0.0)
	assert_eq(GameConfig.get_room_difficulty(Enums.RoomType.SECRET), 1.2)


func test_get_phase_multiplier_all() -> void:
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.SPORE), 1.0)
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.SPROUT), 1.5)
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.BUD), 2.0)
	assert_eq(GameConfig.get_phase_multiplier(Enums.SeedPhase.BLOOM), 3.0)


func test_get_base_stats_returns_copy() -> void:
	## Verify get_base_stats returns a duplicate, not a reference to the const
	var stats_a: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	var stats_b: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	stats_a["health"] = 999
	assert_ne(
		stats_a["health"], stats_b["health"],
		"get_base_stats must return independent copies"
	)


func test_get_base_stats_warrior_exact_values() -> void:
	var stats: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	assert_eq(stats["health"], 120, "Warrior health should be 120")
	assert_eq(stats["attack"], 18, "Warrior attack should be 18")
	assert_eq(stats["defense"], 15, "Warrior defense should be 15")
	assert_eq(stats["speed"], 8, "Warrior speed should be 8")
	assert_eq(stats["utility"], 5, "Warrior utility should be 5")
