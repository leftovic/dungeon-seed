## tests/services/test_adventurer_ui.gd
## GUT test suite for TASK-020: Adventurer Hall & Inventory UI.
## Covers: initialization, roster display, adventurer detail, inventory display,
## enum name formatting, XP bar data, can_equip, stat comparison, and edge cases.
extends GutTest

const AdventurerUIScript = preload("res://src/ui/adventurer_ui.gd")
const AdventurerRosterScript = preload("res://src/services/adventurer_roster.gd")
const EquipmentManagerScript = preload("res://src/services/equipment_manager.gd")
const AdventurerDataScript = preload("res://src/models/adventurer_data.gd")
const InventoryDataScript = preload("res://src/models/inventory_data.gd")
const WalletScript = preload("res://src/models/wallet.gd")
const ItemDatabaseScript = preload("res://src/models/item_database.gd")
const ItemDataScript = preload("res://src/models/item_data.gd")


# =============================================================================
# HELPERS
# =============================================================================

var _ui: RefCounted
var _roster: RefCounted
var _equip_mgr: RefCounted
var _inventory: RefCounted
var _wallet: RefCounted
var _item_db: RefCounted


func before_each() -> void:
	_roster = AdventurerRosterScript.new()
	_equip_mgr = EquipmentManagerScript.new()
	_inventory = InventoryDataScript.new()
	_wallet = WalletScript.new()
	_item_db = ItemDatabaseScript.new()  # pre-populated with ~20 starter items
	_ui = AdventurerUIScript.new()
	_ui.initialize(_roster, _equip_mgr, _inventory, _wallet, _item_db)


func _make_adventurer(
	id: String = "adv_001",
	adv_class: int = 0,  # WARRIOR
	display_name: String = "TestHero",
	level: int = 1,
	xp: int = 0,
	available: bool = true
) -> RefCounted:
	var adv = AdventurerDataScript.new()
	adv.id = id
	adv.display_name = display_name
	adv.adventurer_class = adv_class as Enums.AdventurerClass
	adv.level = level
	adv.xp = xp
	adv.initialize_base_stats()
	adv.is_available = available
	return adv


func _add_to_roster(adv: RefCounted) -> void:
	_roster.add_adventurer(adv)


func _register_custom_item(id: String, item_name: String, slot: int, bonuses: Dictionary) -> void:
	var data: Dictionary = {
		"id": id,
		"display_name": item_name,
		"rarity": int(Enums.ItemRarity.COMMON),
		"slot": slot,
		"stat_bonuses": bonuses,
		"description": "Test item for unit tests.",
	}
	_item_db.register_item(ItemDataScript.new(data))


## Finds the first entry in a display array matching the given item_id.
func _find_display_entry(display: Array, item_id: String) -> Dictionary:
	for entry in display:
		if entry is Dictionary and entry.get("item_id") == item_id:
			return entry
	return {}


# =============================================================================
# §1: INITIALIZATION (~3 tests)
# =============================================================================

func test_uninitialized_ui_returns_empty_roster() -> void:
	var ui = AdventurerUIScript.new()
	var result: Array = ui.get_roster_display()
	assert_eq(result.size(), 0, "Uninitialized UI returns empty roster display")


func test_initialized_ui_with_empty_roster_returns_empty() -> void:
	# _ui is initialized in before_each with empty roster
	var display: Array = _ui.get_roster_display()
	assert_eq(display.size(), 0, "Initialized UI with empty roster returns []")


func test_initialize_without_item_db_still_works() -> void:
	var ui = AdventurerUIScript.new()
	ui.initialize(_roster, _equip_mgr, _inventory, _wallet)
	var display: Array = ui.get_roster_display()
	assert_eq(display.size(), 0, "Init without item_db does not crash")


# =============================================================================
# §2: ROSTER DISPLAY (~10 tests)
# =============================================================================

func test_roster_display_empty() -> void:
	var display: Array = _ui.get_roster_display()
	assert_eq(display.size(), 0, "Empty roster yields empty display array")


func test_roster_display_one_adventurer() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var display: Array = _ui.get_roster_display()
	assert_eq(display.size(), 1, "One adventurer yields one display entry")


func test_roster_display_multiple_adventurers() -> void:
	_add_to_roster(_make_adventurer("a1", 0, "Alice"))
	_add_to_roster(_make_adventurer("a2", 2, "Bob"))
	_add_to_roster(_make_adventurer("a3", 4, "Carol"))
	var display: Array = _ui.get_roster_display()
	assert_eq(display.size(), 3, "Three adventurers yield three display entries")


func test_roster_display_entry_has_all_keys() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var display: Array = _ui.get_roster_display()
	var entry: Dictionary = display[0]
	for key in ["id", "name", "class", "class_name", "level",
				"condition", "condition_name", "element", "element_name",
				"is_available"]:
		assert_true(entry.has(key), "Roster entry should have key '%s'" % key)


func test_roster_display_correct_id_and_name() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var display: Array = _ui.get_roster_display()
	assert_eq(display[0]["id"], "hero_001")
	assert_eq(display[0]["name"], "Kira")


func test_roster_display_correct_class_name() -> void:
	_add_to_roster(_make_adventurer("hero_001", 2, "Alden"))  # MAGE=2
	var display: Array = _ui.get_roster_display()
	assert_eq(display[0]["class"], 2)
	assert_eq(display[0]["class_name"], "Mage")


func test_roster_display_correct_level() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 7))
	var display: Array = _ui.get_roster_display()
	assert_eq(display[0]["level"], 7)


func test_roster_display_condition_defaults_to_healthy() -> void:
	_add_to_roster(_make_adventurer())
	var display: Array = _ui.get_roster_display()
	assert_eq(display[0]["condition"], 0)
	assert_eq(display[0]["condition_name"], "Healthy")


func test_roster_display_element_defaults_to_none() -> void:
	_add_to_roster(_make_adventurer())
	var display: Array = _ui.get_roster_display()
	assert_eq(display[0]["element"], 5)
	assert_eq(display[0]["element_name"], "None")


func test_roster_display_available_true() -> void:
	_add_to_roster(_make_adventurer("a1", 0, "Hero", 1, 0, true))
	var display: Array = _ui.get_roster_display()
	assert_true(display[0]["is_available"], "Available adventurer should show true")


func test_roster_display_available_false() -> void:
	_add_to_roster(_make_adventurer("a1", 0, "Hero", 1, 0, false))
	var display: Array = _ui.get_roster_display()
	assert_false(display[0]["is_available"], "Unavailable adventurer should show false")


# =============================================================================
# §3: ADVENTURER DETAIL (~13 tests)
# =============================================================================

func test_detail_invalid_id_returns_empty() -> void:
	var detail: Dictionary = _ui.get_adventurer_detail("nonexistent")
	assert_eq(detail.size(), 0, "Invalid ID returns empty dictionary")


func test_detail_has_all_expected_keys() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	for key in ["id", "name", "class", "class_name", "level", "xp", "xp_to_next",
				"condition", "condition_name", "element", "element_name",
				"stats", "equipment"]:
		assert_true(detail.has(key), "Detail should have key '%s'" % key)


func test_detail_correct_name() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_eq(detail["name"], "Kira")


func test_detail_correct_class() -> void:
	_add_to_roster(_make_adventurer("hero_001", 3, "Shade"))  # ROGUE=3
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_eq(detail["class"], 3)
	assert_eq(detail["class_name"], "Rogue")


func test_detail_correct_level() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 5))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_eq(detail["level"], 5)


func test_detail_xp_value() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 1, 42))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_eq(detail["xp"], 42)


func test_detail_xp_to_next_at_level_1() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 1, 0))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	# Level 1: BASE_XP * pow(GROWTH_RATE, 0) = 100 * 1 = 100
	assert_eq(detail["xp_to_next"], 100)


func test_detail_stats_is_nonempty_dict() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_true(detail["stats"] is Dictionary, "stats should be a Dictionary")
	assert_true(detail["stats"].size() > 0, "stats should not be empty")


func test_detail_base_stats_for_warrior() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))  # WARRIOR
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	# Warrior base: health=120, attack=18, defense=15, speed=8, utility=5
	assert_eq(detail["stats"]["health"], 120)
	assert_eq(detail["stats"]["attack"], 18)
	assert_eq(detail["stats"]["defense"], 15)
	assert_eq(detail["stats"]["speed"], 8)
	assert_eq(detail["stats"]["utility"], 5)


func test_detail_stats_include_equipment_bonuses() -> void:
	var adv = _make_adventurer("hero_001", 0, "Kira")
	_equip_mgr.equip(adv, "iron_sword", _item_db)  # attack +5
	_add_to_roster(adv)
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	# Warrior base attack=18 + iron_sword attack=5 → 23
	assert_eq(detail["stats"]["attack"], 23)


func test_detail_equipment_slots_present() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	var equip: Dictionary = detail["equipment"]
	assert_true(equip.has("weapon"), "Equipment has weapon slot")
	assert_true(equip.has("armor"), "Equipment has armor slot")
	assert_true(equip.has("accessory"), "Equipment has accessory slot")


func test_detail_shows_equipped_item_id() -> void:
	var adv = _make_adventurer("hero_001", 0, "Kira")
	_equip_mgr.equip(adv, "iron_sword", _item_db)
	_add_to_roster(adv)
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_eq(detail["equipment"]["weapon"], "iron_sword")


func test_detail_empty_slots_are_null() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira"))
	var detail: Dictionary = _ui.get_adventurer_detail("hero_001")
	assert_null(detail["equipment"]["weapon"], "Empty weapon slot is null")
	assert_null(detail["equipment"]["armor"], "Empty armor slot is null")
	assert_null(detail["equipment"]["accessory"], "Empty accessory slot is null")


# =============================================================================
# §4: INVENTORY DISPLAY (~8 tests)
# =============================================================================

func test_inventory_display_empty() -> void:
	var display: Array = _ui.get_inventory_display()
	assert_eq(display.size(), 0, "Empty inventory yields empty display")


func test_inventory_display_one_item() -> void:
	_inventory.add_item("wooden_sword", 1)
	var display: Array = _ui.get_inventory_display()
	assert_eq(display.size(), 1)


func test_inventory_display_multiple_items() -> void:
	_inventory.add_item("wooden_sword", 2)
	_inventory.add_item("cloth_tunic", 1)
	_inventory.add_item("copper_ring", 3)
	var display: Array = _ui.get_inventory_display()
	assert_eq(display.size(), 3)


func test_inventory_display_entry_has_keys() -> void:
	_inventory.add_item("wooden_sword", 1)
	var display: Array = _ui.get_inventory_display()
	var entry: Dictionary = display[0]
	assert_true(entry.has("item_id"), "Entry has item_id")
	assert_true(entry.has("quantity"), "Entry has quantity")
	assert_true(entry.has("display_name"), "Entry has display_name")


func test_inventory_display_correct_quantity() -> void:
	_inventory.add_item("wooden_sword", 7)
	var display: Array = _ui.get_inventory_display()
	var entry: Dictionary = _find_display_entry(display, "wooden_sword")
	assert_eq(entry["quantity"], 7)


func test_inventory_display_name_from_database() -> void:
	_inventory.add_item("iron_sword", 1)
	var display: Array = _ui.get_inventory_display()
	var entry: Dictionary = _find_display_entry(display, "iron_sword")
	assert_eq(entry["display_name"], "Iron Sword")


func test_inventory_display_unknown_item_uses_raw_id() -> void:
	_inventory.add_item("mystery_orb", 1)
	var display: Array = _ui.get_inventory_display()
	var entry: Dictionary = _find_display_entry(display, "mystery_orb")
	assert_eq(entry["display_name"], "mystery_orb", "Unknown item falls back to raw id")


func test_inventory_display_without_item_db_uses_raw_id() -> void:
	var ui = AdventurerUIScript.new()
	ui.initialize(_roster, _equip_mgr, _inventory, _wallet)  # no item_db
	_inventory.add_item("iron_sword", 1)
	var display: Array = ui.get_inventory_display()
	var entry: Dictionary = _find_display_entry(display, "iron_sword")
	assert_eq(entry["display_name"], "iron_sword", "Without item_db, falls back to raw id")


# =============================================================================
# §5: ENUM NAME FORMATTING (~19 tests)
# =============================================================================

# --- Class names ---

func test_class_name_warrior() -> void:
	assert_eq(_ui.get_class_name_str(0), "Warrior")


func test_class_name_ranger() -> void:
	assert_eq(_ui.get_class_name_str(1), "Ranger")


func test_class_name_mage() -> void:
	assert_eq(_ui.get_class_name_str(2), "Mage")


func test_class_name_rogue() -> void:
	assert_eq(_ui.get_class_name_str(3), "Rogue")


func test_class_name_alchemist() -> void:
	assert_eq(_ui.get_class_name_str(4), "Alchemist")


func test_class_name_sentinel() -> void:
	assert_eq(_ui.get_class_name_str(5), "Sentinel")


func test_class_name_invalid_returns_unknown() -> void:
	assert_eq(_ui.get_class_name_str(99), "Unknown")


# --- Condition names ---

func test_condition_name_healthy() -> void:
	assert_eq(_ui.get_condition_name_str(0), "Healthy")


func test_condition_name_fatigued() -> void:
	assert_eq(_ui.get_condition_name_str(1), "Fatigued")


func test_condition_name_injured() -> void:
	assert_eq(_ui.get_condition_name_str(2), "Injured")


func test_condition_name_exhausted() -> void:
	assert_eq(_ui.get_condition_name_str(3), "Exhausted")


func test_condition_name_invalid_returns_unknown() -> void:
	assert_eq(_ui.get_condition_name_str(99), "Unknown")


# --- Element names ---

func test_element_name_terra() -> void:
	assert_eq(_ui.get_element_name_str(0), "Terra")


func test_element_name_flame() -> void:
	assert_eq(_ui.get_element_name_str(1), "Flame")


func test_element_name_frost() -> void:
	assert_eq(_ui.get_element_name_str(2), "Frost")


func test_element_name_arcane() -> void:
	assert_eq(_ui.get_element_name_str(3), "Arcane")


func test_element_name_shadow() -> void:
	assert_eq(_ui.get_element_name_str(4), "Shadow")


func test_element_name_none() -> void:
	assert_eq(_ui.get_element_name_str(5), "None")


func test_element_name_invalid_returns_unknown() -> void:
	assert_eq(_ui.get_element_name_str(99), "Unknown")


# =============================================================================
# §6: XP BAR DATA (~5 tests)
# =============================================================================

func test_xp_bar_level_1_zero_xp() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 1, 0))
	var data: Dictionary = _ui.get_xp_bar_data("hero_001")
	assert_eq(data["current_xp"], 0)
	assert_eq(data["xp_to_next"], 100)
	assert_eq(data["level"], 1)
	assert_true(is_equal_approx(data["progress"], 0.0), "Progress at 0 xp should be 0.0")


func test_xp_bar_mid_progress() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 1, 50))
	var data: Dictionary = _ui.get_xp_bar_data("hero_001")
	assert_eq(data["current_xp"], 50)
	assert_true(is_equal_approx(data["progress"], 0.5), "50/100 should be 0.5")


func test_xp_bar_near_level_up() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 1, 99))
	var data: Dictionary = _ui.get_xp_bar_data("hero_001")
	assert_eq(data["current_xp"], 99)
	assert_true(data["progress"] > 0.9, "99/100 should be > 0.9")


func test_xp_bar_higher_level() -> void:
	_add_to_roster(_make_adventurer("hero_001", 0, "Kira", 3, 20))
	var data: Dictionary = _ui.get_xp_bar_data("hero_001")
	assert_eq(data["level"], 3)
	assert_eq(data["current_xp"], 20)
	# Level 3: roundi(100 * pow(1.15, 2)) = roundi(132.25) = 132
	assert_eq(data["xp_to_next"], 132)


func test_xp_bar_invalid_id_returns_zeros() -> void:
	var data: Dictionary = _ui.get_xp_bar_data("nonexistent")
	assert_eq(data["current_xp"], 0)
	assert_eq(data["xp_to_next"], 0)
	assert_eq(data["level"], 0)
	assert_true(is_equal_approx(data["progress"], 0.0), "Invalid ID progress is 0.0")


# =============================================================================
# §7: CAN_EQUIP, STAT COMPARISON & EDGE CASES (~10 tests)
# =============================================================================

func test_can_equip_valid_item_in_inventory() -> void:
	_add_to_roster(_make_adventurer("hero_001"))
	_inventory.add_item("iron_sword", 1)
	var result: Dictionary = _ui.can_equip("hero_001", "iron_sword")
	assert_true(result["can_equip"], "Should be able to equip valid item from inventory")
	assert_eq(result["reason"], "")


func test_can_equip_invalid_adventurer_id() -> void:
	var result: Dictionary = _ui.can_equip("nonexistent", "iron_sword")
	assert_false(result["can_equip"])
	assert_eq(result["reason"], "Adventurer not found")


func test_can_equip_invalid_item_id() -> void:
	_add_to_roster(_make_adventurer("hero_001"))
	var result: Dictionary = _ui.can_equip("hero_001", "nonexistent_item")
	assert_false(result["can_equip"])
	assert_eq(result["reason"], "Item not found")


func test_can_equip_item_not_in_inventory() -> void:
	_add_to_roster(_make_adventurer("hero_001"))
	# iron_sword exists in ItemDatabase but is NOT in player inventory
	var result: Dictionary = _ui.can_equip("hero_001", "iron_sword")
	assert_false(result["can_equip"])
	assert_eq(result["reason"], "Item not in inventory")


func test_can_equip_non_equippable_item() -> void:
	_add_to_roster(_make_adventurer("hero_001"))
	# Register a quest item (EquipSlot.NONE = -1)
	_register_custom_item("quest_scroll", "Quest Scroll", -1, {})
	_inventory.add_item("quest_scroll", 1)
	var result: Dictionary = _ui.can_equip("hero_001", "quest_scroll")
	assert_false(result["can_equip"])
	assert_eq(result["reason"], "Item is not equippable")


func test_stat_comparison_equip_from_empty_slot() -> void:
	var adv = _make_adventurer("hero_001", 0, "Kira")  # WARRIOR, no equipment
	_add_to_roster(adv)
	# Compare with iron_sword: attack +5
	var comp: Dictionary = _ui.get_stat_comparison("hero_001", "iron_sword")
	# Current: base warrior attack=18
	assert_eq(comp["current_stats"]["attack"], 18)
	# New: 18 + 5 = 23
	assert_eq(comp["new_stats"]["attack"], 23)
	# Delta
	assert_eq(comp["changes"]["attack"], 5)


func test_stat_comparison_replace_weapon() -> void:
	var adv = _make_adventurer("hero_001", 0, "Kira")
	_equip_mgr.equip(adv, "iron_sword", _item_db)  # attack +5
	_add_to_roster(adv)
	# Replace with steel_blade: attack +9, crit +2
	var comp: Dictionary = _ui.get_stat_comparison("hero_001", "steel_blade")
	assert_eq(comp["current_stats"]["attack"], 23)  # 18+5
	assert_eq(comp["new_stats"]["attack"], 27)       # 18+9
	assert_eq(comp["changes"]["attack"], 4)
	# crit only appears with steel_blade
	assert_eq(comp["changes"].get("crit", 0), 2)


func test_stat_comparison_invalid_adventurer_returns_empty() -> void:
	var comp: Dictionary = _ui.get_stat_comparison("nonexistent", "iron_sword")
	assert_eq(comp["current_stats"].size(), 0)
	assert_eq(comp["new_stats"].size(), 0)
	assert_eq(comp["changes"].size(), 0)


func test_stat_comparison_invalid_item_returns_empty() -> void:
	_add_to_roster(_make_adventurer("hero_001"))
	var comp: Dictionary = _ui.get_stat_comparison("hero_001", "nonexistent_item")
	assert_eq(comp["current_stats"].size(), 0)


func test_stat_comparison_does_not_mutate_equipment() -> void:
	var adv = _make_adventurer("hero_001", 0, "Kira")
	_equip_mgr.equip(adv, "iron_sword", _item_db)
	_add_to_roster(adv)
	# Run stat comparison — must NOT change actual equipment
	_ui.get_stat_comparison("hero_001", "steel_blade")
	assert_eq(adv.equipment["weapon"], "iron_sword",
		"Equipment must not be mutated by stat comparison")
