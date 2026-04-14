## tests/models/test_item_data.gd
## GUT test suite for TASK-007: ItemData model
## Covers: construction, stat bonuses, sell values, rarity colors, serialization round-trip
extends GutTest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_sword_data() -> Dictionary:
	return {
		"id": "test_iron_sword",
		"display_name": "Iron Sword",
		"rarity": Enums.ItemRarity.UNCOMMON,
		"slot": Enums.EquipSlot.WEAPON,
		"stat_bonuses": { "attack": 5, "crit": 1 },
		"sell_value": { Enums.Currency.GOLD: 15, Enums.Currency.ESSENCE: 2 },
		"description": "A sturdy blade forged from common iron.",
	}


func _make_ring_data() -> Dictionary:
	return {
		"id": "test_copper_ring",
		"display_name": "Copper Ring",
		"rarity": Enums.ItemRarity.COMMON,
		"slot": Enums.EquipSlot.ACCESSORY,
		"stat_bonuses": { "hp": 5 },
		"sell_value": { Enums.Currency.GOLD: 3 },
		"description": "A simple copper band.",
	}


func _make_quest_item_data() -> Dictionary:
	return {
		"id": "test_dungeon_key",
		"display_name": "Dungeon Key",
		"rarity": Enums.ItemRarity.COMMON,
		"slot": Enums.EquipSlot.NONE,
		"stat_bonuses": {},
		"sell_value": {},
		"description": "Opens a sealed dungeon door.",
	}


# ---------------------------------------------------------------------------
# Construction Tests
# ---------------------------------------------------------------------------

func test_construction_sets_all_fields() -> void:
	var data: Dictionary = _make_sword_data()
	var item: ItemData = ItemData.new(data)
	assert_eq(item.id, "test_iron_sword")
	assert_eq(item.display_name, "Iron Sword")
	assert_eq(item.rarity, Enums.ItemRarity.UNCOMMON)
	assert_eq(item.slot, Enums.EquipSlot.WEAPON)
	assert_eq(item.stat_bonuses["attack"], 5)
	assert_eq(item.stat_bonuses["crit"], 1)
	assert_eq(item.sell_value[Enums.Currency.GOLD], 15)
	assert_eq(item.sell_value[Enums.Currency.ESSENCE], 2)
	assert_eq(item.description, "A sturdy blade forged from common iron.")


func test_is_equippable_true_for_weapon() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	assert_true(item.is_equippable)


func test_is_equippable_true_for_accessory() -> void:
	var item: ItemData = ItemData.new(_make_ring_data())
	assert_true(item.is_equippable)


func test_is_equippable_false_for_none_slot() -> void:
	var item: ItemData = ItemData.new(_make_quest_item_data())
	assert_false(item.is_equippable)


# ---------------------------------------------------------------------------
# Stat Bonus Tests
# ---------------------------------------------------------------------------

func test_get_stat_bonus_existing_stat() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	assert_eq(item.get_stat_bonus("attack"), 5)
	assert_eq(item.get_stat_bonus("crit"), 1)


func test_get_stat_bonus_missing_stat_returns_zero() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	assert_eq(item.get_stat_bonus("defense"), 0)
	assert_eq(item.get_stat_bonus("nonexistent"), 0)


func test_get_stat_bonus_empty_bonuses() -> void:
	var item: ItemData = ItemData.new(_make_quest_item_data())
	assert_eq(item.get_stat_bonus("attack"), 0)


# ---------------------------------------------------------------------------
# Sell Value Tests
# ---------------------------------------------------------------------------

func test_get_sell_value_existing_currency() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	assert_eq(item.get_sell_value(Enums.Currency.GOLD), 15)
	assert_eq(item.get_sell_value(Enums.Currency.ESSENCE), 2)


func test_get_sell_value_missing_currency_returns_zero() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	assert_eq(item.get_sell_value(Enums.Currency.FRAGMENTS), 0)
	assert_eq(item.get_sell_value(Enums.Currency.ARTIFACTS), 0)


func test_get_sell_value_empty_sell_dict() -> void:
	var item: ItemData = ItemData.new(_make_quest_item_data())
	assert_eq(item.get_sell_value(Enums.Currency.GOLD), 0)


# ---------------------------------------------------------------------------
# Rarity Color Tests
# ---------------------------------------------------------------------------

func test_get_rarity_color_common() -> void:
	var item: ItemData = ItemData.new(_make_ring_data())
	var expected: Color = GameConfig.RARITY_COLORS[Enums.ItemRarity.COMMON]
	assert_eq(item.get_rarity_color(), expected)


func test_get_rarity_color_uncommon() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	var expected: Color = GameConfig.RARITY_COLORS[Enums.ItemRarity.UNCOMMON]
	assert_eq(item.get_rarity_color(), expected)


# ---------------------------------------------------------------------------
# Serialization Tests
# ---------------------------------------------------------------------------

func test_to_dict_contains_all_fields() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	var d: Dictionary = item.to_dict()
	assert_true(d.has("id"))
	assert_true(d.has("display_name"))
	assert_true(d.has("rarity"))
	assert_true(d.has("slot"))
	assert_true(d.has("stat_bonuses"))
	assert_true(d.has("sell_value"))
	assert_true(d.has("description"))


func test_to_dict_stores_enums_as_ints() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	var d: Dictionary = item.to_dict()
	assert_eq(typeof(d["rarity"]), TYPE_INT)
	assert_eq(typeof(d["slot"]), TYPE_INT)
	assert_eq(d["rarity"], int(Enums.ItemRarity.UNCOMMON))
	assert_eq(d["slot"], int(Enums.EquipSlot.WEAPON))


func test_to_dict_sell_value_keys_are_ints() -> void:
	var item: ItemData = ItemData.new(_make_sword_data())
	var d: Dictionary = item.to_dict()
	for key in d["sell_value"].keys():
		assert_eq(typeof(key), TYPE_INT)


func test_from_dict_reconstructs_item() -> void:
	var original: ItemData = ItemData.new(_make_sword_data())
	var d: Dictionary = original.to_dict()
	var restored: ItemData = ItemData.from_dict(d)
	assert_eq(restored.id, original.id)
	assert_eq(restored.display_name, original.display_name)
	assert_eq(restored.rarity, original.rarity)
	assert_eq(restored.slot, original.slot)
	assert_eq(restored.is_equippable, original.is_equippable)
	assert_eq(restored.stat_bonuses, original.stat_bonuses)
	assert_eq(restored.description, original.description)


func test_from_dict_round_trip_identity() -> void:
	var original: ItemData = ItemData.new(_make_sword_data())
	var restored: ItemData = ItemData.from_dict(original.to_dict())
	assert_eq(restored.to_dict(), original.to_dict())


func test_from_dict_missing_optional_keys_uses_defaults() -> void:
	var minimal: Dictionary = { "id": "bare_item", "display_name": "Bare" }
	var item: ItemData = ItemData.from_dict(minimal)
	assert_eq(item.id, "bare_item")
	assert_eq(item.display_name, "Bare")
	assert_eq(item.rarity, Enums.ItemRarity.COMMON)
	assert_eq(item.slot, Enums.EquipSlot.NONE)
	assert_false(item.is_equippable)
	assert_eq(item.stat_bonuses, {})
	assert_eq(item.sell_value, {})
	assert_eq(item.description, "")


func test_from_dict_quest_item_round_trip() -> void:
	var original: ItemData = ItemData.new(_make_quest_item_data())
	var restored: ItemData = ItemData.from_dict(original.to_dict())
	assert_eq(restored.id, original.id)
	assert_false(restored.is_equippable)
	assert_eq(restored.stat_bonuses, {})
