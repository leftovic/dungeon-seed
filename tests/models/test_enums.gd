## tests/models/test_enums.gd
## Comprehensive GUT test suite for TASK-003a: Enums — Game-Wide Enumerations
## Covers: All 10 enums, their values and counts, and all 5 helper methods
extends GutTest


# ---------------------------------------------------------------------------
# Section A: Enum Existence and Value Tests
# ---------------------------------------------------------------------------

# —— SeedRarity Tests ——

func test_seed_rarity_values() -> void:
	assert_eq(Enums.SeedRarity.COMMON, 0, "SeedRarity.COMMON should be 0")
	assert_eq(Enums.SeedRarity.UNCOMMON, 1, "SeedRarity.UNCOMMON should be 1")
	assert_eq(Enums.SeedRarity.RARE, 2, "SeedRarity.RARE should be 2")
	assert_eq(Enums.SeedRarity.EPIC, 3, "SeedRarity.EPIC should be 3")
	assert_eq(Enums.SeedRarity.LEGENDARY, 4, "SeedRarity.LEGENDARY should be 4")


func test_seed_rarity_count() -> void:
	assert_eq(Enums.SeedRarity.size(), 5, "SeedRarity should have exactly 5 values")


# —— Element Tests ——

func test_element_values() -> void:
	assert_eq(Enums.Element.TERRA, 0, "Element.TERRA should be 0")
	assert_eq(Enums.Element.FLAME, 1, "Element.FLAME should be 1")
	assert_eq(Enums.Element.FROST, 2, "Element.FROST should be 2")
	assert_eq(Enums.Element.ARCANE, 3, "Element.ARCANE should be 3")
	assert_eq(Enums.Element.SHADOW, 4, "Element.SHADOW should be 4")
	assert_eq(Enums.Element.NONE, 5, "Element.NONE should be 5")


func test_element_count() -> void:
	assert_eq(Enums.Element.size(), 6, "Element should have exactly 6 values (including NONE)")


# —— SeedPhase Tests ——

func test_seed_phase_values() -> void:
	assert_eq(Enums.SeedPhase.SPORE, 0, "SeedPhase.SPORE should be 0")
	assert_eq(Enums.SeedPhase.SPROUT, 1, "SeedPhase.SPROUT should be 1")
	assert_eq(Enums.SeedPhase.BUD, 2, "SeedPhase.BUD should be 2")
	assert_eq(Enums.SeedPhase.BLOOM, 3, "SeedPhase.BLOOM should be 3")


func test_seed_phase_count() -> void:
	assert_eq(Enums.SeedPhase.size(), 4, "SeedPhase should have exactly 4 values")


# —— RoomType Tests ——

func test_room_type_values() -> void:
	assert_eq(Enums.RoomType.COMBAT, 0, "RoomType.COMBAT should be 0")
	assert_eq(Enums.RoomType.TREASURE, 1, "RoomType.TREASURE should be 1")
	assert_eq(Enums.RoomType.TRAP, 2, "RoomType.TRAP should be 2")
	assert_eq(Enums.RoomType.PUZZLE, 3, "RoomType.PUZZLE should be 3")
	assert_eq(Enums.RoomType.REST, 4, "RoomType.REST should be 4")
	assert_eq(Enums.RoomType.BOSS, 5, "RoomType.BOSS should be 5")
	assert_eq(Enums.RoomType.ENTRANCE, 6, "RoomType.ENTRANCE should be 6")
	assert_eq(Enums.RoomType.SECRET, 7, "RoomType.SECRET should be 7")


func test_room_type_count() -> void:
	assert_eq(Enums.RoomType.size(), 8, "RoomType should have exactly 8 values")


# —— AdventurerClass Tests ——

func test_adventurer_class_values() -> void:
	assert_eq(Enums.AdventurerClass.WARRIOR, 0, "AdventurerClass.WARRIOR should be 0")
	assert_eq(Enums.AdventurerClass.RANGER, 1, "AdventurerClass.RANGER should be 1")
	assert_eq(Enums.AdventurerClass.MAGE, 2, "AdventurerClass.MAGE should be 2")
	assert_eq(Enums.AdventurerClass.ROGUE, 3, "AdventurerClass.ROGUE should be 3")
	assert_eq(Enums.AdventurerClass.ALCHEMIST, 4, "AdventurerClass.ALCHEMIST should be 4")
	assert_eq(Enums.AdventurerClass.SENTINEL, 5, "AdventurerClass.SENTINEL should be 5")


func test_adventurer_class_count() -> void:
	assert_eq(Enums.AdventurerClass.size(), 6, "AdventurerClass should have exactly 6 values")


# —— LevelTier Tests ——

func test_level_tier_values() -> void:
	assert_eq(Enums.LevelTier.NOVICE, 0, "LevelTier.NOVICE should be 0")
	assert_eq(Enums.LevelTier.SKILLED, 1, "LevelTier.SKILLED should be 1")
	assert_eq(Enums.LevelTier.VETERAN, 2, "LevelTier.VETERAN should be 2")
	assert_eq(Enums.LevelTier.ELITE, 3, "LevelTier.ELITE should be 3")


func test_level_tier_count() -> void:
	assert_eq(Enums.LevelTier.size(), 4, "LevelTier should have exactly 4 values")


# —— ItemRarity Tests ——

func test_item_rarity_values() -> void:
	assert_eq(Enums.ItemRarity.COMMON, 0, "ItemRarity.COMMON should be 0")
	assert_eq(Enums.ItemRarity.UNCOMMON, 1, "ItemRarity.UNCOMMON should be 1")
	assert_eq(Enums.ItemRarity.RARE, 2, "ItemRarity.RARE should be 2")
	assert_eq(Enums.ItemRarity.EPIC, 3, "ItemRarity.EPIC should be 3")
	assert_eq(Enums.ItemRarity.LEGENDARY, 4, "ItemRarity.LEGENDARY should be 4")


func test_item_rarity_count() -> void:
	assert_eq(Enums.ItemRarity.size(), 5, "ItemRarity should have exactly 5 values")


# —— EquipSlot Tests ——

func test_equip_slot_values() -> void:
	assert_eq(Enums.EquipSlot.NONE, -1, "EquipSlot.NONE should be -1")
	assert_eq(Enums.EquipSlot.WEAPON, 0, "EquipSlot.WEAPON should be 0")
	assert_eq(Enums.EquipSlot.ARMOR, 1, "EquipSlot.ARMOR should be 1")
	assert_eq(Enums.EquipSlot.ACCESSORY, 2, "EquipSlot.ACCESSORY should be 2")


func test_equip_slot_count() -> void:
	assert_eq(Enums.EquipSlot.size(), 4, "EquipSlot should have exactly 4 values (NONE, WEAPON, ARMOR, ACCESSORY)")


# —— Currency Tests ——

func test_currency_values() -> void:
	assert_eq(Enums.Currency.GOLD, 0, "Currency.GOLD should be 0")
	assert_eq(Enums.Currency.ESSENCE, 1, "Currency.ESSENCE should be 1")
	assert_eq(Enums.Currency.FRAGMENTS, 2, "Currency.FRAGMENTS should be 2")
	assert_eq(Enums.Currency.ARTIFACTS, 3, "Currency.ARTIFACTS should be 3")


func test_currency_count() -> void:
	assert_eq(Enums.Currency.size(), 4, "Currency should have exactly 4 values")


# —— ExpeditionStatus Tests ——

func test_expedition_status_values() -> void:
	assert_eq(Enums.ExpeditionStatus.PREPARING, 0, "ExpeditionStatus.PREPARING should be 0")
	assert_eq(Enums.ExpeditionStatus.IN_PROGRESS, 1, "ExpeditionStatus.IN_PROGRESS should be 1")
	assert_eq(Enums.ExpeditionStatus.COMPLETED, 2, "ExpeditionStatus.COMPLETED should be 2")
	assert_eq(Enums.ExpeditionStatus.FAILED, 3, "ExpeditionStatus.FAILED should be 3")


func test_expedition_status_count() -> void:
	assert_eq(Enums.ExpeditionStatus.size(), 4, "ExpeditionStatus should have exactly 4 values")


# ---------------------------------------------------------------------------
# Section D: Helper Method Tests
# ---------------------------------------------------------------------------

# —— seed_rarity_name() tests ——

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


func test_seed_rarity_name_invalid() -> void:
	assert_eq(Enums.seed_rarity_name(999), "Unknown", "Invalid SeedRarity should return 'Unknown'")


# —— item_rarity_name() tests ——

func test_item_rarity_name_common() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.COMMON), "Common")


func test_item_rarity_name_uncommon() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.UNCOMMON), "Uncommon")


func test_item_rarity_name_rare() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.RARE), "Rare")


func test_item_rarity_name_epic() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.EPIC), "Epic")


func test_item_rarity_name_legendary() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.LEGENDARY), "Legendary")


func test_item_rarity_name_invalid() -> void:
	assert_eq(Enums.item_rarity_name(999), "Unknown", "Invalid ItemRarity should return 'Unknown'")


# —— adventurer_class_name() tests ——

func test_adventurer_class_name_warrior() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.WARRIOR), "Warrior")


func test_adventurer_class_name_ranger() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.RANGER), "Ranger")


func test_adventurer_class_name_mage() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.MAGE), "Mage")


func test_adventurer_class_name_rogue() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.ROGUE), "Rogue")


func test_adventurer_class_name_alchemist() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.ALCHEMIST), "Alchemist")


func test_adventurer_class_name_sentinel() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.SENTINEL), "Sentinel")


func test_adventurer_class_name_invalid() -> void:
	assert_eq(Enums.adventurer_class_name(999), "Unknown", "Invalid AdventurerClass should return 'Unknown'")


# —— element_name() tests ——

func test_element_name_terra() -> void:
	assert_eq(Enums.element_name(Enums.Element.TERRA), "Terra")


func test_element_name_flame() -> void:
	assert_eq(Enums.element_name(Enums.Element.FLAME), "Flame")


func test_element_name_frost() -> void:
	assert_eq(Enums.element_name(Enums.Element.FROST), "Frost")


func test_element_name_arcane() -> void:
	assert_eq(Enums.element_name(Enums.Element.ARCANE), "Arcane")


func test_element_name_shadow() -> void:
	assert_eq(Enums.element_name(Enums.Element.SHADOW), "Shadow")


func test_element_name_none() -> void:
	assert_eq(Enums.element_name(Enums.Element.NONE), "None")


func test_element_name_invalid() -> void:
	assert_eq(Enums.element_name(999), "Unknown", "Invalid Element should return 'Unknown'")


# —— equip_slot_name() tests ——

func test_equip_slot_name_none() -> void:
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.NONE), "None")


func test_equip_slot_name_weapon() -> void:
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.WEAPON), "Weapon")


func test_equip_slot_name_armor() -> void:
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.ARMOR), "Armor")


func test_equip_slot_name_accessory() -> void:
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.ACCESSORY), "Accessory")


func test_equip_slot_name_invalid() -> void:
	assert_eq(Enums.equip_slot_name(999), "Unknown", "Invalid EquipSlot should return 'Unknown'")
