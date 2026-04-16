## tests/models/test_inventory_data.gd
## GUT test suite for TASK-007: InventoryData model
## Covers: add/remove, has/get, list, counts, clear, serialization, merge
extends GutTest


var inv: InventoryData


func before_each() -> void:
	inv = InventoryData.new()


# ---------------------------------------------------------------------------
# Add Item Tests
# ---------------------------------------------------------------------------

func test_add_item_creates_entry() -> void:
	inv.add_item("iron_sword", 1)
	assert_eq(inv.get_quantity("iron_sword"), 1)


func test_add_item_stacks_quantity() -> void:
	inv.add_item("iron_sword", 1)
	inv.add_item("iron_sword", 3)
	assert_eq(inv.get_quantity("iron_sword"), 4)


func test_add_item_multiple_different_items() -> void:
	inv.add_item("iron_sword", 2)
	inv.add_item("copper_ring", 5)
	assert_eq(inv.get_quantity("iron_sword"), 2)
	assert_eq(inv.get_quantity("copper_ring"), 5)


# ---------------------------------------------------------------------------
# Remove Item Tests
# ---------------------------------------------------------------------------

func test_remove_item_success() -> void:
	inv.add_item("iron_sword", 5)
	var result: bool = inv.remove_item("iron_sword", 3)
	assert_true(result)
	assert_eq(inv.get_quantity("iron_sword"), 2)


func test_remove_item_insufficient_returns_false() -> void:
	inv.add_item("iron_sword", 2)
	var result: bool = inv.remove_item("iron_sword", 5)
	assert_false(result)
	assert_eq(inv.get_quantity("iron_sword"), 2)


func test_remove_item_nonexistent_returns_false() -> void:
	var result: bool = inv.remove_item("nonexistent", 1)
	assert_false(result)


func test_remove_item_exact_quantity_erases_key() -> void:
	inv.add_item("iron_sword", 3)
	var result: bool = inv.remove_item("iron_sword", 3)
	assert_true(result)
	assert_eq(inv.get_quantity("iron_sword"), 0)
	assert_false(inv.has_item("iron_sword", 1))


func test_remove_item_zero_quantity_not_in_list() -> void:
	inv.add_item("iron_sword", 1)
	inv.remove_item("iron_sword", 1)
	var all_items: Array[Dictionary] = inv.list_all()
	for entry in all_items:
		assert_ne(entry["item_id"], "iron_sword")
	# Ensure zero-quantity items are removed from the list
	assert_eq(inv.get_quantity("iron_sword"), 0, "Removed item should have zero quantity")


# ---------------------------------------------------------------------------
# Has Item Tests
# ---------------------------------------------------------------------------

func test_has_item_sufficient() -> void:
	inv.add_item("copper_ring", 10)
	assert_true(inv.has_item("copper_ring", 1))
	assert_true(inv.has_item("copper_ring", 5))
	assert_true(inv.has_item("copper_ring", 10))


func test_has_item_insufficient() -> void:
	inv.add_item("copper_ring", 3)
	assert_false(inv.has_item("copper_ring", 4))
	assert_false(inv.has_item("copper_ring", 100))


func test_has_item_nonexistent() -> void:
	assert_false(inv.has_item("nonexistent", 1))


# ---------------------------------------------------------------------------
# Get Quantity Tests
# ---------------------------------------------------------------------------

func test_get_quantity_existing_item() -> void:
	inv.add_item("leather_vest", 7)
	assert_eq(inv.get_quantity("leather_vest"), 7)


func test_get_quantity_nonexistent_returns_zero() -> void:
	assert_eq(inv.get_quantity("nonexistent"), 0)


# ---------------------------------------------------------------------------
# List All Tests
# ---------------------------------------------------------------------------

func test_list_all_empty_inventory() -> void:
	var result: Array[Dictionary] = inv.list_all()
	assert_eq(result.size(), 0)


func test_list_all_returns_correct_entries() -> void:
	inv.add_item("iron_sword", 2)
	inv.add_item("copper_ring", 5)
	var result: Array[Dictionary] = inv.list_all()
	assert_eq(result.size(), 2)
	var ids: Array[String] = []
	for entry in result:
		ids.append(entry["item_id"])
		assert_true(entry.has("item_id"))
		assert_true(entry.has("qty"))
	assert_has(ids, "iron_sword")
	assert_has(ids, "copper_ring")


# ---------------------------------------------------------------------------
# Count Tests
# ---------------------------------------------------------------------------

func test_get_unique_item_count() -> void:
	inv.add_item("iron_sword", 2)
	inv.add_item("copper_ring", 5)
	inv.add_item("leather_vest", 1)
	assert_eq(inv.get_unique_item_count(), 3)


func test_get_total_item_count() -> void:
	inv.add_item("iron_sword", 2)
	inv.add_item("copper_ring", 5)
	inv.add_item("leather_vest", 1)
	assert_eq(inv.get_total_item_count(), 8)


func test_get_unique_item_count_empty() -> void:
	assert_eq(inv.get_unique_item_count(), 0)


func test_get_total_item_count_empty() -> void:
	assert_eq(inv.get_total_item_count(), 0)


# ---------------------------------------------------------------------------
# Clear Tests
# ---------------------------------------------------------------------------

func test_clear_empties_inventory() -> void:
	inv.add_item("iron_sword", 5)
	inv.add_item("copper_ring", 3)
	inv.clear()
	assert_eq(inv.get_unique_item_count(), 0)
	assert_eq(inv.get_total_item_count(), 0)
	assert_eq(inv.list_all().size(), 0)


# ---------------------------------------------------------------------------
# Serialization Tests
# ---------------------------------------------------------------------------

func test_to_dict_format() -> void:
	inv.add_item("iron_sword", 2)
	inv.add_item("copper_ring", 5)
	var d: Dictionary = inv.to_dict()
	assert_true(d.has("items"))
	assert_eq(d["items"]["iron_sword"], 2)
	assert_eq(d["items"]["copper_ring"], 5)


func test_from_dict_restores_state() -> void:
	inv.add_item("iron_sword", 2)
	inv.add_item("copper_ring", 5)
	var saved: Dictionary = inv.to_dict()
	var loaded: InventoryData = InventoryData.new()
	loaded.from_dict(saved)
	assert_eq(loaded.get_quantity("iron_sword"), 2)
	assert_eq(loaded.get_quantity("copper_ring"), 5)
	assert_eq(loaded.get_unique_item_count(), 2)


func test_from_dict_clears_existing() -> void:
	inv.add_item("old_item", 99)
	inv.from_dict({ "items": { "new_item": 1 } })
	assert_eq(inv.get_quantity("old_item"), 0)
	assert_eq(inv.get_quantity("new_item"), 1)


func test_from_dict_missing_items_key_empties_inventory() -> void:
	inv.add_item("iron_sword", 5)
	inv.from_dict({})
	assert_eq(inv.get_unique_item_count(), 0)


func test_serialization_round_trip() -> void:
	inv.add_item("iron_sword", 3)
	inv.add_item("copper_ring", 7)
	inv.add_item("leather_vest", 1)
	var saved: Dictionary = inv.to_dict()
	var loaded: InventoryData = InventoryData.new()
	loaded.from_dict(saved)
	assert_eq(loaded.to_dict(), saved)


func test_serialization_empty_inventory_round_trip() -> void:
	var saved: Dictionary = inv.to_dict()
	var loaded: InventoryData = InventoryData.new()
	loaded.from_dict(saved)
	assert_eq(loaded.get_unique_item_count(), 0)
	assert_eq(loaded.to_dict(), saved)


# ---------------------------------------------------------------------------
# Merge Tests
# ---------------------------------------------------------------------------

func test_merge_combines_inventories() -> void:
	inv.add_item("iron_sword", 1)
	inv.add_item("copper_ring", 2)
	var other: InventoryData = InventoryData.new()
	other.add_item("copper_ring", 3)
	other.add_item("leather_vest", 1)
	inv.merge(other)
	assert_eq(inv.get_quantity("iron_sword"), 1)
	assert_eq(inv.get_quantity("copper_ring"), 5)
	assert_eq(inv.get_quantity("leather_vest"), 1)


func test_merge_does_not_modify_source() -> void:
	inv.add_item("iron_sword", 1)
	var other: InventoryData = InventoryData.new()
	other.add_item("copper_ring", 3)
	inv.merge(other)
	assert_eq(other.get_quantity("copper_ring"), 3)
	assert_eq(other.get_unique_item_count(), 1)


func test_merge_empty_into_populated() -> void:
	inv.add_item("iron_sword", 5)
	var other: InventoryData = InventoryData.new()
	inv.merge(other)
	assert_eq(inv.get_quantity("iron_sword"), 5)
	assert_eq(inv.get_unique_item_count(), 1)


func test_merge_populated_into_empty() -> void:
	var other: InventoryData = InventoryData.new()
	other.add_item("iron_sword", 5)
	inv.merge(other)
	assert_eq(inv.get_quantity("iron_sword"), 5)
