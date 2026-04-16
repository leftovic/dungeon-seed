extends RefCounted
## Service for equipping/unequipping items on adventurers and calculating effective stats.
##
## Stateless service — all methods operate on AdventurerData and ItemDatabase
## passed as arguments. No internal state is held between calls.
##
## Equipment slots map to AdventurerData.equipment dictionary keys:
##   EquipSlot.WEAPON    → "weapon"
##   EquipSlot.ARMOR     → "armor"
##   EquipSlot.ACCESSORY → "accessory"
##
## Depends on: AdventurerData, ItemData, ItemDatabase, Enums, GameConfig


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Maps EquipSlot enum values to AdventurerData.equipment dictionary keys.
const SLOT_TO_KEY: Dictionary = {
	Enums.EquipSlot.WEAPON: "weapon",
	Enums.EquipSlot.ARMOR: "armor",
	Enums.EquipSlot.ACCESSORY: "accessory",
}


# ---------------------------------------------------------------------------
# Equip / Unequip
# ---------------------------------------------------------------------------

## Equips an item to the adventurer's appropriate slot.
##
## Validates that the item exists in the database, is equippable, and has a
## valid slot. If the target slot is already occupied, the existing item is
## replaced (the previous item_id is lost — inventory management is external).
##
## Returns true on success, false if validation fails.
func equip(adventurer: AdventurerData, item_id: String, item_database: ItemDatabase) -> bool:
	if adventurer == null or item_database == null:
		return false

	var item: ItemData = item_database.get_item(item_id)
	if item == null:
		return false

	if not item.is_equippable:
		return false

	var slot_key: String = _slot_to_key(item.slot)
	if slot_key.is_empty():
		return false

	adventurer.equipment[slot_key] = item_id
	return true


## Removes the item from the given slot and returns its item_id.
##
## Returns an empty string if the slot is already empty or the slot is invalid.
## Does not interact with inventory — the caller is responsible for returning
## the item to the player's inventory if needed.
func unequip(adventurer: AdventurerData, slot: Enums.EquipSlot) -> String:
	if adventurer == null:
		return ""

	var slot_key: String = _slot_to_key(slot)
	if slot_key.is_empty():
		return ""

	var current_id: Variant = adventurer.equipment.get(slot_key, null)
	if current_id == null or (current_id is String and current_id.is_empty()):
		return ""

	var removed_id: String = str(current_id)
	adventurer.equipment[slot_key] = null
	return removed_id


# ---------------------------------------------------------------------------
# Stat Calculation
# ---------------------------------------------------------------------------

## Calculates effective stats for an adventurer: base stats + all equipment bonuses.
##
## Returns a new Dictionary containing every stat key found in either the base
## stats or any equipped item's stat_bonuses. Stats present only on equipment
## (e.g., "crit", "magic") are included with a base value of 0.
##
## Does not mutate the adventurer — returns a fresh dictionary.
func calculate_effective_stats(adventurer: AdventurerData, item_database: ItemDatabase) -> Dictionary:
	if adventurer == null or item_database == null:
		return {}

	var effective: Dictionary = adventurer.stats.duplicate(true)

	var equipped_items: Array[ItemData] = get_equipped_items(adventurer, item_database)
	for item: ItemData in equipped_items:
		for stat_key: String in item.stat_bonuses:
			var bonus: int = int(item.stat_bonuses[stat_key])
			if effective.has(stat_key):
				effective[stat_key] = int(effective[stat_key]) + bonus
			else:
				effective[stat_key] = bonus

	return effective


# ---------------------------------------------------------------------------
# Query Helpers
# ---------------------------------------------------------------------------

## Returns an Array of ItemData for all currently equipped items.
##
## Only includes items that exist in the database. Skips empty slots and
## items whose IDs are not found in the database.
func get_equipped_items(adventurer: AdventurerData, item_database: ItemDatabase) -> Array[ItemData]:
	var result: Array[ItemData] = []
	if adventurer == null or item_database == null:
		return result

	for slot_key: String in GameConfig.EQUIP_SLOT_KEYS:
		var item_id: Variant = adventurer.equipment.get(slot_key, null)
		if item_id == null or (item_id is String and item_id.is_empty()):
			continue
		var item: ItemData = item_database.get_item(str(item_id))
		if item != null:
			result.append(item)

	return result


## Returns true if the given equipment slot on the adventurer is empty.
func is_slot_empty(adventurer: AdventurerData, slot: Enums.EquipSlot) -> bool:
	if adventurer == null:
		return true

	var slot_key: String = _slot_to_key(slot)
	if slot_key.is_empty():
		return true

	var item_id: Variant = adventurer.equipment.get(slot_key, null)
	return item_id == null or (item_id is String and item_id.is_empty())


## Returns the item_id equipped in the given slot, or an empty string if empty.
func get_equipped_item_id(adventurer: AdventurerData, slot: Enums.EquipSlot) -> String:
	if adventurer == null:
		return ""

	var slot_key: String = _slot_to_key(slot)
	if slot_key.is_empty():
		return ""

	var item_id: Variant = adventurer.equipment.get(slot_key, null)
	if item_id == null or (item_id is String and item_id.is_empty()):
		return ""

	return str(item_id)


## Returns the ItemData for the item in the given slot, or null if empty/invalid.
func get_equipped_item(adventurer: AdventurerData, slot: Enums.EquipSlot, item_database: ItemDatabase) -> ItemData:
	var item_id: String = get_equipped_item_id(adventurer, slot)
	if item_id.is_empty() or item_database == null:
		return null
	return item_database.get_item(item_id)


## Returns a Dictionary mapping each slot key to its equipped item_id (or null).
## Keys match GameConfig.EQUIP_SLOT_KEYS: "weapon", "armor", "accessory".
func get_equipment_summary(adventurer: AdventurerData) -> Dictionary:
	if adventurer == null:
		return { "weapon": null, "armor": null, "accessory": null }
	return adventurer.equipment.duplicate(true)


## Validates whether an item can be equipped to the adventurer.
##
## Checks: item exists, item is equippable, item slot matches the target slot.
## Returns true if valid, false otherwise.
func validate_equip(item_id: String, slot: Enums.EquipSlot, item_database: ItemDatabase) -> bool:
	if item_database == null:
		return false

	var item: ItemData = item_database.get_item(item_id)
	if item == null:
		return false

	if not item.is_equippable:
		return false

	if item.slot != slot:
		return false

	return true


## Swaps equipment: equips a new item and returns the previously equipped item_id.
##
## If the slot was empty, returns an empty string. If equip fails, returns
## an empty string and does not modify the adventurer.
func swap_equipment(adventurer: AdventurerData, new_item_id: String, item_database: ItemDatabase) -> String:
	if adventurer == null or item_database == null:
		return ""

	var new_item: ItemData = item_database.get_item(new_item_id)
	if new_item == null or not new_item.is_equippable:
		return ""

	var slot_key: String = _slot_to_key(new_item.slot)
	if slot_key.is_empty():
		return ""

	var old_id: String = unequip(adventurer, new_item.slot)
	adventurer.equipment[slot_key] = new_item_id
	return old_id


## Removes all equipment from the adventurer. Returns an Array of removed item_ids.
func unequip_all(adventurer: AdventurerData) -> Array[String]:
	var removed: Array[String] = []
	if adventurer == null:
		return removed

	for slot_key: String in GameConfig.EQUIP_SLOT_KEYS:
		var item_id: Variant = adventurer.equipment.get(slot_key, null)
		if item_id != null and not (item_id is String and item_id.is_empty()):
			removed.append(str(item_id))
			adventurer.equipment[slot_key] = null

	return removed


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Converts an EquipSlot enum to the corresponding equipment dictionary key.
## Returns an empty string for EquipSlot.NONE or invalid values.
func _slot_to_key(slot: Enums.EquipSlot) -> String:
	return SLOT_TO_KEY.get(slot, "") as String
