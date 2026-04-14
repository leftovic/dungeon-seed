class_name InventoryData
extends RefCounted
## Mutable inventory container mapping item ids to owned quantities.
## Supports add/remove/query operations and serialization for save/load.
##
## This is the runtime representation of "what the player has in their bag."
## Each item id maps to an integer count, not individual object instances.
##
## Depends on: Nothing (uses only String item ids and int quantities)


var items: Dictionary = {}


## Adds the given quantity of an item. Creates entry if absent.
## Asserts that qty > 0 to prevent zero/negative additions.
func add_item(item_id: String, qty: int) -> void:
	assert(qty > 0, "InventoryData.add_item: qty must be > 0, got %d" % qty)
	if items.has(item_id):
		items[item_id] = items[item_id] + qty
	else:
		items[item_id] = qty


## Removes the given quantity of an item. Returns false if insufficient.
## Erases the key entirely when remaining quantity reaches zero.
func remove_item(item_id: String, qty: int) -> bool:
	if not items.has(item_id):
		return false
	var current: int = items[item_id]
	if current < qty:
		return false
	var remaining: int = current - qty
	if remaining == 0:
		items.erase(item_id)
	else:
		items[item_id] = remaining
	return true


## Returns true if the owned quantity of the item is >= the requested amount.
func has_item(item_id: String, qty: int) -> bool:
	return items.get(item_id, 0) >= qty


## Returns the current quantity of the item, or 0 if not owned.
func get_quantity(item_id: String) -> int:
	return items.get(item_id, 0)


## Returns an array of { "item_id": String, "qty": int } for every owned item.
func list_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id: String in items:
		result.append({ "item_id": item_id, "qty": items[item_id] })
	return result


## Returns the number of distinct item ids in the inventory.
func get_unique_item_count() -> int:
	return items.size()


## Returns the sum of all item quantities.
func get_total_item_count() -> int:
	var total: int = 0
	for qty: int in items.values():
		total += qty
	return total


## Removes all items from the inventory.
func clear() -> void:
	items.clear()


## Serializes the inventory to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	return { "items": items.duplicate() }


## Restores the inventory from a serialized Dictionary. Clears existing state first.
func from_dict(data: Dictionary) -> void:
	items.clear()
	var loaded_items: Variant = data.get("items", {})
	if loaded_items is Dictionary:
		for item_id: String in loaded_items:
			var qty: int = int(loaded_items[item_id])
			if qty > 0:
				items[item_id] = qty
			else:
				push_warning("InventoryData.from_dict: Skipping non-positive qty for '%s': %d" % [item_id, qty])


## Combines another inventory into this one additively. Does not modify the source.
func merge(other: InventoryData) -> void:
	for item_id: String in other.items:
		add_item(item_id, other.items[item_id])
