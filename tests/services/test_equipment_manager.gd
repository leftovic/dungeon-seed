extends GutTest
## Tests for EquipmentManager — equip/unequip service with stat calculation.
##
## Covers: equip valid items, equip invalid items, unequip, stat calculation,
## query helpers, swap, unequip_all, edge cases, and serialization round-trips.

const EquipmentManagerClass = preload("res://src/services/equipment_manager.gd")

var mgr: EquipmentManagerClass
var db: ItemDatabase
var adv: AdventurerData


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_adventurer(cls: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR) -> AdventurerData:
	var a := AdventurerData.new()
	a.id = "test_adv_%d" % randi()
	a.display_name = "Test Adventurer"
	a.adventurer_class = cls
	a.level = 1
	a.initialize_base_stats()
	return a


func _make_custom_item(id: String, slot: Enums.EquipSlot, bonuses: Dictionary) -> void:
	var data: Dictionary = {
		"id": id,
		"display_name": "Test Item %s" % id,
		"rarity": Enums.ItemRarity.COMMON,
		"slot": int(slot),
		"stat_bonuses": bonuses,
		"description": "Test item for unit tests.",
	}
	db.register_item(ItemData.new(data))


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func before_each() -> void:
	mgr = EquipmentManagerClass.new()
	db = ItemDatabase.new()
	adv = _make_adventurer()


# ===========================================================================
# Group 1: Equip Valid Items
# ===========================================================================

func test_equip_weapon_returns_true() -> void:
	var result: bool = mgr.equip(adv, "wooden_sword", db)
	assert_true(result, "Equipping a valid weapon should return true")


func test_equip_weapon_sets_slot() -> void:
	mgr.equip(adv, "iron_sword", db)
	assert_eq(adv.equipment["weapon"], "iron_sword", "Weapon slot should hold iron_sword")


func test_equip_armor_returns_true() -> void:
	var result: bool = mgr.equip(adv, "cloth_tunic", db)
	assert_true(result, "Equipping valid armor should return true")


func test_equip_armor_sets_slot() -> void:
	mgr.equip(adv, "leather_vest", db)
	assert_eq(adv.equipment["armor"], "leather_vest", "Armor slot should hold leather_vest")


func test_equip_accessory_returns_true() -> void:
	var result: bool = mgr.equip(adv, "copper_ring", db)
	assert_true(result, "Equipping valid accessory should return true")


func test_equip_accessory_sets_slot() -> void:
	mgr.equip(adv, "silver_ring", db)
	assert_eq(adv.equipment["accessory"], "silver_ring", "Accessory slot should hold silver_ring")


func test_equip_replaces_existing_weapon() -> void:
	mgr.equip(adv, "wooden_sword", db)
	mgr.equip(adv, "iron_sword", db)
	assert_eq(adv.equipment["weapon"], "iron_sword", "New weapon should replace old one")


func test_equip_replaces_existing_armor() -> void:
	mgr.equip(adv, "cloth_tunic", db)
	mgr.equip(adv, "leather_vest", db)
	assert_eq(adv.equipment["armor"], "leather_vest", "New armor should replace old one")


func test_equip_all_three_slots() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	mgr.equip(adv, "ruby_amulet", db)
	assert_eq(adv.equipment["weapon"], "iron_sword")
	assert_eq(adv.equipment["armor"], "chainmail")
	assert_eq(adv.equipment["accessory"], "ruby_amulet")


# ===========================================================================
# Group 2: Equip Invalid Items
# ===========================================================================

func test_equip_nonexistent_item_returns_false() -> void:
	var result: bool = mgr.equip(adv, "does_not_exist", db)
	assert_false(result, "Equipping a nonexistent item should return false")


func test_equip_nonexistent_does_not_modify_slot() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "does_not_exist", db)
	assert_eq(adv.equipment["weapon"], "iron_sword", "Slot should remain unchanged after failed equip")


func test_equip_non_equippable_item_returns_false() -> void:
	_make_custom_item("quest_item", Enums.EquipSlot.NONE, {})
	var result: bool = mgr.equip(adv, "quest_item", db)
	assert_false(result, "Non-equippable items should fail to equip")


func test_equip_null_adventurer_returns_false() -> void:
	var result: bool = mgr.equip(null, "iron_sword", db)
	assert_false(result, "Null adventurer should return false")


func test_equip_null_database_returns_false() -> void:
	var result: bool = mgr.equip(adv, "iron_sword", null)
	assert_false(result, "Null database should return false")


func test_equip_empty_item_id_returns_false() -> void:
	var result: bool = mgr.equip(adv, "", db)
	assert_false(result, "Empty item ID should return false")


# ===========================================================================
# Group 3: Unequip
# ===========================================================================

func test_unequip_weapon_returns_item_id() -> void:
	mgr.equip(adv, "iron_sword", db)
	var removed: String = mgr.unequip(adv, Enums.EquipSlot.WEAPON)
	assert_eq(removed, "iron_sword", "Unequip should return the removed item's ID")


func test_unequip_clears_slot() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.unequip(adv, Enums.EquipSlot.WEAPON)
	assert_eq(adv.equipment["weapon"], null, "Weapon slot should be null after unequip")


func test_unequip_empty_slot_returns_empty_string() -> void:
	var removed: String = mgr.unequip(adv, Enums.EquipSlot.WEAPON)
	assert_eq(removed, "", "Unequipping an empty slot should return empty string")


func test_unequip_armor() -> void:
	mgr.equip(adv, "chainmail", db)
	var removed: String = mgr.unequip(adv, Enums.EquipSlot.ARMOR)
	assert_eq(removed, "chainmail")
	assert_eq(adv.equipment["armor"], null)


func test_unequip_accessory() -> void:
	mgr.equip(adv, "copper_ring", db)
	var removed: String = mgr.unequip(adv, Enums.EquipSlot.ACCESSORY)
	assert_eq(removed, "copper_ring")
	assert_eq(adv.equipment["accessory"], null)


func test_unequip_null_adventurer_returns_empty() -> void:
	var removed: String = mgr.unequip(null, Enums.EquipSlot.WEAPON)
	assert_eq(removed, "")


func test_unequip_none_slot_returns_empty() -> void:
	var removed: String = mgr.unequip(adv, Enums.EquipSlot.NONE)
	assert_eq(removed, "", "Unequipping NONE slot should return empty string")


# ===========================================================================
# Group 4: Stat Calculation — Base Only
# ===========================================================================

func test_effective_stats_no_equipment_equals_base() -> void:
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	for key: String in GameConfig.STAT_KEYS:
		assert_eq(effective[key], adv.stats[key], "Stat '%s' should equal base with no equipment" % key)


func test_effective_stats_returns_copy_not_reference() -> void:
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	effective["health"] = -999
	assert_ne(adv.stats["health"], -999, "Modifying effective stats should not change base stats")


func test_effective_stats_null_adventurer_returns_empty() -> void:
	var effective: Dictionary = mgr.calculate_effective_stats(null, db)
	assert_eq(effective.size(), 0)


func test_effective_stats_null_database_returns_empty() -> void:
	var effective: Dictionary = mgr.calculate_effective_stats(adv, null)
	assert_eq(effective.size(), 0)


# ===========================================================================
# Group 5: Stat Calculation — With Equipment
# ===========================================================================

func test_effective_stats_weapon_attack_bonus() -> void:
	mgr.equip(adv, "wooden_sword", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# Warrior base attack = 18, wooden_sword attack bonus = 2
	assert_eq(effective["attack"], 18 + 2, "Attack should be base + weapon bonus")


func test_effective_stats_armor_defense_bonus() -> void:
	mgr.equip(adv, "cloth_tunic", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# Warrior base defense = 15, cloth_tunic defense bonus = 2
	assert_eq(effective["defense"], 15 + 2)


func test_effective_stats_accessory_hp_bonus() -> void:
	mgr.equip(adv, "copper_ring", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# copper_ring gives hp: 5 — note: items use "hp" key, base stats use "health"
	# "hp" is a new key introduced by equipment
	assert_eq(effective.get("hp", 0), 5, "HP bonus from accessory should appear in effective stats")


func test_effective_stats_multiple_items_cumulative() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "leather_vest", db)
	mgr.equip(adv, "silver_ring", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# iron_sword: attack +5
	# leather_vest: defense +5
	# silver_ring: hp +12, magic_def +2
	assert_eq(effective["attack"], 18 + 5)
	assert_eq(effective["defense"], 15 + 5)
	assert_eq(effective.get("hp", 0), 12)
	assert_eq(effective.get("magic_def", 0), 2)


func test_effective_stats_chainmail_hp_and_defense() -> void:
	mgr.equip(adv, "chainmail", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# chainmail: defense +10, hp +15
	assert_eq(effective["defense"], 15 + 10)
	assert_eq(effective.get("hp", 0), 15)


func test_effective_stats_crystal_saber_multiple_bonuses() -> void:
	mgr.equip(adv, "crystal_saber", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# crystal_saber: attack +14, crit +5, speed +2
	assert_eq(effective["attack"], 18 + 14)
	assert_eq(effective.get("crit", 0), 5)
	assert_eq(effective["speed"], 8 + 2)


func test_effective_stats_dragon_plate_negative_speed() -> void:
	mgr.equip(adv, "dragon_plate", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# dragon_plate: defense +18, hp +30, speed -3
	assert_eq(effective["defense"], 15 + 18)
	assert_eq(effective.get("hp", 0), 30)
	assert_eq(effective["speed"], 8 - 3)


func test_effective_stats_after_unequip_returns_to_base() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.unequip(adv, Enums.EquipSlot.WEAPON)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	assert_eq(effective["attack"], 18, "Attack should return to base after unequip")


func test_effective_stats_custom_item_all_stat_keys() -> void:
	_make_custom_item("mega_gear", Enums.EquipSlot.WEAPON, {
		"health": 10, "attack": 5, "defense": 3, "speed": 2, "utility": 1,
	})
	mgr.equip(adv, "mega_gear", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	assert_eq(effective["health"], 120 + 10)
	assert_eq(effective["attack"], 18 + 5)
	assert_eq(effective["defense"], 15 + 3)
	assert_eq(effective["speed"], 8 + 2)
	assert_eq(effective["utility"], 5 + 1)


func test_effective_stats_obsidian_charm_all_bonuses() -> void:
	mgr.equip(adv, "obsidian_charm", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# obsidian_charm: attack +8, magic +8, crit +8, speed +5
	assert_eq(effective["attack"], 18 + 8)
	assert_eq(effective.get("magic", 0), 8)
	assert_eq(effective.get("crit", 0), 8)
	assert_eq(effective["speed"], 8 + 5)


func test_effective_stats_full_loadout_epic_gear() -> void:
	mgr.equip(adv, "crystal_saber", db)
	mgr.equip(adv, "dragon_plate", db)
	mgr.equip(adv, "emerald_brooch", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	# crystal_saber: attack +14, crit +5, speed +2
	# dragon_plate: defense +18, hp +30, speed -3
	# emerald_brooch: hp +25, defense +5, magic_def +5
	assert_eq(effective["attack"], 18 + 14)
	assert_eq(effective["defense"], 15 + 18 + 5)
	assert_eq(effective["speed"], 8 + 2 - 3)
	assert_eq(effective.get("hp", 0), 30 + 25)
	assert_eq(effective.get("crit", 0), 5)
	assert_eq(effective.get("magic_def", 0), 5)


# ===========================================================================
# Group 6: Stat Calculation — Different Classes
# ===========================================================================

func test_effective_stats_mage_with_staff() -> void:
	var mage: AdventurerData = _make_adventurer(Enums.AdventurerClass.MAGE)
	mgr.equip(mage, "wooden_staff", db)
	var effective: Dictionary = mgr.calculate_effective_stats(mage, db)
	# Mage base: health 70, attack 12, defense 8, speed 10, utility 20
	# wooden_staff: attack +1, magic +3
	assert_eq(effective["attack"], 12 + 1)
	assert_eq(effective.get("magic", 0), 3)


func test_effective_stats_rogue_base_stats() -> void:
	var rogue: AdventurerData = _make_adventurer(Enums.AdventurerClass.ROGUE)
	var effective: Dictionary = mgr.calculate_effective_stats(rogue, db)
	assert_eq(effective["health"], 75)
	assert_eq(effective["attack"], 16)
	assert_eq(effective["speed"], 18)


# ===========================================================================
# Group 7: get_equipped_items
# ===========================================================================

func test_get_equipped_items_empty() -> void:
	var items: Array[ItemData] = mgr.get_equipped_items(adv, db)
	assert_eq(items.size(), 0, "No items should be equipped initially")


func test_get_equipped_items_one_item() -> void:
	mgr.equip(adv, "iron_sword", db)
	var items: Array[ItemData] = mgr.get_equipped_items(adv, db)
	assert_eq(items.size(), 1)
	assert_eq(items[0].id, "iron_sword")


func test_get_equipped_items_three_items() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	mgr.equip(adv, "ruby_amulet", db)
	var items: Array[ItemData] = mgr.get_equipped_items(adv, db)
	assert_eq(items.size(), 3)
	var ids: Array[String] = []
	for item: ItemData in items:
		ids.append(item.id)
	assert_has(ids, "iron_sword")
	assert_has(ids, "chainmail")
	assert_has(ids, "ruby_amulet")


func test_get_equipped_items_null_adventurer() -> void:
	var items: Array[ItemData] = mgr.get_equipped_items(null, db)
	assert_eq(items.size(), 0)


func test_get_equipped_items_skips_invalid_ids() -> void:
	adv.equipment["weapon"] = "nonexistent_sword"
	var items: Array[ItemData] = mgr.get_equipped_items(adv, db)
	assert_eq(items.size(), 0, "Invalid item IDs should be skipped")


# ===========================================================================
# Group 8: is_slot_empty
# ===========================================================================

func test_is_slot_empty_initially_true() -> void:
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.WEAPON))
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.ARMOR))
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.ACCESSORY))


func test_is_slot_empty_after_equip_false() -> void:
	mgr.equip(adv, "iron_sword", db)
	assert_false(mgr.is_slot_empty(adv, Enums.EquipSlot.WEAPON))


func test_is_slot_empty_after_unequip_true() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.unequip(adv, Enums.EquipSlot.WEAPON)
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.WEAPON))


func test_is_slot_empty_none_slot_returns_true() -> void:
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.NONE))


func test_is_slot_empty_null_adventurer_returns_true() -> void:
	assert_true(mgr.is_slot_empty(null, Enums.EquipSlot.WEAPON))


# ===========================================================================
# Group 9: get_equipped_item_id
# ===========================================================================

func test_get_equipped_item_id_empty_slot() -> void:
	var id: String = mgr.get_equipped_item_id(adv, Enums.EquipSlot.WEAPON)
	assert_eq(id, "")


func test_get_equipped_item_id_after_equip() -> void:
	mgr.equip(adv, "iron_sword", db)
	var id: String = mgr.get_equipped_item_id(adv, Enums.EquipSlot.WEAPON)
	assert_eq(id, "iron_sword")


func test_get_equipped_item_id_null_adventurer() -> void:
	assert_eq(mgr.get_equipped_item_id(null, Enums.EquipSlot.WEAPON), "")


# ===========================================================================
# Group 10: get_equipped_item (returns ItemData)
# ===========================================================================

func test_get_equipped_item_returns_item_data() -> void:
	mgr.equip(adv, "iron_sword", db)
	var item: ItemData = mgr.get_equipped_item(adv, Enums.EquipSlot.WEAPON, db)
	assert_not_null(item)
	assert_eq(item.id, "iron_sword")
	assert_eq(item.display_name, "Iron Sword")


func test_get_equipped_item_empty_slot_returns_null() -> void:
	var item: ItemData = mgr.get_equipped_item(adv, Enums.EquipSlot.WEAPON, db)
	assert_null(item)


# ===========================================================================
# Group 11: get_equipment_summary
# ===========================================================================

func test_get_equipment_summary_empty() -> void:
	var summary: Dictionary = mgr.get_equipment_summary(adv)
	assert_eq(summary["weapon"], null)
	assert_eq(summary["armor"], null)
	assert_eq(summary["accessory"], null)


func test_get_equipment_summary_full() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	mgr.equip(adv, "copper_ring", db)
	var summary: Dictionary = mgr.get_equipment_summary(adv)
	assert_eq(summary["weapon"], "iron_sword")
	assert_eq(summary["armor"], "chainmail")
	assert_eq(summary["accessory"], "copper_ring")


func test_get_equipment_summary_returns_copy() -> void:
	mgr.equip(adv, "iron_sword", db)
	var summary: Dictionary = mgr.get_equipment_summary(adv)
	summary["weapon"] = "modified"
	assert_eq(adv.equipment["weapon"], "iron_sword", "Summary mutation should not affect adventurer")


func test_get_equipment_summary_null_adventurer() -> void:
	var summary: Dictionary = mgr.get_equipment_summary(null)
	assert_eq(summary["weapon"], null)


# ===========================================================================
# Group 12: validate_equip
# ===========================================================================

func test_validate_equip_valid_weapon() -> void:
	assert_true(mgr.validate_equip("iron_sword", Enums.EquipSlot.WEAPON, db))


func test_validate_equip_wrong_slot() -> void:
	assert_false(mgr.validate_equip("iron_sword", Enums.EquipSlot.ARMOR, db),
		"Weapon item should fail validation for armor slot")


func test_validate_equip_nonexistent_item() -> void:
	assert_false(mgr.validate_equip("nope", Enums.EquipSlot.WEAPON, db))


func test_validate_equip_non_equippable() -> void:
	_make_custom_item("material", Enums.EquipSlot.NONE, {})
	assert_false(mgr.validate_equip("material", Enums.EquipSlot.WEAPON, db))


func test_validate_equip_null_database() -> void:
	assert_false(mgr.validate_equip("iron_sword", Enums.EquipSlot.WEAPON, null))


func test_validate_equip_armor_in_armor_slot() -> void:
	assert_true(mgr.validate_equip("chainmail", Enums.EquipSlot.ARMOR, db))


func test_validate_equip_accessory_in_accessory_slot() -> void:
	assert_true(mgr.validate_equip("ruby_amulet", Enums.EquipSlot.ACCESSORY, db))


# ===========================================================================
# Group 13: swap_equipment
# ===========================================================================

func test_swap_equipment_empty_slot() -> void:
	var old_id: String = mgr.swap_equipment(adv, "iron_sword", db)
	assert_eq(old_id, "", "Swap on empty slot returns empty string")
	assert_eq(adv.equipment["weapon"], "iron_sword")


func test_swap_equipment_replaces_item() -> void:
	mgr.equip(adv, "wooden_sword", db)
	var old_id: String = mgr.swap_equipment(adv, "iron_sword", db)
	assert_eq(old_id, "wooden_sword", "Swap should return previous item ID")
	assert_eq(adv.equipment["weapon"], "iron_sword")


func test_swap_equipment_invalid_item_returns_empty() -> void:
	mgr.equip(adv, "wooden_sword", db)
	var old_id: String = mgr.swap_equipment(adv, "nonexistent", db)
	assert_eq(old_id, "")
	assert_eq(adv.equipment["weapon"], "wooden_sword", "Equipment should not change on failed swap")


func test_swap_equipment_null_adventurer() -> void:
	var old_id: String = mgr.swap_equipment(null, "iron_sword", db)
	assert_eq(old_id, "")


# ===========================================================================
# Group 14: unequip_all
# ===========================================================================

func test_unequip_all_no_equipment() -> void:
	var removed: Array[String] = mgr.unequip_all(adv)
	assert_eq(removed.size(), 0)


func test_unequip_all_three_items() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	mgr.equip(adv, "ruby_amulet", db)
	var removed: Array[String] = mgr.unequip_all(adv)
	assert_eq(removed.size(), 3)
	assert_has(removed, "iron_sword")
	assert_has(removed, "chainmail")
	assert_has(removed, "ruby_amulet")
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.WEAPON))
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.ARMOR))
	assert_true(mgr.is_slot_empty(adv, Enums.EquipSlot.ACCESSORY))


func test_unequip_all_partial_equipment() -> void:
	mgr.equip(adv, "iron_sword", db)
	var removed: Array[String] = mgr.unequip_all(adv)
	assert_eq(removed.size(), 1)
	assert_eq(removed[0], "iron_sword")


func test_unequip_all_null_adventurer() -> void:
	var removed: Array[String] = mgr.unequip_all(null)
	assert_eq(removed.size(), 0)


func test_unequip_all_stats_return_to_base() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	mgr.unequip_all(adv)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	assert_eq(effective["attack"], 18, "Attack should be base after unequip_all")
	assert_eq(effective["defense"], 15, "Defense should be base after unequip_all")


# ===========================================================================
# Group 15: Serialization Round-Trip
# ===========================================================================

func test_equipped_items_survive_serialization() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	mgr.equip(adv, "ruby_amulet", db)

	var serialized: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(serialized)

	assert_eq(restored.equipment["weapon"], "iron_sword")
	assert_eq(restored.equipment["armor"], "chainmail")
	assert_eq(restored.equipment["accessory"], "ruby_amulet")


func test_effective_stats_consistent_after_round_trip() -> void:
	mgr.equip(adv, "crystal_saber", db)

	var before: Dictionary = mgr.calculate_effective_stats(adv, db)

	var serialized: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(serialized)

	var after: Dictionary = mgr.calculate_effective_stats(restored, db)
	assert_eq(after["attack"], before["attack"])
	assert_eq(after["speed"], before["speed"])


func test_empty_equipment_survives_serialization() -> void:
	var serialized: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(serialized)
	assert_eq(restored.equipment["weapon"], null)
	assert_eq(restored.equipment["armor"], null)
	assert_eq(restored.equipment["accessory"], null)


# ===========================================================================
# Group 16: Edge Cases
# ===========================================================================

func test_equip_same_item_twice_is_idempotent() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "iron_sword", db)
	assert_eq(adv.equipment["weapon"], "iron_sword")


func test_stats_deterministic_multiple_calculations() -> void:
	mgr.equip(adv, "iron_sword", db)
	mgr.equip(adv, "chainmail", db)
	var first: Dictionary = mgr.calculate_effective_stats(adv, db)
	var second: Dictionary = mgr.calculate_effective_stats(adv, db)
	for key: String in first:
		assert_eq(first[key], second[key], "Stat '%s' should be deterministic" % key)


func test_slot_to_key_mapping() -> void:
	assert_eq(mgr._slot_to_key(Enums.EquipSlot.WEAPON), "weapon")
	assert_eq(mgr._slot_to_key(Enums.EquipSlot.ARMOR), "armor")
	assert_eq(mgr._slot_to_key(Enums.EquipSlot.ACCESSORY), "accessory")
	assert_eq(mgr._slot_to_key(Enums.EquipSlot.NONE), "")


func test_equip_and_immediately_calculate() -> void:
	mgr.equip(adv, "iron_sword", db)
	var effective: Dictionary = mgr.calculate_effective_stats(adv, db)
	mgr.unequip(adv, Enums.EquipSlot.WEAPON)
	var base: Dictionary = mgr.calculate_effective_stats(adv, db)
	assert_gt(effective["attack"], base["attack"], "Equipped attack should exceed unequipped")
