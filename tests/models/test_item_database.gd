## tests/models/test_item_database.gd
## GUT test suite for TASK-007: ItemDatabase model
## Covers: starter item population, lookup, filtering, registration, validation
extends GutTest

const ItemDatabase = preload("res://src/models/item_database.gd")
const ItemData = preload("res://src/models/item_data.gd")

var db: ItemDatabase


func before_each() -> void:
	db = ItemDatabase.new()


# ---------------------------------------------------------------------------
# Starter Item Population Tests
# ---------------------------------------------------------------------------

func test_database_has_at_least_20_items() -> void:
	assert_gte(db.get_item_count(), 20)


func test_database_has_items_in_all_rarity_tiers() -> void:
	for rarity_value in Enums.ItemRarity.values():
		var items: Array[ItemData] = db.get_items_by_rarity(rarity_value)
		assert_gt(items.size(), 0, "Missing items for rarity %d" % rarity_value)


func test_database_has_at_least_3_weapons() -> void:
	var weapons: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.WEAPON)
	assert_gte(weapons.size(), 3)


func test_database_has_at_least_3_armors() -> void:
	var armors: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ARMOR)
	assert_gte(armors.size(), 3)


func test_database_has_at_least_3_accessories() -> void:
	var accessories: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ACCESSORY)
	assert_gte(accessories.size(), 3)


# ---------------------------------------------------------------------------
# Lookup Tests
# ---------------------------------------------------------------------------

func test_get_item_returns_correct_item() -> void:
	var item: ItemData = db.get_item("iron_sword")
	assert_not_null(item)
	assert_eq(item.id, "iron_sword")
	assert_eq(item.display_name, "Iron Sword")
	assert_eq(item.rarity, Enums.ItemRarity.UNCOMMON)
	assert_eq(item.slot, Enums.EquipSlot.WEAPON)


func test_get_item_nonexistent_returns_null() -> void:
	var item: ItemData = db.get_item("nonexistent_item_xyz")
	assert_null(item)


func test_has_item_existing() -> void:
	assert_true(db.has_item("iron_sword"))
	assert_true(db.has_item("copper_ring"))


func test_has_item_nonexistent() -> void:
	assert_false(db.has_item("nonexistent_item_xyz"))
	assert_false(db.has_item(""))


# ---------------------------------------------------------------------------
# Filter Tests
# ---------------------------------------------------------------------------

func test_get_items_by_rarity_common() -> void:
	var items: Array[ItemData] = db.get_items_by_rarity(Enums.ItemRarity.COMMON)
	for item in items:
		assert_eq(item.rarity, Enums.ItemRarity.COMMON)


func test_get_items_by_rarity_legendary() -> void:
	var items: Array[ItemData] = db.get_items_by_rarity(Enums.ItemRarity.LEGENDARY)
	for item in items:
		assert_eq(item.rarity, Enums.ItemRarity.LEGENDARY)
	assert_gt(items.size(), 0)


func test_get_items_by_slot_weapon() -> void:
	var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.WEAPON)
	for item in items:
		assert_eq(item.slot, Enums.EquipSlot.WEAPON)
		assert_true(item.is_equippable)


func test_get_items_by_slot_armor() -> void:
	var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ARMOR)
	for item in items:
		assert_eq(item.slot, Enums.EquipSlot.ARMOR)


func test_get_items_by_slot_accessory() -> void:
	var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ACCESSORY)
	for item in items:
		assert_eq(item.slot, Enums.EquipSlot.ACCESSORY)


func test_get_equippable_items_excludes_none_slot() -> void:
	var equippable: Array[ItemData] = db.get_equippable_items()
	for item in equippable:
		assert_true(item.is_equippable)
		assert_ne(item.slot, Enums.EquipSlot.NONE)


func test_get_all_items_count_matches() -> void:
	var all_items: Array[ItemData] = db.get_all_items()
	assert_eq(all_items.size(), db.get_item_count())


# ---------------------------------------------------------------------------
# Registration Tests
# ---------------------------------------------------------------------------

func test_register_new_item() -> void:
	var new_item: ItemData = ItemData.new({
		"id": "test_custom_blade",
		"display_name": "Custom Blade",
		"rarity": Enums.ItemRarity.EPIC,
		"slot": Enums.EquipSlot.WEAPON,
		"stat_bonuses": { "attack": 20 },
		"sell_value": { Enums.Currency.GOLD: 200 },
		"description": "A custom test weapon.",
	})
	var count_before: int = db.get_item_count()
	db.register_item(new_item)
	assert_eq(db.get_item_count(), count_before + 1)
	assert_not_null(db.get_item("test_custom_blade"))
	assert_eq(db.get_item("test_custom_blade").display_name, "Custom Blade")


func test_register_item_overwrites_existing() -> void:
	var original: ItemData = db.get_item("iron_sword")
	assert_not_null(original)
	var replacement: ItemData = ItemData.new({
		"id": "iron_sword",
		"display_name": "Iron Sword MK II",
		"rarity": Enums.ItemRarity.RARE,
		"slot": Enums.EquipSlot.WEAPON,
		"stat_bonuses": { "attack": 99 },
		"sell_value": { Enums.Currency.GOLD: 999 },
		"description": "An upgraded iron sword.",
	})
	var count_before: int = db.get_item_count()
	db.register_item(replacement)
	assert_eq(db.get_item_count(), count_before)
	assert_eq(db.get_item("iron_sword").display_name, "Iron Sword MK II")
	assert_eq(db.get_item("iron_sword").get_stat_bonus("attack"), 99)


# ---------------------------------------------------------------------------
# Clear Tests
# ---------------------------------------------------------------------------

func test_clear_removes_all_items() -> void:
	assert_gt(db.get_item_count(), 0)
	db.clear()
	assert_eq(db.get_item_count(), 0)
	assert_null(db.get_item("iron_sword"))


func test_clear_followed_by_register() -> void:
	db.clear()
	var new_item: ItemData = ItemData.new({
		"id": "test_item",
		"display_name": "Test Item",
		"rarity": Enums.ItemRarity.COMMON,
		"slot": Enums.EquipSlot.WEAPON,
		"stat_bonuses": { "attack": 1 },
		"sell_value": { Enums.Currency.GOLD: 1 },
		"description": "Test",
	})
	db.register_item(new_item)
	assert_eq(db.get_item_count(), 1)
	assert_eq(db.get_item("test_item").display_name, "Test Item")


# ---------------------------------------------------------------------------
# Serialization Tests
# ---------------------------------------------------------------------------

func test_to_dict_contains_items_key() -> void:
	var d: Dictionary = db.to_dict()
	assert_true(d.has("items"))
	assert_true(d["items"] is Dictionary)


func test_to_dict_serializes_all_items() -> void:
	var d: Dictionary = db.to_dict()
	var items_dict: Dictionary = d["items"]
	assert_eq(items_dict.size(), db.get_item_count())


func test_from_dict_round_trip_identity() -> void:
	var original_dict: Dictionary = db.to_dict()
	var restored_db: ItemDatabase = ItemDatabase.from_dict(original_dict)
	assert_eq(restored_db.get_item_count(), db.get_item_count())
	# Verify a few specific items
	assert_not_null(restored_db.get_item("iron_sword"))
	assert_eq(restored_db.get_item("iron_sword").display_name, "Iron Sword")
	assert_not_null(restored_db.get_item("obsidian_charm"))
	assert_eq(restored_db.get_item("obsidian_charm").rarity, Enums.ItemRarity.LEGENDARY)


func test_from_dict_empty_creates_empty_db() -> void:
	var empty_db: ItemDatabase = ItemDatabase.from_dict({})
	assert_eq(empty_db.get_item_count(), 0)


func test_from_dict_missing_items_key_creates_empty_db() -> void:
	var empty_db: ItemDatabase = ItemDatabase.from_dict({"other_key": "value"})
	assert_eq(empty_db.get_item_count(), 0)


# ---------------------------------------------------------------------------
# Load From Dict Tests
# ---------------------------------------------------------------------------

func test_load_from_dict_adds_items() -> void:
	var count_before: int = db.get_item_count()
	db.load_from_dict({
		"test_item_1": {
			"display_name": "Test Item 1",
			"rarity": Enums.ItemRarity.COMMON,
			"slot": Enums.EquipSlot.WEAPON,
			"stat_bonuses": { "attack": 1 },
			"sell_value": { Enums.Currency.GOLD: 1 },
			"description": "Test 1",
		},
		"test_item_2": {
			"display_name": "Test Item 2",
			"rarity": Enums.ItemRarity.UNCOMMON,
			"slot": Enums.EquipSlot.ARMOR,
			"stat_bonuses": { "defense": 5 },
			"sell_value": { Enums.Currency.GOLD: 10 },
			"description": "Test 2",
		},
	})
	assert_eq(db.get_item_count(), count_before + 2)
	assert_not_null(db.get_item("test_item_1"))
	assert_eq(db.get_item("test_item_1").display_name, "Test Item 1")
	assert_not_null(db.get_item("test_item_2"))
	assert_eq(db.get_item("test_item_2").display_name, "Test Item 2")


# ---------------------------------------------------------------------------
# Starter Item Validation
# ---------------------------------------------------------------------------

func test_all_starter_items_have_nonempty_id() -> void:
	for item in db.get_all_items():
		assert_ne(item.id, "", "Item has empty id")


func test_all_starter_items_have_nonempty_display_name() -> void:
	for item in db.get_all_items():
		assert_ne(item.display_name, "", "Item %s has empty display_name" % item.id)


func test_all_equippable_items_have_stat_bonuses() -> void:
	for item in db.get_equippable_items():
		assert_gt(item.stat_bonuses.size(), 0, "Equippable item %s has no stat bonuses" % item.id)


func test_all_starter_items_have_valid_rarity() -> void:
	var valid_rarities: Array = Enums.ItemRarity.values()
	for item in db.get_all_items():
		assert_has(valid_rarities, item.rarity, "Item %s has invalid rarity" % item.id)
